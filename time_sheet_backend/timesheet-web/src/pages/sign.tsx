import { useState, useEffect, useCallback } from 'react'
import { useParams } from 'react-router-dom'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { SignatureCanvas } from '@/components/shared/signature-canvas'
import { FadeIn } from '@/components/motion'
import { CheckCircle2, XCircle, Clock, Download, Loader2 } from 'lucide-react'
import type { SignerRole } from '@/types/database'

interface SigningInfo {
  validation_id: string
  signer_role: SignerRole
  signer_name: string
  period_start: string
  period_end: string
  employee_name: string
  pdf_url: string | null
  signing_step: string
  already_signed: boolean
  expired: boolean
  signers: Array<{
    signer_role: string
    signer_name: string
    signed_at: string | null
  }>
}

type PageState =
  | { type: 'loading' }
  | { type: 'error'; message: string }
  | { type: 'expired'; signerName: string }
  | { type: 'already_signed'; signerName: string; signedAt: string }
  | { type: 'ready'; info: SigningInfo }
  | { type: 'signing' }
  | { type: 'success' }

const ROLE_LABELS: Record<string, string> = {
  employee: 'Employe',
  manager: 'Manager',
  client: 'Client',
}

function StepIndicator({ steps, currentStep }: { steps: Array<{ label: string; done: boolean }>; currentStep: number }) {
  return (
    <div className="flex items-center gap-2">
      {steps.map((step, i) => (
        <div key={i} className="flex items-center gap-2">
          <div className={`flex h-8 w-8 items-center justify-center rounded-full text-xs font-bold transition-colors ${
            step.done
              ? 'bg-emerald-500 text-white'
              : i === currentStep
              ? 'bg-primary text-white'
              : 'bg-muted text-muted-foreground'
          }`}>
            {step.done ? <CheckCircle2 className="h-4 w-4" /> : i + 1}
          </div>
          <span className={`text-sm ${step.done ? 'text-emerald-600 font-medium' : i === currentStep ? 'font-medium' : 'text-muted-foreground'}`}>
            {step.label}
          </span>
          {i < steps.length - 1 && (
            <div className={`h-0.5 w-8 rounded ${step.done ? 'bg-emerald-400' : 'bg-muted'}`} />
          )}
        </div>
      ))}
    </div>
  )
}

