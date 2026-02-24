import {
  startOfMonth,
  endOfMonth,
  startOfWeek,
  endOfWeek,
  eachDayOfInterval,
  format,
  isSameMonth,
  isToday,
} from 'date-fns'
import { cn } from '@/lib/utils'

interface MiniCalendarProps {
  month: Date
  selectedDate: string | null
  onDayClick: (dateStr: string) => void
}

const WEEKDAY_HEADERS = ['L', 'M', 'M', 'J', 'V', 'S', 'D']

export function MiniCalendar({ month, selectedDate, onDayClick }: MiniCalendarProps) {
  const monthStart = startOfMonth(month)
  const monthEnd = endOfMonth(month)
  const calStart = startOfWeek(monthStart, { weekStartsOn: 1 })
  const calEnd = endOfWeek(monthEnd, { weekStartsOn: 1 })
  const days = eachDayOfInterval({ start: calStart, end: calEnd })

  return (
    <div>
      <div className="grid grid-cols-7 text-center text-xs text-muted-foreground">
        {WEEKDAY_HEADERS.map((d, i) => (
          <div key={i} className="py-2 font-medium">{d}</div>
        ))}
      </div>
      <div className="isolate mt-1 grid grid-cols-7 gap-px rounded-lg bg-border/50 text-sm ring-1 ring-border/50 overflow-hidden">
        {days.map((date, idx) => {
          const dateStr = format(date, 'yyyy-MM-dd')
          const isCurrentMonth = isSameMonth(date, month)
          const isTodayDate = isToday(date)
          const isSelected = selectedDate === dateStr

          return (
            <button
              key={dateStr}
              type="button"
              onClick={() => onDayClick(dateStr)}
              className={cn(
                'py-1.5 transition-colors focus:z-10',
                isCurrentMonth
                  ? 'bg-card hover:bg-muted/80'
                  : 'bg-muted/30 text-muted-foreground/50 hover:bg-muted/50',
                isTodayDate && !isSelected && 'font-semibold text-primary',
                isSelected && 'font-semibold',
                idx === 0 && 'rounded-tl-lg',
                idx === 6 && 'rounded-tr-lg',
                idx === days.length - 7 && 'rounded-bl-lg',
                idx === days.length - 1 && 'rounded-br-lg',
              )}
            >
              <time
                dateTime={dateStr}
                className={cn(
                  'mx-auto flex size-7 items-center justify-center rounded-full',
                  isSelected && !isTodayDate && 'bg-foreground text-background',
                  isSelected && isTodayDate && 'bg-primary text-primary-foreground',
                )}
              >
                {format(date, 'd')}
              </time>
            </button>
          )
        })}
      </div>
    </div>
  )
}
