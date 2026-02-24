import { Fragment, useEffect, useRef } from 'react'
import { cn } from '@/lib/utils'
import type { TimesheetEntry } from '@/types/database'

interface DayTimelineProps {
  entry?: TimesheetEntry
  onBlockClick?: () => void
}

function timeToRow(time: string): number {
  const [h, m] = time.split(':').map(Number)
  return 2 + h * 12 + Math.floor(m / 5)
}

function timeSpan(start: string, end: string): number {
  const [sh, sm] = start.split(':').map(Number)
  const [eh, em] = end.split(':').map(Number)
  return Math.max(1, Math.round(((eh * 60 + em) - (sh * 60 + sm)) / 5))
}

const HOURS = Array.from({ length: 24 }, (_, i) => i)

export function DayTimeline({ entry, onBlockClick }: DayTimelineProps) {
  const containerRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    requestAnimationFrame(() => {
      if (containerRef.current) {
        containerRef.current.scrollTop = containerRef.current.scrollHeight * (7 / 24)
      }
    })
  }, [])

  const hasMorning = entry?.start_morning && entry?.end_morning
  const hasAfternoon = entry?.start_afternoon && entry?.end_afternoon
  const hasAbsenceOnly = entry?.absence_reason && !hasMorning && !hasAfternoon

  return (
    <div
      ref={containerRef}
      className="overflow-auto"
      style={{ maxHeight: 'calc(100vh - 20rem)' }}
    >
      <div className="flex w-full flex-auto">
        <div className="w-14 flex-none border-r border-border/30" />
        <div className="grid flex-auto grid-cols-1 grid-rows-1">
          {/* Hour grid lines */}
          <div
            style={{ gridTemplateRows: 'repeat(48, minmax(3.5rem, 1fr))' }}
            className="col-start-1 col-end-2 row-start-1 grid divide-y divide-border/30"
          >
            <div className="row-end-1 h-7" />
            {HOURS.map((hour) => (
              <Fragment key={hour}>
                <div>
                  <div className="-mt-2.5 -ml-14 w-14 pr-2 text-right text-xs/5 text-muted-foreground">
                    {hour}h
                  </div>
                </div>
                <div />
              </Fragment>
            ))}
          </div>

          {/* Time blocks */}
          <ol
            style={{ gridTemplateRows: '1.75rem repeat(288, minmax(0, 1fr)) auto' }}
            className="col-start-1 col-end-2 row-start-1 grid grid-cols-1"
          >
            {hasMorning && (
              <li
                style={{
                  gridRow: `${timeToRow(entry.start_morning!)} / span ${timeSpan(entry.start_morning!, entry.end_morning!)}`,
                }}
                className="relative mt-px flex"
              >
                <button
                  type="button"
                  onClick={onBlockClick}
                  className={cn(
                    'absolute inset-1 flex flex-col overflow-y-auto rounded-lg bg-emerald-50 p-2 text-xs/5 border border-emerald-200 text-left transition-colors',
                    onBlockClick && 'hover:bg-emerald-100 cursor-pointer',
                  )}
                >
                  <p className="order-1 font-semibold text-emerald-700">Matin</p>
                  <p className="text-emerald-600">
                    {entry.start_morning} - {entry.end_morning}
                  </p>
                </button>
              </li>
            )}
            {hasAfternoon && (
              <li
                style={{
                  gridRow: `${timeToRow(entry.start_afternoon!)} / span ${timeSpan(entry.start_afternoon!, entry.end_afternoon!)}`,
                }}
                className="relative mt-px flex"
              >
                <button
                  type="button"
                  onClick={onBlockClick}
                  className={cn(
                    'absolute inset-1 flex flex-col overflow-y-auto rounded-lg bg-blue-50 p-2 text-xs/5 border border-blue-200 text-left transition-colors',
                    onBlockClick && 'hover:bg-blue-100 cursor-pointer',
                  )}
                >
                  <p className="order-1 font-semibold text-blue-700">Apres-midi</p>
                  <p className="text-blue-600">
                    {entry.start_afternoon} - {entry.end_afternoon}
                  </p>
                </button>
              </li>
            )}
            {hasAbsenceOnly && (
              <li
                style={{ gridRow: `${timeToRow('08:00')} / span ${timeSpan('08:00', '17:00')}` }}
                className="relative mt-px flex"
              >
                <div className="absolute inset-1 flex flex-col overflow-y-auto rounded-lg bg-pink-50 p-2 text-xs/5 border border-pink-200">
                  <p className="order-1 font-semibold text-pink-700 capitalize">{entry.absence_reason}</p>
                  <p className="text-pink-600">Journee complete</p>
                </div>
              </li>
            )}
          </ol>
        </div>
      </div>
    </div>
  )
}
