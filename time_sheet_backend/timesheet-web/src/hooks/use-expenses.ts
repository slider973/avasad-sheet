import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth-store'
import { startOfMonth, endOfMonth, format } from 'date-fns'
import type { Expense, ExpenseCategory } from '@/types/database'

export function useExpenses(date: Date) {
  const { session } = useAuthStore()
  const userId = session?.user?.id
  const monthStart = format(startOfMonth(date), 'yyyy-MM-dd')
  const monthEnd = format(endOfMonth(date), 'yyyy-MM-dd')

  return useQuery({
    queryKey: ['expenses', userId, monthStart],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('expenses')
        .select('*')
        .eq('user_id', userId!)
        .gte('date', monthStart)
        .lte('date', monthEnd)
        .order('date', { ascending: false })
      if (error) throw error
      return data as Expense[]
    },
    enabled: !!userId,
  })
}

export function useCreateExpense() {
  const queryClient = useQueryClient()
  const { session } = useAuthStore()

  return useMutation({
    mutationFn: async (expense: {
      date: string
      category: ExpenseCategory
      description?: string
      currency?: string
      amount: number
      mileage_rate?: number
      distance_km?: number
      departure_location?: string
      arrival_location?: string
      attachment_url?: string
    }) => {
      const { data, error } = await supabase
        .from('expenses')
        .insert({
          ...expense,
          user_id: session!.user.id,
          currency: expense.currency ?? 'CHF',
        })
        .select()
        .single()
      if (error) throw error
      return data as Expense
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['expenses'] })
    },
  })
}

export function useUploadReceipt() {
  return useMutation({
    mutationFn: async ({ userId, expenseId, file }: { userId: string; expenseId: string; file: File }) => {
      const path = `${userId}/${expenseId}.jpg`
      const { error } = await supabase.storage.from('receipts').upload(path, file, { upsert: true })
      if (error) throw error
      const { data: urlData } = supabase.storage.from('receipts').getPublicUrl(path)
      return urlData.publicUrl
    },
  })
}

export function useTeamPendingExpenses() {
  const { session, profile } = useAuthStore()
  const managerId = session?.user?.id
  const orgId = profile?.organization_id

  return useQuery({
    queryKey: ['team-pending-expenses', managerId, orgId],
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
        .from('expenses')
        .select('*, profiles!expenses_user_id_fkey(first_name, last_name)')
        .in('user_id', employeeIds)
        .is('is_approved', null)
        .order('date', { ascending: false })
      if (error) throw error
      return data
    },
    enabled: !!managerId,
  })
}

export function useApproveExpense() {
  const queryClient = useQueryClient()
  const { session } = useAuthStore()

  return useMutation({
    mutationFn: async ({ id, approved, comment }: { id: string; approved: boolean; comment?: string }) => {
      const { error } = await supabase
        .from('expenses')
        .update({
          is_approved: approved,
          approved_by: session!.user.id,
          manager_comment: comment ?? null,
          approved_at: new Date().toISOString(),
        })
        .eq('id', id)
      if (error) throw error
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['team-pending-expenses'] })
      queryClient.invalidateQueries({ queryKey: ['expenses'] })
    },
  })
}
