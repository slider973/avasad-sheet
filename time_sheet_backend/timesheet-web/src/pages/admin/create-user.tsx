import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { PageHeader } from '@/components/shared/page-header'
import { FadeIn } from '@/components/motion'
import { useCreateUser } from '@/hooks/use-users-management'
import { useOrganizations } from '@/hooks/use-organizations'
import { ArrowLeft, Loader2, UserPlus } from 'lucide-react'
import type { UserRole } from '@/types/database'

export default function AdminCreateUserPage() {
  const navigate = useNavigate()
  const createUser = useCreateUser()
  const { data: organizations } = useOrganizations()

  const [email, setEmail] = useState('')
  const [firstName, setFirstName] = useState('')
  const [lastName, setLastName] = useState('')
  const [role, setRole] = useState<UserRole>('employee')
  const [organizationId, setOrganizationId] = useState('')
  const [error, setError] = useState<string | null>(null)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)

    try {
      await createUser.mutateAsync({
        email,
        first_name: firstName,
        last_name: lastName,
        role,
        organization_id: organizationId || undefined,
      })
      navigate('/admin/users')
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Erreur lors de la creation'
      setError(message)
    }
  }

  return (
    <div className="space-y-8">
      <PageHeader
        title="Creer un utilisateur"
        description="Ajoutez un nouveau compte utilisateur au systeme"
        actions={
          <Button variant="ghost" onClick={() => navigate('/admin/users')}>
            <ArrowLeft className="mr-2 h-4 w-4" />
            Retour
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
                <CardDescription>Invitez un utilisateur — il recevra un email pour definir son mot de passe.</CardDescription>
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
                    required
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="lastName" className="text-xs font-medium text-muted-foreground">Nom</Label>
                  <Input
                    id="lastName"
                    value={lastName}
                    onChange={(e) => setLastName(e.target.value)}
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
                  required
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
                    <SelectItem value="admin">Admin</SelectItem>
                    <SelectItem value="org_admin">Admin organisation</SelectItem>
                    <SelectItem value="super_admin">Super admin</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label className="text-xs font-medium text-muted-foreground">Organisation</Label>
                <Select value={organizationId} onValueChange={setOrganizationId}>
                  <SelectTrigger>
                    <SelectValue placeholder="Choisir une organisation" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="none">Aucune</SelectItem>
                    {organizations?.map((org) => (
                      <SelectItem key={org.id} value={org.id}>{org.name}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              {error && (
                <p className="text-sm text-destructive">{error}</p>
              )}

              <Button type="submit" className="w-full" disabled={createUser.isPending}>
                {createUser.isPending && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                Envoyer l'invitation
              </Button>
            </form>
          </CardContent>
        </Card>
      </FadeIn>
    </div>
  )
}
