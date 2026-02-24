import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { PageHeader } from '@/components/shared/page-header'
import { StatsCard } from '@/components/shared/stats-card'
import { EmptyState } from '@/components/shared/empty-state'
import { StaggerContainer, StaggerItem, FadeIn } from '@/components/motion'
import { useTeamMembers, useTeamStats } from '@/hooks/use-team'
import { useTeamPendingValidations } from '@/hooks/use-validations'
import { useTeamPendingExpenses } from '@/hooks/use-expenses'
import { useTeamAnomalies } from '@/hooks/use-anomalies'
import { Users, CheckSquare, Receipt, ShieldAlert, UserCheck, UserX, UserMinus } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import type { TeamMember } from '@/hooks/use-team'
import { PieChart, Pie, Cell, ResponsiveContainer } from 'recharts'

function MemberStatus({ member }: { member: TeamMember }) {
  if (member.todayEntry?.absence_reason) {
    return <Badge variant="outline" className="bg-orange-50 text-orange-700 border-orange-200">Absent</Badge>
  }
  if (member.todayEntry && !member.todayEntry.absence_reason) {
    return <Badge variant="outline" className="bg-emerald-50 text-emerald-700 border-emerald-200">Present</Badge>
  }
  return <Badge variant="outline" className="bg-gray-50 text-gray-500 border-gray-200">Pas pointe</Badge>
}

const DONUT_COLORS = ['oklch(0.60 0.16 160)', 'oklch(0.65 0.15 40)', 'oklch(0.75 0.02 270)']

export default function ManagerOverviewPage() {
  const { data: members, isLoading } = useTeamMembers()
  const stats = useTeamStats()
  const { data: pendingValidations } = useTeamPendingValidations()
  const { data: pendingExpenses } = useTeamPendingExpenses()
  const { data: teamAnomalies } = useTeamAnomalies()
  const navigate = useNavigate()

  const donutData = [
    { name: 'Presents', value: stats.present },
    { name: 'Absents', value: stats.absent },
    { name: 'Pas pointe', value: stats.notClockedIn },
  ].filter((d) => d.value > 0)

  return (
    <div className="space-y-8">
      <PageHeader title="Vue equipe" description={`${stats.total} employes dans votre equipe`} />

      <StaggerContainer className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StaggerItem>
          <StatsCard
            title="Equipe"
            value={stats.total}
            description="employes"
            icon={Users}
            iconClassName="from-primary to-[oklch(0.60_0.18_300)] text-white"
          />
        </StaggerItem>
        <StaggerItem>
          <div className="cursor-pointer" onClick={() => navigate('/manager/approvals')}>
            <StatsCard
              title="Validations en attente"
              value={pendingValidations?.length ?? 0}
              description="a traiter"
              icon={CheckSquare}
              iconClassName="from-amber-500 to-amber-400 text-white"
            />
          </div>
        </StaggerItem>
        <StaggerItem>
          <div className="cursor-pointer" onClick={() => navigate('/manager/approvals')}>
            <StatsCard
              title="Depenses en attente"
              value={pendingExpenses?.length ?? 0}
              description="a traiter"
              icon={Receipt}
              iconClassName="from-blue-500 to-blue-400 text-white"
            />
          </div>
        </StaggerItem>
        <StaggerItem>
          <div className="cursor-pointer" onClick={() => navigate('/manager/anomalies')}>
            <StatsCard
              title="Anomalies equipe"
              value={teamAnomalies?.length ?? 0}
              description="non resolues"
              icon={ShieldAlert}
              iconClassName="from-[oklch(0.65_0.18_25)] to-[oklch(0.70_0.15_35)] text-white"
            />
          </div>
        </StaggerItem>
      </StaggerContainer>

      <div className="grid gap-6 lg:grid-cols-3">
        {/* Donut chart */}
        <FadeIn delay={0.2}>
          <Card className="lg:col-span-1">
            <CardHeader>
              <CardTitle className="text-base">Statut equipe</CardTitle>
            </CardHeader>
            <CardContent>
              {donutData.length > 0 ? (
                <div className="flex flex-col items-center gap-4">
                  <ResponsiveContainer width="100%" height={180}>
                    <PieChart>
                      <Pie
                        data={donutData}
                        cx="50%"
                        cy="50%"
                        innerRadius={50}
                        outerRadius={75}
                        dataKey="value"
                        stroke="none"
                      >
                        {donutData.map((_, i) => (
                          <Cell key={i} fill={DONUT_COLORS[i % DONUT_COLORS.length]} />
                        ))}
                      </Pie>
                    </PieChart>
                  </ResponsiveContainer>
                  <div className="flex gap-4 text-sm">
                    <div className="flex items-center gap-1.5">
                      <UserCheck className="h-3.5 w-3.5 text-emerald-500" />
                      <span>{stats.present} presents</span>
                    </div>
                    <div className="flex items-center gap-1.5">
                      <UserX className="h-3.5 w-3.5 text-orange-500" />
                      <span>{stats.absent} absents</span>
                    </div>
                    <div className="flex items-center gap-1.5">
                      <UserMinus className="h-3.5 w-3.5 text-gray-400" />
                      <span>{stats.notClockedIn} pas pointe</span>
                    </div>
                  </div>
                </div>
              ) : (
                <p className="py-8 text-center text-sm text-muted-foreground">Aucune donnee</p>
              )}
            </CardContent>
          </Card>
        </FadeIn>

        {/* Employee list */}
        <FadeIn delay={0.3}>
          <Card className="lg:col-span-2">
            <CardHeader>
              <CardTitle className="text-base">Employes</CardTitle>
            </CardHeader>
            <CardContent>
              {isLoading ? (
                <div className="space-y-3">
                  {Array.from({ length: 3 }).map((_, i) => (
                    <div key={i} className="h-14 animate-pulse rounded-lg bg-muted" />
                  ))}
                </div>
              ) : (!members || members.length === 0) ? (
                <EmptyState icon={Users} title="Aucun employe" />
              ) : (
                <div className="space-y-1.5">
                  {members.map((member) => (
                    <div
                      key={member.id}
                      className="flex items-center justify-between rounded-lg p-3 transition-colors hover:bg-muted/40 cursor-pointer"
                      onClick={() => navigate(`/manager/timesheet/${member.id}`)}
                    >
                      <div className="flex items-center gap-3">
                        <div className="flex h-9 w-9 items-center justify-center rounded-full bg-primary/10 text-xs font-semibold text-primary">
                          {(member.first_name?.[0] ?? '') + (member.last_name?.[0] ?? '')}
                        </div>
                        <div>
                          <p className="text-sm font-medium">
                            {member.first_name} {member.last_name}
                          </p>
                          <p className="text-xs text-muted-foreground">{member.email}</p>
                        </div>
                      </div>
                      <MemberStatus member={member} />
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </FadeIn>
      </div>
    </div>
  )
}
