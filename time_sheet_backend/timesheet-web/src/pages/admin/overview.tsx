import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { PageHeader } from '@/components/shared/page-header'
import { StatsCard } from '@/components/shared/stats-card'
import { EmptyState } from '@/components/shared/empty-state'
import { CardSkeletonGrid, TableSkeleton } from '@/components/shared/loading-skeleton'
import { StaggerContainer, StaggerItem, FadeIn } from '@/components/motion'
import { useGlobalStats } from '@/hooks/use-org-data'
import { useNavigate } from 'react-router-dom'
import { Building2, Users, UserCheck, ShieldCheck } from 'lucide-react'
import { Badge } from '@/components/ui/badge'

export default function AdminOverviewPage() {
  const { data: stats, isLoading } = useGlobalStats()
  const navigate = useNavigate()

  return (
    <div className="space-y-8">
      <PageHeader
        title="Administration globale"
        description="Vue d'ensemble de toutes les organisations et utilisateurs"
      />

      {isLoading ? (
        <CardSkeletonGrid count={4} />
      ) : (
        <StaggerContainer className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <StaggerItem>
            <div className="cursor-pointer" onClick={() => navigate('/admin/organizations')}>
              <StatsCard
                title="Organisations"
                value={stats?.totalOrganizations ?? 0}
                description={`${stats?.activeOrganizations ?? 0} actives`}
                icon={Building2}
                iconClassName="from-primary to-[oklch(0.60_0.18_300)] text-white"
              />
            </div>
          </StaggerItem>
          <StaggerItem>
            <div className="cursor-pointer" onClick={() => navigate('/admin/users')}>
              <StatsCard
                title="Utilisateurs"
                value={stats?.totalUsers ?? 0}
                description={`${stats?.activeUsers ?? 0} actifs`}
                icon={Users}
                iconClassName="from-blue-500 to-blue-400 text-white"
              />
            </div>
          </StaggerItem>
          <StaggerItem>
            <StatsCard
              title="Employes"
              value={stats?.byRole.employee ?? 0}
              description="employes actifs"
              icon={UserCheck}
              iconClassName="from-emerald-500 to-emerald-400 text-white"
            />
          </StaggerItem>
          <StaggerItem>
            <StatsCard
              title="Managers"
              value={stats?.byRole.manager ?? 0}
              description="managers / admins"
              icon={ShieldCheck}
              iconClassName="from-[oklch(0.65_0.18_25)] to-[oklch(0.70_0.15_35)] text-white"
            />
          </StaggerItem>
        </StaggerContainer>
      )}

      <FadeIn delay={0.2}>
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-base">
              <Building2 className="h-4 w-4 text-primary" />
              Organisations
            </CardTitle>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <TableSkeleton rows={3} cols={2} />
            ) : (!stats?.organizations || stats.organizations.length === 0) ? (
              <EmptyState
                icon={Building2}
                title="Aucune organisation"
                description="Commencez par creer une organisation"
              />
            ) : (
              <div className="space-y-1.5">
                {stats.organizations.map((org) => (
                  <div
                    key={org.id}
                    className="flex items-center justify-between rounded-lg p-3 transition-colors hover:bg-muted/40 cursor-pointer"
                    onClick={() => navigate(`/admin/organizations/${org.id}`)}
                  >
                    <div className="flex items-center gap-3">
                      <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-primary/10 to-primary/5">
                        <Building2 className="h-4 w-4 text-primary" />
                      </div>
                      <span className="text-sm font-medium">{org.name}</span>
                    </div>
                    <Badge variant={org.is_active ? 'default' : 'secondary'}>
                      {org.is_active ? 'Active' : 'Inactive'}
                    </Badge>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </FadeIn>
    </div>
  )
}
