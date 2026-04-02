import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import type { Profile, UserRole } from '@/types/database'

export function useAllUsers(filters?: { organizationId?: string; role?: UserRole }) {
  return useQuery({
    queryKey: ['all-users', filters],
    queryFn: async () => {
      let query = supabase
        .from('profiles')
        .select('*, organizations(name)')
        .order('last_name', { ascending: true })

      if (filters?.organizationId) {
        query = query.eq('organization_id', filters.organizationId)
      }
      if (filters?.role) {
        query = query.eq('role', filters.role)
      }

      const { data, error } = await query
      if (error) throw error
      return data as (Profile & { organizations: { name: string } | null })[]
    },
  })
}

export function useCreateUser() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async (userData: {
      email: string
      first_name: string
      last_name: string
      organization_id?: string
      role: UserRole
    }) => {
      const { data, error } = await supabase.functions.invoke('create-user', {
        body: userData,
      })
      if (error) throw error
      return data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['all-users'] })
      queryClient.invalidateQueries({ queryKey: ['org-members'] })
    },
  })
}

export function useUpdateUserProfile() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async ({ id, ...updates }: Partial<Profile> & { id: string }) => {
      const { data, error } = await supabase
        .from('profiles')
        .update(updates)
        .eq('id', id)
        .select()
        .single()
      if (error) throw error
      return data as Profile
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['all-users'] })
      queryClient.invalidateQueries({ queryKey: ['org-members'] })
    },
  })
}
