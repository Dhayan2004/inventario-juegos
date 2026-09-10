// Server actions for team / tenant management. L-003 enforced — whitelist
// validation con Zod schemas explícitos por field (NUNCA z.record(z.any())).
//
// Las 9 acciones de teams-model §4. Las destructivas (revoke/remove/delete/
// transfer/leave/updateRole) siguen el patrón R14: reciben un campo de
// confirmación tipada y corren SÓLO tras esa confirmación en UI. NO se exponen
// como agentic tools con execute() automático — humano-in-the-loop obligatorio.
//
// La autoridad real vive en Postgres (RLS + funciones definer + triggers de
// 0005_teams.sql). Estas actions son la cara server-side: NO reimplementan la
// frontera de seguridad, sólo invocan a través del server client con la sesión
// del caller, de modo que RLS valida cada operación. El organization_id NUNCA
// se confía del body sin que RLS lo valide (R16 invariante 3).
//
// Cita:
// - [memory:lessons#L-005]   (la autoridad de tenant se enforce en RLS, no en código)
// - [memory:CONSTRAINTS.md#R14] (destructivas → confirmación tipada, sin execute())
// - [memory:CONSTRAINTS.md#R16] (aislamiento de tenant: organization_id validado por RLS)
// - [memory:lessons#L-003]   (whitelist Zod explícita por field)
// - [docs:supabase-js] [docs:nextjs]
'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { cookies } from 'next/headers';
import { z } from 'zod';
import { createClient } from '@/lib/supabase/server';

// Cookie de org activa (espejo server-side de la que escribe useOrganization en
// el cliente). NO es fuente de autoridad: RLS valida cada acceso (R16). Sólo es
// una preferencia de UI persistida; httpOnly para que no la manipule JS del cliente.
const ACTIVE_ORG_COOKIE = 'forja-active-org';
const ACTIVE_ORG_COOKIE_MAX_AGE = 60 * 60 * 24 * 30; // 30 días

// ─────────────────────────────────────────────────────────────────────────────
// L-003: whitelist explícita por field. Nada de z.record(z.any()).
// ─────────────────────────────────────────────────────────────────────────────
const uuidSchema = z.string().uuid();
const emailSchema = z.string().email().max(254);
const orgNameSchema = z.string().min(2).max(80);
// slug: minúsculas, números y guiones (kebab) — sin espacios ni símbolos raros.
const slugSchema = z
  .string()
  .min(2)
  .max(48)
  .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, 'Slug must be lowercase kebab-case');
// El cliente NUNCA elige 'owner' por estas vías — sólo admin|member (teams-model §1).
const invitableRoleSchema = z.enum(['admin', 'member']);
const inviteTokenSchema = z.string().min(16).max(256);

const createOrganizationSchema = z.object({
  name: orgNameSchema,
  slug: slugSchema,
});

const inviteMemberSchema = z.object({
  organization_id: uuidSchema,
  email: emailSchema,
  role: invitableRoleSchema,
});

const acceptInvitationSchema = z.object({
  invite_token: inviteTokenSchema,
});

// ── Destructivas (R14): cada una exige un campo de confirmación tipada. ──
const revokeInvitationSchema = z.object({
  organization_id: uuidSchema,
  invitation_id: uuidSchema,
});

const updateMemberRoleSchema = z.object({
  organization_id: uuidSchema,
  membership_id: uuidSchema,
  // updateMemberRole NUNCA permite role='owner' (la promoción a owner sólo
  // ocurre vía transferOwnership → transfer_org_ownership, atómico y owner-only).
  role: invitableRoleSchema,
});

const removeMemberSchema = z.object({
  organization_id: uuidSchema,
  membership_id: uuidSchema,
});

const leaveOrganizationSchema = z.object({
  organization_id: uuidSchema,
});

const transferOwnershipSchema = z.object({
  organization_id: uuidSchema,
  // La UI sólo conoce el EMAIL del nuevo owner; resolvemos email→user_id
  // server-side contra las memberships de ESA org (debe ser miembro existente).
  new_owner_email: emailSchema,
  // R14: confirmación tipada — el caller debe escribir el NOMBRE exacto de la org.
  confirm_name: orgNameSchema,
});

const renameOrganizationSchema = z.object({
  organization_id: uuidSchema,
  name: orgNameSchema,
});

const setActiveOrganizationSchema = z.object({
  organization_id: uuidSchema,
});

const resendInvitationSchema = z.object({
  organization_id: uuidSchema,
  invitation_id: uuidSchema,
});

const deleteOrganizationSchema = z.object({
  organization_id: uuidSchema,
  // R14: confirmación tipada — el caller debe escribir el SLUG exacto de la org.
  confirm_slug: slugSchema,
});

