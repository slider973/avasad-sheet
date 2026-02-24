import { useState } from 'react'
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
import { Badge } from '@/components/ui/badge'
import { PageHeader } from '@/components/shared/page-header'
import { DataTable, type Column } from '@/components/shared/data-table'
import { FadeIn } from '@/components/motion'
import { useAbsences, useCreateAbsence, useDeleteAbsence } from '@/hooks/use-absences'
import { format, parseISO } from 'date-fns'
import { fr } from 'date-fns/locale'
import { Plus, Trash2, Plane, Thermometer, CalendarCheck, Ban, HelpCircle } from 'lucide-react'
import type { Absence, AbsenceType } from '@/types/database'
import type { LucideIcon } from 'lucide-react'

const absenceTypeConfig: Record<AbsenceType, { label: string; icon: LucideIcon; style: string }> = {
  vacation: { label: 'Vacances', icon: Plane, style: 'bg-blue-50 text-blue-700 border-blue-200' },
  sick: { label: 'Maladie', icon: Thermometer, style: 'bg-red-50 text-red-700 border-red-200' },
  holiday: { label: 'Jour ferie', icon: CalendarCheck, style: 'bg-emerald-50 text-emerald-700 border-emerald-200' },
  unpaid: { label: 'Conge sans solde', icon: Ban, style: 'bg-gray-50 text-gray-600 border-gray-200' },
  other: { label: 'Autre', icon: HelpCircle, style: 'bg-purple-50 text-purple-700 border-purple-200' },
}

export default function AbsencesPage() {
  const [showDialog, setShowDialog] = useState(false)
  const [form, setForm] = useState({ start_date: '', end_date: '', type: 'vacation' as AbsenceType, motif: '' })

  const { data: absences, isLoading } = useAbsences()
  const createMutation = useCreateAbsence()
  const deleteMutation = useDeleteAbsence()

  const handleCreate = async () => {
    await createMutation.mutateAsync({
      start_date: form.start_date,
      end_date: form.end_date,
      type: form.type,
      motif: form.motif || undefined,
    })
    setShowDialog(false)
    setForm({ start_date: '', end_date: '', type: 'vacation', motif: '' })
  }

  const columns: Column<Absence>[] = [
    {
      key: 'type',
      header: 'Type',
      cell: (row) => {
        const config = absenceTypeConfig[row.type]
        const Icon = config?.icon ?? HelpCircle
        return (
          <Badge variant="outline" className={`gap-1.5 ${config?.style ?? ''}`}>
            <Icon className="h-3 w-3" />
            {config?.label ?? row.type}
          </Badge>
        )
      },
    },
    {
      key: 'start_date',
      header: 'Debut',
      cell: (row) => format(parseISO(row.start_date), 'd MMM yyyy', { locale: fr }),
    },
    {
      key: 'end_date',
      header: 'Fin',
      cell: (row) => format(parseISO(row.end_date), 'd MMM yyyy', { locale: fr }),
    },
    {
      key: 'motif',
      header: 'Motif',
      cell: (row) => row.motif ?? <span className="text-muted-foreground/40">-</span>,
    },
    {
      key: 'actions',
      header: '',
      cell: (row) => (
        <Button
          variant="ghost"
          size="icon"
          className="h-8 w-8"
          onClick={() => deleteMutation.mutate(row.id)}
          disabled={deleteMutation.isPending}
        >
          <Trash2 className="h-3.5 w-3.5 text-destructive" />
        </Button>
      ),
      className: 'w-12',
    },
  ]

  return (
    <div className="space-y-6">
      <PageHeader
        title="Absences"
        description="Gerez vos conges et absences"
        actions={
          <Button onClick={() => setShowDialog(true)}>
            <Plus className="mr-2 h-4 w-4" />
            Nouvelle absence
          </Button>
        }
      />

      <FadeIn delay={0.1}>
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Mes absences</CardTitle>
          </CardHeader>
          <CardContent>
            <DataTable columns={columns} data={absences ?? []} emptyMessage="Aucune absence" isLoading={isLoading} />
          </CardContent>
        </Card>
      </FadeIn>

      <Dialog open={showDialog} onOpenChange={setShowDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Nouvelle absence</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div className="space-y-2">
              <Label className="text-xs font-medium text-muted-foreground">Type</Label>
              <Select value={form.type} onValueChange={(v) => setForm({ ...form, type: v as AbsenceType })}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {Object.entries(absenceTypeConfig).map(([key, config]) => {
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
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label className="text-xs font-medium text-muted-foreground">Date de debut</Label>
                <Input
                  type="date"
                  value={form.start_date}
                  onChange={(e) => setForm({ ...form, start_date: e.target.value })}
                />
              </div>
              <div className="space-y-2">
                <Label className="text-xs font-medium text-muted-foreground">Date de fin</Label>
                <Input
                  type="date"
                  value={form.end_date}
                  onChange={(e) => setForm({ ...form, end_date: e.target.value })}
                />
              </div>
            </div>
            <div className="space-y-2">
              <Label className="text-xs font-medium text-muted-foreground">Motif (optionnel)</Label>
              <Textarea
                value={form.motif}
                onChange={(e) => setForm({ ...form, motif: e.target.value })}
                placeholder="Raison de l'absence..."
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowDialog(false)}>
              Annuler
            </Button>
            <Button
              onClick={handleCreate}
              disabled={!form.start_date || !form.end_date || createMutation.isPending}
            >
              Creer
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}
