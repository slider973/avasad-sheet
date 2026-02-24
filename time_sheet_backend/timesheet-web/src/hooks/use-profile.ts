import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth-store'
import type { Profile } from '@/types/database'

export function useProfile() {
  const { session } = useAuthStore()
  const userId = session?.user?.id

  return useQuery({
    queryKey: ['profile', userId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', userId!)
        .single()
      if (error) throw error
      return data as Profile
    },
    enabled: !!userId,
  })
}

export function useUpdateProfile() {
  const queryClient = useQueryClient()
  const { session, setProfile } = useAuthStore()
  const userId = session?.user?.id

  return useMutation({
    mutationFn: async (updates: Partial<Profile>) => {
      const { data, error } = await supabase
        .from('profiles')
        .update(updates)
        .eq('id', userId!)
        .select()
        .single()
      if (error) throw error
      return data as Profile
    },
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey: ['profile', userId] })
      setProfile(data)
    },
  })
}
