import { motion } from 'motion/react'
import type { ReactNode } from 'react'
import { cn } from '@/lib/utils'

interface AnimatedCardProps {
  children: ReactNode
  className?: string
}

export function AnimatedCard({ children, className }: AnimatedCardProps) {
  return (
    <motion.div
      whileHover={{ y: -2, transition: { duration: 0.2 } }}
      className={cn(
        'rounded-xl border bg-card text-card-foreground shadow-sm transition-shadow duration-200 hover:shadow-lg hover:shadow-primary/5',
        className
      )}
    >
      {children}
    </motion.div>
  )
}
