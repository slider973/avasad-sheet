import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth-store'
import { startOfMonth, endOfMonth, format } from 'date-fns'
import type { TimesheetEntry } from '@/types/database'

export function useTimesheetEntries(date: Date) {
  const { session } = useAuthStore()
  const userId = session?.user?.id
  const monthStart = format(startOfMonth(date), 'yyyy-MM-dd')
  const monthEnd = format(endOfMonth(date), 'yyyy-MM-dd')

  return useQuery({
    queryKey: ['timesheet', userId, monthStart],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('timesheet_entries')
        .select('*')
        .eq('user_id', userId!)
        .gte('day_date', monthStart)
        .lte('day_date', monthEnd)
        .order('day_date', { ascending: true })
      if (error) throw error
      return data as TimesheetEntry[]
    },
    enabled: !!userId,
  })
}

export function useUpsertTimesheetEntry() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async (entry: Partial<TimesheetEntry> & { user_id: string; day_date: string }) => {
      const { data, error } = await supabase
        .from('timesheet_entries')
        .upsert(entry, { onConflict: 'user_id,day_date' })
        .select()
        .single()
      if (error) throw error
      return data as TimesheetEntry
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['timesheet'] })
    },
  })
}

export function useEmployeeTimesheetEntries(employeeId: string | null, date: Date) {
  const monthStart = format(startOfMonth(date), 'yyyy-MM-dd')
  const monthEnd = format(endOfMonth(date), 'yyyy-MM-dd')

  return useQuery({
    queryKey: ['timesheet', employeeId, monthStart],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('timesheet_entries')
        .select('*')
        .eq('user_id', employeeId!)
        .gte('day_date', monthStart)
        .lte('day_date', monthEnd)
        .order('day_date', { ascending: true })
      if (error) throw error
      return data as TimesheetEntry[]
    },
    enabled: !!employeeId,
  })
}
