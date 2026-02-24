import { useAuth } from '@/hooks/use-auth'
import { useAuthStore } from '@/stores/auth-store'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { LogOut, Settings, User } from 'lucide-react'
import { useNavigate, useLocation } from 'react-router-dom'

const pageTitles: Record<string, string> = {
  '/dashboard': 'Dashboard',
  '/timesheet': 'Pointages',
  '/absences': 'Absences',
  '/expenses': 'Depenses',
  '/anomalies': 'Anomalies',
  '/validations': 'Validations',
  '/settings': 'Parametres',
  '/manager': 'Vue equipe',
  '/manager/approvals': 'Approbations',
  '/manager/anomalies': 'Anomalies equipe',
  '/org': 'Vue organisation',
  '/org/users': 'Utilisateurs',
  '/org/timesheet': 'Pointages org',
  '/org/expenses': 'Depenses org',
  '/org/anomalies': 'Anomalies org',
  '/admin': 'Vue globale',
  '/admin/organizations': 'Organisations',
  '/admin/users': 'Tous les utilisateurs',
}

export function Header() {
  const { signOut } = useAuth()
  const { profile } = useAuthStore()
  const navigate = useNavigate()
  const location = useLocation()

  const initials =
    (profile?.first_name?.[0] ?? '') + (profile?.last_name?.[0] ?? '')

  const pageTitle = pageTitles[location.pathname] ?? ''

  return (
    <header className="flex h-16 items-center justify-between bg-card/80 px-8 shadow-[0_1px_3px_-1px_oklch(0.50_0.16_270_/_0.06)]">
      <h2 className="text-lg font-semibold text-foreground">{pageTitle}</h2>

      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <button className="flex items-center gap-2.5 rounded-lg p-1.5 transition-colors hover:bg-accent">
            <span className="text-sm font-medium text-muted-foreground">
              {profile?.first_name} {profile?.last_name}
            </span>
            <div className="rounded-full bg-gradient-to-br from-primary to-[oklch(0.60_0.18_300)] p-[2px]">
              <Avatar className="h-8 w-8 border-2 border-card">
                <AvatarFallback className="bg-card text-xs font-semibold text-primary">
                  {initials || <User className="h-4 w-4" />}
                </AvatarFallback>
              </Avatar>
            </div>
          </button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end" className="w-48">
          <DropdownMenuItem onClick={() => navigate('/settings')}>
            <Settings className="mr-2 h-4 w-4" />
            Parametres
          </DropdownMenuItem>
          <DropdownMenuSeparator />
          <DropdownMenuItem onClick={signOut}>
            <LogOut className="mr-2 h-4 w-4" />
            Deconnexion
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    </header>
  )
}
