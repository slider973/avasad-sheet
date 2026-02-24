export type UserRole = 'employee' | 'manager' | 'admin' | 'org_admin' | 'super_admin'

export type AbsenceType = 'vacation' | 'sick' | 'holiday' | 'unpaid' | 'other'

export type AnomalyType =
  | 'insufficient_hours'
  | 'missing_entry'
  | 'invalid_times'
  | 'excessive_hours'
  | 'missing_break'
  | 'schedule_inconsistency'
  | 'weekly_compensation'

export type ValidationStatus = 'pending' | 'approved' | 'rejected' | 'expired'

export type SignerRole = 'employee' | 'manager' | 'client'
export type SigningStep = 'employee' | 'manager' | 'client' | 'completed'

export type ExpenseCategory = 'transport' | 'meal' | 'accommodation' | 'mileage' | 'office' | 'other'

export type OvertimeType = 'weekday' | 'weekend' | 'holiday'

export interface Profile {
  id: string
  first_name: string | null
  last_name: string | null
  email: string | null
  organization_id: string | null
  role: UserRole
  signature_url: string | null
  phone: string | null
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface Organization {
  id: string
  name: string
  slug: string | null
  parent_id: string | null
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface TimesheetEntry {
  id: string
  user_id: string
  day_date: string
  day_of_week: string | null
  start_morning: string | null
  end_morning: string | null
  start_afternoon: string | null
  end_afternoon: string | null
  absence_reason: AbsenceType | null
  period: string | null
  has_overtime_hours: boolean
  is_weekend_day: boolean
  is_weekend_overtime_enabled: boolean
  overtime_type: OvertimeType | null
  created_at: string
  updated_at: string
}

export interface Absence {
  id: string
  user_id: string
  timesheet_entry_id: string | null
  start_date: string
  end_date: string
  type: AbsenceType
  motif: string | null
  created_at: string
}

export interface Anomaly {
  id: string
  user_id: string
  timesheet_entry_id: string | null
  detected_date: string
  description: string
  is_resolved: boolean
  type: AnomalyType
  created_at: string
}

export interface OvertimeConfiguration {
  id: string
  user_id: string
  weekend_overtime_enabled: boolean
  weekend_days: string | null
  weekend_overtime_rate: number
  weekday_overtime_rate: number
  daily_work_threshold_minutes: number
  description: string | null
  created_at: string
  updated_at: string
}

export interface Expense {
  id: string
  user_id: string
  date: string
  category: ExpenseCategory
  description: string | null
  currency: string
  amount: number
  mileage_rate: number | null
  distance_km: number | null
  departure_location: string | null
  arrival_location: string | null
  attachment_url: string | null
  is_approved: boolean | null
  approved_by: string | null
  manager_comment: string | null
  approved_at: string | null
  created_at: string
  updated_at: string
}

export interface ValidationRequest {
  id: string
  employee_id: string
  manager_id: string | null
  period_start: string
  period_end: string
  status: ValidationStatus
  pdf_url: string | null
  employee_signature_url: string | null
  manager_signature_url: string | null
  manager_comment: string | null
  validated_at: string | null
  expires_at: string | null
  signing_step: SigningStep | null
  client_signer_name: string | null
  client_signer_email: string | null
  created_at: string
  updated_at: string
}

export interface SigningToken {
  id: string
  validation_id: string
  token: string
  signer_role: SignerRole
  signer_name: string
  signer_email: string | null
  signed_at: string | null
  signature_url: string | null
  expires_at: string
  created_at: string
}

export interface Notification {
  id: string
  user_id: string
  type: string
  title: string
  message: string
  data: string | null
  is_read: boolean
  read_at: string | null
  created_at: string
}

export interface GeneratedPdf {
  id: string
  user_id: string
  file_name: string
  file_url: string
  generated_date: string
  month: number
  year: number
}

export interface ManagerEmployee {
  id: string
  manager_id: string
  employee_id: string
  created_at: string
}

export interface Database {
  public: {
    Tables: {
      profiles: { Row: Profile; Insert: Partial<Profile> & { id: string }; Update: Partial<Profile> }
      organizations: { Row: Organization; Insert: Partial<Organization>; Update: Partial<Organization> }
      timesheet_entries: { Row: TimesheetEntry; Insert: Omit<TimesheetEntry, 'id' | 'created_at' | 'updated_at'> & { id?: string }; Update: Partial<TimesheetEntry> }
      absences: { Row: Absence; Insert: Omit<Absence, 'id' | 'created_at'> & { id?: string }; Update: Partial<Absence> }
      anomalies: { Row: Anomaly; Insert: Omit<Anomaly, 'id' | 'created_at'> & { id?: string }; Update: Partial<Anomaly> }
      overtime_configurations: { Row: OvertimeConfiguration; Insert: Omit<OvertimeConfiguration, 'id' | 'created_at' | 'updated_at'> & { id?: string }; Update: Partial<OvertimeConfiguration> }
      expenses: { Row: Expense; Insert: Omit<Expense, 'id' | 'created_at' | 'updated_at'> & { id?: string }; Update: Partial<Expense> }
      validation_requests: { Row: ValidationRequest; Insert: Omit<ValidationRequest, 'id' | 'created_at' | 'updated_at'> & { id?: string }; Update: Partial<ValidationRequest> }
      notifications: { Row: Notification; Insert: Omit<Notification, 'id' | 'created_at'> & { id?: string }; Update: Partial<Notification> }
      generated_pdfs: { Row: GeneratedPdf; Insert: Omit<GeneratedPdf, 'id'> & { id?: string }; Update: Partial<GeneratedPdf> }
      manager_employees: { Row: ManagerEmployee; Insert: Omit<ManagerEmployee, 'id' | 'created_at'> & { id?: string }; Update: Partial<ManagerEmployee> }
      signing_tokens: { Row: SigningToken; Insert: Omit<SigningToken, 'id' | 'token' | 'created_at'> & { id?: string }; Update: Partial<SigningToken> }
    }
  }
}