type ActionResult = { error?: string; success?: boolean };

function parseFormData<T>(
  schema: z.ZodSchema<T>,
  formData: FormData,
): T | { error: string } {
  const raw = Object.fromEntries(formData.entries());
  const parsed = schema.safeParse(raw);
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message ?? 'Invalid input' };
  }
  return parsed.data;
}

// ═════════════════════════════════════════════════════════════════════════════
// NO-destructivas
// ═════════════════════════════════════════════════════════════════════════════

// Crear una org. El trigger creator→owner (0000_tenancy.sql) inserta la
// membership owner del caller automáticamente — aquí NO insertamos memberships.
export async function createOrganization(formData: FormData): Promise<ActionResult> {
  const parsed = parseFormData(createOrganizationSchema, formData);
  if ('error' in parsed) return { error: parsed.error };

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { error: 'Not authenticated' };

  const { error } = await supabase
    .from('organizations')
    .insert({ name: parsed.name, slug: parsed.slug });
  if (error) return { error: error.message };

  revalidatePath('/', 'layout');
  return { success: true };
}

// Invitar por email. RLS ("invitations create") exige que el caller sea
// owner/admin de organization_id — el body NO se confía (R16 invariante 3): si
// el caller no pertenece a esa org con rol suficiente, el insert rebota por RLS.
// El token, status, invited_by y expires_at los pone la DB (defaults de la tabla).
export async function inviteMember(formData: FormData): Promise<ActionResult> {
  const parsed = parseFormData(inviteMemberSchema, formData);
  if ('error' in parsed) return { error: parsed.error };

  const supabase = await createClient();
  const { error } = await supabase.from('invitations').insert({
    organization_id: parsed.organization_id,
    email: parsed.email,
    role: parsed.role,
  });
  if (error) return { error: error.message };

  revalidatePath('/', 'layout');
  return { success: true };
}

// Aceptar invitación. Recibe el token OPACO de la landing /invite/[token] como
// string (no FormData: los call-sites lo pasan directo). Lo validamos con Zod y
// llamamos a la función SECURITY DEFINER accept_invitation, que revalida token +
// status + expiración + match de email JWT↔invitación antes de insertar la
// membership (el cliente NUNCA elige su rol). teams-model §2.
export async function acceptInvitation(token: string): Promise<ActionResult> {
  const parsed = acceptInvitationSchema.safeParse({ invite_token: token });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message ?? 'Invalid invitation token' };
  }

  const supabase = await createClient();
  const { error } = await supabase.rpc('accept_invitation', {
    invite_token: parsed.data.invite_token,
  });
  if (error) return { error: error.message };

  revalidatePath('/', 'layout');
  redirect('/dashboard');
}

// Fijar la org activa. Valida el uuid, verifica MEMBRESÍA vía RLS (un select
// sobre memberships del caller; si no pertenece, no hay fila) y SÓLO entonces
// escribe la cookie httpOnly. NO se confía el orgId sin validar la membresía
// (R16 inv. 3): la cookie es preferencia de UI, no autoridad.
export async function setActiveOrganization(orgId: string): Promise<ActionResult> {
  const parsed = setActiveOrganizationSchema.safeParse({ organization_id: orgId });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message ?? 'Invalid organization id' };
  }

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { error: 'Not authenticated' };

  // RLS sobre memberships ya limita a las del caller; si la org no es suya, vacío.
  const { data: membership, error } = await supabase
    .from('memberships')
    .select('id')
    .eq('organization_id', parsed.data.organization_id)
    .eq('user_id', user.id)
    .maybeSingle();
  if (error) return { error: error.message };
  if (!membership) return { error: 'You are not a member of that organization' };

  const cookieStore = await cookies();
  cookieStore.set(ACTIVE_ORG_COOKIE, parsed.data.organization_id, {
    httpOnly: true,
    sameSite: 'lax',
    secure: process.env.NODE_ENV === 'production',
    path: '/',
    maxAge: ACTIVE_ORG_COOKIE_MAX_AGE,
  });

  revalidatePath('/', 'layout');
  return { success: true };
}

// Leer la org activa para el primer render server-side. Devuelve la org de la
// cookie SÓLO si el caller sigue siendo miembro (RLS lo valida); si está vacía o
// ya no es miembro, hace fallback a la primera org del usuario. Nunca confía la
// cookie sin revalidar la membresía (R16).
export async function getActiveOrganizationId(): Promise<string | null> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;

  const cookieStore = await cookies();
  const cookieOrgId = cookieStore.get(ACTIVE_ORG_COOKIE)?.value ?? null;

  if (cookieOrgId && uuidSchema.safeParse(cookieOrgId).success) {
    // RLS limita memberships a las del caller; si la cookie apunta a una org
    // ajena/abandonada, no hay fila y caemos al fallback.
    const { data: membership } = await supabase
      .from('memberships')
      .select('id')
      .eq('organization_id', cookieOrgId)
      .eq('user_id', user.id)
      .maybeSingle();
    if (membership) return cookieOrgId;
  }

  // Fallback: la primera org del usuario (RLS-scoped).
  const { data: first } = await supabase
    .from('memberships')
    .select('organization_id, created_at')
    .eq('user_id', user.id)
    .order('created_at', { ascending: true })
    .limit(1)
    .maybeSingle();
  return (first?.organization_id as string | undefined) ?? null;
}

