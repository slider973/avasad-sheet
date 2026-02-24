import { useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { PageHeader } from '@/components/shared/page-header'
import { StatusBadge } from '@/components/shared/status-badge'
import { DataTable, type Column } from '@/components/shared/data-table'
import { StatsCard } from '@/components/shared/stats-card'
import { StaggerContainer, StaggerItem, FadeIn } from '@/components/motion'
import { useAnomalies, useResolveAnomaly } from '@/hooks/use-anomalies'
import { format, parseISO } from 'date-fns'
import { fr } from 'date-fns/locale'
import {
  AlertTriangle,
  Clock,
  CalendarX,
  Timer,
  Coffee,
  CalendarClock,
  Scale,
  Filter,
  CheckCircle2,
} from 'lucide-react'
import type { Anomaly, AnomalyType } from '@/types/database'

const anomalyConfig: Record<AnomalyType, { label: string; icon: typeof AlertTriangle; color: string }> = {
  insufficient_hours: { label: 'Heures insuffisantes', icon: Clock, color: 'text-orange-500' },
  missing_entry: { label: 'Pointage manquant', icon: CalendarX, color: 'text-red-500' },
  invalid_times: { label: 'Horaires invalides', icon: Timer, color: 'text-red-600' },
  excessive_hours: { label: 'Heures excessives', icon: AlertTriangle, color: 'text-amber-500' },
  missing_break: { label: 'Pause manquante', icon: Coffee, color: 'text-yellow-500' },
  schedule_inconsistency: { label: 'Incoherence horaire', icon: CalendarClock, color: 'text-purple-500' },
  weekly_compensation: { label: 'Compensation hebdo.', icon: Scale, color: 'text-blue-500' },
}

export default function AnomaliesPage() {
  const [unresolvedOnly, setUnresolvedOnly] = useState(false)
  const { data: anomalies, isLoading } = useAnomalies(unresolvedOnly)
  const resolveMutation = useResolveAnomaly()

  const unresolvedCount = anomalies?.filter((a) => !a.is_resolved).length ?? 0
  const resolvedCount = anomalies?.filter((a) => a.is_resolved).length ?? 0

  const columns: Column<Anomaly>[] = [
    {
      key: 'type',
      header: 'Type',
      cell: (row) => {
        const config = anomalyConfig[row.type]
        const Icon = config?.icon ?? AlertTriangle
        return (
          <div className="flex items-center gap-2">
            <div className={`flex h-7 w-7 items-center justify-center rounded-lg ${row.is_resolved ? 'bg-muted' : 'bg-orange-50'}`}>
              <Icon className={`h-3.5 w-3.5 ${row.is_resolved ? 'text-muted-foreground' : config?.color ?? 'text-muted-foreground'}`} />
            </div>
            <span className="font-medium">{config?.label ?? row.type}</span>
          </div>
        )
      },
    },
    {
      key: 'date',
      header: 'Date',
      cell: (row) => format(parseISO(row.detected_date), 'd MMM yyyy', { locale: fr }),
    },
    {
      key: 'description',
      header: 'Description',
      cell: (row) => <span className="text-muted-foreground">{row.description}</span>,
    },
    {
      key: 'status',
      header: 'Statut',
      cell: (row) => <StatusBadge status={row.is_resolved ? 'resolved' : 'unresolved'} />,
    },
    {
      key: 'actions',
      header: '',
      cell: (row) =>
        !row.is_resolved ? (
          <Button
            variant="outline"
            size="sm"
            className="gap-1.5"
            onClick={() => resolveMutation.mutate(row.id)}
            disabled={resolveMutation.isPending}
          >
            <CheckCircle2 className="h-3.5 w-3.5" />
            Resoudre
          </Button>
        ) : null,
      className: 'w-28',
    },
  ]

  return (
    <div className="space-y-6">
      <PageHeader
        title="Anomalies"
        description="Detectez et resolvez les incoherences"
        actions={
          <Button
            variant={unresolvedOnly ? 'default' : 'outline'}
            onClick={() => setUnresolvedOnly(!unresolvedOnly)}
          >
            <Filter className="mr-2 h-4 w-4" />
            {unresolvedOnly ? 'Non resolues' : 'Toutes'}
          </Button>
        }
      />

      <StaggerContainer className="grid gap-4 sm:grid-cols-2">
        <StaggerItem>
          <StatsCard
            title="Non resolues"
            value={unresolvedCount}
            icon={AlertTriangle}
            iconClassName="from-[oklch(0.65_0.18_25)] to-[oklch(0.70_0.15_35)] text-white"
          />
        </StaggerItem>
        <StaggerItem>
          <StatsCard
            title="Resolues"
            value={resolvedCount}
            icon={CheckCircle2}
            iconClassName="from-emerald-500 to-emerald-400 text-white"
          />
        </StaggerItem>
      </StaggerContainer>

      <FadeIn delay={0.2}>
        <Card>
          <CardHeader>
            <CardTitle className="text-base">
              {anomalies?.length ?? 0} anomalie(s)
            </CardTitle>
          </CardHeader>
          <CardContent>
            <DataTable columns={columns} data={anomalies ?? []} emptyMessage="Aucune anomalie" isLoading={isLoading} />
          </CardContent>
        </Card>
      </FadeIn>
    </div>
  )
}
