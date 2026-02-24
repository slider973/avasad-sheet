import { useState, useMemo } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { useOrgExpenses, useEffectiveOrgIds } from '@/hooks/use-org-data'
import { useOrganizations } from '@/hooks/use-organizations'
import { useAuthStore } from '@/stores/auth-store'
import {
  Receipt,
  Car,
  UtensilsCrossed,
  Hotel,
  Gauge,
  Building,
  Package,
} from 'lucide-react'
import { format, parseISO } from 'date-fns'
import { fr } from 'date-fns/locale'
import { PageHeader } from '@/components/shared/page-header'
import { MonthNavigator } from '@/components/shared/date-range-picker'
import { StatusBadge } from '@/components/shared/status-badge'
import { DataTable, type Column } from '@/components/shared/data-table'
import { FadeIn, StaggerContainer, StaggerItem, AnimatedNumber } from '@/components/motion'
import type { Expense, ExpenseCategory } from '@/types/database'
import type { LucideIcon } from 'lucide-react'

const categoryConfig: Record<ExpenseCategory, { label: string; icon: LucideIcon }> = {
  transport: { label: 'Transport', icon: Car },
  meal: { label: 'Repas', icon: UtensilsCrossed },
  accommodation: { label: 'Hebergement', icon: Hotel },
  mileage: { label: 'Kilometrage', icon: Gauge },
  office: { label: 'Bureau', icon: Building },
  other: { label: 'Autre', icon: Package },
}

export default function OrgExpensesPage() {
  const [date, setDate] = useState(new Date())
  const [selectedUser, setSelectedUser] = useState<string>('all')
  const [filterOrgId, setFilterOrgId] = useState<string>('all')
  const { data, isLoading } = useOrgExpenses(date)
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

  const filteredExpenses = useMemo(() => {
    if (!data?.expenses) return []
    let expenses = data.expenses
    if (filterOrgId !== 'all') {
      const memberIds = new Set(filteredMembers.map((m) => m.id))
      expenses = expenses.filter((e) => memberIds.has(e.user_id))
    }
    if (selectedUser !== 'all') {
      expenses = expenses.filter((e) => e.user_id === selectedUser)
    }
    return expenses
  }, [data, selectedUser, filterOrgId, filteredMembers])

  const memberMap = useMemo(() => {
    const map = new Map<string, string>()
    data?.members?.forEach((m) => map.set(m.id, `${m.first_name} ${m.last_name}`))
    return map
  }, [data?.members])

  const totalAmount = useMemo(() => {
    return filteredExpenses.reduce((sum, e) => sum + e.amount, 0)
  }, [filteredExpenses])

  const columns: Column<Expense>[] = [
    {
      key: 'date',
      header: 'Date',
      cell: (row) => format(parseISO(row.date), 'd MMM yyyy', { locale: fr }),
    },
    {
      key: 'employee',
      header: 'Employe',
      cell: (row) => <span className="truncate">{memberMap.get(row.user_id) ?? '-'}</span>,
    },
    {
      key: 'category',
      header: 'Categorie',
      cell: (row) => {
        const config = categoryConfig[row.category]
        const Icon = config?.icon ?? Package
        return (
          <div className="flex items-center gap-2">
            <Icon className="h-4 w-4 text-muted-foreground" />
            <span>{config?.label ?? row.category}</span>
          </div>
        )
      },
    },
    {
      key: 'description',
      header: 'Description',
      cell: (row) => row.description ?? <span className="text-muted-foreground/40">-</span>,
    },
    {
      key: 'status',
      header: 'Statut',
      cell: (row) => (
        <StatusBadge
          status={row.is_approved === true ? 'approved' : row.is_approved === false ? 'rejected' : 'pending'}
        />
      ),
    },
    {
      key: 'amount',
      header: 'Montant',
      cell: (row) => <span className="font-semibold tabular-nums">{row.amount.toFixed(2)} {row.currency}</span>,
      className: 'text-right',
    },
  ]

  return (
    <div className="space-y-6">
      <PageHeader
        title="Depenses organisation"
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
        {/* Total gradient card */}
        <StaggerItem>
          <div className="rounded-xl bg-gradient-to-r from-primary to-[oklch(0.60_0.18_300)] p-6 text-white">
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-white/20">
                <Receipt className="h-5 w-5" />
              </div>
              <div>
                <p className="text-sm font-medium text-white/80">Total {format(date, 'MMMM yyyy', { locale: fr })}</p>
                <p className="text-2xl font-bold">
                  <AnimatedNumber value={totalAmount} decimals={2} suffix=" CHF" />
                </p>
              </div>
              <p className="ml-auto text-sm text-white/70">{filteredExpenses.length} depense(s)</p>
            </div>
          </div>
        </StaggerItem>

        <StaggerItem>
          <Card>
            <CardHeader>
              <CardTitle className="text-base">
                {format(date, 'MMMM yyyy', { locale: fr })}
              </CardTitle>
            </CardHeader>
            <CardContent>
              <DataTable columns={columns} data={filteredExpenses} emptyMessage="Aucune depense" isLoading={isLoading} />
            </CardContent>
          </Card>
        </StaggerItem>
      </StaggerContainer>
    </div>
  )
}
