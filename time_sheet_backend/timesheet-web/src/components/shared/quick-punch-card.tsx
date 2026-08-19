import { format } from 'date-fns'
import { fr } from 'date-fns/locale'
import { toast } from 'sonner'
import { Check, Coffee, LogIn, LogOut, Play } from 'lucide-react'
import type { LucideIcon } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'
import { cn } from '@/lib/utils'
import { useTimesheetEntries, useUpsertTimesheetEntry } from '@/hooks/use-timesheet'
import { useAuthStore } from '@/stores/auth-store'
import { isFilled } from '@/lib/timesheet'
import type { TimesheetEntry } from '@/types/database'

type PunchField =
  | 'start_morning'
  | 'end_morning'
  | 'start_afternoon'
  | 'end_afternoon'

interface Step {
  field: PunchField
  /** Nom de l'evenement, repris dans la confirmation et l'historique du jour. */
  action: string
  /** Libelle du bouton quand cette etape est la prochaine a pointer. */
  label: string
  icon: LucideIcon
  className: string
}

/**
 * Les quatre etapes reprennent exactement le vocabulaire et l'enchainement de
 * l'application mobile (`quick_actions_card.dart`) : Arrivee -> Pause ->
 * Reprise -> Sortie. Les deux clients ecrivent les memes colonnes, un jour
 * commence sur le telephone peut donc etre termine ici, et inversement.
 */
const STEPS: Step[] = [
  {
    field: 'start_morning',
    action: 'Arrivée',
    label: 'Pointer mon arrivée',
    icon: LogIn,
    className: 'bg-emerald-600 hover:bg-emerald-700 text-white',
  },
  {
    field: 'end_morning',
    action: 'Pause',
    label: 'Partir en pause',
    icon: Coffee,
    className: 'bg-amber-500 hover:bg-amber-600 text-white',
  },
  {
    field: 'start_afternoon',
    action: 'Reprise',
    label: 'Reprendre le travail',
    icon: Play,
    className: 'bg-emerald-600 hover:bg-emerald-700 text-white',
  },
  {
    field: 'end_afternoon',
    action: 'Sortie',
    label: 'Terminer ma journée',
    icon: LogOut,
    className: 'bg-slate-800 hover:bg-slate-900 text-white',
  },
]

/** Premiere etape non encore pointee, ou `null` si la journee est complete. */
function nextStep(entry?: TimesheetEntry): Step | null {
  return STEPS.find((step) => !isFilled(entry?.[step.field])) ?? null
}

export function QuickPunchCard() {
  const { session } = useAuthStore()
  const today = new Date()
  const todayStr = format(today, 'yyyy-MM-dd')

  // Meme cle de cache que la page (mois courant) : aucune requete
  // supplementaire tant que l'utilisateur consulte le mois en cours.
  const { data: entries } = useTimesheetEntries(today)
  const upsert = useUpsertTimesheetEntry()

  const entry = entries?.find((e) => e.day_date === todayStr)
  const step = nextStep(entry)

  const handlePunch = async () => {
    if (!step || !session) return
    const now = format(new Date(), 'HH:mm')

    try {
      await upsert.mutateAsync({
        user_id: session.user.id,
        day_date: todayStr,
        day_of_week: format(today, 'EEEE', { locale: fr }),
        [step.field]: now,
      })
      toast.success(`${step.action} enregistrée à ${now}`)
    } catch (error) {
      // Remonter le message brut : c'est lui qui permet de distinguer un
      // refus RLS d'une simple coupure reseau.
      toast.error(
        `Pointage impossible : ${error instanceof Error ? error.message : 'erreur inconnue'}`,
      )
    }
  }

  const punched = STEPS.filter((s) => isFilled(entry?.[s.field]))

  return (
    <Card className="p-5">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div className="space-y-1">
          <p className="text-sm font-medium first-letter:uppercase">
            {format(today, 'EEEE d MMMM', { locale: fr })}
          </p>

          {punched.length > 0 ? (
            <div className="flex flex-wrap items-center gap-x-3 gap-y-1">
              {punched.map((s) => (
                <span key={s.field} className="text-sm text-muted-foreground">
                  {s.action}
                  <span className="ml-1 font-semibold tabular-nums text-foreground">
                    {entry?.[s.field]}
                  </span>
                </span>
              ))}
            </div>
          ) : (
            <p className="text-sm text-muted-foreground">
              Aucun pointage aujourd'hui.
            </p>
          )}
        </div>

        {step ? (
          <Button
            size="lg"
            onClick={handlePunch}
            disabled={upsert.isPending}
            className={cn('gap-2 shrink-0', step.className)}
          >
            <step.icon className="h-4 w-4" />
            {upsert.isPending ? 'Enregistrement...' : step.label}
          </Button>
        ) : (
          <div className="flex shrink-0 items-center gap-2 rounded-lg bg-muted px-4 py-2.5 text-sm font-medium text-muted-foreground">
            <Check className="h-4 w-4 text-emerald-600" />
            Journée terminée
          </div>
        )}
      </div>
    </Card>
  )
}
