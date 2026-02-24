import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth-store'
import type { ValidationRequest } from '@/types/database'

export function useValidations() {
  const { session } = useAuthStore()
  const userId = session?.user?.id

  return useQuery({
    queryKey: ['validations', userId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('validation_requests')
        .select('*')
        .eq('employee_id', userId!)
        .order('created_at', { ascending: false })
      if (error) throw error
      return data as ValidationRequest[]
    },
    enabled: !!userId,
  })
}

export function useTeamPendingValidations() {
  const { session } = useAuthStore()
  const managerId = session?.user?.id

  return useQuery({
    queryKey: ['team-pending-validations', managerId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('validation_requests')
        .select('*, profiles!validation_requests_employee_id_fkey(first_name, last_name)')
        .eq('manager_id', managerId!)
        .eq('status', 'pending')
        .order('created_at', { ascending: false })
      if (error) throw error
      return data
    },
    enabled: !!managerId,
  })
}

export function useApproveValidation() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async ({ id, approved, comment }: { id: string; approved: boolean; comment?: string }) => {
      const { error } = await supabase.functions.invoke(
        approved ? 'approve-validation' : 'reject-validation',
        { body: { validation_id: id, comment } }
      )
      if (error) throw error
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['team-pending-validations'] })
      queryClient.invalidateQueries({ queryKey: ['validations'] })
    },
  })
}
