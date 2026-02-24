import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth-store'
import type { Absence, AbsenceType } from '@/types/database'

export function useAbsences() {
  const { session } = useAuthStore()
  const userId = session?.user?.id

  return useQuery({
    queryKey: ['absences', userId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('absences')
        .select('*')
        .eq('user_id', userId!)
        .order('start_date', { ascending: false })
      if (error) throw error
      return data as Absence[]
    },
    enabled: !!userId,
  })
}

export function useCreateAbsence() {
  const queryClient = useQueryClient()
  const { session } = useAuthStore()

  return useMutation({
    mutationFn: async (absence: {
      start_date: string
      end_date: string
      type: AbsenceType
      motif?: string
    }) => {
      const { data, error } = await supabase
        .from('absences')
        .insert({ ...absence, user_id: session!.user.id })
        .select()
        .single()
      if (error) throw error
      return data as Absence
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['absences'] })
    },
  })
}

export function useDeleteAbsence() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase.from('absences').delete().eq('id', id)
      if (error) throw error
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['absences'] })
    },
  })
}
