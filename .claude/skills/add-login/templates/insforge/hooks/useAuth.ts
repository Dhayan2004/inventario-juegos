// useAuth hook (Insforge variant).
//
// Cita: [docs:insforge] [docs:react]
'use client';

import { useEffect, useState } from 'react';
import { createClient } from '@/lib/insforge/client';
import type { Profile } from '@/types/database';

interface InsforgeUser {
  id: string;
  email: string;
  metadata?: Record<string, unknown>;
}

export function useAuth() {
  const [user, setUser] = useState<InsforgeUser | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const insforge = createClient();

    async function loadProfile(userId: string) {
      const { data } = await insforge
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();
      setProfile(data ?? null);
    }

    insforge.auth.getUser().then(({ data: { user } }) => {
      setUser(user);
      if (user) loadProfile(user.id);
      setLoading(false);
    });

    const {
      data: { subscription },
    } = insforge.auth.onAuthStateChange((_event, session) => {
      const currentUser = session?.user ?? null;
      setUser(currentUser);
      if (currentUser) loadProfile(currentUser.id);
      else setProfile(null);
      setLoading(false);
    });

    return () => subscription.unsubscribe();
  }, []);

  return { user, profile, loading };
}
