import { useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { PageHeader } from '@/components/shared/page-header'
import { EmptyState } from '@/components/shared/empty-state'
import { TableSkeleton } from '@/components/shared/loading-skeleton'
import { FadeIn } from '@/components/motion'
import { useAllUsers, useUpdateUserProfile } from '@/hooks/use-users-management'
import { useOrganizations } from '@/hooks/use-organizations'
import { useNavigate } from 'react-router-dom'
import { Plus, Search, Users } from 'lucide-react'
import type { UserRole } from '@/types/database'

export default function AdminUsersPage() {
  const [orgFilter, setOrgFilter] = useState<string>('')
  const [roleFilter, setRoleFilter] = useState<string>('')
  const [search, setSearch] = useState('')
  const navigate = useNavigate()

  const { data: users, isLoading } = useAllUsers({
    organizationId: orgFilter && orgFilter !== 'all' ? orgFilter : undefined,
    role: roleFilter && roleFilter !== 'all' ? (roleFilter as UserRole) : undefined,
  })
  const { data: organizations } = useOrganizations()
  const updateProfile = useUpdateUserProfile()

  const filteredUsers = users?.filter((u) => {
    if (!search) return true
    const full = `${u.first_name} ${u.last_name} ${u.email}`.toLowerCase()
    return full.includes(search.toLowerCase())
  })

  const handleRoleChange = async (userId: string, newRole: UserRole) => {
    await updateProfile.mutateAsync({ id: userId, role: newRole })
  }

  const handleOrgChange = async (userId: string, newOrgId: string) => {
    await updateProfile.mutateAsync({ id: userId, organization_id: newOrgId || null })
  }

  return (
    <div className="space-y-8">
      <PageHeader
        title="Tous les utilisateurs"
        description={`${filteredUsers?.length ?? 0} utilisateurs enregistres`}
        actions={
          <Button onClick={() => navigate('/admin/users/new')}>
            <Plus className="mr-2 h-4 w-4" />
            Nouvel utilisateur
          </Button>
        }
      />

      <FadeIn delay={0.05}>
        <div className="flex flex-wrap gap-3">
          <div className="relative flex-1 min-w-[200px]">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              placeholder="Rechercher par nom ou email..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="pl-9 bg-background"
            />
          </div>
          <Select value={orgFilter} onValueChange={setOrgFilter}>
            <SelectTrigger className="w-[200px] bg-background">
              <SelectValue placeholder="Toutes les orgs" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Toutes les orgs</SelectItem>
              {organizations?.map((org) => (
                <SelectItem key={org.id} value={org.id}>{org.name}</SelectItem>
              ))}
            </SelectContent>
          </Select>
          <Select value={roleFilter} onValueChange={setRoleFilter}>
            <SelectTrigger className="w-[160px] bg-background">
              <SelectValue placeholder="Tous les roles" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Tous les roles</SelectItem>
              <SelectItem value="employee">Employe</SelectItem>
              <SelectItem value="manager">Manager</SelectItem>
              <SelectItem value="admin">Admin</SelectItem>
              <SelectItem value="org_admin">Admin org</SelectItem>
              <SelectItem value="super_admin">Super admin</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </FadeIn>

      <FadeIn delay={0.1}>
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-base">
              <Users className="h-4 w-4 text-primary" />
              {filteredUsers?.length ?? 0} utilisateurs
            </CardTitle>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <TableSkeleton rows={5} cols={3} />
            ) : (!filteredUsers || filteredUsers.length === 0) ? (
              <EmptyState
                icon={Users}
                title="Aucun utilisateur"
                description={search ? "Aucun resultat pour cette recherche" : "Creez votre premier utilisateur pour commencer"}
                action={!search ? (
                  <Button onClick={() => navigate('/admin/users/new')}>
                    <Plus className="mr-2 h-4 w-4" />
                    Nouvel utilisateur
                  </Button>
                ) : undefined}
              />
            ) : (
              <div className="space-y-1.5">
                {filteredUsers.map((user) => (
                  <div key={user.id} className="flex items-center justify-between gap-4 rounded-lg p-4 cursor-pointer transition-colors hover:bg-muted/40" onClick={() => navigate(`/admin/users/${user.id}`)}>
                    <div className="flex items-center gap-3 min-w-0 flex-1">
                      <div className="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-full bg-primary/10 text-xs font-semibold text-primary">
                        {(user.first_name?.[0] ?? '').toUpperCase()}{(user.last_name?.[0] ?? '').toUpperCase()}
                      </div>
                      <div className="min-w-0">
                        <p className="text-sm font-medium truncate">{user.first_name} {user.last_name}</p>
                        <p className="text-xs text-muted-foreground truncate">{user.email}</p>
                        <p className="text-xs text-muted-foreground">{user.organizations?.name ?? 'Sans organisation'}</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2" onClick={(e) => e.stopPropagation()}>
                      <Select
                        value={user.role}
                        onValueChange={(v) => handleRoleChange(user.id, v as UserRole)}
                      >
                        <SelectTrigger className="w-[130px]">
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="employee">Employe</SelectItem>
                          <SelectItem value="manager">Manager</SelectItem>
                          <SelectItem value="admin">Admin</SelectItem>
                          <SelectItem value="org_admin">Admin org</SelectItem>
                          <SelectItem value="super_admin">Super admin</SelectItem>
                        </SelectContent>
                      </Select>
                      <Select
                        value={user.organization_id ?? 'none'}
                        onValueChange={(v) => handleOrgChange(user.id, v === 'none' ? '' : v)}
                      >
                        <SelectTrigger className="w-[160px]">
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="none">Sans org</SelectItem>
                          {organizations?.map((org) => (
                            <SelectItem key={org.id} value={org.id}>{org.name}</SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                      <Badge variant={user.is_active ? 'default' : 'secondary'}>
                        {user.is_active ? 'Actif' : 'Inactif'}
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
