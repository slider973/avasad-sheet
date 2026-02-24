import { Button } from '@/components/ui/button'
import { ChevronLeft, ChevronRight } from 'lucide-react'
import { format, addMonths, subMonths } from 'date-fns'
import { fr } from 'date-fns/locale'

interface MonthNavigatorProps {
  date: Date
  onChange: (date: Date) => void
}

export function MonthNavigator({ date, onChange }: MonthNavigatorProps) {
  return (
    <div className="flex items-center gap-1">
      <Button
        variant="ghost"
        size="icon"
        className="h-8 w-8"
        onClick={() => onChange(subMonths(date, 1))}
      >
        <ChevronLeft className="h-4 w-4" />
      </Button>
      <span className="min-w-[160px] rounded-lg bg-muted/50 px-4 py-1.5 text-center text-sm font-semibold capitalize">
        {format(date, 'MMMM yyyy', { locale: fr })}
      </span>
      <Button
        variant="ghost"
        size="icon"
        className="h-8 w-8"
        onClick={() => onChange(addMonths(date, 1))}
      >
        <ChevronRight className="h-4 w-4" />
      </Button>
    </div>
  )
}