// Renombrar la org. NO es destructiva (sin R14): la policy "admins update org"
// (sobre organizations) gobierna quién puede — el body NO se confía (R16): si el
// caller no es owner/admin de esa org, el update rebota por RLS.
export async function renameOrganization(formData: FormData): Promise<ActionResult> {
  const parsed = parseFormData(renameOrganizationSchema, formData);
  if ('error' in parsed) return { error: parsed.error };

  const supabase = await createClient();
  const { error } = await supabase
    .from('organizations')
    .update({ name: parsed.name })
    .eq('id', parsed.organization_id); // R16: scoping por org (RLS lo re-valida)
  if (error) return { error: error.message };

  revalidatePath('/', 'layout');
  return { success: true };
}

// ═════════════════════════════════════════════════════════════════════════════
// Destructivas — R14: corren tras confirmación tipada en UI. NUNCA se exportan
// como agentic tools con execute() automático. [memory:CONSTRAINTS.md#R14]
// ═════════════════════════════════════════════════════════════════════════════

// Revocar invitación pendiente. RLS ("invitations manage") exige owner/admin de
// la org. Marca status='revoked' (no borra: deja rastro de auditoría).
export async function revokeInvitation(formData: FormData): Promise<ActionResult> {
  const parsed = parseFormData(revokeInvitationSchema, formData);
  if ('error' in parsed) return { error: parsed.error };

  const supabase = await createClient();
  const { error } = await supabase
    .from('invitations')
    .update({ status: 'revoked' })
    .eq('id', parsed.invitation_id)
    .eq('organization_id', parsed.organization_id) // R16: scoping por org (RLS lo re-valida)
    .eq('status', 'pending');
  if (error) return { error: error.message };

  revalidatePath('/', 'layout');
  return { success: true };
}

// Reenviar invitación: NO es destructiva. Sólo extiende la expiración de una
// invitación que SIGUE pendiente (refresca su ventana de 7 días). NUNCA reactiva
// una invitación revoked/expired (el WHERE status='pending' lo garantiza). RLS
// ("invitations manage") exige owner/admin de la org.
export async function resendInvitation(formData: FormData): Promise<ActionResult> {
  const parsed = parseFormData(resendInvitationSchema, formData);
  if ('error' in parsed) return { error: parsed.error };

  const supabase = await createClient();
  const { error } = await supabase
    .from('invitations')
    .update({ expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString() })
    .eq('id', parsed.invitation_id)
    .eq('organization_id', parsed.organization_id) // R16: scoping por org (RLS lo re-valida)
    .eq('status', 'pending'); // NUNCA reactivar revoked/expired
  if (error) return { error: error.message };

  revalidatePath('/', 'layout');
  return { success: true };
}

// Cambiar rol de un miembro. NUNCA a 'owner' (lo impide el schema invitableRole
// + el WITH CHECK de la policy "manage memberships update"). RLS además exige que
// el caller sea owner/admin y que un admin no toque a un owner. teams-model §3.
export async function updateMemberRole(formData: FormData): Promise<ActionResult> {
  const parsed = parseFormData(updateMemberRoleSchema, formData);
  if ('error' in parsed) return { error: parsed.error };

  const supabase = await createClient();
  const { error } = await supabase
    .from('memberships')
    .update({ role: parsed.role })
    .eq('id', parsed.membership_id)
    .eq('organization_id', parsed.organization_id); // R16: scoping por org (RLS lo re-valida)
  if (error) return { error: error.message };

  revalidatePath('/', 'layout');
  return { success: true };
}

// Expulsar a un miembro. RLS ("manage memberships delete") + el trigger
// guard_last_owner impiden que un admin expulse a un owner o que la org quede
// sin owner. El caller no puede expulsarse a sí mismo si es el último owner.
export async function removeMember(formData: FormData): Promise<ActionResult> {
  const parsed = parseFormData(removeMemberSchema, formData);
  if ('error' in parsed) return { error: parsed.error };

  const supabase = await createClient();
  const { error } = await supabase
    .from('memberships')
    .delete()
    .eq('id', parsed.membership_id)
    .eq('organization_id', parsed.organization_id); // R16: scoping por org (RLS lo re-valida)
  if (error) return { error: error.message };

  revalidatePath('/', 'layout');
  return { success: true };
}

