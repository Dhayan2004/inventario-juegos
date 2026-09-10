// Server actions for auth flows (Insforge variant). L-003 enforced.
//
// Cita: [memory:lessons#L-003] [docs:insforge] [docs:nextjs]
'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { z } from 'zod';
import { createClient } from '@/lib/insforge/server';

const emailSchema = z.string().email().max(254);
const passwordSchema = z.string().min(8).max(128);
const fullNameSchema = z.string().min(1).max(120).optional();

const credentialsSchema = z.object({
  email: emailSchema,
  password: passwordSchema,
});
const resetPasswordSchema = z.object({ email: emailSchema });
const updatePasswordSchema = z.object({ password: passwordSchema });
const updateProfileSchema = z.object({ full_name: fullNameSchema });

type ActionResult = { error?: string; success?: boolean };

function parseFormData<T>(schema: z.ZodSchema<T>, formData: FormData): T | { error: string } {
  const raw = Object.fromEntries(formData.entries());
  const parsed = schema.safeParse(raw);
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message ?? 'Invalid input' };
  }
  return parsed.data;
}

export async function login(formData: FormData): Promise<ActionResult> {
  const parsed = parseFormData(credentialsSchema, formData);
  if ('error' in parsed) return { error: parsed.error };

  const insforge = await createClient();
  const { error } = await insforge.auth.signIn(parsed);
  if (error) return { error: error.message };

  revalidatePath('/', 'layout');
  redirect('/dashboard');
}

export async function signup(formData: FormData): Promise<ActionResult> {
  const parsed = parseFormData(credentialsSchema, formData);
  if ('error' in parsed) return { error: parsed.error };

  const insforge = await createClient();
  const { error } = await insforge.auth.signUp(parsed);
  if (error) return { error: error.message };

  revalidatePath('/', 'layout');
  redirect('/check-email');
}

export async function signout(): Promise<void> {
  const insforge = await createClient();
  await insforge.auth.signOut();
  revalidatePath('/', 'layout');
  redirect('/sign-in');
}

export async function resetPassword(formData: FormData): Promise<ActionResult> {
  const parsed = parseFormData(resetPasswordSchema, formData);
  if ('error' in parsed) return { error: parsed.error };

  const insforge = await createClient();
  const { error } = await insforge.auth.sendPasswordReset({
    email: parsed.email,
    redirectTo: `${process.env.NEXT_PUBLIC_SITE_URL}/update-password`,
  });
  if (error) return { error: error.message };

  return { success: true };
}

export async function updatePassword(formData: FormData): Promise<ActionResult> {
  const parsed = parseFormData(updatePasswordSchema, formData);
  if ('error' in parsed) return { error: parsed.error };

  const insforge = await createClient();
  const { error } = await insforge.auth.updatePassword({ password: parsed.password });
  if (error) return { error: error.message };

  revalidatePath('/', 'layout');
  redirect('/dashboard');
}

export async function updateProfile(formData: FormData): Promise<ActionResult> {
  const parsed = parseFormData(updateProfileSchema, formData);
  if ('error' in parsed) return { error: parsed.error };

  const insforge = await createClient();
  const {
    data: { user },
  } = await insforge.auth.getUser();
  if (!user) return { error: 'Not authenticated' };

  const { error } = await insforge
    .from('profiles')
    .update({
      full_name: parsed.full_name,
      updated_at: new Date().toISOString(),
    })
    .eq('id', user.id);
  if (error) return { error: error.message };

  revalidatePath('/', 'layout');
  return { success: true };
}
