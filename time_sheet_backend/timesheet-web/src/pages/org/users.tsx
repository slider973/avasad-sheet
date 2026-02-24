import { useState, useMemo } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { useAuthStore } from '@/stores/auth-store'
import { useMultiOrgMembers, useOrganizations } from '@/hooks/use-organizations'
import { useEffectiveOrgIds } from '@/hooks/use-org-data'
import { useUpdateUserProfile } from '@/hooks/use-users-management'
import { useNavigate } from 'react-router-dom'
import { Plus, Search, Users } from 'lucide-react'
import { PageHeader } from '@/components/shared/page-header'
import { EmptyState } from '@/components/shared/empty-state'
import { TableSkeleton } from '@/components/shared/loading-skeleton'
import { FadeIn } from '@/components/motion'
import type { UserRole } from '@/types/database'

function getInitials(firstName: string | null, lastName: string | null): string {
  return `${(firstName ?? '')[0] ?? ''}${(lastName ?? '')[0] ?? ''}`.toUpperCase()
}

export default function OrgUsersPage() {
  const { profile, isOrgAdmin } = useAuthStore()
  const { data: orgIds } = useEffectiveOrgIds()
  const { data: allOrgs } = useOrganizations()
  const { data: members, isLoading } = useMultiOrgMembers(orgIds)
  const updateProfile = useUpdateUserProfile()
  const navigate = useNavigate()
  const [search, setSearch] = useState('')
  const [filterOrgId, setFilterOrgId] = useState<string>('all')

  // Build org name map
  const orgNameMap = useMemo(() => {
    const map = new Map<string, string>()
    allOrgs?.forEach((o) => map.set(o.id, o.name))
    return map
  }, [allOrgs])

  // Get orgs in the hierarchy for the filter dropdown
  const availableOrgs = useMemo(() => {
    if (!orgIds || !allOrgs) return []
    return allOrgs.filter((o) => orgIds.includes(o.id))
  }, [orgIds, allOrgs])

  const filteredMembers = useMemo(() => {
    let list = (members ?? []).filter((m) => m.id !== profile?.id)
    if (filterOrgId !== 'all') {
      list = list.filter((m) => m.organization_id === filterOrgId)
    }
    if (search) {
      const q = search.toLowerCase()
      list = list.filter((m) => {
        const full = `${m.first_name} ${m.last_name} ${m.email}`.toLowerCase()
        return full.includes(q)
      })
    }
    return list
  }, [members, search, filterOrgId])

  const handleRoleChange = async (userId: string, newRole: UserRole) => {
    await updateProfile.mutateAsync({ id: userId, role: newRole })
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Utilisateurs de l'organisation"
        description={`${filteredMembers.length} membre${filteredMembers.length !== 1 ? 's' : ''}`}
        actions={
          <Button onClick={() => navigate('/org/users/new')}>
            <Plus className="mr-2 h-4 w-4" />
            Nouvel utilisateur
          </Button>
        }
      />

      <FadeIn>
        <div className="flex items-center gap-4">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              placeholder="Rechercher un membre..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="pl-9"
            />
          </div>
          {isOrgAdmin && availableOrgs.length > 1 && (
            <Select value={filterOrgId} onValueChange={setFilterOrgId}>
              <SelectTrigger className="w-[200px]">
                <SelectValue placeholder="Toutes les orgs" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Toutes les orgs</SelectItem>
                {availableOrgs.map((o) => (
                  <SelectItem key={o.id} value={o.id}>{o.name}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          )}
        </div>
      </FadeIn>

      <FadeIn delay={0.1}>
        <Card>
          <CardHeader>
            <CardTitle className="text-base">{filteredMembers?.length ?? 0} membres</CardTitle>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <TableSkeleton rows={5} cols={3} />
            ) : filteredMembers.length === 0 ? (
              <EmptyState
                icon={Users}
                title="Aucun membre"
                description="Aucun utilisateur ne correspond a votre recherche"
              />
            ) : (
              <div className="space-y-1.5">
                {filteredMembers.map((member) => (
                  <div key={member.id} className="flex items-center justify-between gap-4 rounded-lg border p-4 transition-colors hover:bg-muted/40">
                    <div className="flex items-center gap-3 min-w-0 flex-1">
                      <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-primary/10 to-primary/5 text-xs font-semibold text-primary">
                        {getInitials(member.first_name, member.last_name)}
                      </div>
                      <div className="min-w-0">
                        <p className="font-medium truncate">{member.first_name} {member.last_name}</p>
                        <div className="flex items-center gap-2">
                          <p className="text-sm text-muted-foreground truncate">{member.email}</p>
                          {isOrgAdmin && availableOrgs.length > 1 && member.organization_id && (
                            <Badge variant="outline" className="text-xs shrink-0">
                              {orgNameMap.get(member.organization_id) ?? ''}
                            </Badge>
                          )}
                        </div>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <Select
                        value={member.role}
                        onValueChange={(v) => handleRoleChange(member.id, v as UserRole)}
                      >
                        <SelectTrigger className="w-[130px]">
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="employee">Employe</SelectItem>
                          <SelectItem value="manager">Manager</SelectItem>
                          <SelectItem value="org_admin">Org Admin</SelectItem>
                        </SelectContent>
                      </Select>
                      <Badge variant={member.is_active ? 'default' : 'secondary'}>
                        {member.is_active ? 'Actif' : 'Inactif'}
                      </Badge>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </FadeIn>
    </div>
  )
}
