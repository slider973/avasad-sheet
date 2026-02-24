import { BrowserRouter, Routes, Route, Navigate, Outlet } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { TooltipProvider } from '@/components/ui/tooltip'
import { Toaster } from 'sonner'
import { useAuth } from '@/hooks/use-auth'
import { AuthGuard } from '@/components/auth/auth-guard'
import { RoleGuard } from '@/components/auth/role-guard'
import { AppLayout } from '@/components/layout/app-layout'
import LoginPage from '@/pages/login'
import SignPage from '@/pages/sign'
import DashboardPage from '@/pages/dashboard'
import TimesheetPage from '@/pages/timesheet'
import AbsencesPage from '@/pages/absences'
import ExpensesPage from '@/pages/expenses'
import AnomaliesPage from '@/pages/anomalies'
import ValidationsPage from '@/pages/validations'
import SettingsPage from '@/pages/settings'
import ManagerOverviewPage from '@/pages/manager/overview'
import PendingApprovalsPage from '@/pages/manager/pending-approvals'
import TeamTimesheetPage from '@/pages/manager/team-timesheet'
import TeamAnomaliesPage from '@/pages/manager/team-anomalies'
// Admin pages (super_admin)
import AdminOverviewPage from '@/pages/admin/overview'
import AdminOrganizationsPage from '@/pages/admin/organizations'
import AdminOrgDetailPage from '@/pages/admin/organization-detail'
import AdminUsersPage from '@/pages/admin/users'
import AdminUserDetailPage from '@/pages/admin/user-detail'
import AdminCreateUserPage from '@/pages/admin/create-user'
// Org admin pages
import OrgOverviewPage from '@/pages/org/overview'
import OrgUsersPage from '@/pages/org/users'
import OrgCreateUserPage from '@/pages/org/create-user'
import OrgTimesheetPage from '@/pages/org/timesheet'
import OrgExpensesPage from '@/pages/org/expenses'
import OrgAnomaliesPage from '@/pages/org/anomalies'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 2,
      retry: 1,
    },
  },
})

function AppRoutes() {
  useAuth()

  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route path="/sign/:token" element={<SignPage />} />
      <Route
        element={
          <AuthGuard>
            <AppLayout />
          </AuthGuard>
        }
      >
        {/* Employee routes (all roles) */}
        <Route path="/dashboard" element={<DashboardPage />} />
        <Route path="/timesheet" element={<TimesheetPage />} />
        <Route path="/absences" element={<AbsencesPage />} />
        <Route path="/expenses" element={<ExpensesPage />} />
        <Route path="/anomalies" element={<AnomaliesPage />} />
        <Route path="/validations" element={<ValidationsPage />} />
        <Route path="/settings" element={<SettingsPage />} />

        {/* Manager routes */}
        <Route path="/manager" element={<ManagerOverviewPage />} />
        <Route path="/manager/approvals" element={<PendingApprovalsPage />} />
        <Route path="/manager/timesheet/:employeeId?" element={<TeamTimesheetPage />} />
        <Route path="/manager/anomalies" element={<TeamAnomaliesPage />} />

        {/* Admin routes (super_admin only) */}
        <Route path="/admin" element={<RoleGuard roles={['super_admin']}><Outlet /></RoleGuard>}>
          <Route index element={<AdminOverviewPage />} />
          <Route path="organizations" element={<AdminOrganizationsPage />} />
          <Route path="organizations/:id" element={<AdminOrgDetailPage />} />
          <Route path="users" element={<AdminUsersPage />} />
          <Route path="users/new" element={<AdminCreateUserPage />} />
          <Route path="users/:id" element={<AdminUserDetailPage />} />
        </Route>

        {/* Org admin routes */}
        <Route path="/org" element={<RoleGuard roles={['org_admin']}><Outlet /></RoleGuard>}>
          <Route index element={<OrgOverviewPage />} />
          <Route path="users" element={<OrgUsersPage />} />
          <Route path="users/new" element={<OrgCreateUserPage />} />
          <Route path="timesheet" element={<OrgTimesheetPage />} />
          <Route path="expenses" element={<OrgExpensesPage />} />
          <Route path="anomalies" element={<OrgAnomaliesPage />} />
        </Route>
      </Route>
      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  )
}

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <TooltipProvider>
        <BrowserRouter>
          <AppRoutes />
        </BrowserRouter>
        <Toaster
          position="bottom-right"
          toastOptions={{
            style: {
              fontFamily: "'Plus Jakarta Sans', system-ui, sans-serif",
              borderRadius: '0.75rem',
            },
          }}
        />
      </TooltipProvider>
    </QueryClientProvider>
  )
}
