import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth-store'
import type { Anomaly } from '@/types/database'

export function useAnomalies(unresolvedOnly = false) {
  const { session } = useAuthStore()
  const userId = session?.user?.id

  return useQuery({
    queryKey: ['anomalies', userId, unresolvedOnly],
    queryFn: async () => {
      let query = supabase
        .from('anomalies')
        .select('*')
        .eq('user_id', userId!)
        .order('detected_date', { ascending: false })

      if (unresolvedOnly) {
        query = query.eq('is_resolved', false)
      }

      const { data, error } = await query
      if (error) throw error
      return data as Anomaly[]
    },
    enabled: !!userId,
  })
}

export function useResolveAnomaly() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from('anomalies')
        .update({ is_resolved: true })
        .eq('id', id)
      if (error) throw error
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['anomalies'] })
      queryClient.invalidateQueries({ queryKey: ['team-anomalies'] })
    },
  })
}

export function useTeamAnomalies() {
  const { session, profile } = useAuthStore()
  const managerId = session?.user?.id
  const orgId = profile?.organization_id

  return useQuery({
    queryKey: ['team-anomalies', managerId, orgId],
    queryFn: async () => {
      const employeeIdSet = new Set<string>()

      const { data: relationships } = await supabase
        .from('manager_employees')
        .select('employee_id')
        .eq('manager_id', managerId!)
      relationships?.forEach((r) => employeeIdSet.add(r.employee_id))

      if (orgId) {
        const { data: orgMembers } = await supabase
          .from('profiles')
          .select('id')
          .eq('organization_id', orgId)
          .neq('id', managerId!)
        orgMembers?.forEach((m) => employeeIdSet.add(m.id))
      }

      const employeeIds = Array.from(employeeIdSet)
      if (employeeIds.length === 0) return []

      const { data, error } = await supabase
        .from('anomalies')
        .select('*, profiles!anomalies_user_id_fkey(first_name, last_name)')
        .in('user_id', employeeIds)
        .eq('is_resolved', false)
        .order('detected_date', { ascending: false })
      if (error) throw error
      return data
    },
    enabled: !!managerId,
  })
}
