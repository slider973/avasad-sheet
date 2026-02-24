import { useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog'
import { PageHeader } from '@/components/shared/page-header'
import { MonthNavigator } from '@/components/shared/date-range-picker'
import { DataTable, type Column } from '@/components/shared/data-table'
import { CalendarGrid, type CalendarDay } from '@/components/shared/calendar-grid'
import { DayDetailPanel } from '@/components/shared/day-detail-panel'
import { DayTimeline } from '@/components/shared/day-timeline'
import { MiniCalendar } from '@/components/shared/mini-calendar'
import { FadeIn } from '@/components/motion'
import { Badge } from '@/components/ui/badge'
import { useTimesheetEntries, useUpsertTimesheetEntry } from '@/hooks/use-timesheet'
import { useAuthStore } from '@/stores/auth-store'
import {
  format, parseISO, eachDayOfInterval, startOfMonth, endOfMonth,
  isWeekend, isSameMonth, addDays, subDays,
} from 'date-fns'
import { fr } from 'date-fns/locale'
import { cn } from '@/lib/utils'
import { CalendarDays, ChevronLeft, ChevronRight, Clock, List, Pencil } from 'lucide-react'
import type { TimesheetEntry } from '@/types/database'

type ViewMode = 'list' | 'calendar' | 'day'

interface DayRow {
  date: string
  dayLabel: string
  entry?: TimesheetEntry
  isWeekend: boolean
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

export default function TimesheetPage() {
  const [currentMonth, setCurrentMonth] = useState(new Date())
  const [viewMode, setViewMode] = useState<ViewMode>('list')
  const [selectedDate, setSelectedDate] = useState<string | null>(null)
  const [editEntry, setEditEntry] = useState<DayRow | null>(null)
  const [formData, setFormData] = useState({
    start_morning: '',
    end_morning: '',
    start_afternoon: '',
    end_afternoon: '',
  })

  const { session } = useAuthStore()
  const { data: entries, isLoading } = useTimesheetEntries(currentMonth)
  const upsertMutation = useUpsertTimesheetEntry()

  const days: DayRow[] = eachDayOfInterval({
    start: startOfMonth(currentMonth),
    end: endOfMonth(currentMonth),
  }).map((day) => {
    const dateStr = format(day, 'yyyy-MM-dd')
    return {
      date: dateStr,
      dayLabel: format(day, 'EEE dd', { locale: fr }),
      entry: entries?.find((e) => e.day_date === dateStr),
      isWeekend: isWeekend(day),
    }
  })

  const openEdit = (row: DayRow) => {
    setEditEntry(row)
    setFormData({
      start_morning: row.entry?.start_morning ?? '',
      end_morning: row.entry?.end_morning ?? '',
      start_afternoon: row.entry?.start_afternoon ?? '',
      end_afternoon: row.entry?.end_afternoon ?? '',
    })
  }

  const handleSave = async () => {
    if (!editEntry || !session) return
    await upsertMutation.mutateAsync({
      user_id: session.user.id,
      day_date: editEntry.date,
      day_of_week: format(parseISO(editEntry.date), 'EEEE', { locale: fr }),
      start_morning: formData.start_morning || null,
      end_morning: formData.end_morning || null,
      start_afternoon: formData.start_afternoon || null,
      end_afternoon: formData.end_afternoon || null,
    })
    setEditEntry(null)
  }

  const getDayColor = (row: DayRow) => {
    if (row.isWeekend) return 'bg-gray-300'
    if (row.entry?.absence_reason) return 'bg-blue-400'
    const hours = computeHours(row.entry)
    if (hours >= 8) return 'bg-emerald-400'
    if (hours > 0) return 'bg-amber-400'
    return 'bg-gray-200'
  }

  const handleMonthChange = (date: Date) => {
    setCurrentMonth(date)
    setSelectedDate(null)
  }

  const handleDayClick = (dateStr: string) => {
    setSelectedDate(dateStr === selectedDate ? null : dateStr)
  }

  // Ensure selectedDate is set for day view
  const currentSelectedDate = selectedDate ?? format(new Date(), 'yyyy-MM-dd')

  const navigateDay = (offset: number) => {
    const next = offset > 0
      ? addDays(parseISO(currentSelectedDate), offset)
      : subDays(parseISO(currentSelectedDate), Math.abs(offset))
    const nextStr = format(next, 'yyyy-MM-dd')
    setSelectedDate(nextStr)
    if (!isSameMonth(next, currentMonth)) {
      setCurrentMonth(startOfMonth(next))
    }
  }

  // Build a lookup for calendar day content
  const entryMap = new Map<string, TimesheetEntry>()
  entries?.forEach((e) => entryMap.set(e.day_date, e))

  const renderDayContent = (day: CalendarDay) => {
    const entry = entryMap.get(day.dateStr)
    if (!entry) return null
    const hours = computeHours(entry)
    return (
      <div className="space-y-0.5">
        {hours > 0 && (
          <span className="text-xs font-semibold tabular-nums">{hours.toFixed(1)}h</span>
        )}
        {entry.absence_reason && (
          <Badge variant="secondary" className="bg-blue-100 text-blue-700 text-[10px] px-1 py-0">
            {entry.absence_reason}
          </Badge>
        )}
      </div>
    )
  }

  const renderDayDot = (day: CalendarDay) => {
    const entry = entryMap.get(day.dateStr)
    if (!entry && !day.isWeekend) return null
    const dotColor = day.isWeekend
      ? 'bg-gray-300'
      : entry?.absence_reason
        ? 'bg-blue-400'
        : computeHours(entry) >= 8
          ? 'bg-emerald-400'
          : computeHours(entry) > 0
            ? 'bg-amber-400'
            : 'bg-gray-200'
    return <div className={cn('h-1.5 w-1.5 rounded-full', dotColor)} />
  }

  // Selected day data
  const selectedDayRow = selectedDate
    ? days.find((d) => d.date === selectedDate) ?? {
        date: selectedDate,
        dayLabel: '',
        entry: entryMap.get(selectedDate),
        isWeekend: isWeekend(parseISO(selectedDate)),
      }
    : null

  // Day view data
  const dayViewRow: DayRow = {
    date: currentSelectedDate,
    dayLabel: '',
    entry: entryMap.get(currentSelectedDate),
    isWeekend: isWeekend(parseISO(currentSelectedDate)),
  }
  const dayViewHours = computeHours(dayViewRow.entry)

  const columns: Column<DayRow>[] = [
    {
      key: 'date',
      header: 'Date',
      cell: (row) => (
        <div className="flex items-center gap-2.5">
          <div className={cn('h-6 w-1 rounded-full', getDayColor(row))} />
          <span className={cn('font-medium capitalize', row.isWeekend && 'text-muted-foreground/60')}>
            {format(parseISO(row.date), 'EEEE d', { locale: fr })}
          </span>
        </div>
      ),
    },
    {
      key: 'morning',
      header: 'Matin',
      cell: (row) =>
        row.entry?.start_morning && row.entry?.end_morning
          ? <span className="tabular-nums">{row.entry.start_morning} - {row.entry.end_morning}</span>
          : <span className="text-muted-foreground/40">-</span>,
    },
    {
      key: 'afternoon',
      header: 'Apres-midi',
      cell: (row) =>
        row.entry?.start_afternoon && row.entry?.end_afternoon
          ? <span className="tabular-nums">{row.entry.start_afternoon} - {row.entry.end_afternoon}</span>
          : <span className="text-muted-foreground/40">-</span>,
    },
    {
      key: 'hours',
      header: 'Heures',
      cell: (row) => {
        const h = computeHours(row.entry)
        return h > 0 ? <span className="font-semibold tabular-nums">{h.toFixed(1)}h</span> : null
      },
      className: 'text-right',
    },
    {
      key: 'absence',
      header: 'Absence',
      cell: (row) =>
        row.entry?.absence_reason ? (
          <span className="text-blue-600 font-medium">{row.entry.absence_reason}</span>
        ) : null,
    },
    {
      key: 'actions',
      header: '',
      cell: (row) => (
        <Button variant="ghost" size="icon" className="h-8 w-8" onClick={() => openEdit(row)}>
          <Pencil className="h-3.5 w-3.5" />
        </Button>
      ),
      className: 'w-12',
    },
  ]

  return (
    <div className="space-y-6">
      <PageHeader
        title="Pointages"
        description={format(currentMonth, 'MMMM yyyy', { locale: fr })}
        actions={
          <div className="flex items-center gap-3">
            <div className="flex items-center rounded-lg bg-muted/50 p-0.5">
              <Button
                variant={viewMode === 'list' ? 'secondary' : 'ghost'}
                size="icon"
                className="h-7 w-7"
                onClick={() => setViewMode('list')}
              >
                <List className="h-3.5 w-3.5" />
              </Button>
              <Button
                variant={viewMode === 'calendar' ? 'secondary' : 'ghost'}
                size="icon"
                className="h-7 w-7"
                onClick={() => setViewMode('calendar')}
              >
                <CalendarDays className="h-3.5 w-3.5" />
              </Button>
              <Button
                variant={viewMode === 'day' ? 'secondary' : 'ghost'}
                size="icon"
                className="h-7 w-7"
                onClick={() => {
                  setViewMode('day')
                  if (!selectedDate) setSelectedDate(format(new Date(), 'yyyy-MM-dd'))
                }}
              >
                <Clock className="h-3.5 w-3.5" />
              </Button>
            </div>
            <MonthNavigator date={currentMonth} onChange={handleMonthChange} />
          </div>
        }
      />

      {/* List view */}
      {viewMode === 'list' && (
        <FadeIn delay={0.1}>
          <Card>
            <CardHeader>
              <CardTitle className="text-base">
                {format(currentMonth, 'MMMM yyyy', { locale: fr })}
              </CardTitle>
            </CardHeader>
            <CardContent>
              <DataTable columns={columns} data={days} emptyMessage="Aucun jour" isLoading={isLoading} />
            </CardContent>
          </Card>
        </FadeIn>
      )}

      {/* Calendar (month) view */}
      {viewMode === 'calendar' && (
        <FadeIn delay={0.1}>
          <div className="flex flex-col gap-6 lg:flex-row">
            <div className="flex-1">
              <Card>
                <CardContent>
                  <CalendarGrid
                    month={currentMonth}
                    selectedDate={selectedDate}
                    onDayClick={handleDayClick}
                    renderDayContent={renderDayContent}
                    renderDayDot={renderDayDot}
                    isLoading={isLoading}
                  />
                </CardContent>
              </Card>
            </div>
            {selectedDayRow && (
              <div className="lg:w-80">
                <DayDetailPanel
                  date={selectedDayRow.date}
                  entry={selectedDayRow.entry}
                  dayColor={getDayColor(selectedDayRow)}
                  onEdit={() => openEdit(selectedDayRow)}
                  onClose={() => setSelectedDate(null)}
                />
              </div>
            )}
          </div>
        </FadeIn>
      )}

      {/* Day (timeline) view */}
      {viewMode === 'day' && (
        <FadeIn delay={0.1}>
          <div className="flex flex-col gap-6 lg:flex-row">
            <div className="flex-1">
              <Card className="overflow-hidden">
                {/* Day header with navigation */}
                <div className="flex items-center justify-between border-b px-6 py-4">
                  <Button variant="ghost" size="icon" className="h-8 w-8" onClick={() => navigateDay(-1)}>
                    <ChevronLeft className="h-4 w-4" />
                  </Button>
                  <div className="text-center">
                    <p className="text-sm font-semibold capitalize">
                      {format(parseISO(currentSelectedDate), 'EEEE d MMMM yyyy', { locale: fr })}
                    </p>
                    <p className="text-xs text-muted-foreground">
                      {dayViewHours > 0 ? `${dayViewHours.toFixed(1)}h travaillees` : 'Aucun pointage'}
                    </p>
                  </div>
                  <Button variant="ghost" size="icon" className="h-8 w-8" onClick={() => navigateDay(1)}>
                    <ChevronRight className="h-4 w-4" />
                  </Button>
                </div>
                {/* Timeline */}
                <DayTimeline
                  entry={dayViewRow.entry}
                  onBlockClick={() => openEdit(dayViewRow)}
                />
              </Card>
            </div>
            {/* Mini calendar sidebar */}
            <div className="hidden lg:block lg:w-72">
              <Card>
                <CardHeader>
                  <CardTitle className="text-sm text-center capitalize">
                    {format(currentMonth, 'MMMM yyyy', { locale: fr })}
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <MiniCalendar
                    month={currentMonth}
                    selectedDate={currentSelectedDate}
                    onDayClick={(dateStr) => setSelectedDate(dateStr)}
                  />
                </CardContent>
              </Card>
            </div>
          </div>
        </FadeIn>
      )}

      <Dialog open={!!editEntry} onOpenChange={(open) => !open && setEditEntry(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              Modifier le pointage
            </DialogTitle>
            {editEntry && (
              <p className="text-sm text-muted-foreground capitalize">
                {format(parseISO(editEntry.date), 'EEEE d MMMM yyyy', { locale: fr })}
              </p>
            )}
          </DialogHeader>
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label className="text-xs font-medium text-muted-foreground">Debut matin</Label>
              <Input
                type="time"
                value={formData.start_morning}
                onChange={(e) => setFormData({ ...formData, start_morning: e.target.value })}
              />
            </div>
            <div className="space-y-2">
              <Label className="text-xs font-medium text-muted-foreground">Fin matin</Label>
              <Input
                type="time"
                value={formData.end_morning}
                onChange={(e) => setFormData({ ...formData, end_morning: e.target.value })}
              />
            </div>
            <div className="space-y-2">
              <Label className="text-xs font-medium text-muted-foreground">Debut apres-midi</Label>
              <Input
                type="time"
                value={formData.start_afternoon}
                onChange={(e) => setFormData({ ...formData, start_afternoon: e.target.value })}
              />
            </div>
            <div className="space-y-2">
              <Label className="text-xs font-medium text-muted-foreground">Fin apres-midi</Label>
              <Input
                type="time"
                value={formData.end_afternoon}
                onChange={(e) => setFormData({ ...formData, end_afternoon: e.target.value })}
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setEditEntry(null)}>
              Annuler
            </Button>
            <Button onClick={handleSave} disabled={upsertMutation.isPending}>
              Enregistrer
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}
