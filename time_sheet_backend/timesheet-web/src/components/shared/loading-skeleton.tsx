import { cn } from '@/lib/utils'

function Bone({ className }: { className?: string }) {
  return (
    <div className={cn('animate-pulse rounded-lg bg-muted', className)} />
  )
}

export function TableSkeleton({ rows = 5, cols = 4 }: { rows?: number; cols?: number }) {
  return (
    <div className="space-y-3">
      <div className="flex gap-4 px-2">
        {Array.from({ length: cols }).map((_, i) => (
          <Bone key={i} className="h-4 flex-1" />
        ))}
      </div>
      {Array.from({ length: rows }).map((_, i) => (
        <div key={i} className="flex gap-4 rounded-lg border p-3">
          {Array.from({ length: cols }).map((_, j) => (
            <Bone key={j} className="h-4 flex-1" />
          ))}
        </div>
      ))}
    </div>
  )
}

export function CardSkeleton() {
  return (
    <div className="rounded-xl border bg-card p-6">
      <div className="space-y-3">
        <Bone className="h-4 w-24" />
        <Bone className="h-8 w-20" />
        <Bone className="h-3 w-32" />
      </div>
    </div>
  )
}

export function CardSkeletonGrid({ count = 3 }: { count?: number }) {
  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      {Array.from({ length: count }).map((_, i) => (
        <CardSkeleton key={i} />
      ))}
    </div>
  )
}
