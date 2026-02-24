import { type ReactNode } from 'react'
import { FadeIn } from '@/components/motion'
import {
  startOfMonth,
  endOfMonth,
  startOfWeek,
  endOfWeek,
  eachDayOfInterval,
  format,
  isSameMonth,
  isToday,
  isWeekend,
} from 'date-fns'
import { cn } from '@/lib/utils'

export interface CalendarDay {
  date: Date
  dateStr: string
  isCurrentMonth: boolean
  isToday: boolean
  isWeekend: boolean
}

interface CalendarGridProps {
  month: Date
  selectedDate: string | null
  onDayClick: (dateStr: string) => void
  renderDayContent?: (day: CalendarDay) => ReactNode
  renderDayDot?: (day: CalendarDay) => ReactNode
  isLoading?: boolean
}

const WEEKDAY_HEADERS = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']

function buildCalendarDays(month: Date): CalendarDay[] {
  const monthStart = startOfMonth(month)
  const monthEnd = endOfMonth(month)
  const calStart = startOfWeek(monthStart, { weekStartsOn: 1 })
  const calEnd = endOfWeek(monthEnd, { weekStartsOn: 1 })

  return eachDayOfInterval({ start: calStart, end: calEnd }).map((date) => ({
    date,
    dateStr: format(date, 'yyyy-MM-dd'),
    isCurrentMonth: isSameMonth(date, month),
    isToday: isToday(date),
    isWeekend: isWeekend(date),
  }))
}

export function CalendarGrid({
  month,
  selectedDate,
  onDayClick,
  renderDayContent,
  renderDayDot,
  isLoading,
}: CalendarGridProps) {
  if (isLoading) {
    return (
      <div className="grid grid-cols-7 gap-px">
        {WEEKDAY_HEADERS.map((d) => (
          <div key={d} className="py-2 text-center text-xs font-medium text-muted-foreground">
            {d}
          </div>
        ))}
        {Array.from({ length: 42 }).map((_, i) => (
          <div key={i} className="min-h-[2.5rem] lg:min-h-[6rem] animate-pulse rounded-md bg-muted/40" />
        ))}
      </div>
    )
  }

  const days = buildCalendarDays(month)

  return (
    <FadeIn key={format(month, 'yyyy-MM')}>
      <div className="grid grid-cols-7 gap-px">
        {/* Weekday headers */}
        {WEEKDAY_HEADERS.map((d) => (
          <div key={d} className="py-2 text-center text-xs font-medium text-muted-foreground">
            {d}
          </div>
        ))}

        {/* Day cells */}
        {days.map((day) => {
          const isSelected = selectedDate === day.dateStr

          return (
            <button
              key={day.dateStr}
              type="button"
              onClick={() => onDayClick(day.dateStr)}
              className={cn(
                'relative flex flex-col items-start rounded-md border border-transparent p-1 text-left transition-colors',
                'min-h-[2.5rem] lg:min-h-[6rem]',
                'hover:bg-muted/50 cursor-pointer',
                !day.isCurrentMonth && 'opacity-40',
                day.isWeekend && day.isCurrentMonth && 'bg-muted/30',
                isSelected && 'ring-2 ring-primary border-primary/20',
              )}
            >
              {/* Day number */}
              <span
                className={cn(
                  'inline-flex h-6 w-6 items-center justify-center rounded-full text-xs font-medium',
                  day.isToday && 'bg-primary text-primary-foreground',
                  !day.isToday && day.isWeekend && 'text-muted-foreground',
                )}
              >
                {format(day.date, 'd')}
              </span>

              {/* Desktop: full content */}
              {renderDayContent && (
                <div className="mt-1 hidden w-full lg:block">
                  {renderDayContent(day)}
                </div>
              )}

              {/* Mobile: dot indicator */}
              {renderDayDot && (
                <div className="mt-0.5 flex justify-center self-center lg:hidden">
                  {renderDayDot(day)}
                </div>
              )}
            </button>
          )
        })}
      </div>
    </FadeIn>
  )
}
