import { Card, CardContent, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { FadeIn } from '@/components/motion'
import { Badge } from '@/components/ui/badge'
import { format, parseISO } from 'date-fns'
import { fr } from 'date-fns/locale'
import { Pencil, Plus, X } from 'lucide-react'
import { cn } from '@/lib/utils'
import type { TimesheetEntry } from '@/types/database'

interface DayDetailPanelProps {
  date: string
  entry?: TimesheetEntry
  dayColor: string
  onEdit: () => void
  onClose: () => void
  readOnly?: boolean
}

function computeHours(entry?: TimesheetEntry): number {
  if (!entry) return 0
  let total = 0
  if (entry.start_morning && entry.end_morning) {
    const [sh, sm] = entry.start_morning.split(':').map(Number)
    const [eh, em] = entry.end_morning.split(':').map(Number)
    total += (eh * 60 + em - sh * 60 - sm) / 60
  }
  if (entry.start_afternoon && entry.end_afternoon) {
    const [sh, sm] = entry.start_afternoon.split(':').map(Number)
    const [eh, em] = entry.end_afternoon.split(':').map(Number)
    total += (eh * 60 + em - sh * 60 - sm) / 60
  }
  return Math.max(0, total)
}

export function DayDetailPanel({ date, entry, dayColor, onEdit, onClose, readOnly }: DayDetailPanelProps) {
  const hours = computeHours(entry)
  const hasEntry = entry && (entry.start_morning || entry.start_afternoon || entry.absence_reason)

  return (
    <FadeIn>
      <Card>
        <CardHeader className="relative">
          <div className="flex items-start gap-3">
            <div className={cn('mt-1 h-10 w-1 shrink-0 rounded-full', dayColor)} />
            <div className="min-w-0 flex-1">
              <CardTitle className="capitalize text-base">
                {format(parseISO(date), 'EEEE d MMMM yyyy', { locale: fr })}
              </CardTitle>
            </div>
            <Button variant="ghost" size="icon" className="h-7 w-7 shrink-0" onClick={onClose}>
              <X className="h-3.5 w-3.5" />
            </Button>
          </div>
        </CardHeader>

        <CardContent className="space-y-4">
          {hasEntry ? (
            <>
              <div className="space-y-3">
                <div className="flex justify-between text-sm">
                  <span className="text-muted-foreground">Matin</span>
                  <span className="tabular-nums font-medium">
                    {entry.start_morning && entry.end_morning
                      ? `${entry.start_morning} - ${entry.end_morning}`
                      : '-'}
                  </span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-muted-foreground">Apres-midi</span>
                  <span className="tabular-nums font-medium">
                    {entry.start_afternoon && entry.end_afternoon
                      ? `${entry.start_afternoon} - ${entry.end_afternoon}`
                      : '-'}
                  </span>
                </div>
                {hours > 0 && (
                  <div className="flex justify-between border-t pt-3 text-sm">
                    <span className="font-medium">Heures travaillees</span>
                    <span className="font-bold tabular-nums">{hours.toFixed(1)}h</span>
                  </div>
                )}
              </div>

              {entry.absence_reason && (
                <div className="flex items-center gap-2">
                  <Badge variant="secondary" className="bg-blue-100 text-blue-700">
                    {entry.absence_reason}
                  </Badge>
                </div>
              )}
            </>
          ) : (
            <p className="text-sm text-muted-foreground">Aucun pointage</p>
          )}
        </CardContent>

        {!readOnly && (
          <CardFooter>
            <Button variant="outline" size="sm" className="w-full" onClick={onEdit}>
              {hasEntry ? (
                <>
                  <Pencil className="mr-1.5 h-3.5 w-3.5" />
                  Modifier
                </>
              ) : (
                <>
                  <Plus className="mr-1.5 h-3.5 w-3.5" />
                  Ajouter
                </>
              )}
            </Button>
          </CardFooter>
        )}
      </Card>
    </FadeIn>
  )
}