export default function SignPage() {
  const { token } = useParams<{ token: string }>()
  const [state, setState] = useState<PageState>({ type: 'loading' })
  const [signatureData, setSignatureData] = useState<string | null>(null)

  useEffect(() => {
    if (!token) {
      setState({ type: 'error', message: 'Token manquant' })
      return
    }
    loadSigningInfo(token)
  }, [token])

  async function loadSigningInfo(t: string) {
    try {
      const supabaseUrl = import.meta.env.VITE_SUPABASE_URL as string
      const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string

      const response = await fetch(
        `${supabaseUrl}/functions/v1/get-signing-info?token=${encodeURIComponent(t)}`,
        {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
            'apikey': supabaseAnonKey,
          },
        },
      )

      const result = await response.json()

      if (response.status === 410) {
        setState({ type: 'expired', signerName: result.signer_name ?? '' })
        return
      }

      if (!response.ok) {
        setState({ type: 'error', message: result.error ?? 'Erreur inconnue' })
        return
      }

      if (result.already_signed) {
        setState({
          type: 'already_signed',
          signerName: result.signer_name,
          signedAt: result.signed_at,
        })
        return
      }

      setState({ type: 'ready', info: result })
    } catch {
      setState({ type: 'error', message: 'Impossible de charger les informations de signature' })
    }
  }

  const handleSign = useCallback(async () => {
    if (!signatureData || !token) return

    setState({ type: 'signing' })

    try {
      const supabaseUrl = import.meta.env.VITE_SUPABASE_URL as string
      const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string

      const response = await fetch(
        `${supabaseUrl}/functions/v1/sign-with-token`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'apikey': supabaseAnonKey,
          },
          body: JSON.stringify({
            token,
            signature_data: signatureData,
          }),
        },
      )

      const result = await response.json()

      if (!response.ok) {
        if (result.already_signed) {
          setState({
            type: 'already_signed',
            signerName: '',
            signedAt: new Date().toISOString(),
          })
          return
        }
        setState({ type: 'error', message: result.error ?? 'Erreur lors de la signature' })
        return
      }

      setState({ type: 'success' })
    } catch {
      setState({ type: 'error', message: 'Erreur reseau lors de la signature' })
    }
  }, [signatureData, token])

  function formatPeriod(period: string): string {
    const date = new Date(period)
    const months = [
      'janvier', 'fevrier', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'aout', 'septembre', 'octobre', 'novembre', 'decembre',
    ]
    return `${months[date.getMonth()]} ${date.getFullYear()}`
  }

  function formatDate(dateStr: string): string {
    return new Date(dateStr).toLocaleDateString('fr-CH', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    })
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-background to-muted/30 flex items-center justify-center p-4">
      <div className="w-full max-w-2xl space-y-6">
        {/* Header */}
        <FadeIn>
          <div className="text-center">
            <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-[oklch(0.60_0.18_300)]">
              <span className="text-lg font-extrabold text-white">TS</span>
            </div>
            <h1 className="text-2xl font-bold tracking-tight">Signature de releve d'heures</h1>
            <p className="text-sm text-muted-foreground mt-1">Sonrysa — Gestion du temps</p>
          </div>
        </FadeIn>

        {/* Loading */}
        {state.type === 'loading' && (
          <FadeIn>
            <Card>
              <CardContent className="flex items-center justify-center py-16">
                <div className="text-center space-y-3">
                  <Loader2 className="h-8 w-8 animate-spin text-primary mx-auto" />
                  <p className="text-sm text-muted-foreground">Chargement...</p>
                </div>
              </CardContent>
            </Card>
          </FadeIn>
        )}

        {/* Error */}
        {state.type === 'error' && (
          <FadeIn>
            <Card>
              <CardContent className="py-16">
                <div className="text-center space-y-3">
                  <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-red-50">
                    <XCircle className="h-7 w-7 text-red-500" />
                  </div>
                  <h2 className="text-lg font-semibold text-destructive">Erreur</h2>
                  <p className="text-sm text-muted-foreground">{state.message}</p>
                </div>
              </CardContent>
            </Card>
          </FadeIn>
        )}

        {/* Expired */}
        {state.type === 'expired' && (
          <FadeIn>
            <Card>
              <CardContent className="py-16">
                <div className="text-center space-y-3">
                  <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-amber-50">
                    <Clock className="h-7 w-7 text-amber-500" />
                  </div>
                  <h2 className="text-lg font-semibold text-amber-600">Lien expire</h2>
                  <p className="text-sm text-muted-foreground">
                    Ce lien de signature a expire. Veuillez contacter l'employe pour obtenir un nouveau lien.
                  </p>
                </div>
              </CardContent>
            </Card>
          </FadeIn>
        )}

        {/* Already signed */}
        {state.type === 'already_signed' && (
          <FadeIn>
            <Card>
              <CardContent className="py-16">
                <div className="text-center space-y-3">
                  <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-emerald-50">
                    <CheckCircle2 className="h-7 w-7 text-emerald-500" />
                  </div>
                  <h2 className="text-lg font-semibold text-emerald-600">Deja signe</h2>
                  <p className="text-sm text-muted-foreground">
                    Ce document a deja ete signe
                    {state.signedAt && ` le ${formatDate(state.signedAt)}`}.
                  </p>
                </div>
              </CardContent>
            </Card>
          </FadeIn>
        )}

        {/* Ready to sign */}
        {state.type === 'ready' && (
          <FadeIn>
            {/* Stepper */}
            <div className="flex justify-center">
              <StepIndicator
                steps={state.info.signers.map((s) => ({
                  label: ROLE_LABELS[s.signer_role] ?? s.signer_role,
                  done: !!s.signed_at,
                }))}
                currentStep={state.info.signers.findIndex((s) => !s.signed_at)}
              />
            </div>

            {/* Validation info */}
            <Card className="mt-6">
              <CardHeader>
                <CardTitle className="text-base">Informations du releve</CardTitle>
                <CardDescription>
                  Vous signez en tant que <strong>{ROLE_LABELS[state.info.signer_role] ?? state.info.signer_role}</strong>
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-2 gap-4 text-sm">
                  <div>
                    <p className="text-xs font-medium text-muted-foreground">Employe</p>
                    <p className="font-medium">{state.info.employee_name}</p>
                  </div>
                  <div>
                    <p className="text-xs font-medium text-muted-foreground">Periode</p>
                    <p className="font-medium">{formatPeriod(state.info.period_start)}</p>
                  </div>
                  <div>
                    <p className="text-xs font-medium text-muted-foreground">Signataire</p>
                    <p className="font-medium">{state.info.signer_name}</p>
                  </div>
                  <div>
                    <p className="text-xs font-medium text-muted-foreground">Role</p>
                    <Badge variant="outline">
                      {ROLE_LABELS[state.info.signer_role] ?? state.info.signer_role}
                    </Badge>
                  </div>
                </div>

                {/* Signing progress */}
                {state.info.signers.length > 0 && (
                  <div className="border-t pt-4">
                    <p className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-3">Progression des signatures</p>
                    <div className="space-y-2">
                      {state.info.signers.map((signer, i) => (
                        <div key={i} className="flex items-center gap-3 text-sm">
                          <div className={`h-2 w-2 rounded-full ${signer.signed_at ? 'bg-emerald-500' : 'bg-gray-300'}`} />
                          <span className="font-medium">{ROLE_LABELS[signer.signer_role] ?? signer.signer_role}</span>
                          <span className="text-muted-foreground">({signer.signer_name})</span>
                          {signer.signed_at ? (
                            <Badge variant="secondary" className="ml-auto bg-emerald-50 text-emerald-700">
                              Signe
                            </Badge>
                          ) : (
                            <Badge variant="outline" className="ml-auto">En attente</Badge>
                          )}
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </CardContent>
            </Card>

            {/* PDF viewer */}
            {state.info.pdf_url && (
              <Card>
                <CardHeader>
                  <CardTitle className="text-base">Releve d'heures a verifier</CardTitle>
                  <CardDescription>
                    Veuillez lire attentivement le document ci-dessous avant de signer
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-3">
                  <div className="rounded-lg border overflow-hidden bg-muted/30">
                    <iframe
                      src={state.info.pdf_url}
                      className="w-full"
                      style={{ height: '70vh', minHeight: '500px' }}
                      title="Releve d'heures"
                    />
                  </div>
                  <a
                    href={state.info.pdf_url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-2 text-xs text-muted-foreground hover:text-primary hover:underline"
                  >
                    <Download className="h-3 w-3" />
                    Ouvrir dans un nouvel onglet
                  </a>
                </CardContent>
              </Card>
            )}

            {/* Signature pad */}
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Votre signature</CardTitle>
                <CardDescription>
                  En signant ci-dessous, vous confirmez avoir lu et approuve le releve d'heures ci-dessus
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="rounded-xl border-2 border-dashed border-muted-foreground/20 overflow-hidden">
                  <SignatureCanvas onSignatureChange={setSignatureData} height={200} />
                </div>
                <Button
                  className="w-full h-11"
                  disabled={!signatureData}
                  onClick={handleSign}
                >
                  Signer et valider
                </Button>
              </CardContent>
            </Card>
          </FadeIn>
        )}

        {/* Signing in progress */}
        {state.type === 'signing' && (
          <FadeIn>
            <Card>
              <CardContent className="flex items-center justify-center py-16">
                <div className="text-center space-y-3">
                  <Loader2 className="h-8 w-8 animate-spin text-primary mx-auto" />
                  <p className="text-sm text-muted-foreground">Signature en cours...</p>
                </div>
              </CardContent>
            </Card>
          </FadeIn>
        )}

        {/* Success */}
        {state.type === 'success' && (
          <FadeIn>
            <Card>
              <CardContent className="py-16">
                <div className="text-center space-y-3">
                  <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-emerald-50">
                    <CheckCircle2 className="h-7 w-7 text-emerald-500" />
                  </div>
                  <h2 className="text-lg font-semibold text-emerald-600">Signature enregistree</h2>
                  <p className="text-sm text-muted-foreground">
                    Votre signature a ete enregistree avec succes. Vous pouvez fermer cette page.
                  </p>
                </div>
              </CardContent>
            </Card>
          </FadeIn>
        )}

        {/* Footer */}
        <p className="text-center text-xs text-muted-foreground">
          Ce lien est personnel et securise. Ne le partagez pas.
        </p>
      </div>
    </div>
  )
}
