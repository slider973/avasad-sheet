import { AnimatedCard, AnimatedNumber } from '@/components/motion'
import { cn } from '@/lib/utils'
import type { LucideIcon } from 'lucide-react'

interface StatsCardProps {
  title: string
  value: number
  suffix?: string
  decimals?: number
  description?: string
  icon: LucideIcon
  iconClassName?: string
  className?: string
}

export function StatsCard({
  title,
  value,
  suffix = '',
  decimals = 0,
  description,
  icon: Icon,
  iconClassName,
  className,
}: StatsCardProps) {
  return (
    <AnimatedCard className={cn('p-6', className)}>
      <div className="flex items-start justify-between">
        <div className="space-y-2">
          <p className="text-sm font-medium text-muted-foreground">{title}</p>
          <div className="text-3xl font-bold tracking-tight">
            <AnimatedNumber value={value} decimals={decimals} suffix={suffix} />
          </div>
          {description && (
            <p className="text-xs text-muted-foreground">{description}</p>
          )}
        </div>
        <div className={cn(
          'flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br',
          iconClassName ?? 'from-primary/10 to-primary/5'
        )}>
          <Icon className={cn('h-5 w-5', iconClassName ? 'text-white' : 'text-primary')} />
        </div>
      </div>
    </AnimatedCard>
  )
}
