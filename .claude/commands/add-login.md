---
description: "Auth drop-in (Supabase default / Insforge override): email+password + OAuth Google + RLS profiles."
---

# /add-login

Lee y ejecuta `.claude/skills/add-login/SKILL.md`.

Templates pre-armados (no docs) — SDK clients server+client, middleware Next.js 16, 4 auth pages (sign-in/sign-up/forgot/update-password), callback OAuth, sign-out, delete-account, useAuth hook, migration `0001_profiles.sql` con RLS L-001 enforced.

**Pre-requisitos:**
- Brand DNA presente (`brand/brand.json` + `voice.json`) — sin esto halt + handoff a `add-ui-kit`.
- `impeccable` components base — sin esto halt + handoff a `impeccable` Mode C.
- BaaS decision documentada (o fallback Supabase default).

**Tip:** si arrancás greenfield, usar `/init-saas` en lugar de `/add-login` directo — el wizard resuelve la cadena automáticamente.
