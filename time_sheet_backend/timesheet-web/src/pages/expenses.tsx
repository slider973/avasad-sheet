import { useState, useRef } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog'
import { PageHeader } from '@/components/shared/page-header'
import { MonthNavigator } from '@/components/shared/date-range-picker'
import { StatusBadge } from '@/components/shared/status-badge'
import { DataTable, type Column } from '@/components/shared/data-table'
import { StaggerContainer, StaggerItem, AnimatedNumber } from '@/components/motion'
import { useExpenses, useCreateExpense, useUploadReceipt } from '@/hooks/use-expenses'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth-store'
import { format, parseISO } from 'date-fns'
import { fr } from 'date-fns/locale'
import {
  Plus,
  Upload,
  Car,
  UtensilsCrossed,
  Hotel,
  Gauge,
  Building,
  Package,
  Receipt,
} from 'lucide-react'
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

export default function ExpensesPage() {
  const [currentMonth, setCurrentMonth] = useState(new Date())
  const [showDialog, setShowDialog] = useState(false)
  const [form, setForm] = useState({
    date: '',
    category: 'other' as ExpenseCategory,
    description: '',
    amount: '',
    departure_location: '',
    arrival_location: '',
    distance_km: '',
    mileage_rate: '0.70',
  })
  const [file, setFile] = useState<File | null>(null)
  const fileRef = useRef<HTMLInputElement>(null)

  const { session } = useAuthStore()
  const { data: expenses, isLoading } = useExpenses(currentMonth)
  const createMutation = useCreateExpense()
  const uploadMutation = useUploadReceipt()

  const total = expenses?.reduce((sum, e) => sum + e.amount, 0) ?? 0

  const handleCreate = async () => {
    if (!session) return
    const isMileage = form.category === 'mileage'

    const expense = await createMutation.mutateAsync({
      date: form.date,
      category: form.category,
      description: form.description || undefined,
      amount: isMileage
        ? Number(form.distance_km) * Number(form.mileage_rate)
        : Number(form.amount),
      distance_km: isMileage ? Number(form.distance_km) : undefined,
      mileage_rate: isMileage ? Number(form.mileage_rate) : undefined,
      departure_location: isMileage ? form.departure_location : undefined,
      arrival_location: isMileage ? form.arrival_location : undefined,
    })

    if (file && expense.id) {
      const url = await uploadMutation.mutateAsync({
        userId: session.user.id,
        expenseId: expense.id,
        file,
      })
      await supabase.from('expenses').update({ attachment_url: url }).eq('id', expense.id)
    }

    setShowDialog(false)
    setForm({
      date: '',
      category: 'other',
      description: '',
      amount: '',
      departure_location: '',
      arrival_location: '',
      distance_km: '',
      mileage_rate: '0.70',
    })
    setFile(null)
  }

  const columns: Column<Expense>[] = [
    {
      key: 'date',
      header: 'Date',
      cell: (row) => format(parseISO(row.date), 'd MMM yyyy', { locale: fr }),
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
      key: 'amount',
      header: 'Montant',
      cell: (row) => <span className="font-semibold tabular-nums">{row.amount.toFixed(2)} {row.currency}</span>,
      className: 'text-right',
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
  ]

  return (
    <div className="space-y-6">
      <PageHeader
        title="Depenses"
        description="Gerez vos notes de frais"
        actions={
          <div className="flex items-center gap-4">
            <MonthNavigator date={currentMonth} onChange={setCurrentMonth} />
            <Button onClick={() => setShowDialog(true)}>
              <Plus className="mr-2 h-4 w-4" />
              Nouvelle depense
            </Button>
          </div>
        }
      />

      <StaggerContainer className="space-y-6">
        {/* Total card */}
        <StaggerItem>
          <div className="rounded-xl bg-gradient-to-r from-primary to-[oklch(0.60_0.18_300)] p-6 text-white">
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-white/20">
                <Receipt className="h-5 w-5" />
              </div>
              <div>
                <p className="text-sm font-medium text-white/80">Total {format(currentMonth, 'MMMM yyyy', { locale: fr })}</p>
                <p className="text-2xl font-bold">
                  <AnimatedNumber value={total} decimals={2} suffix=" CHF" />
                </p>
              </div>
              <p className="ml-auto text-sm text-white/70">{expenses?.length ?? 0} depense(s)</p>
            </div>
          </div>
        </StaggerItem>

        <StaggerItem>
          <Card>
            <CardHeader>
              <CardTitle className="text-base">
                {format(currentMonth, 'MMMM yyyy', { locale: fr })}
              </CardTitle>
            </CardHeader>
            <CardContent>
              <DataTable columns={columns} data={expenses ?? []} emptyMessage="Aucune depense" isLoading={isLoading} />
            </CardContent>
          </Card>
        </StaggerItem>
      </StaggerContainer>

      <Dialog open={showDialog} onOpenChange={setShowDialog}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>Nouvelle depense</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label className="text-xs font-medium text-muted-foreground">Date</Label>
                <Input
                  type="date"
                  value={form.date}
                  onChange={(e) => setForm({ ...form, date: e.target.value })}
                />
              </div>
              <div className="space-y-2">
                <Label className="text-xs font-medium text-muted-foreground">Categorie</Label>
                <Select
                  value={form.category}
                  onValueChange={(v) => setForm({ ...form, category: v as ExpenseCategory })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {Object.entries(categoryConfig).map(([key, config]) => {
                      const Icon = config.icon
                      return (
                        <SelectItem key={key} value={key}>
                          <div className="flex items-center gap-2">
                            <Icon className="h-3.5 w-3.5" />
                            {config.label}
                          </div>
                        </SelectItem>
                      )
                    })}
                  </SelectContent>
                </Select>
              </div>
            </div>

            {form.category === 'mileage' ? (
              <>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label className="text-xs font-medium text-muted-foreground">Depart</Label>
                    <Input
                      value={form.departure_location}
                      onChange={(e) => setForm({ ...form, departure_location: e.target.value })}
                      placeholder="Lieu de depart"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label className="text-xs font-medium text-muted-foreground">Arrivee</Label>
                    <Input
                      value={form.arrival_location}
                      onChange={(e) => setForm({ ...form, arrival_location: e.target.value })}
                      placeholder="Lieu d'arrivee"
                    />
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label className="text-xs font-medium text-muted-foreground">Distance (km)</Label>
                    <Input
                      type="number"
                      value={form.distance_km}
                      onChange={(e) => setForm({ ...form, distance_km: e.target.value })}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label className="text-xs font-medium text-muted-foreground">Taux (CHF/km)</Label>
                    <Input
                      type="number"
                      step="0.01"
                      value={form.mileage_rate}
                      onChange={(e) => setForm({ ...form, mileage_rate: e.target.value })}
                    />
                  </div>
                </div>
                {form.distance_km && (
                  <p className="text-sm font-medium text-primary">
                    Montant: {(Number(form.distance_km) * Number(form.mileage_rate)).toFixed(2)} CHF
                  </p>
                )}
              </>
            ) : (
              <div className="space-y-2">
                <Label className="text-xs font-medium text-muted-foreground">Montant (CHF)</Label>
                <Input
                  type="number"
                  step="0.01"
                  value={form.amount}
                  onChange={(e) => setForm({ ...form, amount: e.target.value })}
                />
              </div>
            )}

            <div className="space-y-2">
              <Label className="text-xs font-medium text-muted-foreground">Description (optionnel)</Label>
              <Textarea
                value={form.description}
                onChange={(e) => setForm({ ...form, description: e.target.value })}
              />
            </div>

            <div className="space-y-2">
              <Label className="text-xs font-medium text-muted-foreground">Justificatif (optionnel)</Label>
              <input
                ref={fileRef}
                type="file"
                accept="image/*"
                className="hidden"
                onChange={(e) => setFile(e.target.files?.[0] ?? null)}
              />
              <div
                onClick={() => fileRef.current?.click()}
                className="flex cursor-pointer items-center justify-center gap-2 rounded-lg border-2 border-dashed border-muted-foreground/20 p-6 text-sm text-muted-foreground transition-colors hover:border-primary/30 hover:bg-primary/5"
              >
                <Upload className="h-4 w-4" />
                {file ? file.name : 'Cliquez ou glissez un justificatif'}
              </div>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowDialog(false)}>
              Annuler
            </Button>
            <Button onClick={handleCreate} disabled={!form.date || createMutation.isPending}>
              Creer
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}
