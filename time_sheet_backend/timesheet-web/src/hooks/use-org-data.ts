import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth-store'
import { startOfMonth, endOfMonth, format } from 'date-fns'
import type { TimesheetEntry, Expense, Anomaly, Profile } from '@/types/database'

/**
 * Returns all org IDs accessible by the current user:
 * - org_admin: own org + child orgs
 * - others: just own org
 */
export function useEffectiveOrgIds() {
  const { profile, isOrgAdmin } = useAuthStore()
  const orgId = profile?.organization_id

  return useQuery({
    queryKey: ['effective-org-ids', orgId, isOrgAdmin],
    queryFn: async () => {
      if (!orgId) return []
      if (!isOrgAdmin) return [orgId]

      const { data: children } = await supabase
        .from('organizations')
        .select('id')
        .eq('parent_id', orgId)

      return [orgId, ...(children?.map((c) => c.id) ?? [])]
    },
    enabled: !!orgId,
  })
}

/**
 * Get all timesheet entries for the current user's organization(s)
 */
export function useOrgTimesheetEntries(date: Date) {
  const { data: orgIds } = useEffectiveOrgIds()
  const monthStart = format(startOfMonth(date), 'yyyy-MM-dd')
  const monthEnd = format(endOfMonth(date), 'yyyy-MM-dd')

  return useQuery({
    queryKey: ['org-timesheet', orgIds, monthStart],
    queryFn: async () => {
      // Get all org member IDs
      const { data: members, error: memError } = await supabase
        .from('profiles')
        .select('id, first_name, last_name, organization_id')
        .in('organization_id', orgIds!)
      if (memError) throw memError

      const memberIds = members.map((m) => m.id)
      if (memberIds.length === 0) return { entries: [], members }

      const { data, error } = await supabase
        .from('timesheet_entries')
        .select('*')
        .in('user_id', memberIds)
        .gte('day_date', monthStart)
        .lte('day_date', monthEnd)
        .order('day_date', { ascending: true })
      if (error) throw error

      return { entries: data as TimesheetEntry[], members }
    },
    enabled: !!orgIds && orgIds.length > 0,
  })
}

/**
 * Get all expenses for the current user's organization(s)
 */
export function useOrgExpenses(date: Date) {
  const { data: orgIds } = useEffectiveOrgIds()
  const monthStart = format(startOfMonth(date), 'yyyy-MM-dd')
  const monthEnd = format(endOfMonth(date), 'yyyy-MM-dd')

  return useQuery({
    queryKey: ['org-expenses', orgIds, monthStart],
    queryFn: async () => {
      const { data: members, error: memError } = await supabase
        .from('profiles')
        .select('id, first_name, last_name, organization_id')
        .in('organization_id', orgIds!)
      if (memError) throw memError

      const memberIds = members.map((m) => m.id)
      if (memberIds.length === 0) return { expenses: [], members }

      const { data, error } = await supabase
        .from('expenses')
        .select('*')
        .in('user_id', memberIds)
        .gte('date', monthStart)
        .lte('date', monthEnd)
        .order('date', { ascending: false })
      if (error) throw error

      return { expenses: data as Expense[], members }
    },
    enabled: !!orgIds && orgIds.length > 0,
  })
}

/**
 * Get all anomalies for the current user's organization(s)
 */
export function useOrgAnomalies() {
  const { data: orgIds } = useEffectiveOrgIds()

  return useQuery({
    queryKey: ['org-anomalies', orgIds],
    queryFn: async () => {
      const { data: members, error: memError } = await supabase
        .from('profiles')
        .select('id, first_name, last_name, organization_id')
        .in('organization_id', orgIds!)
      if (memError) throw memError

      const memberIds = members.map((m) => m.id)
      if (memberIds.length === 0) return { anomalies: [], members }

      const { data, error } = await supabase
        .from('anomalies')
        .select('*')
        .in('user_id', memberIds)
        .eq('is_resolved', false)
        .order('detected_date', { ascending: false })
      if (error) throw error

      return { anomalies: data as Anomaly[], members }
    },
    enabled: !!orgIds && orgIds.length > 0,
  })
}

/**
 * Get org stats: total users, by role, present today, etc.
 */
export function useOrgStats() {
  const { data: orgIds } = useEffectiveOrgIds()
  const today = format(new Date(), 'yyyy-MM-dd')

  return useQuery({
    queryKey: ['org-stats', orgIds, today],
    queryFn: async () => {
      const { data: members, error: memError } = await supabase
        .from('profiles')
        .select('id, role, is_active, organization_id')
        .in('organization_id', orgIds!)
      if (memError) throw memError

      const activeMembers = members.filter((m) => m.is_active)
      const memberIds = activeMembers.map((m) => m.id)

      const { data: entries, error: entError } = await supabase
        .from('timesheet_entries')
        .select('user_id, absence_reason')
        .in('user_id', memberIds)
        .eq('day_date', today)
      if (entError) throw entError

      const present = entries.filter((e) => !e.absence_reason).length
      const absent = entries.filter((e) => e.absence_reason).length

      return {
        total: activeMembers.length,
        byRole: {
          employee: activeMembers.filter((m) => m.role === 'employee').length,
          manager: activeMembers.filter((m) => m.role === 'manager' || m.role === 'admin').length,
          org_admin: activeMembers.filter((m) => m.role === 'org_admin').length,
        },
        present,
        absent,
        notClockedIn: activeMembers.length - present - absent,
      }
    },
    enabled: !!orgIds && orgIds.length > 0,
  })
}

/**
 * Global stats for super_admin: all orgs, all users
 */
export function useGlobalStats() {
  const today = format(new Date(), 'yyyy-MM-dd')

  return useQuery({
    queryKey: ['global-stats', today],
    queryFn: async () => {
      const [orgsResult, profilesResult] = await Promise.all([
        supabase.from('organizations').select('id, name, is_active, parent_id'),
        supabase.from('profiles').select('id, role, is_active, organization_id'),
      ])

      if (orgsResult.error) throw orgsResult.error
      if (profilesResult.error) throw profilesResult.error

      const orgs = orgsResult.data
      const profiles = profilesResult.data as Profile[]

      return {
        totalOrganizations: orgs.length,
        activeOrganizations: orgs.filter((o) => o.is_active).length,
        totalUsers: profiles.length,
        activeUsers: profiles.filter((p) => p.is_active).length,
        byRole: {
          employee: profiles.filter((p) => p.role === 'employee').length,
          manager: profiles.filter((p) => p.role === 'manager' || p.role === 'admin').length,
          org_admin: profiles.filter((p) => p.role === 'org_admin').length,
          super_admin: profiles.filter((p) => p.role === 'super_admin').length,
        },
        organizations: orgs,
      }
    },
  })
}
