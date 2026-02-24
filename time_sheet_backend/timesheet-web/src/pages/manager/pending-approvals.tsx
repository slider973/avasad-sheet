import { useState } from 'react'
import { Card, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog'
import { PageHeader } from '@/components/shared/page-header'
import { StatusBadge } from '@/components/shared/status-badge'
import { EmptyState } from '@/components/shared/empty-state'
import { FadeIn } from '@/components/motion'
import { useTeamPendingValidations, useApproveValidation } from '@/hooks/use-validations'
import { useTeamPendingExpenses, useApproveExpense } from '@/hooks/use-expenses'
import { format, parseISO } from 'date-fns'
import { fr } from 'date-fns/locale'
import { Check, X, CheckSquare, Receipt } from 'lucide-react'

export default function PendingApprovalsPage() {
  const { data: validations, isLoading: valLoading } = useTeamPendingValidations()
  const { data: expenses, isLoading: expLoading } = useTeamPendingExpenses()
  const approveValidation = useApproveValidation()
  const approveExpense = useApproveExpense()

  const [rejectDialog, setRejectDialog] = useState<{ type: 'validation' | 'expense'; id: string } | null>(null)
  const [comment, setComment] = useState('')

  const handleApproveValidation = (id: string) => {
    approveValidation.mutate({ id, approved: true })
  }

  const handleApproveExpense = (id: string) => {
    approveExpense.mutate({ id, approved: true })
  }

  const handleReject = () => {
    if (!rejectDialog) return
    if (rejectDialog.type === 'validation') {
      approveValidation.mutate({ id: rejectDialog.id, approved: false, comment })
    } else {
      approveExpense.mutate({ id: rejectDialog.id, approved: false, comment })
    }
    setRejectDialog(null)
    setComment('')
  }

  const valCount = validations?.length ?? 0
  const expCount = expenses?.length ?? 0

  return (
    <div className="space-y-6">
      <PageHeader title="Approbations en attente" description={`${valCount + expCount} element(s) a traiter`} />

      <FadeIn delay={0.1}>
        <Tabs defaultValue="validations">
          <TabsList>
            <TabsTrigger value="validations" className="gap-1.5">
              Validations
              {valCount > 0 && (
                <span className="flex h-5 min-w-5 items-center justify-center rounded-full bg-primary px-1.5 text-[10px] font-bold text-primary-foreground">
                  {valCount}
                </span>
              )}
            </TabsTrigger>
            <TabsTrigger value="expenses" className="gap-1.5">
              Depenses
              {expCount > 0 && (
                <span className="flex h-5 min-w-5 items-center justify-center rounded-full bg-primary px-1.5 text-[10px] font-bold text-primary-foreground">
                  {expCount}
                </span>
              )}
            </TabsTrigger>
          </TabsList>

          <TabsContent value="validations" className="mt-4 space-y-3">
            {valLoading ? (
              <div className="space-y-3">
                {Array.from({ length: 2 }).map((_, i) => (
                  <div key={i} className="h-20 animate-pulse rounded-xl bg-muted" />
                ))}
              </div>
            ) : validations?.length === 0 ? (
              <EmptyState icon={CheckSquare} title="Aucune validation en attente" description="Toutes les validations ont ete traitees" />
            ) : (
              validations?.map((v: Record<string, unknown>) => (
                <Card key={v.id as string}>
                  <CardContent className="flex items-center justify-between p-5">
                    <div className="flex items-center gap-3">
                      <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary/10 text-xs font-semibold text-primary">
                        {((v.profiles as Record<string, string>)?.first_name?.[0] ?? '') +
                          ((v.profiles as Record<string, string>)?.last_name?.[0] ?? '')}
                      </div>
                      <div>
                        <p className="font-medium">
                          {(v.profiles as Record<string, string>)?.first_name}{' '}
                          {(v.profiles as Record<string, string>)?.last_name}
                        </p>
                        <p className="text-sm text-muted-foreground">
                          {format(parseISO(v.period_start as string), 'd MMM', { locale: fr })} -{' '}
                          {format(parseISO(v.period_end as string), 'd MMM yyyy', { locale: fr })}
                        </p>
                        <StatusBadge status="pending" className="mt-1.5" />
                      </div>
                    </div>
                    <div className="flex gap-2">
                      <Button
                        size="sm"
                        className="gap-1.5"
                        onClick={() => handleApproveValidation(v.id as string)}
                        disabled={approveValidation.isPending}
                      >
                        <Check className="h-3.5 w-3.5" />
                        Approuver
                      </Button>
                      <Button
                        size="sm"
                        variant="destructive"
                        className="gap-1.5"
                        onClick={() => setRejectDialog({ type: 'validation', id: v.id as string })}
                      >
                        <X className="h-3.5 w-3.5" />
                        Rejeter
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              ))
            )}
          </TabsContent>

          <TabsContent value="expenses" className="mt-4 space-y-3">
            {expLoading ? (
              <div className="space-y-3">
                {Array.from({ length: 2 }).map((_, i) => (
                  <div key={i} className="h-20 animate-pulse rounded-xl bg-muted" />
                ))}
              </div>
            ) : expenses?.length === 0 ? (
              <EmptyState icon={Receipt} title="Aucune depense en attente" description="Toutes les depenses ont ete traitees" />
            ) : (
              expenses?.map((e: Record<string, unknown>) => (
                <Card key={e.id as string}>
                  <CardContent className="flex items-center justify-between p-5">
                    <div className="flex items-center gap-3">
                      <div className="flex h-10 w-10 items-center justify-center rounded-full bg-blue-500/10 text-xs font-semibold text-blue-600">
                        {((e.profiles as Record<string, string>)?.first_name?.[0] ?? '') +
                          ((e.profiles as Record<string, string>)?.last_name?.[0] ?? '')}
                      </div>
                      <div>
                        <p className="font-medium">
                          {(e.profiles as Record<string, string>)?.first_name}{' '}
                          {(e.profiles as Record<string, string>)?.last_name}
                        </p>
                        <p className="text-sm text-muted-foreground">
                          {format(parseISO(e.date as string), 'd MMM yyyy', { locale: fr })} - {e.category as string}
                        </p>
                        <p className="text-lg font-bold tabular-nums">
                          {(e.amount as number).toFixed(2)} {e.currency as string}
                        </p>
                        {e.description ? (
                          <p className="text-sm text-muted-foreground">{String(e.description)}</p>
                        ) : null}
                      </div>
                    </div>
                    <div className="flex gap-2">
                      <Button
                        size="sm"
                        className="gap-1.5"
                        onClick={() => handleApproveExpense(e.id as string)}
                        disabled={approveExpense.isPending}
                      >
                        <Check className="h-3.5 w-3.5" />
                        Approuver
                      </Button>
                      <Button
                        size="sm"
                        variant="destructive"
                        className="gap-1.5"
                        onClick={() => setRejectDialog({ type: 'expense', id: e.id as string })}
                      >
                        <X className="h-3.5 w-3.5" />
                        Rejeter
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              ))
            )}
          </TabsContent>
        </Tabs>
      </FadeIn>

      <Dialog open={!!rejectDialog} onOpenChange={(open) => !open && setRejectDialog(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Motif du rejet</DialogTitle>
          </DialogHeader>
          <Textarea
            value={comment}
            onChange={(e) => setComment(e.target.value)}
            placeholder="Raison du rejet..."
          />
          <DialogFooter>
            <Button variant="outline" onClick={() => setRejectDialog(null)}>
              Annuler
            </Button>
            <Button variant="destructive" onClick={handleReject}>
              Confirmer le rejet
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}
