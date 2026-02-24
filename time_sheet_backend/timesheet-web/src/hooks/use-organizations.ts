import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import type { Organization } from '@/types/database'

export function useOrganizations() {
  return useQuery({
    queryKey: ['organizations'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('organizations')
        .select('*')
        .order('name', { ascending: true })
      if (error) throw error
      return data as Organization[]
    },
  })
}

export function useOrganization(id: string | null) {
  return useQuery({
    queryKey: ['organization', id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('organizations')
        .select('*')
        .eq('id', id!)
        .single()
      if (error) throw error
      return data as Organization
    },
    enabled: !!id,
  })
}

export function useChildOrganizations(parentId: string | null) {
  return useQuery({
    queryKey: ['child-organizations', parentId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('organizations')
        .select('*')
        .eq('parent_id', parentId!)
        .order('name', { ascending: true })
      if (error) throw error
      return data as Organization[]
    },
    enabled: !!parentId,
  })
}

export function useCreateOrganization() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async (org: { name: string; slug?: string; parent_id?: string | null }) => {
      const { data, error } = await supabase
        .from('organizations')
        .insert(org)
        .select()
        .single()
      if (error) throw error
      return data as Organization
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['organizations'] })
      queryClient.invalidateQueries({ queryKey: ['child-organizations'] })
      queryClient.invalidateQueries({ queryKey: ['effective-org-ids'] })
    },
  })
}

export function useUpdateOrganization() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async ({ id, ...updates }: Partial<Organization> & { id: string }) => {
      const { data, error } = await supabase
        .from('organizations')
        .update(updates)
        .eq('id', id)
        .select()
        .single()
      if (error) throw error
      return data as Organization
    },
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey: ['organizations'] })
      queryClient.invalidateQueries({ queryKey: ['organization', data.id] })
      queryClient.invalidateQueries({ queryKey: ['child-organizations'] })
    },
  })
}

export function useDeleteOrganization() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from('organizations')
        .delete()
        .eq('id', id)
      if (error) throw error
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['organizations'] })
      queryClient.invalidateQueries({ queryKey: ['child-organizations'] })
      queryClient.invalidateQueries({ queryKey: ['effective-org-ids'] })
    },
  })
}

/**
 * Get members across all effective org IDs (org + child orgs for org_admin)
 */
export function useOrganizationMembers(orgId: string | null) {
  return useQuery({
    queryKey: ['org-members', orgId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('organization_id', orgId!)
        .order('last_name', { ascending: true })
      if (error) throw error
      return data
    },
    enabled: !!orgId,
  })
}

/**
 * Get members across multiple orgs (for org_admin hierarchy view)
 */
export function useMultiOrgMembers(orgIds: string[] | undefined) {
  return useQuery({
    queryKey: ['org-members-multi', orgIds],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .in('organization_id', orgIds!)
        .order('last_name', { ascending: true })
      if (error) throw error
      return data
    },
    enabled: !!orgIds && orgIds.length > 0,
  })
}
