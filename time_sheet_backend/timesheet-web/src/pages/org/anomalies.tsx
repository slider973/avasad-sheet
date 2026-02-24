import { useMemo, useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { useOrgAnomalies, useEffectiveOrgIds } from '@/hooks/use-org-data'
import { useOrganizations } from '@/hooks/use-organizations'
import { useAuthStore } from '@/stores/auth-store'
import {
  AlertTriangle,
  Clock,
  CalendarX,
  Timer,
  Coffee,
  CalendarClock,
  Scale,
} from 'lucide-react'
import { PageHeader } from '@/components/shared/page-header'
import { StatsCard } from '@/components/shared/stats-card'
import { StatusBadge } from '@/components/shared/status-badge'
import { DataTable, type Column } from '@/components/shared/data-table'
import { StaggerContainer, StaggerItem, FadeIn } from '@/components/motion'
import type { Anomaly } from '@/types/database'

const anomalyConfig: Record<string, { label: string; icon: typeof AlertTriangle; color: string }> = {
  insufficient_hours: { label: 'Heures insuffisantes', icon: Clock, color: 'text-orange-500' },
  missing_entry: { label: 'Pointage manquant', icon: CalendarX, color: 'text-red-500' },
  invalid_times: { label: 'Horaires invalides', icon: Timer, color: 'text-red-600' },
  excessive_hours: { label: 'Heures excessives', icon: AlertTriangle, color: 'text-amber-500' },
  missing_break: { label: 'Pause manquante', icon: Coffee, color: 'text-yellow-500' },
  schedule_inconsistency: { label: 'Incoherence horaire', icon: CalendarClock, color: 'text-purple-500' },
  weekly_compensation: { label: 'Compensation hebdo.', icon: Scale, color: 'text-blue-500' },
  // camelCase aliases
  insufficientHours: { label: 'Heures insuffisantes', icon: Clock, color: 'text-orange-500' },
  missingEntry: { label: 'Pointage manquant', icon: CalendarX, color: 'text-red-500' },
  invalidTimes: { label: 'Horaires invalides', icon: Timer, color: 'text-red-600' },
  excessiveHours: { label: 'Heures excessives', icon: AlertTriangle, color: 'text-amber-500' },
  missingBreak: { label: 'Pause manquante', icon: Coffee, color: 'text-yellow-500' },
  scheduleInconsistency: { label: 'Incoherence horaire', icon: CalendarClock, color: 'text-purple-500' },
  weeklyCompensation: { label: 'Compensation hebdo.', icon: Scale, color: 'text-blue-500' },
}

export default function OrgAnomaliesPage() {
  const { data, isLoading } = useOrgAnomalies()
  const [selectedUser, setSelectedUser] = useState<string>('all')
  const [filterOrgId, setFilterOrgId] = useState<string>('all')
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

  const filteredAnomalies = useMemo(() => {
    if (!data?.anomalies) return []
    let anomalies = data.anomalies
    if (filterOrgId !== 'all') {
      const memberIds = new Set(filteredMembers.map((m) => m.id))
      anomalies = anomalies.filter((a) => memberIds.has(a.user_id))
    }
    if (selectedUser !== 'all') {
      anomalies = anomalies.filter((a) => a.user_id === selectedUser)
    }
    return anomalies
  }, [data, selectedUser, filterOrgId, filteredMembers])

  const memberMap = useMemo(() => {
    const map = new Map<string, string>()
    data?.members?.forEach((m) => map.set(m.id, `${m.first_name} ${m.last_name}`))
    return map
  }, [data?.members])

  const columns: Column<Anomaly>[] = [
    {
      key: 'type',
      header: 'Type',
      cell: (row) => {
        const config = anomalyConfig[row.type]
        const Icon = config?.icon ?? AlertTriangle
        return (
          <div className="flex items-center gap-2">
            <div className="flex h-7 w-7 items-center justify-center rounded-lg bg-orange-50">
              <Icon className={`h-3.5 w-3.5 ${config?.color ?? 'text-muted-foreground'}`} />
            </div>
            <span className="font-medium">{config?.label ?? row.type}</span>
          </div>
        )
      },
    },
    {
      key: 'employee',
      header: 'Employe',
      cell: (row) => <span className="font-medium">{memberMap.get(row.user_id) ?? '-'}</span>,
    },
    {
      key: 'date',
      header: 'Date',
      cell: (row) => row.detected_date,
    },
    {
      key: 'description',
      header: 'Description',
      cell: (row) => <span className="text-muted-foreground">{row.description}</span>,
    },
    {
      key: 'status',
      header: 'Statut',
      cell: () => <StatusBadge status="unresolved" />,
    },
  ]

  return (
    <div className="space-y-6">
      <PageHeader
        title="Anomalies organisation"
        description="Anomalies non resolues detectees dans votre organisation"
      />

      <StaggerContainer className="grid gap-4 sm:grid-cols-2">
        <StaggerItem>
          <StatsCard
            title="Non resolues"
            value={filteredAnomalies.length}
            description="anomalies detectees"
            icon={AlertTriangle}
            iconClassName="from-[oklch(0.65_0.18_25)] to-[oklch(0.70_0.15_35)] text-white"
          />
        </StaggerItem>
        <StaggerItem>
          <StatsCard
            title="Membres concernes"
            value={new Set(filteredAnomalies.map((a) => a.user_id)).size}
            description="avec anomalies"
            icon={CalendarX}
            iconClassName="from-amber-500 to-amber-400 text-white"
          />
        </StaggerItem>
      </StaggerContainer>

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
            <SelectTrigger className="w-[250px]">
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

      <FadeIn delay={0.2}>
        <Card>
          <CardHeader>
            <CardTitle className="text-base">
              {filteredAnomalies.length} anomalie(s)
            </CardTitle>
          </CardHeader>
          <CardContent>
            <DataTable columns={columns} data={filteredAnomalies} emptyMessage="Aucune anomalie non resolue" isLoading={isLoading} />
          </CardContent>
        </Card>
      </FadeIn>
    </div>
  )
}
