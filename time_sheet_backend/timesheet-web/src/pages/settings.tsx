import { useState, useEffect } from 'react'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { PageHeader } from '@/components/shared/page-header'
import { FadeIn } from '@/components/motion'
import { CardSkeleton } from '@/components/shared/loading-skeleton'
import { useProfile, useUpdateProfile } from '@/hooks/use-profile'
import { Loader2, Save, User, Mail, Phone } from 'lucide-react'

export default function SettingsPage() {
  const { data: profile, isLoading } = useProfile()
  const updateMutation = useUpdateProfile()
  const [form, setForm] = useState({ first_name: '', last_name: '', email: '', phone: '' })

  useEffect(() => {
    if (profile) {
      setForm({
        first_name: profile.first_name ?? '',
        last_name: profile.last_name ?? '',
        email: profile.email ?? '',
        phone: profile.phone ?? '',
      })
    }
  }, [profile])

  const handleSave = async () => {
    await updateMutation.mutateAsync({
      first_name: form.first_name,
      last_name: form.last_name,
      phone: form.phone || null,
    })
  }

  if (isLoading) {
    return (
      <div className="space-y-6">
        <PageHeader title="Parametres" />
        <CardSkeleton />
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <PageHeader title="Parametres" description="Gerez votre profil et vos preferences" />

      <FadeIn delay={0.1}>
        <Card className="max-w-lg">
          <CardHeader>
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-primary/10 to-primary/5">
                <User className="h-5 w-5 text-primary" />
              </div>
              <div>
                <CardTitle className="text-base">Profil</CardTitle>
                <CardDescription>Modifier vos informations personnelles</CardDescription>
              </div>
            </div>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label className="text-xs font-medium text-muted-foreground">Prenom</Label>
                <Input
                  value={form.first_name}
                  onChange={(e) => setForm({ ...form, first_name: e.target.value })}
                />
              </div>
              <div className="space-y-2">
                <Label className="text-xs font-medium text-muted-foreground">Nom</Label>
                <Input
                  value={form.last_name}
                  onChange={(e) => setForm({ ...form, last_name: e.target.value })}
                />
              </div>
            </div>
            <div className="space-y-2">
              <Label className="flex items-center gap-1.5 text-xs font-medium text-muted-foreground">
                <Mail className="h-3 w-3" />
                Email
              </Label>
              <Input value={form.email} disabled className="bg-muted/30" />
              <p className="text-xs text-muted-foreground">L'email ne peut pas etre modifie ici</p>
            </div>
            <div className="space-y-2">
              <Label className="flex items-center gap-1.5 text-xs font-medium text-muted-foreground">
                <Phone className="h-3 w-3" />
                Telephone
              </Label>
              <Input
                value={form.phone}
                onChange={(e) => setForm({ ...form, phone: e.target.value })}
                placeholder="+41 79 000 00 00"
              />
            </div>
            <div className="flex items-center gap-3 pt-2">
              <Button onClick={handleSave} disabled={updateMutation.isPending}>
                {updateMutation.isPending ? (
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                ) : (
                  <Save className="mr-2 h-4 w-4" />
                )}
                Enregistrer
              </Button>
              {updateMutation.isSuccess && (
                <p className="text-sm font-medium text-emerald-600">Profil mis a jour</p>
              )}
            </div>
          </CardContent>
        </Card>
      </FadeIn>
    </div>
  )
}
