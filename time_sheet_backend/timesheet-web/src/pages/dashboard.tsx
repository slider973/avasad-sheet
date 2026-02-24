import { useMemo, useState } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { PageHeader } from '@/components/shared/page-header'
import { StatsCard } from '@/components/shared/stats-card'
import { CardSkeletonGrid } from '@/components/shared/loading-skeleton'
import { StaggerContainer, StaggerItem, FadeIn } from '@/components/motion'
import { useTimesheetEntries } from '@/hooks/use-timesheet'
import { useAnomalies } from '@/hooks/use-anomalies'
import { useAbsences } from '@/hooks/use-absences'
import { useAuthStore } from '@/stores/auth-store'
import { Clock, CalendarOff, AlertTriangle, TrendingUp } from 'lucide-react'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'
import { format, startOfWeek, endOfWeek, eachDayOfInterval, parseISO, isWithinInterval } from 'date-fns'
import { fr } from 'date-fns/locale'
import type { TimesheetEntry } from '@/types/database'

function computeHours(entry: TimesheetEntry): number {
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

export default function DashboardPage() {
  const [currentDate] = useState(new Date())
  const { profile } = useAuthStore()
  const { data: entries, isLoading } = useTimesheetEntries(currentDate)
  const { data: anomalies } = useAnomalies(true)
  const { data: absences } = useAbsences()

  const monthHours = useMemo(() => {
    if (!entries) return 0
    return entries.reduce((sum, e) => sum + computeHours(e), 0)
  }, [entries])

  const monthAbsences = useMemo(() => {
    if (!absences) return 0
    const start = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1)
    const end = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 0)
    return absences.filter((a) => {
      const aStart = parseISO(a.start_date)
      return isWithinInterval(aStart, { start, end })
    }).length
  }, [absences, currentDate])

  const weeklyData = useMemo(() => {
    if (!entries) return []
    const weekStart = startOfWeek(new Date(), { weekStartsOn: 1 })
    const weekEnd = endOfWeek(new Date(), { weekStartsOn: 1 })
    const days = eachDayOfInterval({ start: weekStart, end: weekEnd })

    return days.map((day) => {
      const dayStr = format(day, 'yyyy-MM-dd')
      const entry = entries.find((e) => e.day_date === dayStr)
      return {
        day: format(day, 'EEE', { locale: fr }),
        heures: entry ? Number(computeHours(entry).toFixed(1)) : 0,
      }
    })
  }, [entries])

  const recentEntries = useMemo(() => {
    if (!entries) return []
    return [...entries].sort((a, b) => b.day_date.localeCompare(a.day_date)).slice(0, 5)
  }, [entries])

  const greeting = profile?.first_name
    ? `Bonjour, ${profile.first_name}`
    : 'Bonjour'

  return (
    <div className="space-y-8">
      <PageHeader
        title={greeting}
        description={format(currentDate, "EEEE d MMMM yyyy", { locale: fr })}
      />

      {isLoading ? (
        <CardSkeletonGrid count={3} />
      ) : (
        <StaggerContainer className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          <StaggerItem>
            <StatsCard
              title="Heures ce mois"
              value={monthHours}
              decimals={1}
              suffix="h"
              description={format(currentDate, 'MMMM yyyy', { locale: fr })}
              icon={Clock}
              iconClassName="from-primary to-[oklch(0.60_0.18_300)] text-white"
            />
          </StaggerItem>
          <StaggerItem>
            <StatsCard
              title="Absences ce mois"
              value={monthAbsences}
              suffix=" jours"
              description={format(currentDate, 'MMMM yyyy', { locale: fr })}
              icon={CalendarOff}
              iconClassName="from-blue-500 to-blue-400 text-white"
            />
          </StaggerItem>
          <StaggerItem>
            <StatsCard
              title="Anomalies"
              value={anomalies?.length ?? 0}
              description="non resolues"
              icon={AlertTriangle}
              iconClassName="from-[oklch(0.65_0.18_25)] to-[oklch(0.70_0.15_35)] text-white"
            />
          </StaggerItem>
        </StaggerContainer>
      )}

      <div className="grid gap-6 lg:grid-cols-2">
        <FadeIn delay={0.2}>
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-base">
                <TrendingUp className="h-4 w-4 text-primary" />
                Progression hebdomadaire
              </CardTitle>
              <CardDescription>Heures travaillees cette semaine</CardDescription>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={220}>
                <BarChart data={weeklyData}>
                  <defs>
                    <linearGradient id="barGradient" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="oklch(0.50 0.16 270)" stopOpacity={1} />
                      <stop offset="100%" stopColor="oklch(0.60 0.18 300)" stopOpacity={0.8} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" className="stroke-border" />
                  <XAxis dataKey="day" className="text-xs" tick={{ fill: 'oklch(0.50 0.03 270)' }} />
                  <YAxis className="text-xs" tick={{ fill: 'oklch(0.50 0.03 270)' }} />
                  <Tooltip
                    contentStyle={{
                      backgroundColor: 'white',
                      border: '1px solid oklch(0.91 0.008 270)',
                      borderRadius: '0.75rem',
                      boxShadow: '0 4px 12px oklch(0.50 0.16 270 / 0.08)',
                      fontSize: '0.875rem',
                    }}
                  />
                  <Bar dataKey="heures" fill="url(#barGradient)" radius={[6, 6, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </FadeIn>

        <FadeIn delay={0.3}>
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Activite recente</CardTitle>
              <CardDescription>5 derniers pointages</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-2">
                {recentEntries.map((entry) => {
                  const hours = computeHours(entry)
                  const isAbsent = !!entry.absence_reason
                  return (
                    <div
                      key={entry.id}
                      className="flex items-center gap-3 rounded-lg border p-3 transition-colors hover:bg-muted/30"
                    >
                      <div className={`h-full w-1 self-stretch rounded-full ${isAbsent ? 'bg-blue-400' : hours >= 8 ? 'bg-emerald-400' : hours > 0 ? 'bg-amber-400' : 'bg-gray-300'}`} />
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium capitalize">
                          {format(parseISO(entry.day_date), 'EEEE d MMMM', { locale: fr })}
                        </p>
                        <p className="text-xs text-muted-foreground">
                          {entry.absence_reason
                            ? `Absence: ${entry.absence_reason}`
                            : `${entry.start_morning ?? '-'} - ${entry.end_morning ?? '-'} / ${entry.start_afternoon ?? '-'} - ${entry.end_afternoon ?? '-'}`}
                        </p>
                      </div>
                      <span className="text-sm font-bold tabular-nums">{hours.toFixed(1)}h</span>
                    </div>
                  )
                })}
                {recentEntries.length === 0 && (
                  <p className="py-8 text-center text-sm text-muted-foreground">Aucun pointage</p>
                )}
              </div>
            </CardContent>
          </Card>
        </FadeIn>
      </div>
    </div>
  )
}
