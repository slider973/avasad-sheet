import { useState, useMemo } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { useOrgTimesheetEntries, useEffectiveOrgIds } from '@/hooks/use-org-data'
import { useOrganizations } from '@/hooks/use-organizations'
import { useAuthStore } from '@/stores/auth-store'
import { Clock } from 'lucide-react'
import { format } from 'date-fns'
import { fr } from 'date-fns/locale'
import { cn } from '@/lib/utils'
import { PageHeader } from '@/components/shared/page-header'
import { MonthNavigator } from '@/components/shared/date-range-picker'
import { DataTable, type Column } from '@/components/shared/data-table'
import { StatsCard } from '@/components/shared/stats-card'
import { StaggerContainer, StaggerItem, FadeIn } from '@/components/motion'
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

function getDayColor(entry: TimesheetEntry): string {
  if (entry.absence_reason) return 'bg-blue-400'
  const hours = computeHours(entry)
  if (hours >= 8) return 'bg-emerald-400'
  if (hours > 0) return 'bg-amber-400'
  return 'bg-gray-200'
}

export default function OrgTimesheetPage() {
  const [date, setDate] = useState(new Date())
  const [selectedUser, setSelectedUser] = useState<string>('all')
  const [filterOrgId, setFilterOrgId] = useState<string>('all')
  const { data, isLoading } = useOrgTimesheetEntries(date)
  const { data: orgIds } = useEffectiveOrgIds()
  const { data: allOrgs } = useOrganizations()
  const { isOrgAdmin } = useAuthStore()

  const availableOrgs = useMemo(() => {
    if (!orgIds || !allOrgs) return []
    return allOrgs.filter((o) => orgIds.includes(o.id))
  }, [orgIds, allOrgs])

  const filteredMembers = useMemo(() => {
    if (!data?.members) return []
    if (filterOrgId === 'all') return data.members
    return data.members.filter((m) => (m as any).organization_id === filterOrgId)
  }, [data?.members, filterOrgId])

  const filteredEntries = useMemo(() => {
    if (!data?.entries) return []
    let entries = data.entries
    if (filterOrgId !== 'all') {
      const memberIds = new Set(filteredMembers.map((m) => m.id))
      entries = entries.filter((e) => memberIds.has(e.user_id))
    }
    if (selectedUser !== 'all') {
      entries = entries.filter((e) => e.user_id === selectedUser)
    }
    return entries
  }, [data, selectedUser, filterOrgId, filteredMembers])

  const memberMap = useMemo(() => {
    const map = new Map<string, string>()
    data?.members?.forEach((m) => map.set(m.id, `${m.first_name} ${m.last_name}`))
    return map
  }, [data?.members])

  const totalHours = useMemo(() => {
    return filteredEntries.reduce((sum, e) => sum + computeHours(e), 0)
  }, [filteredEntries])

  const columns: Column<TimesheetEntry>[] = [
    {
      key: 'date',
      header: 'Date',
      cell: (row) => (
        <div className="flex items-center gap-2.5">
          <div className={cn('h-6 w-1 rounded-full', getDayColor(row))} />
          <span className="font-medium">{row.day_date}</span>
        </div>
      ),
    },
    {
      key: 'employee',
      header: 'Employe',
      cell: (row) => <span className="truncate">{memberMap.get(row.user_id) ?? '-'}</span>,
    },
    {
      key: 'morning',
      header: 'Matin',
      cell: (row) =>
        row.start_morning && row.end_morning
          ? <span className="tabular-nums">{row.start_morning} - {row.end_morning}</span>
          : <span className="text-muted-foreground/40">-</span>,
    },
    {
      key: 'afternoon',
      header: 'Apres-midi',
      cell: (row) =>
        row.start_afternoon && row.end_afternoon
          ? <span className="tabular-nums">{row.start_afternoon} - {row.end_afternoon}</span>
          : <span className="text-muted-foreground/40">-</span>,
    },
    {
      key: 'absence',
      header: 'Absence',
      cell: (row) =>
        row.absence_reason ? (
          <span className="text-blue-600 font-medium">{row.absence_reason}</span>
        ) : null,
    },
    {
      key: 'hours',
      header: 'Heures',
      cell: (row) => {
        const h = computeHours(row)
        return h > 0 ? <span className="font-semibold tabular-nums">{h.toFixed(1)}h</span> : null
      },
      className: 'text-right',
    },
  ]

  return (
    <div className="space-y-6">
      <PageHeader
        title="Pointages organisation"
        description={format(date, 'MMMM yyyy', { locale: fr })}
        actions={<MonthNavigator date={date} onChange={setDate} />}
      />

      <FadeIn>
        <div className="flex items-center gap-4 flex-wrap">
          {isOrgAdmin && availableOrgs.length > 1 && (
            <Select value={filterOrgId} onValueChange={(v) => { setFilterOrgId(v); setSelectedUser('all') }}>
              <SelectTrigger className="w-[200px]">
                <SelectValue placeholder="Toutes les orgs" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Toutes les orgs</SelectItem>
                {availableOrgs.map((o) => (
                  <SelectItem key={o.id} value={o.id}>{o.name}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          )}

          <Select value={selectedUser} onValueChange={setSelectedUser}>
            <SelectTrigger className="w-[200px]">
              <SelectValue placeholder="Tous les membres" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Tous les membres</SelectItem>
              {filteredMembers.map((m) => (
                <SelectItem key={m.id} value={m.id}>
                  {m.first_name} {m.last_name}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
      </FadeIn>

      <StaggerContainer className="space-y-6">
        <StaggerItem>
          <StatsCard
            title="Total heures"
            value={totalHours}
            decimals={1}
            suffix="h"
            description={`${filteredEntries.length} entree${filteredEntries.length !== 1 ? 's' : ''} - ${format(date, 'MMMM yyyy', { locale: fr })}`}
            icon={Clock}
            iconClassName="from-primary to-[oklch(0.60_0.18_300)] text-white"
          />
        </StaggerItem>

        <StaggerItem>
          <Card>
            <CardHeader>
              <CardTitle className="text-base">
                {format(date, 'MMMM yyyy', { locale: fr })}
              </CardTitle>
            </CardHeader>
            <CardContent>
              <DataTable columns={columns} data={filteredEntries} emptyMessage="Aucun pointage" isLoading={isLoading} />
            </CardContent>
          </Card>
        </StaggerItem>
      </StaggerContainer>
    </div>
  )
}
