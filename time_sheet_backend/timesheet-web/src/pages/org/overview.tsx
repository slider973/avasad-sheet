import { useOrgStats, useEffectiveOrgIds } from '@/hooks/use-org-data'
import { useAuthStore } from '@/stores/auth-store'
import { useNavigate } from 'react-router-dom'
import { Users, UserCheck, UserX, UserMinus, Building2, Briefcase, ShieldCheck, Crown } from 'lucide-react'
import { useMemo } from 'react'
import { PageHeader } from '@/components/shared/page-header'
import { StatsCard } from '@/components/shared/stats-card'
import { CardSkeletonGrid } from '@/components/shared/loading-skeleton'
import { StaggerContainer, StaggerItem, FadeIn } from '@/components/motion'

export default function OrgOverviewPage() {
  const { data: stats, isLoading } = useOrgStats()
  const { data: orgIds } = useEffectiveOrgIds()
  const { isOrgAdmin } = useAuthStore()
  const navigate = useNavigate()

  const childOrgCount = useMemo(() => {
    if (!orgIds) return 0
    return Math.max(0, orgIds.length - 1)
  }, [orgIds])

  return (
    <div className="space-y-8">
      <PageHeader
        title="Vue organisation"
        description="Tableau de bord de votre organisation"
      />

      {isLoading ? (
        <CardSkeletonGrid count={4} />
      ) : (
        <>
          {isOrgAdmin && childOrgCount > 0 && (
            <FadeIn>
              <StatsCard
                title="Sous-organisations"
                value={childOrgCount}
                description={`sous-organisation${childOrgCount > 1 ? 's' : ''} rattachee${childOrgCount > 1 ? 's' : ''}`}
                icon={Building2}
                iconClassName="from-primary to-[oklch(0.60_0.18_300)] text-white"
              />
            </FadeIn>
          )}

          <StaggerContainer className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <StaggerItem>
              <div className="cursor-pointer" onClick={() => navigate('/org/users')}>
                <StatsCard
                  title="Membres"
                  value={stats?.total ?? 0}
                  description="membres actifs"
                  icon={Users}
                  iconClassName="from-primary to-[oklch(0.60_0.18_300)] text-white"
                />
              </div>
            </StaggerItem>
            <StaggerItem>
              <StatsCard
                title="Presents"
                value={stats?.present ?? 0}
                description="aujourd'hui"
                icon={UserCheck}
                iconClassName="from-emerald-500 to-emerald-400 text-white"
              />
            </StaggerItem>
            <StaggerItem>
              <StatsCard
                title="Absents"
                value={stats?.absent ?? 0}
                description="aujourd'hui"
                icon={UserX}
                iconClassName="from-[oklch(0.65_0.18_25)] to-[oklch(0.70_0.15_35)] text-white"
              />
            </StaggerItem>
            <StaggerItem>
              <StatsCard
                title="Pas pointe"
                value={stats?.notClockedIn ?? 0}
                description="aujourd'hui"
                icon={UserMinus}
                iconClassName="from-amber-500 to-amber-400 text-white"
              />
            </StaggerItem>
          </StaggerContainer>

          <StaggerContainer className="grid gap-4 sm:grid-cols-3" delay={0.15}>
            <StaggerItem>
              <StatsCard
                title="Employes"
                value={stats?.byRole.employee ?? 0}
                description="dans l'organisation"
                icon={Briefcase}
                iconClassName="from-blue-500 to-blue-400 text-white"
              />
            </StaggerItem>
            <StaggerItem>
              <StatsCard
                title="Managers"
                value={stats?.byRole.manager ?? 0}
                description="dans l'organisation"
                icon={ShieldCheck}
                iconClassName="from-emerald-500 to-emerald-400 text-white"
              />
            </StaggerItem>
            <StaggerItem>
              <StatsCard
                title="Admins org"
                value={stats?.byRole.org_admin ?? 0}
                description="dans l'organisation"
                icon={Crown}
                iconClassName="from-[oklch(0.65_0.18_25)] to-[oklch(0.70_0.15_35)] text-white"
              />
            </StaggerItem>
          </StaggerContainer>
        </>
      )}
    </div>
  )
}
