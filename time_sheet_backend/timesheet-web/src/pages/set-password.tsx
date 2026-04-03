import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { supabase } from '@/lib/supabase'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { FadeIn } from '@/components/motion'
import { Loader2, CheckCircle2, AlertCircle } from 'lucide-react'

export default function SetPasswordPage() {
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [verifying, setVerifying] = useState(true)
  const [success, setSuccess] = useState(false)
  const [invalidLink, setInvalidLink] = useState(false)
  const navigate = useNavigate()

  useEffect(() => {
    // Supabase auto-detects tokens in the URL hash and fires auth events
    const { data: { subscription } } = supabase.auth.onAuthStateChange((event) => {
      if (event === 'PASSWORD_RECOVERY' || event === 'SIGNED_IN') {
        setVerifying(false)
      }
    })

    // Timeout: if no auth event after 5s, the link is invalid/expired
    const timeout = setTimeout(() => {
      setVerifying((v) => {
        if (v) setInvalidLink(true)
        return false
      })
    }, 5000)

    return () => {
      subscription.unsubscribe()
      clearTimeout(timeout)
    }
  }, [])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)

    if (password.length < 6) {
      setError('Le mot de passe doit contenir au moins 6 caracteres')
      return
    }

    if (password !== confirmPassword) {
      setError('Les mots de passe ne correspondent pas')
      return
    }

    setLoading(true)

    const { error } = await supabase.auth.updateUser({ password })
    if (error) {
      setError(error.message)
      setLoading(false)
    } else {
      setSuccess(true)
      setTimeout(() => navigate('/dashboard', { replace: true }), 2000)
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-background p-8">
      <FadeIn className="w-full max-w-sm">
        <div className="mb-8 flex items-center justify-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-[oklch(0.60_0.18_300)]">
            <span className="text-lg font-extrabold text-white">TS</span>
          </div>
          <span className="text-xl font-bold">TimeSheet</span>
        </div>

        {verifying ? (
          <div className="mt-8 flex items-center justify-center gap-2 text-sm text-muted-foreground">
            <Loader2 className="h-4 w-4 animate-spin" />
            Verification du lien...
          </div>
        ) : invalidLink ? (
          <div className="space-y-4 text-center">
            <AlertCircle className="mx-auto h-12 w-12 text-destructive" />
            <h1 className="text-2xl font-bold tracking-tight">Lien invalide</h1>
            <p className="text-sm text-muted-foreground">
              Ce lien n'est pas valide ou a expire. Utilisez "Mot de passe oublie" pour en recevoir un nouveau.
            </p>
            <Button variant="ghost" onClick={() => navigate('/login')} className="mt-4">
              Retour a la connexion
            </Button>
          </div>
        ) : success ? (
          <div className="space-y-4 text-center">
            <CheckCircle2 className="mx-auto h-12 w-12 text-green-500" />
            <h1 className="text-2xl font-bold tracking-tight">Mot de passe defini</h1>
            <p className="text-sm text-muted-foreground">
              Redirection vers votre espace...
            </p>
          </div>
        ) : (
          <>
            <div className="space-y-2">
              <h1 className="text-2xl font-bold tracking-tight">Definir votre mot de passe</h1>
              <p className="text-sm text-muted-foreground">
                Choisissez un mot de passe pour acceder a votre compte TimeSheet.
              </p>
            </div>

            <form onSubmit={handleSubmit} className="mt-8 space-y-5">
              <div className="space-y-2">
                <Label className="text-xs font-medium text-muted-foreground">Nouveau mot de passe</Label>
                <Input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Minimum 6 caracteres"
                  required
                  minLength={6}
                  className="h-11"
                />
              </div>
              <div className="space-y-2">
                <Label className="text-xs font-medium text-muted-foreground">Confirmer le mot de passe</Label>
                <Input
                  type="password"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  required
                  minLength={6}
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
                Definir le mot de passe
              </Button>
            </form>
          </>
        )}
      </FadeIn>
    </div>
  )
}
