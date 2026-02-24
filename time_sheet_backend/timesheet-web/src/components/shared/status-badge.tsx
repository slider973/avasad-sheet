import { Badge } from '@/components/ui/badge'
import { cn } from '@/lib/utils'
import { Clock, CheckCircle2, XCircle, Timer, CircleCheck, CircleAlert } from 'lucide-react'
import type { LucideIcon } from 'lucide-react'

type StatusVariant = 'pending' | 'approved' | 'rejected' | 'expired' | 'resolved' | 'unresolved'

const variantConfig: Record<StatusVariant, { style: string; label: string; icon: LucideIcon; pulse?: boolean }> = {
  pending: {
    style: 'bg-amber-50 text-amber-700 border-amber-200',
    label: 'En attente',
    icon: Clock,
    pulse: true,
  },
  approved: {
    style: 'bg-emerald-50 text-emerald-700 border-emerald-200',
    label: 'Approuve',
    icon: CheckCircle2,
  },
  rejected: {
    style: 'bg-red-50 text-red-700 border-red-200',
    label: 'Rejete',
    icon: XCircle,
  },
  expired: {
    style: 'bg-gray-50 text-gray-500 border-gray-200',
    label: 'Expire',
    icon: Timer,
  },
  resolved: {
    style: 'bg-emerald-50 text-emerald-700 border-emerald-200',
    label: 'Resolu',
    icon: CircleCheck,
  },
  unresolved: {
    style: 'bg-orange-50 text-orange-700 border-orange-200',
    label: 'Non resolu',
    icon: CircleAlert,
  },
}

interface StatusBadgeProps {
  status: StatusVariant
  className?: string
}

export function StatusBadge({ status, className }: StatusBadgeProps) {
  const config = variantConfig[status]
  const Icon = config.icon

  return (
    <Badge variant="outline" className={cn('gap-1.5 font-medium', config.style, className)}>
      <span className="relative flex h-2 w-2">
        {config.pulse && (
          <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-current opacity-40" />
        )}
        <Icon className="h-2 w-2" />
      </span>
      {config.label}
    </Badge>
  )
}
