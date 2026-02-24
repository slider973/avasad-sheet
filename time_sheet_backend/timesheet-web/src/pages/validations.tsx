import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { PageHeader } from '@/components/shared/page-header'
import { StatusBadge } from '@/components/shared/status-badge'
import { DataTable, type Column } from '@/components/shared/data-table'
import { FadeIn } from '@/components/motion'
import { useValidations } from '@/hooks/use-validations'
import { supabase } from '@/lib/supabase'
import { format, parseISO } from 'date-fns'
import { fr } from 'date-fns/locale'
import { Download, FileText } from 'lucide-react'
import type { ValidationRequest, ValidationStatus } from '@/types/database'

const timelineSteps: Record<ValidationStatus, number> = {
  pending: 1,
  approved: 2,
  rejected: 2,
  expired: 2,
}

function ValidationTimeline({ status }: { status: ValidationStatus }) {
  const step = timelineSteps[status] ?? 0
  return (
    <div className="flex items-center gap-1">
      <div className="flex h-5 w-5 items-center justify-center rounded-full bg-primary text-[10px] font-bold text-white">1</div>
      <div className={`h-0.5 w-6 rounded ${step >= 2 ? (status === 'approved' ? 'bg-emerald-400' : status === 'rejected' ? 'bg-red-400' : 'bg-gray-300') : 'bg-gray-200'}`} />
      <div className={`flex h-5 w-5 items-center justify-center rounded-full text-[10px] font-bold ${step >= 2 ? (status === 'approved' ? 'bg-emerald-500 text-white' : status === 'rejected' ? 'bg-red-500 text-white' : 'bg-gray-400 text-white') : 'bg-gray-200 text-gray-500'}`}>2</div>
    </div>
  )
}

export default function ValidationsPage() {
  const { data: validations, isLoading } = useValidations()

  const downloadPdf = async (url: string) => {
    const { data } = await supabase.storage.from('pdfs').createSignedUrl(url, 3600)
    if (data?.signedUrl) {
      window.open(data.signedUrl, '_blank')
    }
  }

  const columns: Column<ValidationRequest>[] = [
    {
      key: 'timeline',
      header: '',
      cell: (row) => <ValidationTimeline status={row.status as ValidationStatus} />,
      className: 'w-24',
    },
    {
      key: 'period',
      header: 'Periode',
      cell: (row) => (
        <span className="font-medium">
          {format(parseISO(row.period_start), 'd MMM', { locale: fr })} - {format(parseISO(row.period_end), 'd MMM yyyy', { locale: fr })}
        </span>
      ),
    },
    {
      key: 'status',
      header: 'Statut',
      cell: (row) => <StatusBadge status={row.status as ValidationStatus} />,
    },
    {
      key: 'comment',
      header: 'Commentaire',
      cell: (row) => row.manager_comment ?? <span className="text-muted-foreground/40">-</span>,
    },
    {
      key: 'validated_at',
      header: 'Date validation',
      cell: (row) =>
        row.validated_at
          ? format(parseISO(row.validated_at), 'd MMM yyyy', { locale: fr })
          : <span className="text-muted-foreground/40">-</span>,
    },
    {
      key: 'actions',
      header: '',
      cell: (row) =>
        row.pdf_url ? (
          <Button
            variant="ghost"
            size="sm"
            className="gap-1.5 text-primary hover:text-primary"
            onClick={() => downloadPdf(row.pdf_url!)}
          >
            <Download className="h-3.5 w-3.5" />
            PDF
          </Button>
        ) : null,
      className: 'w-20',
    },
  ]

  return (
    <div className="space-y-6">
      <PageHeader
        title="Validations"
        description="Suivez vos demandes de validation"
        actions={
          <div className="flex items-center gap-2 text-sm text-muted-foreground">
            <FileText className="h-4 w-4" />
            {validations?.length ?? 0} demande(s)
          </div>
        }
      />

      <FadeIn delay={0.1}>
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Mes demandes de validation</CardTitle>
          </CardHeader>
          <CardContent>
            <DataTable columns={columns} data={validations ?? []} emptyMessage="Aucune validation" isLoading={isLoading} />
          </CardContent>
        </Card>
      </FadeIn>
    </div>
  )
}
