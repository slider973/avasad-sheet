import { useState, useMemo } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog'
import { PageHeader } from '@/components/shared/page-header'
import { EmptyState } from '@/components/shared/empty-state'
import { TableSkeleton } from '@/components/shared/loading-skeleton'
import { FadeIn } from '@/components/motion'
import { useOrganizations, useCreateOrganization, useUpdateOrganization } from '@/hooks/use-organizations'
import { useNavigate } from 'react-router-dom'
import { Building2, Plus, Loader2, ChevronRight } from 'lucide-react'

export default function AdminOrganizationsPage() {
  const { data: organizations, isLoading } = useOrganizations()
  const createOrg = useCreateOrganization()
  const updateOrg = useUpdateOrganization()
  const navigate = useNavigate()
  const [open, setOpen] = useState(false)
  const [name, setName] = useState('')
  const [slug, setSlug] = useState('')
  const [parentId, setParentId] = useState<string>('none')

  // Separate parent orgs (no parent_id) and child orgs
  const { parentOrgs, childOrgsByParent } = useMemo(() => {
    if (!organizations) return { parentOrgs: [], childOrgsByParent: new Map<string, typeof organizations>() }
    const parents = organizations.filter((o) => !o.parent_id)
    const childMap = new Map<string, typeof organizations>()
    organizations.filter((o) => o.parent_id).forEach((o) => {
      const existing = childMap.get(o.parent_id!) ?? []
      existing.push(o)
      childMap.set(o.parent_id!, existing)
    })
    return { parentOrgs: parents, childOrgsByParent: childMap }
  }, [organizations])

  // Only root orgs can be parents
  const rootOrgs = useMemo(() => {
    return organizations?.filter((o) => !o.parent_id) ?? []
  }, [organizations])

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault()
    await createOrg.mutateAsync({
      name,
      slug: slug || undefined,
      parent_id: parentId !== 'none' ? parentId : undefined,
    })
    setName('')
    setSlug('')
    setParentId('none')
    setOpen(false)
  }

  const toggleActive = async (id: string, currentActive: boolean) => {
    await updateOrg.mutateAsync({ id, is_active: !currentActive })
  }

  const renderOrgRow = (org: typeof organizations extends (infer T)[] | undefined ? T : never, isChild = false) => (
    <div
      key={org.id}
      className={`flex items-center justify-between rounded-lg border p-4 transition-colors hover:bg-muted/40 hover:border-primary/20 ${isChild ? 'ml-8 border-l-4 border-l-muted' : ''}`}
    >
      <div
        className="flex items-center gap-3 cursor-pointer flex-1"
        onClick={() => navigate(`/admin/organizations/${org.id}`)}
      >
        {isChild && <ChevronRight className="h-4 w-4 text-muted-foreground" />}
        <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-primary/10 to-primary/5">
          <Building2 className="h-4 w-4 text-primary" />
        </div>
        <div>
          <p className="text-sm font-medium">{org.name}</p>
          <div className="flex items-center gap-2">
            {org.slug && <p className="text-xs text-muted-foreground">{org.slug}</p>}
            {isChild && org.parent_id && (
              <Badge variant="outline" className="text-xs">
                Sous-org
              </Badge>
            )}
            {!isChild && childOrgsByParent.has(org.id) && (
              <Badge variant="outline" className="text-xs">
                {childOrgsByParent.get(org.id)!.length} sous-org{childOrgsByParent.get(org.id)!.length > 1 ? 's' : ''}
              </Badge>
            )}
          </div>
        </div>
      </div>
      <div className="flex items-center gap-2">
        <Badge variant={org.is_active ? 'default' : 'secondary'}>
          {org.is_active ? 'Active' : 'Inactive'}
        </Badge>
        <Button
          variant="outline"
          size="sm"
          onClick={() => toggleActive(org.id, org.is_active)}
          disabled={updateOrg.isPending}
        >
          {org.is_active ? 'Desactiver' : 'Activer'}
        </Button>
      </div>
    </div>
  )

  return (
    <div className="space-y-8">
      <PageHeader
        title="Organisations"
        description={`${organizations?.length ?? 0} organisations enregistrees`}
        actions={
          <Dialog open={open} onOpenChange={setOpen}>
            <DialogTrigger asChild>
              <Button>
                <Plus className="mr-2 h-4 w-4" />
                Nouvelle organisation
              </Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>Creer une organisation</DialogTitle>
                <DialogDescription>Ajoutez une nouvelle entreprise au systeme.</DialogDescription>
              </DialogHeader>
              <form onSubmit={handleCreate} className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="org-name" className="text-xs font-medium text-muted-foreground">Nom</Label>
                  <Input
                    id="org-name"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="Nom de l'entreprise"
                    required
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="org-slug" className="text-xs font-medium text-muted-foreground">Slug (optionnel)</Label>
                  <Input
                    id="org-slug"
                    value={slug}
                    onChange={(e) => setSlug(e.target.value)}
                    placeholder="mon-entreprise"
                  />
                </div>
                <div className="space-y-2">
                  <Label className="text-xs font-medium text-muted-foreground">Organisation parente (optionnel)</Label>
                  <Select value={parentId} onValueChange={setParentId}>
                    <SelectTrigger>
                      <SelectValue placeholder="Aucune (org racine)" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="none">Aucune (org racine)</SelectItem>
                      {rootOrgs.map((org) => (
                        <SelectItem key={org.id} value={org.id}>
                          {org.name}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <Button type="submit" className="w-full" disabled={createOrg.isPending}>
                  {createOrg.isPending && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                  Creer
                </Button>
              </form>
            </DialogContent>
          </Dialog>
        }
      />

      <FadeIn delay={0.1}>
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-base">
              <Building2 className="h-4 w-4 text-primary" />
              {organizations?.length ?? 0} organisations
            </CardTitle>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <TableSkeleton rows={4} cols={3} />
            ) : (!organizations || organizations.length === 0) ? (
              <EmptyState
                icon={Building2}
                title="Aucune organisation"
                description="Creez votre premiere organisation pour commencer"
                action={
                  <Button onClick={() => setOpen(true)}>
                    <Plus className="mr-2 h-4 w-4" />
                    Nouvelle organisation
                  </Button>
                }
              />
            ) : (
              <div className="space-y-2">
                {parentOrgs.map((org) => (
                  <div key={org.id}>
                    {renderOrgRow(org, false)}
                    {childOrgsByParent.get(org.id)?.map((child) => renderOrgRow(child, true))}
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
