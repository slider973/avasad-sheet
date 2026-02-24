import { Navigate } from 'react-router-dom'
import { useAuthStore } from '@/stores/auth-store'
import type { UserRole } from '@/types/database'
import { Loader2 } from 'lucide-react'

interface RoleGuardProps {
  roles: UserRole[]
  children: React.ReactNode
  redirectTo?: string
}

export function RoleGuard({ roles, children, redirectTo = '/dashboard' }: RoleGuardProps) {
  const { role, isLoading } = useAuthStore()

  if (isLoading) {
    return (
      <div className="flex h-full items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    )
  }

  if (!role || !roles.includes(role)) {
    return <Navigate to={redirectTo} replace />
  }

  return <>{children}</>
}
