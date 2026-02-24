import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth-store'
import { format } from 'date-fns'
import type { Profile, TimesheetEntry } from '@/types/database'

export interface TeamMember extends Profile {
  todayEntry?: TimesheetEntry | null
}

export function useTeamMembers() {
  const { session, profile: myProfile } = useAuthStore()
  const managerId = session?.user?.id
  const orgId = myProfile?.organization_id
  const today = format(new Date(), 'yyyy-MM-dd')

  return useQuery({
    queryKey: ['team-members', managerId, orgId, today],
    queryFn: async () => {
      // Get employee IDs from manager_employees + all employees in the same org
      const employeeIdSet = new Set<string>()

      // 1. Explicit manager-employee links
      const { data: relationships } = await supabase
        .from('manager_employees')
        .select('employee_id')
        .eq('manager_id', managerId!)
      relationships?.forEach((r) => employeeIdSet.add(r.employee_id))

      // 2. All employees/managers in the same organization (exclude self)
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

      const { data: profiles, error: profError } = await supabase
        .from('profiles')
        .select('*')
        .in('id', employeeIds)
      if (profError) throw profError

      const { data: entries, error: entError } = await supabase
        .from('timesheet_entries')
        .select('*')
        .in('user_id', employeeIds)
        .eq('day_date', today)
      if (entError) throw entError

      return (profiles as Profile[]).map((profile) => ({
        ...profile,
        todayEntry: (entries as TimesheetEntry[]).find((e) => e.user_id === profile.id) ?? null,
      })) as TeamMember[]
    },
    enabled: !!managerId,
  })
}

export function useTeamStats() {
  const { data: members } = useTeamMembers()

  const total = members?.length ?? 0
  const present = members?.filter((m) => m.todayEntry && !m.todayEntry.absence_reason).length ?? 0
  const absent = members?.filter((m) => m.todayEntry?.absence_reason).length ?? 0
  const notClockedIn = total - present - absent

  return { total, present, absent, notClockedIn }
}
