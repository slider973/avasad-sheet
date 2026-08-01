import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import type { ManagerCandidate, Organization, Profile } from '@/types/database'

const ORG_LOGO_BUCKET = 'org-logos'

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
 * Upload (ou remplace) le logo de l'organisation dans le bucket public
 * `org-logos`, puis enregistre son URL publique sur la ligne organisation.
 * Le chemin `{orgId}/logo.{ext}` est imposé par les policies storage (00023) :
 * seul un super_admin (ou l'org_admin de cette org) peut y écrire.
 */
export function useUploadOrganizationLogo() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async ({ orgId, file }: { orgId: string; file: File }) => {
      const ext = (file.name.split('.').pop() ?? 'png').toLowerCase()
      const path = `${orgId}/logo.${ext}`

      const { error: uploadError } = await supabase.storage
        .from(ORG_LOGO_BUCKET)
        .upload(path, file, { upsert: true, contentType: file.type })
      if (uploadError) throw uploadError

      const { data: publicUrl } = supabase.storage
        .from(ORG_LOGO_BUCKET)
        .getPublicUrl(path)

      // Cache-buster : le chemin est stable (upsert), l'URL doit changer pour
      // que les navigateurs et les PDF regénérés reprennent le nouveau logo.
      const logoUrl = `${publicUrl.publicUrl}?v=${Date.now()}`

      const { data, error } = await supabase
        .from('organizations')
        .update({ logo_url: logoUrl })
        .eq('id', orgId)
        .select()
        .single()
      if (error) throw error
      return data as Organization
    },
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey: ['organizations'] })
      queryClient.invalidateQueries({ queryKey: ['organization', data.id] })
    },
  })
}

export function useRemoveOrganizationLogo() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async ({ orgId, logoUrl }: { orgId: string; logoUrl: string | null }) => {
      if (logoUrl) {
        // Reconstruit le chemin storage depuis l'URL publique (sans le ?v=).
        const marker = `/${ORG_LOGO_BUCKET}/`
        const idx = logoUrl.indexOf(marker)
        if (idx !== -1) {
          const path = logoUrl.slice(idx + marker.length).split('?')[0]
          await supabase.storage.from(ORG_LOGO_BUCKET).remove([path])
        }
      }
      const { data, error } = await supabase
        .from('organizations')
        .update({ logo_url: null })
        .eq('id', orgId)
        .select()
        .single()
      if (error) throw error
      return data as Organization
    },
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey: ['organizations'] })
      queryClient.invalidateQueries({ queryKey: ['organization', data.id] })
    },
  })
}

/**
 * Candidats manager pour une organisation : membres de l'org, de ses orgs
 * ancêtres (le manager vit souvent dans l'org mère) et de ses descendants.
 */
export function useManagerCandidates(orgId: string | null) {
  return useQuery({
    queryKey: ['manager-candidates', orgId],
    queryFn: async () => {
      const { data, error } = await supabase.rpc('list_manager_candidates', {
        p_org_id: orgId!,
      })
      if (error) throw error
      return data as ManagerCandidate[]
    },
    enabled: !!orgId,
  })
}

/**
 * Affecte le manager responsable des relevés d'heures de l'organisation.
 * La RPC promeut le profil en `manager` si besoin, mémorise le choix dans
 * `organizations.default_manager_id` et crée les liens `manager_employees`
 * — c'est ce lien qui ouvre la lecture des pointages, la validation et la
 * signature (migrations 00019/00020).
 */
export function useSetOrganizationManager() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async ({
      orgId,
      managerId,
      includeDescendants = true,
    }: {
      orgId: string
      managerId: string
      includeDescendants?: boolean
    }) => {
      const { data, error } = await supabase.rpc('set_organization_manager', {
        p_org_id: orgId,
        p_manager_id: managerId,
        p_include_descendants: includeDescendants,
      })
      if (error) throw error
      return { orgId, linked: (data as number) ?? 0 }
    },
    onSuccess: ({ orgId }) => {
      queryClient.invalidateQueries({ queryKey: ['organizations'] })
      queryClient.invalidateQueries({ queryKey: ['organization', orgId] })
      queryClient.invalidateQueries({ queryKey: ['org-members', orgId] })
      queryClient.invalidateQueries({ queryKey: ['manager-candidates', orgId] })
      queryClient.invalidateQueries({ queryKey: ['all-users'] })
    },
  })
}

export function useClearOrganizationManager() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async ({
      orgId,
      includeDescendants = true,
    }: {
      orgId: string
      includeDescendants?: boolean
    }) => {
      const { data, error } = await supabase.rpc('clear_organization_manager', {
        p_org_id: orgId,
        p_include_descendants: includeDescendants,
      })
      if (error) throw error
      return { orgId, removed: (data as number) ?? 0 }
    },
    onSuccess: ({ orgId }) => {
      queryClient.invalidateQueries({ queryKey: ['organizations'] })
      queryClient.invalidateQueries({ queryKey: ['organization', orgId] })
      queryClient.invalidateQueries({ queryKey: ['org-members', orgId] })
      queryClient.invalidateQueries({ queryKey: ['manager-candidates', orgId] })
    },
  })
}

/** Profil du manager responsable, pour l'affichage de la fiche organisation. */
export function useOrganizationManager(managerId: string | null | undefined) {
  return useQuery({
    queryKey: ['organization-manager', managerId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', managerId!)
        .single()
      if (error) throw error
      return data as Profile
    },
    enabled: !!managerId,
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
