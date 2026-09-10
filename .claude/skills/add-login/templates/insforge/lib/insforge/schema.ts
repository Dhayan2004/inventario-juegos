// Profiles schema declarativo. RLS-equivalent enforced vía `access` config.
// L-001: tabla persiste datos derivados de input del usuario, RLS-equivalent
// limita read/write a own profile. delete: false por design — eliminación
// vía deleteAccount route (R14, typed confirmation).
//
// Cita: [memory:lessons#L-001] [memory:CONSTRAINTS.md#R14] [docs:insforge]
import { defineCollection } from '@insforge/sdk';

export const profiles = defineCollection({
  name: 'profiles',
  schema: {
    id: { type: 'uuid', primaryKey: true, foreignKey: 'auth.users.id', onDelete: 'cascade' },
    email: { type: 'string', notNull: true },
    full_name: { type: 'string', nullable: true },
    avatar_url: { type: 'string', nullable: true },
    created_at: { type: 'timestamp', default: 'now()' },
    updated_at: { type: 'timestamp', default: 'now()' },
  },
  access: {
    select: 'auth.uid() == id',
    insert: 'auth.uid() == id',
    update: 'auth.uid() == id',
    delete: false,
  },
  triggers: {
    onUserCreate: (user) => ({
      id: user.id,
      email: user.email,
      full_name: user.metadata?.full_name ?? user.metadata?.name,
      avatar_url: user.metadata?.avatar_url,
    }),
    onUpdate: (existing) => ({ ...existing, updated_at: 'now()' }),
  },
});
