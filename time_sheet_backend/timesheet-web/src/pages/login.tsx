import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '@/hooks/use-auth'
import { supabase } from '@/lib/supabase'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { FadeIn } from '@/components/motion'
import { Loader2 } from 'lucide-react'
import type { UserRole } from '@/types/database'

function getRedirectPath(role: UserRole): string {
  switch (role) {
    case 'super_admin': return '/admin'
    case 'org_admin': return '/org'
    default: return '/dashboard'
  }
}

export default function LoginPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const { signIn } = useAuth()
  const navigate = useNavigate()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setLoading(true)

    const { error } = await signIn(email, password)
    if (error) {
      setError('Email ou mot de passe incorrect')
      setLoading(false)
    } else {
      const { data: { user } } = await supabase.auth.getUser()
      if (user) {
        const { data: profile } = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single()
        const redirectPath = getRedirectPath(profile?.role ?? 'employee')
        navigate(redirectPath, { replace: true })
      } else {
        navigate('/dashboard', { replace: true })
      }
    }
  }

  return (
    <div className="flex min-h-screen">
      {/* Left panel - Gradient branding */}
      <div className="relative hidden w-1/2 overflow-hidden lg:flex lg:flex-col lg:justify-between lg:p-12">
        {/* Animated gradient background */}
        <div className="absolute inset-0 bg-gradient-to-br from-[oklch(0.35_0.12_270)] via-[oklch(0.28_0.10_280)] to-[oklch(0.22_0.08_260)]" />

        {/* Decorative orbs */}
        <div className="absolute -left-20 -top-20 h-80 w-80 rounded-full bg-[oklch(0.50_0.16_270)] opacity-20 blur-3xl" />
        <div className="absolute -bottom-32 -right-32 h-96 w-96 rounded-full bg-[oklch(0.65_0.18_25)] opacity-15 blur-3xl" />
        <div className="absolute left-1/3 top-1/2 h-64 w-64 rounded-full bg-[oklch(0.60_0.18_300)] opacity-10 blur-3xl" />

        {/* Content */}
        <div className="relative z-10">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-white/10 backdrop-blur-sm">
              <span className="text-lg font-extrabold text-white">TS</span>
            </div>
            <span className="text-xl font-bold text-white">TimeSheet</span>
          </div>
        </div>

        <div className="relative z-10">
          <h2 className="text-4xl font-bold leading-tight text-white">
            Gerez votre temps,<br />
            simplifiez votre quotidien.
          </h2>
          <p className="mt-4 max-w-md text-lg text-white/60">
            Pointage, absences, notes de frais et validations — tout en un seul espace.
          </p>
        </div>

        <div className="relative z-10">
          <p className="text-sm text-white/40">Sonrysa — Gestion du temps</p>
        </div>
      </div>

      {/* Right panel - Login form */}
      <div className="flex flex-1 items-center justify-center bg-background p-8">
        <FadeIn className="w-full max-w-sm">
          {/* Mobile logo */}
          <div className="mb-8 flex items-center justify-center gap-3 lg:hidden">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-[oklch(0.60_0.18_300)]">
              <span className="text-lg font-extrabold text-white">TS</span>
            </div>
            <span className="text-xl font-bold">TimeSheet</span>
          </div>

          <div className="space-y-2">
            <h1 className="text-2xl font-bold tracking-tight">Connexion</h1>
            <p className="text-sm text-muted-foreground">
              Connectez-vous pour acceder a votre espace
            </p>
          </div>

          <form onSubmit={handleSubmit} className="mt-8 space-y-5">
            <div className="space-y-2">
              <Label className="text-xs font-medium text-muted-foreground">Email</Label>
              <Input
                type="email"
                placeholder="nom@entreprise.ch"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                className="h-11"
              />
            </div>
            <div className="space-y-2">
              <Label className="text-xs font-medium text-muted-foreground">Mot de passe</Label>
              <Input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                className="h-11"
              />
            </div>
            {error && (
              <div className="rounded-lg bg-destructive/10 p-3 text-sm font-medium text-destructive">
                {error}
              </div>
            )}
            <Button type="submit" className="h-11 w-full text-sm font-semibold" disabled={loading}>
              {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
              Se connecter
            </Button>
          </form>

          <div className="mt-4 flex flex-col items-center gap-2">
            <button
              type="button"
              onClick={() => navigate('/forgot-password')}
              className="text-sm text-muted-foreground hover:text-primary transition-colors"
            >
              Mot de passe oublie ?
            </button>
            <button
              type="button"
              onClick={() => navigate('/signup')}
              className="text-sm text-muted-foreground hover:text-primary transition-colors"
            >
              Pas encore de compte ? S'inscrire
            </button>
          </div>
        </FadeIn>
      </div>
    </div>
  )
}
