import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { PageHeader } from '@/components/shared/page-header'
import { StatusBadge } from '@/components/shared/status-badge'
import { EmptyState } from '@/components/shared/empty-state'
import { StaggerContainer, StaggerItem } from '@/components/motion'
import { useTeamAnomalies, useResolveAnomaly } from '@/hooks/use-anomalies'
import { format, parseISO } from 'date-fns'
import { fr } from 'date-fns/locale'
import { AlertTriangle, CheckCircle2, ShieldAlert } from 'lucide-react'

type AnomalyRow = Record<string, unknown>

export default function TeamAnomaliesPage() {
  const { data: anomalies, isLoading } = useTeamAnomalies()
  const resolveMutation = useResolveAnomaly()

  const grouped: Record<string, AnomalyRow[]> = {}
  if (anomalies) {
    for (const a of anomalies as AnomalyRow[]) {
      const name = `${(a.profiles as Record<string, string>)?.first_name ?? ''} ${(a.profiles as Record<string, string>)?.last_name ?? ''}`
      if (!grouped[name]) grouped[name] = []
      grouped[name].push(a)
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Anomalies equipe"
        description={`${anomalies?.length ?? 0} anomalie(s) non resolue(s)`}
      />

      {isLoading ? (
        <div className="space-y-3">
          {Array.from({ length: 3 }).map((_, i) => (
            <div key={i} className="h-24 animate-pulse rounded-xl bg-muted" />
          ))}
        </div>
      ) : Object.keys(grouped).length === 0 ? (
        <EmptyState
          icon={ShieldAlert}
          title="Aucune anomalie non resolue"
          description="Tout est en ordre dans votre equipe"
        />
      ) : (
        <StaggerContainer className="space-y-4">
          {Object.entries(grouped).map(([name, items]) => (
            <StaggerItem key={name}>
              <Card>
                <CardHeader>
                  <div className="flex items-center gap-3">
                    <div className="flex h-9 w-9 items-center justify-center rounded-full bg-primary/10 text-xs font-semibold text-primary">
                      {name.split(' ').map((n) => n[0]).join('')}
                    </div>
                    <div>
                      <CardTitle className="text-base">{name}</CardTitle>
                      <p className="text-xs text-muted-foreground">{items.length} anomalie(s)</p>
                    </div>
                  </div>
                </CardHeader>
                <CardContent className="space-y-2">
                  {items.map((a: AnomalyRow) => (
                    <div key={a.id as string} className="flex items-center justify-between rounded-lg border p-3 transition-colors hover:bg-muted/30">
                      <div className="flex items-center gap-3">
                        <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-orange-50">
                          <AlertTriangle className="h-4 w-4 text-orange-500" />
                        </div>
                        <div>
                          <p className="text-sm font-medium">{a.type as string}</p>
                          <p className="text-xs text-muted-foreground">
                            {format(parseISO(a.detected_date as string), 'd MMM yyyy', { locale: fr })} -{' '}
                            {a.description as string}
                          </p>
                        </div>
                      </div>
                      <div className="flex items-center gap-2">
                        <StatusBadge status="unresolved" />
                        <Button
                          variant="outline"
                          size="sm"
                          className="gap-1.5"
                          onClick={() => resolveMutation.mutate(a.id as string)}
                          disabled={resolveMutation.isPending}
                        >
                          <CheckCircle2 className="h-3.5 w-3.5" />
                          Resoudre
                        </Button>
                      </div>
                    </div>
                  ))}
                </CardContent>
              </Card>
            </StaggerItem>
          ))}
        </StaggerContainer>
      )}
    </div>
  )
}