// Salir de la org. Borra la membership del propio caller. Si es el único owner,
// el trigger guard_last_owner aborta — debe transferir la propiedad primero.
export async function leaveOrganization(formData: FormData): Promise<ActionResult> {
  const parsed = parseFormData(leaveOrganizationSchema, formData);
  if ('error' in parsed) return { error: parsed.error };

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { error: 'Not authenticated' };

  const { error } = await supabase
    .from('memberships')
    .delete()
    .eq('organization_id', parsed.organization_id) // R16: scoping por org (RLS lo re-valida)
    .eq('user_id', user.id);
  if (error) return { error: error.message };

  revalidatePath('/', 'layout');
  redirect('/dashboard');
}

// Transferir la propiedad. Llama a transfer_org_ownership (atómico, owner-only):
// degrada al owner actual a admin y promueve al nuevo en una sola transacción.
// La UI sólo conoce el EMAIL del nuevo owner; aquí lo resolvemos a user_id contra
// las memberships de ESA org (intersección con profiles) — debe ser un miembro
// existente. R14: el caller debe escribir el NOMBRE exacto de la org como
// confirmación; lo validamos contra la fila real (no contra el body). La RPC
// reexige que el caller sea owner (definer), pero también lo verificamos aquí.
export async function transferOwnership(formData: FormData): Promise<ActionResult> {
  const parsed = parseFormData(transferOwnershipSchema, formData);
  if ('error' in parsed) return { error: parsed.error };

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { error: 'Not authenticated' };

  // R14 typed-confirmation gate: la frase debe igualar el name REAL de la org.
  const { data: org, error: readError } = await supabase
    .from('organizations')
    .select('name')
    .eq('id', parsed.organization_id) // RLS asegura que sólo se lea una org propia
    .single();
  if (readError || !org) return { error: 'Organization not found' };
  if (org.name !== parsed.confirm_name) {
    return { error: `Confirmation mismatch. Type the organization name exactly: "${org.name}"` };
  }

  // El caller debe ser owner de esta org (RLS lo limita a su propia membership).
  const { data: callerMembership } = await supabase
    .from('memberships')
    .select('role')
    .eq('organization_id', parsed.organization_id)
    .eq('user_id', user.id)
    .maybeSingle();
  if (callerMembership?.role !== 'owner') {
    return { error: 'Only the current owner can transfer ownership' };
  }

  // Resolver email→user_id: join memberships∩profiles de ESA org. RLS sobre
  // memberships ya nos limita a co-miembros de orgs propias; el filtro por
  // profiles.email exige que el destinatario sea un miembro existente.
  const { data: target } = await supabase
    .from('memberships')
    .select('user_id, profiles!inner ( email )')
    .eq('organization_id', parsed.organization_id)
    .eq('profiles.email', parsed.new_owner_email)
    .maybeSingle();
  const newOwnerId = (target?.user_id as string | undefined) ?? null;
  if (!newOwnerId) {
    return { error: 'The new owner must already be a member of this organization' };
  }

  const { error } = await supabase.rpc('transfer_org_ownership', {
    org: parsed.organization_id,
    new_owner: newOwnerId,
  });
  if (error) return { error: error.message };

  revalidatePath('/', 'layout');
  return { success: true };
}

// Borrar la org (cascade). Sólo owner (RLS sobre organizations lo enforce).
// R14: el caller debe escribir el SLUG exacto como confirmación; lo validamos
// contra la fila real antes de borrar.
export async function deleteOrganization(formData: FormData): Promise<ActionResult> {
  const parsed = parseFormData(deleteOrganizationSchema, formData);
  if ('error' in parsed) return { error: parsed.error };

  const supabase = await createClient();

  // R14 typed-confirmation gate: la frase debe igualar el slug REAL de la org.
  const { data: org, error: readError } = await supabase
    .from('organizations')
    .select('slug')
    .eq('id', parsed.organization_id) // RLS asegura que sólo se lea una org propia
    .single();
  if (readError || !org) return { error: 'Organization not found' };
  if (org.slug !== parsed.confirm_slug) {
    return { error: `Confirmation mismatch. Type the organization slug exactly: "${org.slug}"` };
  }

  const { error } = await supabase
    .from('organizations')
    .delete()
    .eq('id', parsed.organization_id);
  if (error) return { error: error.message };

  revalidatePath('/', 'layout');
  redirect('/dashboard');
}

// Explicit (R14): NINGUNA destructiva de este módulo se exporta como agentic
// tool con execute() async automático. Todas requieren humano-in-the-loop con
// confirmación tipada desde la UI antes de correr.
