import { create } from 'zustand'
import type { Session } from '@supabase/supabase-js'
import type { Profile, UserRole } from '@/types/database'

interface AuthState {
  session: Session | null
  profile: Profile | null
  isLoading: boolean
  role: UserRole | null
  isManager: boolean
  isSuperAdmin: boolean
  isOrgAdmin: boolean
  hasAdminAccess: boolean
  setSession: (session: Session | null) => void
  setProfile: (profile: Profile | null) => void
  setLoading: (loading: boolean) => void
  reset: () => void
}

export const useAuthStore = create<AuthState>((set) => ({
  session: null,
  profile: null,
  isLoading: true,
  role: null,
  isManager: false,
  isSuperAdmin: false,
  isOrgAdmin: false,
  hasAdminAccess: false,
  setSession: (session) => set({ session }),
  setProfile: (profile) => {
    const role = profile?.role ?? null
    set({
      profile,
      role,
      isManager: role === 'manager' || role === 'admin',
      isSuperAdmin: role === 'super_admin',
      isOrgAdmin: role === 'org_admin',
      hasAdminAccess: role === 'super_admin' || role === 'org_admin',
    })
  },
  setLoading: (isLoading) => set({ isLoading }),
  reset: () =>
    set({
      session: null,
      profile: null,
      isLoading: false,
      role: null,
      isManager: false,
      isSuperAdmin: false,
      isOrgAdmin: false,
      hasAdminAccess: false,
    }),
}))
