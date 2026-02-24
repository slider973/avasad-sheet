import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { FadeIn } from '@/components/motion'
import { EmptyState } from '@/components/shared/empty-state'
import { TableSkeleton, CardSkeletonGrid } from '@/components/shared/loading-skeleton'
import {
  useOrganization,
  useOrganizationMembers,
  useUpdateOrganization,
  useChildOrganizations,
} from '@/hooks/use-organizations'
import { Building2, Users, ArrowLeft, Loader2, Save, Plus } from 'lucide-react'
import type { UserRole } from '@/types/database'

const roleLabels: Record<UserRole, string> = {
  employee: 'Employe',
  manager: 'Manager',
  admin: 'Admin',
  org_admin: 'Admin org',
  super_admin: 'Super admin',
}

const roleBadgeVariant: Record<UserRole, 'default' | 'secondary' | 'outline' | 'destructive'> = {
  employee: 'secondary',
  manager: 'default',
  admin: 'default',
  org_admin: 'outline',
  super_admin: 'destructive',
}

export default function AdminOrgDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data: org, isLoading: orgLoading } = useOrganization(id ?? null)
  const { data: members, isLoading: membersLoading } = useOrganizationMembers(id ?? null)
  const { data: childOrgs } = useChildOrganizations(id ?? null)
  const { data: parentOrg } = useOrganization(org?.parent_id ?? null)
  const updateOrg = useUpdateOrganization()

  const [editName, setEditName] = useState('')
  const [editSlug, setEditSlug] = useState('')
  const [editing, setEditing] = useState(false)

  const startEdit = () => {
    if (org) {
      setEditName(org.name)
      setEditSlug(org.slug ?? '')
      setEditing(true)
    }
  }

  const handleSave = async () => {
    if (!id) return
    await updateOrg.mutateAsync({ id, name: editName, slug: editSlug || null })
    setEditing(false)
  }

  if (orgLoading) {
    return (
      <div className="space-y-6">
        <div className="flex items-center gap-4">
          <Button variant="ghost" size="icon" onClick={() => navigate('/admin/organizations')}>
            <ArrowLeft className="h-4 w-4" />
          </Button>
          <div className="h-8 w-48 animate-pulse rounded-lg bg-muted" />
        </div>
        <CardSkeletonGrid count={2} />
      </div>
    )
  }

  if (!org) {
    return (
      <div className="space-y-4">
        <Button variant="ghost" onClick={() => navigate('/admin/organizations')}>
          <ArrowLeft className="mr-2 h-4 w-4" /> Retour
        </Button>
        <EmptyState
          icon={Building2}
          title="Organisation non trouvee"
          description="Cette organisation n'existe pas ou a ete supprimee"
        />
      </div>
    )
  }

  const isParentOrg = !org.parent_id
  const isChildOrg = !!org.parent_id

  return (
    <div className="space-y-6">
      <FadeIn>
        <div className="flex items-center gap-4">
          <Button variant="ghost" size="icon" onClick={() => navigate('/admin/organizations')}>
            <ArrowLeft className="h-4 w-4" />
          </Button>
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-[oklch(0.60_0.18_300)]">
            <Building2 className="h-5 w-5 text-white" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-2xl font-bold tracking-tight">{org.name}</h1>
              <Badge variant={org.is_active ? 'default' : 'secondary'}>
                {org.is_active ? 'Active' : 'Inactive'}
              </Badge>
              {isChildOrg && (
                <Badge variant="outline">Sous-organisation</Badge>
              )}
            </div>
            {isChildOrg && parentOrg && (
              <div className="mt-0.5 flex items-center gap-1.5 text-xs text-muted-foreground">
                <Building2 className="h-3 w-3" />
                <span>Organisation parente :</span>
                <Button
                  variant="link"
                  className="h-auto p-0 text-xs"
                  onClick={() => navigate(`/admin/organizations/${parentOrg.id}`)}
                >
                  {parentOrg.name}
                </Button>
              </div>
            )}
          </div>
        </div>
      </FadeIn>

      <div className="grid gap-4 sm:grid-cols-2">
        <FadeIn delay={0.1}>
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-base">
                <Building2 className="h-4 w-4 text-primary" />
                Informations
              </CardTitle>
            </CardHeader>
            <CardContent>
              {editing ? (
                <div className="space-y-4">
                  <div className="space-y-2">
                    <Label className="text-xs font-medium text-muted-foreground">Nom</Label>
                    <Input value={editName} onChange={(e) => setEditName(e.target.value)} />
                  </div>
                  <div className="space-y-2">
                    <Label className="text-xs font-medium text-muted-foreground">Slug</Label>
                    <Input value={editSlug} onChange={(e) => setEditSlug(e.target.value)} />
                  </div>
                  <div className="flex gap-2">
                    <Button onClick={handleSave} disabled={updateOrg.isPending}>
                      {updateOrg.isPending && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                      <Save className="mr-2 h-4 w-4" />
                      Enregistrer
                    </Button>
                    <Button variant="outline" onClick={() => setEditing(false)}>Annuler</Button>
                  </div>
                </div>
              ) : (
                <div className="space-y-3">
                  <div>
                    <p className="text-xs font-medium text-muted-foreground">Nom</p>
                    <p className="text-sm font-medium">{org.name}</p>
                  </div>
                  <div>
                    <p className="text-xs font-medium text-muted-foreground">Slug</p>
                    <p className="text-sm font-medium">{org.slug ?? '-'}</p>
                  </div>
                  <div>
                    <p className="text-xs font-medium text-muted-foreground">Cree le</p>
                    <p className="text-sm font-medium">{new Date(org.created_at).toLocaleDateString('fr-CH')}</p>
                  </div>
                  <Button variant="outline" onClick={startEdit}>Modifier</Button>
                </div>
              )}
            </CardContent>
          </Card>
        </FadeIn>

        <FadeIn delay={0.2}>
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-base">
                <Users className="h-4 w-4 text-primary" />
                {members?.length ?? 0} membres
              </CardTitle>
            </CardHeader>
            <CardContent>
              {membersLoading ? (
                <TableSkeleton rows={3} cols={2} />
              ) : (!members || members.length === 0) ? (
                <EmptyState
                  icon={Users}
                  title="Aucun membre"
                  description="Cette organisation n'a pas encore de membres"
                />
              ) : (
                <div className="space-y-1.5 max-h-96 overflow-y-auto">
                  {members.map((member) => (
                    <div key={member.id} className="flex items-center justify-between rounded-lg p-3 transition-colors hover:bg-muted/40">
                      <div className="flex items-center gap-3">
                        <div className="flex h-9 w-9 items-center justify-center rounded-full bg-primary/10 text-xs font-semibold text-primary">
                          {(member.first_name?.[0] ?? '').toUpperCase()}{(member.last_name?.[0] ?? '').toUpperCase()}
                        </div>
                        <div>
                          <p className="text-sm font-medium">{member.first_name} {member.last_name}</p>
                          <p className="text-xs text-muted-foreground">{member.email}</p>
                        </div>
                      </div>
                      <Badge variant={roleBadgeVariant[member.role as UserRole]}>
                        {roleLabels[member.role as UserRole]}
                      </Badge>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </FadeIn>
      </div>

      {/* Child organizations section (only for parent orgs) */}
      {isParentOrg && (
        <FadeIn delay={0.3}>
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center justify-between text-base">
                <div className="flex items-center gap-2">
                  <Building2 className="h-4 w-4 text-primary" />
                  Sous-organisations ({childOrgs?.length ?? 0})
                </div>
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => navigate('/admin/organizations', { state: { createChildOf: org.id } })}
                >
                  <Plus className="mr-2 h-4 w-4" />
                  Ajouter
                </Button>
              </CardTitle>
            </CardHeader>
            <CardContent>
              {childOrgs && childOrgs.length > 0 ? (
                <div className="space-y-1.5">
                  {childOrgs.map((child) => (
                    <div
                      key={child.id}
                      className="flex items-center justify-between rounded-lg p-3 cursor-pointer transition-colors hover:bg-muted/40"
                      onClick={() => navigate(`/admin/organizations/${child.id}`)}
                    >
                      <div className="flex items-center gap-3">
                        <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-primary/10 to-primary/5">
                          <Building2 className="h-4 w-4 text-primary" />
                        </div>
                        <div>
                          <p className="text-sm font-medium">{child.name}</p>
                          {child.slug && <p className="text-xs text-muted-foreground">{child.slug}</p>}
                        </div>
                      </div>
                      <Badge variant={child.is_active ? 'default' : 'secondary'}>
                        {child.is_active ? 'Active' : 'Inactive'}
                      </Badge>
                    </div>
                  ))}
                </div>
              ) : (
                <EmptyState
                  icon={Building2}
                  title="Aucune sous-organisation"
                  description="Ajoutez des sous-organisations pour structurer votre entreprise"
                />
              )}
            </CardContent>
          </Card>
        </FadeIn>
      )}
    </div>
  )
}
