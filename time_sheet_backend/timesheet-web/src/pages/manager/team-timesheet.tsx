import { useState, useMemo, useRef, useEffect } from 'react'
import { useParams } from 'react-router-dom'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { FadeIn } from '@/components/motion'
import { useEmployeeTimesheetEntries } from '@/hooks/use-timesheet'
import { useTeamMembers } from '@/hooks/use-team'
import {
  format, addMonths, subMonths, addDays, subDays,
  startOfMonth, endOfMonth, startOfWeek, endOfWeek,
  eachDayOfInterval, isSameDay, isSameMonth, isToday,
} from 'date-fns'
import { fr } from 'date-fns/locale'
import { cn } from '@/lib/utils'
import { ChevronLeft, ChevronRight, Loader2 } from 'lucide-react'
import { detectAnomaliesForEntries, severityColors, type DetectedAnomaly } from '@/lib/anomaly-detection'
import type { TimesheetEntry } from '@/types/database'

const absenceLabels: Record<string, string> = {
  vacation: 'Vacances', sick: 'Maladie', holiday: 'Jour ferie',
  unpaid: 'Sans solde', other: 'Autre',
}

const HOUR_HEIGHT = 4
const START_HOUR = 6
const END_HOUR = 20
const TOTAL_MINUTES = (END_HOUR - START_HOUR) * 60
const HOURS = Array.from({ length: END_HOUR - START_HOUR }, (_, i) => START_HOUR + i)

function timeToMinutes(time: string): number {
  const [h, m] = time.split(':').map(Number)
  return h * 60 + m
}

function computeHours(entry: TimesheetEntry): number {
  let total = 0
  if (entry.start_morning && entry.end_morning)
    total += (timeToMinutes(entry.end_morning) - timeToMinutes(entry.start_morning)) / 60
  if (entry.start_afternoon && entry.end_afternoon)
    total += (timeToMinutes(entry.end_afternoon) - timeToMinutes(entry.start_afternoon)) / 60
  return Math.max(0, total)
}

function generateCalendarDays(month: Date) {
  const calStart = startOfWeek(startOfMonth(month), { weekStartsOn: 1 })
  const calEnd = endOfWeek(endOfMonth(month), { weekStartsOn: 1 })
  return eachDayOfInterval({ start: calStart, end: calEnd }).map(day => ({
    date: day,
    dateStr: format(day, 'yyyy-MM-dd'),
    isCurrentMonth: isSameMonth(day, month),
    isToday: isToday(day),
  }))
}

