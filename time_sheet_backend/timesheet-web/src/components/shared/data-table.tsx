import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { TableSkeleton } from './loading-skeleton'
import { EmptyState } from './empty-state'
import { Inbox } from 'lucide-react'

export interface Column<T> {
  key: string
  header: string
  cell: (row: T) => React.ReactNode
  className?: string
}

interface DataTableProps<T> {
  columns: Column<T>[]
  data: T[]
  emptyMessage?: string
  isLoading?: boolean
}

export function DataTable<T>({ columns, data, emptyMessage = 'Aucune donnee', isLoading }: DataTableProps<T>) {
  if (isLoading) {
    return <TableSkeleton rows={6} cols={columns.length} />
  }

  if (data.length === 0) {
    return <EmptyState icon={Inbox} title={emptyMessage} />
  }

  return (
    <div className="rounded-lg border">
      <Table>
        <TableHeader>
          <TableRow className="bg-muted/30 hover:bg-muted/30">
            {columns.map((col) => (
              <TableHead key={col.key} className={col.className}>
                {col.header}
              </TableHead>
            ))}
          </TableRow>
        </TableHeader>
        <TableBody>
          {data.map((row, i) => (
            <TableRow
              key={i}
              className="transition-colors duration-150 hover:bg-muted/40"
            >
              {columns.map((col) => (
                <TableCell key={col.key} className={col.className}>
                  {col.cell(row)}
                </TableCell>
              ))}
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  )
}
