import { useState, useMemo } from 'react'
import { useNavigate } from 'react-router-dom'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { useCreateUser } from '@/hooks/use-users-management'
import { useOrganizations } from '@/hooks/use-organizations'
import { useEffectiveOrgIds } from '@/hooks/use-org-data'
import { useAuthStore } from '@/stores/auth-store'
import { ArrowLeft, Loader2, UserPlus } from 'lucide-react'
import { PageHeader } from '@/components/shared/page-header'
import { FadeIn } from '@/components/motion'
import type { UserRole } from '@/types/database'

export default function OrgCreateUserPage() {
  const navigate = useNavigate()
  const createUser = useCreateUser()
  const { profile, isOrgAdmin } = useAuthStore()
  const { data: orgIds } = useEffectiveOrgIds()
  const { data: allOrgs } = useOrganizations()

  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [firstName, setFirstName] = useState('')
  const [lastName, setLastName] = useState('')
  const [role, setRole] = useState<UserRole>('employee')
  const [selectedOrgId, setSelectedOrgId] = useState<string>(profile?.organization_id ?? '')
  const [error, setError] = useState<string | null>(null)

  // Orgs available for user creation (own + children)
  const availableOrgs = useMemo(() => {
    if (!orgIds || !allOrgs) return []
    return allOrgs.filter((o) => orgIds.includes(o.id))
  }, [orgIds, allOrgs])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)

    try {
      await createUser.mutateAsync({
        email,
        password,
        first_name: firstName,
        last_name: lastName,
        role,
        organization_id: selectedOrgId || profile?.organization_id || undefined,
      })
      navigate('/org/users')
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Erreur lors de la creation'
      setError(message)
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Creer un utilisateur"
        description="Ajoutez un nouveau membre a votre organisation"
        actions={
          <Button variant="ghost" size="icon" onClick={() => navigate('/org/users')}>
            <ArrowLeft className="h-4 w-4" />
          </Button>
        }
      />

      <FadeIn delay={0.1}>
        <Card className="max-w-lg">
          <CardHeader>
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-[oklch(0.60_0.18_300)]">
                <UserPlus className="h-5 w-5 text-white" />
              </div>
              <div>
                <CardTitle>Nouvel utilisateur</CardTitle>
                <CardDescription>Creez un employe ou manager dans votre organisation.</CardDescription>
              </div>
            </div>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="firstName" className="text-xs font-medium text-muted-foreground">Prenom</Label>
                  <Input
                    id="firstName"
                    value={firstName}
                    onChange={(e) => setFirstName(e.target.value)}
                    placeholder="Jean"
                    required
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="lastName" className="text-xs font-medium text-muted-foreground">Nom</Label>
                  <Input
                    id="lastName"
                    value={lastName}
                    onChange={(e) => setLastName(e.target.value)}
                    placeholder="Dupont"
                    required
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="email" className="text-xs font-medium text-muted-foreground">Email</Label>
                <Input
                  id="email"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="jean.dupont@exemple.com"
                  required
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="password" className="text-xs font-medium text-muted-foreground">Mot de passe</Label>
                <Input
                  id="password"
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Minimum 6 caracteres"
                  required
                  minLength={6}
                />
              </div>

              <div className="space-y-2">
                <Label className="text-xs font-medium text-muted-foreground">Role</Label>
                <Select value={role} onValueChange={(v) => setRole(v as UserRole)}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="employee">Employe</SelectItem>
                    <SelectItem value="manager">Manager</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              {/* Org selector for org_admin with child orgs */}
              {isOrgAdmin && availableOrgs.length > 1 && (
                <div className="space-y-2">
                  <Label className="text-xs font-medium text-muted-foreground">Organisation</Label>
                  <Select value={selectedOrgId} onValueChange={setSelectedOrgId}>
                    <SelectTrigger>
                      <SelectValue placeholder="Choisir l'organisation" />
                    </SelectTrigger>
                    <SelectContent>
                      {availableOrgs.map((org) => (
                        <SelectItem key={org.id} value={org.id}>
                          {org.name}
                          {org.parent_id ? ' (sous-org)' : ''}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              )}

              {error && (
                <p className="text-sm text-destructive">{error}</p>
              )}

              <Button type="submit" className="w-full" disabled={createUser.isPending}>
                {createUser.isPending && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                Creer l'utilisateur
              </Button>
            </form>
          </CardContent>
        </Card>
      </FadeIn>
    </div>
  )
}
