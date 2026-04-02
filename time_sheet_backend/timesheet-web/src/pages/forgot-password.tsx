import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { supabase } from '@/lib/supabase'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { FadeIn } from '@/components/motion'
import { Loader2, ArrowLeft, CheckCircle2 } from 'lucide-react'

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [sent, setSent] = useState(false)
  const navigate = useNavigate()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setLoading(true)

    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/set-password`,
    })

    if (error) {
      setError(error.message)
    } else {
      setSent(true)
    }
    setLoading(false)
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

        {sent ? (
          <div className="space-y-4 text-center">
            <CheckCircle2 className="mx-auto h-12 w-12 text-green-500" />
            <h1 className="text-2xl font-bold tracking-tight">Email envoye</h1>
            <p className="text-sm text-muted-foreground">
              Un lien de reinitialisation a ete envoye a <strong>{email}</strong>.
              Verifiez votre boite de reception.
            </p>
            <Button variant="ghost" onClick={() => navigate('/login')} className="mt-4">
              <ArrowLeft className="mr-2 h-4 w-4" />
              Retour a la connexion
            </Button>
          </div>
        ) : (
          <>
            <div className="space-y-2">
              <h1 className="text-2xl font-bold tracking-tight">Mot de passe oublie</h1>
              <p className="text-sm text-muted-foreground">
                Entrez votre email pour recevoir un lien de reinitialisation.
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
              {error && (
                <div className="rounded-lg bg-destructive/10 p-3 text-sm font-medium text-destructive">
                  {error}
                </div>
              )}
              <Button type="submit" className="h-11 w-full text-sm font-semibold" disabled={loading}>
                {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                Envoyer le lien
              </Button>
            </form>

            <div className="mt-6 text-center">
              <Button variant="link" onClick={() => navigate('/login')} className="text-sm text-muted-foreground">
                <ArrowLeft className="mr-1 h-3 w-3" />
                Retour a la connexion
              </Button>
            </div>
          </>
        )}
      </FadeIn>
    </div>
  )
}
