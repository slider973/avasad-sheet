import { useEffect, useRef, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { storageImageSrc } from '@/lib/supabase'
import { FadeIn } from '@/components/motion'
import { EmptyState } from '@/components/shared/empty-state'
import { TableSkeleton, CardSkeletonGrid } from '@/components/shared/loading-skeleton'
import {
  useOrganization,
  useOrganizationMembers,
  useUpdateOrganization,
  useChildOrganizations,
  useUploadOrganizationLogo,
  useRemoveOrganizationLogo,
  useManagerCandidates,
  useSetOrganizationManager,
  useClearOrganizationManager,
  useOrganizationManager,
} from '@/hooks/use-organizations'
import {
  Building2,
  Users,
  ArrowLeft,
  Loader2,
  Save,
  Plus,
  ImageUp,
  Trash2,
  ShieldCheck,
  UserCog,
  Check,
} from 'lucide-react'
import type { UserRole } from '@/types/database'

const roleLabels: Record<UserRole, string> = {
  employee: 'Employé',
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

const MAX_LOGO_BYTES = 2 * 1024 * 1024
// PNG/JPEG uniquement : ce sont les seuls formats que le générateur de PDF
// Flutter (`pw.MemoryImage`) sait décoder pour l'en-tête du relevé d'heures.
const ACCEPTED_LOGO_TYPES = ['image/png', 'image/jpeg']

/** Champs texte éditables de l'organisation. */
type OrgForm = {
  name: string
  slug: string
  web_url: string
  contact_first_name: string
  contact_last_name: string
  contact_email: string
  contact_phone: string
  address: string
  is_active: boolean
}

const EMPTY_FORM: OrgForm = {
  name: '',
  slug: '',
  web_url: '',
  contact_first_name: '',
  contact_last_name: '',
  contact_email: '',
  contact_phone: '',
  address: '',
  is_active: true,
}

/** '' -> null : ne jamais écrire de chaîne vide dans une colonne nullable. */
const orNull = (v: string) => {
  const t = v.trim()
  return t.length > 0 ? t : null
}

export default function AdminOrgDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data: org, isLoading: orgLoading } = useOrganization(id ?? null)
  const { data: members, isLoading: membersLoading } = useOrganizationMembers(id ?? null)
  const { data: childOrgs } = useChildOrganizations(id ?? null)
  const { data: parentOrg } = useOrganization(org?.parent_id ?? null)
  const { data: candidates } = useManagerCandidates(id ?? null)
  const { data: currentManager } = useOrganizationManager(org?.default_manager_id)

  const updateOrg = useUpdateOrganization()
  const uploadLogo = useUploadOrganizationLogo()
  const removeLogo = useRemoveOrganizationLogo()
  const setManager = useSetOrganizationManager()
  const clearManager = useClearOrganizationManager()

  const [form, setForm] = useState<OrgForm>(EMPTY_FORM)
  const [editing, setEditing] = useState(false)
  const [selectedManagerId, setSelectedManagerId] = useState<string>('')
  const [includeDescendants, setIncludeDescendants] = useState(true)
  const fileInputRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    if (!org) return
    setForm({
      name: org.name,
      slug: org.slug ?? '',
      web_url: org.web_url ?? '',
      contact_first_name: org.contact_first_name ?? '',
      contact_last_name: org.contact_last_name ?? '',
      contact_email: org.contact_email ?? '',
      contact_phone: org.contact_phone ?? '',
      address: org.address ?? '',
      is_active: org.is_active,
    })
    setSelectedManagerId(org.default_manager_id ?? '')
  }, [org])

  const setField = (key: keyof OrgForm, value: string | boolean) =>
    setForm((prev) => ({ ...prev, [key]: value }))

  const handleSave = async () => {
    if (!id) return
    if (!form.name.trim()) {
      toast.error("Le nom de l'organisation est obligatoire")
      return
    }
    try {
      await updateOrg.mutateAsync({
        id,
        name: form.name.trim(),
        slug: orNull(form.slug),
        web_url: orNull(form.web_url),
        contact_first_name: orNull(form.contact_first_name),
        contact_last_name: orNull(form.contact_last_name),
        contact_email: orNull(form.contact_email),
        contact_phone: orNull(form.contact_phone),
        address: orNull(form.address),
        is_active: form.is_active,
      })
      setEditing(false)
      toast.success('Paramètres enregistrés')
    } catch (e) {
      toast.error((e as Error).message ?? "Échec de l'enregistrement")
    }
  }

  const handleLogoPicked = async (file: File | undefined) => {
    if (!file || !id) return
    if (!ACCEPTED_LOGO_TYPES.includes(file.type)) {
      toast.error('Format non supporté (PNG ou JPEG)')
      return
    }
    if (file.size > MAX_LOGO_BYTES) {
      toast.error('Le logo ne doit pas dépasser 2 Mo')
      return
    }
    try {
      await uploadLogo.mutateAsync({ orgId: id, file })
      toast.success('Logo mis à jour')
    } catch (e) {
      toast.error((e as Error).message ?? "Échec de l'envoi du logo")
    } finally {
      if (fileInputRef.current) fileInputRef.current.value = ''
    }
  }

  const handleRemoveLogo = async () => {
    if (!id || !org) return
    try {
      await removeLogo.mutateAsync({ orgId: id, logoUrl: org.logo_url })
      toast.success('Logo supprimé')
    } catch (e) {
      toast.error((e as Error).message ?? 'Échec de la suppression du logo')
    }
  }

  const handleAssignManager = async () => {
    if (!id || !selectedManagerId) return
    try {
      const { linked } = await setManager.mutateAsync({
        orgId: id,
        managerId: selectedManagerId,
        includeDescendants,
      })
      toast.success(
        linked > 0
          ? `Manager affecté — ${linked} employé${linked > 1 ? 's' : ''} rattaché${linked > 1 ? 's' : ''}`
          : 'Manager affecté (aucun nouvel employé à rattacher)',
      )
    } catch (e) {
      toast.error((e as Error).message ?? "Échec de l'affectation du manager")
    }
  }

  const handleClearManager = async () => {
    if (!id) return
    try {
      const { removed } = await clearManager.mutateAsync({ orgId: id, includeDescendants })
      setSelectedManagerId('')
      toast.success(`Manager retiré — ${removed} rattachement${removed > 1 ? 's' : ''} supprimé${removed > 1 ? 's' : ''}`)
    } catch (e) {
      toast.error((e as Error).message ?? 'Échec du retrait du manager')
    }
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
          title="Organisation non trouvée"
          description="Cette organisation n'existe pas ou a été supprimée"
        />
      </div>
    )
  }

  const isParentOrg = !org.parent_id
  const isChildOrg = !!org.parent_id
  const logoBusy = uploadLogo.isPending || removeLogo.isPending
  const managerBusy = setManager.isPending || clearManager.isPending
  const managerChanged = selectedManagerId !== (org.default_manager_id ?? '')

  return (
    <div className="space-y-6">
      <FadeIn>
        <div className="flex items-center gap-4">
          <Button variant="ghost" size="icon" onClick={() => navigate('/admin/organizations')}>
            <ArrowLeft className="h-4 w-4" />
          </Button>
          {org.logo_url ? (
            <img
              src={storageImageSrc(org.logo_url)}
              alt={`Logo ${org.name}`}
              className="h-10 w-10 rounded-xl border object-contain bg-white p-0.5"
            />
          ) : (
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-[oklch(0.60_0.18_300)]">
              <Building2 className="h-5 w-5 text-white" />
            </div>
          )}
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-2xl font-bold tracking-tight">{org.name}</h1>
              <Badge variant={org.is_active ? 'default' : 'secondary'}>
                {org.is_active ? 'Active' : 'Inactive'}
              </Badge>
              {isChildOrg && <Badge variant="outline">Sous-organisation</Badge>}
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

      {/* Identité + logo */}
      <FadeIn delay={0.1}>
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center justify-between text-base">
              <div className="flex items-center gap-2">
                <Building2 className="h-4 w-4 text-primary" />
                Paramètres de l'organisation
              </div>
              {!editing && (
                <Button variant="outline" size="sm" onClick={() => setEditing(true)}>
                  Modifier
                </Button>
              )}
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-6">
            {/* Logo — édité indépendamment du formulaire texte */}
            <div className="flex flex-wrap items-center gap-4">
              <div className="flex h-20 w-20 items-center justify-center overflow-hidden rounded-xl border bg-white">
                {org.logo_url ? (
                  <img
                    src={storageImageSrc(org.logo_url)}
                    alt={`Logo ${org.name}`}
                    className="h-full w-full object-contain p-1.5"
                  />
                ) : (
                  <Building2 className="h-7 w-7 text-muted-foreground" />
                )}
              </div>
              <div className="space-y-2">
                <p className="text-xs font-medium text-muted-foreground">
                  Logo — affiché dans l'application et sur les PDF de relevé d'heures
                </p>
                <div className="flex flex-wrap gap-2">
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept={ACCEPTED_LOGO_TYPES.join(',')}
                    className="hidden"
                    onChange={(e) => handleLogoPicked(e.target.files?.[0])}
                  />
                  <Button
                    variant="outline"
                    size="sm"
                    disabled={logoBusy}
                    onClick={() => fileInputRef.current?.click()}
                  >
                    {uploadLogo.isPending ? (
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    ) : (
                      <ImageUp className="mr-2 h-4 w-4" />
                    )}
                    {org.logo_url ? 'Remplacer' : 'Téléverser un logo'}
                  </Button>
                  {org.logo_url && (
                    <Button
                      variant="ghost"
                      size="sm"
                      disabled={logoBusy}
                      onClick={handleRemoveLogo}
                    >
                      <Trash2 className="mr-2 h-4 w-4" />
                      Supprimer
                    </Button>
                  )}
                </div>
                <p className="text-xs text-muted-foreground">PNG ou JPEG — 2 Mo maximum</p>
              </div>
            </div>

            {editing ? (
              <div className="space-y-4">
                <div className="grid gap-4 sm:grid-cols-2">
                  <Field label="Nom de l'organisation">
                    <Input value={form.name} onChange={(e) => setField('name', e.target.value)} />
                  </Field>
                  <Field label="Slug">
                    <Input
                      value={form.slug}
                      onChange={(e) => setField('slug', e.target.value)}
                      placeholder="mon-entreprise"
                    />
                  </Field>
                  <Field label="URL de l'application web">
                    <Input
                      value={form.web_url}
                      onChange={(e) => setField('web_url', e.target.value)}
                      placeholder="https://timesheet.exemple.ch"
                    />
                  </Field>
                  <Field label="Statut">
                    <Select
                      value={form.is_active ? 'active' : 'inactive'}
                      onValueChange={(v) => setField('is_active', v === 'active')}
                    >
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="active">Active</SelectItem>
                        <SelectItem value="inactive">Inactive</SelectItem>
                      </SelectContent>
                    </Select>
                  </Field>
                </div>

                <div className="border-t pt-4">
                  <p className="mb-3 text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                    Personne de contact
                  </p>
                  <div className="grid gap-4 sm:grid-cols-2">
                    <Field label="Prénom">
                      <Input
                        value={form.contact_first_name}
                        onChange={(e) => setField('contact_first_name', e.target.value)}
                      />
                    </Field>
                    <Field label="Nom">
                      <Input
                        value={form.contact_last_name}
                        onChange={(e) => setField('contact_last_name', e.target.value)}
                      />
                    </Field>
                    <Field label="Email">
                      <Input
                        type="email"
                        value={form.contact_email}
                        onChange={(e) => setField('contact_email', e.target.value)}
                      />
                    </Field>
                    <Field label="Téléphone">
                      <Input
                        value={form.contact_phone}
                        onChange={(e) => setField('contact_phone', e.target.value)}
                      />
                    </Field>
                    <div className="sm:col-span-2">
                      <Field label="Adresse">
                        <Input
                          value={form.address}
                          onChange={(e) => setField('address', e.target.value)}
                        />
                      </Field>
                    </div>
                  </div>
                </div>

                <div className="flex gap-2">
                  <Button onClick={handleSave} disabled={updateOrg.isPending}>
                    {updateOrg.isPending ? (
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    ) : (
                      <Save className="mr-2 h-4 w-4" />
                    )}
                    Enregistrer
                  </Button>
                  <Button variant="outline" onClick={() => setEditing(false)}>
                    Annuler
                  </Button>
                </div>
              </div>
            ) : (
              <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                <ReadOnly label="Nom" value={org.name} />
                <ReadOnly label="Slug" value={org.slug} />
                <ReadOnly label="URL de l'application web" value={org.web_url} />
                <ReadOnly
                  label="Personne de contact"
                  value={
                    [org.contact_first_name, org.contact_last_name].filter(Boolean).join(' ') || null
                  }
                />
                <ReadOnly label="Email de contact" value={org.contact_email} />
                <ReadOnly label="Téléphone de contact" value={org.contact_phone} />
                <ReadOnly label="Adresse" value={org.address} />
                <ReadOnly
                  label="Créée le"
                  value={new Date(org.created_at).toLocaleDateString('fr-CH')}
                />
              </div>
            )}
          </CardContent>
        </Card>
      </FadeIn>

      {/* Manager responsable */}
      <FadeIn delay={0.15}>
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-base">
              <ShieldCheck className="h-4 w-4 text-primary" />
              Manager responsable des relevés d'heures
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="rounded-lg border bg-muted/30 p-3">
              {currentManager ? (
                <div className="flex items-center gap-3">
                  <div className="flex h-9 w-9 items-center justify-center rounded-full bg-primary/10 text-xs font-semibold text-primary">
                    {(currentManager.first_name?.[0] ?? '').toUpperCase()}
                    {(currentManager.last_name?.[0] ?? '').toUpperCase()}
                  </div>
                  <div className="flex-1">
                    <p className="text-sm font-medium">
                      {currentManager.first_name} {currentManager.last_name}
                    </p>
                    <p className="text-xs text-muted-foreground">{currentManager.email}</p>
                  </div>
                  <Badge variant={roleBadgeVariant[currentManager.role as UserRole]}>
                    {roleLabels[currentManager.role as UserRole]}
                  </Badge>
                </div>
              ) : (
                <p className="text-sm text-muted-foreground">
                  Aucun manager affecté. Les employés de cette organisation n'ont personne à qui
                  soumettre leur relevé d'heures.
                </p>
              )}
            </div>

            <div className="grid gap-3 sm:grid-cols-[1fr_auto]">
              <div className="space-y-2">
                <Label className="text-xs font-medium text-muted-foreground">
                  Affecter un manager
                </Label>
                <Select
                  value={selectedManagerId || undefined}
                  onValueChange={setSelectedManagerId}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Choisir une personne" />
                  </SelectTrigger>
                  <SelectContent>
                    {(candidates ?? []).map((c) => (
                      <SelectItem key={c.id} value={c.id}>
                        {c.first_name} {c.last_name} — {roleLabels[c.role]}
                        {c.organization_name ? ` (${c.organization_name})` : ''}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="flex items-end gap-2">
                {/* Rejouable : réaffecter le même manager rattache les employés
                    arrivés depuis la dernière affectation. */}
                <Button onClick={handleAssignManager} disabled={!selectedManagerId || managerBusy}>
                  {setManager.isPending ? (
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  ) : (
                    <Check className="mr-2 h-4 w-4" />
                  )}
                  {managerChanged || !currentManager ? 'Affecter' : 'Resynchroniser'}
                </Button>
                {org.default_manager_id && (
                  <Button variant="outline" onClick={handleClearManager} disabled={managerBusy}>
                    {clearManager.isPending ? (
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    ) : (
                      <UserCog className="mr-2 h-4 w-4" />
                    )}
                    Retirer
                  </Button>
                )}
              </div>
            </div>

            <label className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                className="h-4 w-4 rounded border-input accent-primary"
                checked={includeDescendants}
                onChange={(e) => setIncludeDescendants(e.target.checked)}
              />
              Inclure les employés des sous-organisations
            </label>

            <p className="text-xs text-muted-foreground">
              L'affectation rattache le manager à chaque employé actif du périmètre. C'est ce
              rattachement qui lui donne accès aux pointages, aux validations et à la signature des
              relevés — y compris si le manager appartient à une autre organisation.
            </p>
          </CardContent>
        </Card>
      </FadeIn>

      {/* Membres */}
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
            ) : !members || members.length === 0 ? (
              <EmptyState
                icon={Users}
                title="Aucun membre"
                description="Cette organisation n'a pas encore de membres"
              />
            ) : (
              <div className="max-h-96 space-y-1.5 overflow-y-auto">
                {members.map((member) => (
                  <div
                    key={member.id}
                    className="flex items-center justify-between rounded-lg p-3 transition-colors hover:bg-muted/40"
                  >
                    <div className="flex items-center gap-3">
                      <div className="flex h-9 w-9 items-center justify-center rounded-full bg-primary/10 text-xs font-semibold text-primary">
                        {(member.first_name?.[0] ?? '').toUpperCase()}
                        {(member.last_name?.[0] ?? '').toUpperCase()}
                      </div>
                      <div>
                        <p className="text-sm font-medium">
                          {member.first_name} {member.last_name}
                        </p>
                        <p className="text-xs text-muted-foreground">{member.email}</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      {member.id === org.default_manager_id && (
                        <Badge variant="outline" className="gap-1">
                          <ShieldCheck className="h-3 w-3" />
                          Responsable
                        </Badge>
                      )}
                      <Badge variant={roleBadgeVariant[member.role as UserRole]}>
                        {roleLabels[member.role as UserRole]}
                      </Badge>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </FadeIn>

      {/* Sous-organisations (uniquement pour les organisations racines) */}
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
                  onClick={() =>
                    navigate('/admin/organizations', { state: { createChildOf: org.id } })
                  }
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
                      className="flex cursor-pointer items-center justify-between rounded-lg p-3 transition-colors hover:bg-muted/40"
                      onClick={() => navigate(`/admin/organizations/${child.id}`)}
                    >
                      <div className="flex items-center gap-3">
                        {child.logo_url ? (
                          <img
                            src={storageImageSrc(child.logo_url)}
                            alt={`Logo ${child.name}`}
                            className="h-9 w-9 rounded-xl border bg-white object-contain p-0.5"
                          />
                        ) : (
                          <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-primary/10 to-primary/5">
                            <Building2 className="h-4 w-4 text-primary" />
                          </div>
                        )}
                        <div>
                          <p className="text-sm font-medium">{child.name}</p>
                          {child.slug && (
                            <p className="text-xs text-muted-foreground">{child.slug}</p>
                          )}
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

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="space-y-2">
      <Label className="text-xs font-medium text-muted-foreground">{label}</Label>
      {children}
    </div>
  )
}

function ReadOnly({ label, value }: { label: string; value: string | null | undefined }) {
  return (
    <div>
      <p className="text-xs font-medium text-muted-foreground">{label}</p>
      <p className="text-sm font-medium break-words">{value?.trim() ? value : '—'}</p>
    </div>
  )
}