export default function TeamTimesheetPage() {
  const { employeeId: paramId } = useParams()
  const [selectedEmployee, setSelectedEmployee] = useState<string>(paramId ?? '')
  const [selectedDate, setSelectedDate] = useState(new Date())
  const [calendarMonth, setCalendarMonth] = useState(new Date())
  const timelineRef = useRef<HTMLDivElement>(null)

  const { data: members } = useTeamMembers()
  const { data: monthEntries, isLoading } = useEmployeeTimesheetEntries(
    selectedEmployee || null,
    calendarMonth
  )

  const selectedMember = members?.find((m) => m.id === selectedEmployee)
  const selectedDateStr = format(selectedDate, 'yyyy-MM-dd')

  useEffect(() => {
    if (timelineRef.current) {
      const pxPerRem = parseFloat(getComputedStyle(document.documentElement).fontSize)
      timelineRef.current.scrollTop = 1 * HOUR_HEIGHT * pxPerRem
    }
  }, [])

  const selectDate = (date: Date) => {
    setSelectedDate(date)
    if (!isSameMonth(date, calendarMonth)) setCalendarMonth(date)
  }

  const computedAnomalies = useMemo(() => {
    if (!monthEntries) return new Map<string, DetectedAnomaly[]>()
    return detectAnomaliesForEntries(monthEntries)
  }, [monthEntries])

  const calendarDays = useMemo(() => generateCalendarDays(calendarMonth), [calendarMonth])

  const entriesByDate = useMemo(() => {
    const map = new Map<string, TimesheetEntry>()
    monthEntries?.forEach(e => map.set(e.day_date, e))
    return map
  }, [monthEntries])

  const selectedEntry = entriesByDate.get(selectedDateStr)
  const selectedAnomalies = computedAnomalies.get(selectedDateStr) ?? []

  const monthTotalHours = useMemo(() => {
    return (monthEntries ?? []).reduce((sum, e) => sum + computeHours(e), 0)
  }, [monthEntries])

  const blocks = useMemo(() => {
    if (!selectedEntry) return []
    const result: { top: string; height: string; label: string; time: string; color: 'indigo' | 'emerald' | 'orange' }[] = []

    if (selectedEntry.absence_reason) {
      const top = ((8 * 60 - START_HOUR * 60) / TOTAL_MINUTES) * (END_HOUR - START_HOUR) * HOUR_HEIGHT
      const h = (9 * 60 / TOTAL_MINUTES) * (END_HOUR - START_HOUR) * HOUR_HEIGHT
      result.push({
        top: `${top}rem`, height: `${h}rem`,
        label: absenceLabels[selectedEntry.absence_reason] ?? selectedEntry.absence_reason,
        time: 'Journee entiere', color: 'orange',
      })
      return result
    }

    if (selectedEntry.start_morning && selectedEntry.end_morning) {
      const startMins = timeToMinutes(selectedEntry.start_morning)
      const endMins = timeToMinutes(selectedEntry.end_morning)
      if (endMins > startMins) {
        const top = ((startMins - START_HOUR * 60) / 60) * HOUR_HEIGHT
        const h = ((endMins - startMins) / 60) * HOUR_HEIGHT
        result.push({ top: `${top}rem`, height: `${h}rem`, label: 'Matin', time: `${selectedEntry.start_morning} - ${selectedEntry.end_morning}`, color: 'indigo' })
      }
    }

    if (selectedEntry.start_afternoon && selectedEntry.end_afternoon) {
      const startMins = timeToMinutes(selectedEntry.start_afternoon)
      const endMins = timeToMinutes(selectedEntry.end_afternoon)
      if (endMins > startMins) {
        const top = ((startMins - START_HOUR * 60) / 60) * HOUR_HEIGHT
        const h = ((endMins - startMins) / 60) * HOUR_HEIGHT
        result.push({ top: `${top}rem`, height: `${h}rem`, label: 'Apres-midi', time: `${selectedEntry.start_afternoon} - ${selectedEntry.end_afternoon}`, color: 'emerald' })
      }
    }

    return result
  }, [selectedEntry])

  if (!selectedEmployee) {
    return (
      <div className="space-y-6">
        <FadeIn>
          <h1 className="text-2xl font-bold tracking-tight">Pointages employe</h1>
          <p className="text-sm text-muted-foreground">Selectionnez un employe</p>
        </FadeIn>
        <FadeIn delay={0.1}>
          <Select value={selectedEmployee} onValueChange={setSelectedEmployee}>
            <SelectTrigger className="w-64">
              <SelectValue placeholder="Selectionner un employe" />
            </SelectTrigger>
            <SelectContent>
              {members?.map((m) => (
                <SelectItem key={m.id} value={m.id}>
                  {m.first_name} {m.last_name}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </FadeIn>
      </div>
    )
  }

  if (isLoading) {
    return (
      <div className="flex h-64 items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    )
  }

  return (
    <div className="-m-6 flex flex-col" style={{ height: 'calc(100vh - 4rem)' }}>
      {/* Header */}
      <FadeIn>
        <header className="flex flex-none items-center justify-between border-b bg-background px-6 py-3">
          <div className="flex items-center gap-3">
            <Select value={selectedEmployee} onValueChange={setSelectedEmployee}>
              <SelectTrigger className="w-56">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {members?.map((m) => (
                  <SelectItem key={m.id} value={m.id}>
                    {m.first_name} {m.last_name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            {selectedMember && (
              <div>
                <div className="flex items-center gap-2">
                  <div className="flex h-8 w-8 items-center justify-center rounded-full bg-gradient-to-br from-primary to-[oklch(0.60_0.18_300)] text-xs font-bold text-white">
                    {(selectedMember.first_name?.[0] ?? '').toUpperCase()}{(selectedMember.last_name?.[0] ?? '').toUpperCase()}
                  </div>
                  <Badge variant="outline" className="text-xs">Employe</Badge>
                </div>
              </div>
            )}
            <p className="text-xs text-muted-foreground capitalize">
              {format(selectedDate, 'EEEE d MMMM yyyy', { locale: fr })}
            </p>
          </div>
          <div className="flex items-center gap-2">
            <div className="flex items-center rounded-md border">
              <Button variant="ghost" size="icon" className="h-9 w-9 rounded-r-none" onClick={() => selectDate(subDays(selectedDate, 1))}>
                <ChevronLeft className="h-4 w-4" />
              </Button>
              <Button
                variant="ghost"
                className="h-9 rounded-none border-x px-3 text-sm font-medium"
                onClick={() => { const today = new Date(); setSelectedDate(today); setCalendarMonth(today) }}
              >
                Aujourd'hui
              </Button>
              <Button variant="ghost" size="icon" className="h-9 w-9 rounded-l-none" onClick={() => selectDate(addDays(selectedDate, 1))}>
                <ChevronRight className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </header>
      </FadeIn>

      {/* Main content: timeline + sidebar */}
      <div className="flex min-h-0 flex-1">
        {/* Day timeline */}
        <div ref={timelineRef} className="flex flex-auto overflow-y-auto">
          <div className="w-16 flex-none">
            {HOURS.map(hour => (
              <div key={hour} style={{ height: `${HOUR_HEIGHT}rem` }} className="relative">
                <span className="absolute -top-2.5 right-3 text-xs text-muted-foreground">{hour}h</span>
              </div>
            ))}
          </div>
          <div className="relative flex-auto border-l">
            {HOURS.map(hour => (
              <div key={hour} style={{ height: `${HOUR_HEIGHT}rem` }} className="border-b border-dashed border-muted" />
            ))}
            {blocks.map((block, i) => (
              <div
                key={i}
                className={cn(
                  'absolute left-2 right-3 rounded-lg p-3 text-xs shadow-sm',
                  block.color === 'indigo' && 'bg-primary/10 text-primary border border-primary/20',
                  block.color === 'emerald' && 'bg-emerald-50 text-emerald-700 border border-emerald-200',
                  block.color === 'orange' && 'bg-orange-50 text-orange-700 border border-orange-200',
                )}
                style={{ top: block.top, height: block.height }}
              >
                <p className="font-semibold">{block.label}</p>
                <p className="mt-0.5 opacity-80">{block.time}</p>
              </div>
            ))}
            {!selectedEntry && (
              <div
                className="absolute left-2 right-3 flex items-center justify-center rounded-lg border border-dashed border-muted-foreground/30 text-sm text-muted-foreground"
                style={{ top: `${2 * HOUR_HEIGHT}rem`, height: `${8 * HOUR_HEIGHT}rem` }}
              >
                Aucun pointage ce jour
              </div>
            )}
          </div>
        </div>

        {/* Right sidebar */}
        <div className="hidden w-80 flex-none overflow-y-auto border-l md:block">
          <div className="p-6">
            {/* Mini calendar navigation */}
            <div className="flex items-center text-center">
              <Button variant="ghost" size="icon" className="h-7 w-7" onClick={() => setCalendarMonth(subMonths(calendarMonth, 1))}>
                <ChevronLeft className="h-4 w-4" />
              </Button>
              <div className="flex-auto text-sm font-semibold capitalize">
                {format(calendarMonth, 'MMMM yyyy', { locale: fr })}
              </div>
              <Button variant="ghost" size="icon" className="h-7 w-7" onClick={() => setCalendarMonth(addMonths(calendarMonth, 1))}>
                <ChevronRight className="h-4 w-4" />
              </Button>
            </div>

            <div className="mt-4 grid grid-cols-7 text-center text-xs font-medium text-muted-foreground">
              {['L', 'M', 'M', 'J', 'V', 'S', 'D'].map((d, i) => (
                <div key={i} className="py-1">{d}</div>
              ))}
            </div>

            <div className="mt-1 grid grid-cols-7 gap-px overflow-hidden rounded-xl bg-muted/60 text-sm">
              {calendarDays.map(day => {
                const entry = entriesByDate.get(day.dateStr)
                const hasWork = !!entry && !entry.absence_reason
                const hasAbsence = !!entry?.absence_reason
                const hasAnomaly = computedAnomalies.has(day.dateStr)
                const isSelected = isSameDay(day.date, selectedDate)

                return (
                  <button
                    key={day.dateStr}
                    onClick={() => selectDate(day.date)}
                    className={cn(
                      'flex flex-col items-center bg-background py-1.5 hover:bg-muted/80 transition-colors',
                      !day.isCurrentMonth && 'text-muted-foreground/40',
                      day.isToday && !isSelected && 'font-semibold text-primary',
                    )}
                  >
                    <span className={cn(
                      'flex h-7 w-7 items-center justify-center rounded-full text-xs transition-colors',
                      isSelected && day.isToday && 'bg-primary text-primary-foreground',
                      isSelected && !day.isToday && 'bg-foreground text-background',
                    )}>
                      {format(day.date, 'd')}
                    </span>
                    <div className="flex gap-0.5 mt-0.5 h-1.5">
                      {hasWork && <span className="h-1 w-1 rounded-full bg-emerald-500" />}
                      {hasAbsence && <span className="h-1 w-1 rounded-full bg-orange-500" />}
                      {hasAnomaly && <span className="h-1 w-1 rounded-full bg-red-500" />}
                    </div>
                  </button>
                )
              })}
            </div>

            {/* Month summary */}
            <div className="mt-4 rounded-xl border bg-gradient-to-br from-primary/5 to-transparent p-3">
              <p className="text-xs font-medium text-muted-foreground uppercase tracking-wider">Bilan du mois</p>
              <p className="mt-1 text-lg font-bold">{monthTotalHours.toFixed(1)}h</p>
              <p className="text-xs text-muted-foreground">
                {monthEntries?.filter(e => !e.absence_reason).length ?? 0} jours travailles
                {' / '}
                {monthEntries?.filter(e => e.absence_reason).length ?? 0} absences
              </p>
            </div>

            {/* Selected day summary */}
            <div className="mt-6">
              <h3 className="text-sm font-semibold capitalize">
                {format(selectedDate, 'EEEE d MMMM', { locale: fr })}
              </h3>

              {selectedEntry ? (
                <div className="mt-3 space-y-3">
                  {selectedEntry.absence_reason ? (
                    <div className="rounded-lg border border-orange-200 bg-orange-50 p-3">
                      <p className="text-sm font-medium text-orange-700">
                        {absenceLabels[selectedEntry.absence_reason] ?? selectedEntry.absence_reason}
                      </p>
                    </div>
                  ) : (
                    <div className="rounded-lg border p-3 space-y-1">
                      <p className="text-sm font-semibold">{computeHours(selectedEntry).toFixed(1)}h travaillees</p>
                      {(selectedEntry.start_morning || selectedEntry.end_morning) && (
                        <p className="text-xs text-muted-foreground">
                          Matin: {selectedEntry.start_morning || '?'} - {selectedEntry.end_morning || '?'}
                        </p>
                      )}
                      {(selectedEntry.start_afternoon || selectedEntry.end_afternoon) && (
                        <p className="text-xs text-muted-foreground">
                          Apres-midi: {selectedEntry.start_afternoon || '?'} - {selectedEntry.end_afternoon || '?'}
                        </p>
                      )}
                      {!!selectedEntry.has_overtime_hours && (
                        <Badge variant="outline" className="mt-1 text-xs">Heures sup.</Badge>
                      )}
                    </div>
                  )}

                  {selectedAnomalies.length > 0 && (
                    <div className="space-y-2">
                      <p className="text-xs font-semibold text-destructive">
                        {selectedAnomalies.length} anomalie{selectedAnomalies.length > 1 ? 's' : ''}
                      </p>
                      {selectedAnomalies.map((a, i) => (
                        <div key={i} className={cn('rounded-lg border p-2', severityColors[a.severity])}>
                          <p className="text-xs font-medium">{a.label}</p>
                          <p className="text-xs mt-0.5 opacity-80">{a.description}</p>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              ) : (
                <p className="mt-3 text-sm text-muted-foreground">Aucun pointage</p>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
