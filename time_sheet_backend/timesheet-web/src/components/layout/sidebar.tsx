import { NavLink } from 'react-router-dom'
import { cn } from '@/lib/utils'
import { useAuthStore } from '@/stores/auth-store'
import {
  LayoutDashboard,
  Clock,
  CalendarOff,
  Receipt,
  AlertTriangle,
  FileCheck,
  Settings,
  Users,
  CheckSquare,
  ShieldAlert,
  Building2,
  UserCog,
  Globe,
} from 'lucide-react'

const employeeLinks = [
  { to: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { to: '/timesheet', label: 'Pointages', icon: Clock },
  { to: '/absences', label: 'Absences', icon: CalendarOff },
  { to: '/expenses', label: 'Depenses', icon: Receipt },
  { to: '/anomalies', label: 'Anomalies', icon: AlertTriangle },
  { to: '/validations', label: 'Validations', icon: FileCheck },
  { to: '/settings', label: 'Parametres', icon: Settings },
]

const managerLinks = [
  { to: '/manager', label: 'Vue equipe', icon: Users },
  { to: '/manager/approvals', label: 'Approbations', icon: CheckSquare },
  { to: '/manager/anomalies', label: 'Anomalies equipe', icon: ShieldAlert },
]

const orgAdminLinks = [
  { to: '/org', label: 'Vue organisation', icon: Building2 },
  { to: '/org/users', label: 'Utilisateurs', icon: UserCog },
  { to: '/org/timesheet', label: 'Pointages org', icon: Clock },
  { to: '/org/expenses', label: 'Depenses org', icon: Receipt },
  { to: '/org/anomalies', label: 'Anomalies org', icon: AlertTriangle },
]

const superAdminLinks = [
  { to: '/admin', label: 'Vue globale', icon: Globe },
  { to: '/admin/organizations', label: 'Organisations', icon: Building2 },
  { to: '/admin/users', label: 'Tous les utilisateurs', icon: Users },
]

function SidebarLink({ to, label, icon: Icon, end }: { to: string; label: string; icon: React.ComponentType<{ className?: string }>; end?: boolean }) {
  return (
    <NavLink
      to={to}
      end={end}
      className={({ isActive }) =>
        cn(
          'group relative flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-all duration-200',
          isActive
            ? 'bg-sidebar-accent text-sidebar-accent-foreground'
            : 'text-sidebar-foreground/60 hover:bg-sidebar-accent/50 hover:text-sidebar-foreground'
        )
      }
    >
      {({ isActive }) => (
        <>
          {isActive && (
            <span className="absolute left-0 top-1/2 h-5 w-[3px] -translate-y-1/2 rounded-r-full bg-sidebar-primary" />
          )}
          <Icon className="h-4 w-4 shrink-0" />
          {label}
        </>
      )}
    </NavLink>
  )
}

function NavSection({ title, links }: { title: string; links: typeof employeeLinks }) {
  return (
    <div className="mt-6">
      <p className="mb-2 px-3 text-[11px] font-semibold uppercase tracking-[0.08em] text-sidebar-foreground/40">
        {title}
      </p>
      <div className="space-y-0.5">
        {links.map((link) => (
          <SidebarLink
            key={link.to}
            to={link.to}
            label={link.label}
            icon={link.icon}
            end={link.to === '/manager' || link.to === '/org' || link.to === '/admin'}
          />
        ))}
      </div>
    </div>
  )
}

export function Sidebar() {
  const { isManager, isOrgAdmin, isSuperAdmin, profile } = useAuthStore()

  const showEmployeeLinks = !isSuperAdmin && !isOrgAdmin

  return (
    <aside className="flex h-full w-64 flex-col bg-sidebar">
      {/* Logo */}
      <div className="flex h-16 items-center gap-3 px-6">
        <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-gradient-to-br from-sidebar-primary to-[oklch(0.60_0.18_300)]">
          <span className="text-sm font-extrabold text-white">TS</span>
        </div>
        <span className="text-base font-bold text-sidebar-foreground">TimeSheet</span>
      </div>

      {/* Navigation */}
      <nav className="flex-1 space-y-0.5 overflow-y-auto px-3 py-2">
        {isSuperAdmin && <NavSection title="Administration" links={superAdminLinks} />}
        {isOrgAdmin && <NavSection title="Organisation" links={orgAdminLinks} />}
        {showEmployeeLinks && (
          <div className="space-y-0.5">
            {employeeLinks.map((link) => (
              <SidebarLink key={link.to} to={link.to} label={link.label} icon={link.icon} />
            ))}
          </div>
        )}
        {showEmployeeLinks && isManager && <NavSection title="Manager" links={managerLinks} />}
      </nav>

      {/* User info bottom */}
      {profile && (
        <div className="border-t border-sidebar-border px-4 py-3">
          <div className="flex items-center gap-3">
            <div className="flex h-8 w-8 items-center justify-center rounded-full bg-sidebar-accent text-xs font-semibold text-sidebar-accent-foreground">
              {(profile.first_name?.[0] ?? '') + (profile.last_name?.[0] ?? '')}
            </div>
            <div className="min-w-0 flex-1">
              <p className="truncate text-sm font-medium text-sidebar-foreground">
                {profile.first_name} {profile.last_name}
              </p>
              <p className="truncate text-xs text-sidebar-foreground/50">
                {profile.role}
              </p>
            </div>
          </div>
        </div>
      )}
    </aside>
  )
}
