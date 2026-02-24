-- ============================================
-- TimeSheet Application - Database Schema
-- Migration: 00001_create_schema
-- ============================================

-- ============================================
-- ORGANISATIONS
-- ============================================
CREATE TABLE public.organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- PROFILES (linked to auth.users)
-- ============================================
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT NOT NULL,
  organization_id UUID REFERENCES public.organizations(id),
  role TEXT NOT NULL DEFAULT 'employee' CHECK (role IN ('employee', 'manager', 'admin')),
  signature_url TEXT,
  phone TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- TIMESHEET ENTRIES (replaces TimeSheetEntryModel Isar)
-- ============================================
CREATE TABLE public.timesheet_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  day_date DATE NOT NULL,
  day_of_week TEXT,
  start_morning TEXT,
  end_morning TEXT,
  start_afternoon TEXT,
  end_afternoon TEXT,
  absence_reason TEXT,
  period TEXT,
  has_overtime_hours BOOLEAN DEFAULT false,
  is_weekend_day BOOLEAN DEFAULT false,
  is_weekend_overtime_enabled BOOLEAN DEFAULT false,
  overtime_type TEXT DEFAULT 'NONE' CHECK (overtime_type IN ('NONE', 'WEEKDAY_ONLY', 'WEEKEND_ONLY', 'BOTH', 'MONTHLY')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, day_date)
);

CREATE INDEX idx_timesheet_user_date ON public.timesheet_entries(user_id, day_date);
CREATE INDEX idx_timesheet_date ON public.timesheet_entries(day_date);

-- ============================================
-- ABSENCES (replaces Absence Isar)
-- ============================================
CREATE TABLE public.absences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  timesheet_entry_id UUID REFERENCES public.timesheet_entries(id) ON DELETE SET NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('vacation', 'sick', 'holiday', 'unpaid', 'training', 'other')),
  motif TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_absences_user ON public.absences(user_id);

-- ============================================
-- ANOMALIES (replaces AnomalyModel Isar)
-- ============================================
CREATE TABLE public.anomalies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  timesheet_entry_id UUID REFERENCES public.timesheet_entries(id) ON DELETE CASCADE,
  detected_date DATE NOT NULL,
  description TEXT,
  is_resolved BOOLEAN DEFAULT false,
  type TEXT NOT NULL CHECK (type IN ('insufficient_hours', 'missing_entry', 'invalid_times', 'excessive_hours', 'missing_break', 'schedule_inconsistency', 'weekly_compensation')),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_anomalies_user ON public.anomalies(user_id);

-- ============================================
-- OVERTIME CONFIGURATION (replaces OvertimeConfiguration Isar)
-- ============================================
CREATE TABLE public.overtime_configurations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  weekend_overtime_enabled BOOLEAN DEFAULT false,
  weekend_days INTEGER[] DEFAULT '{6,7}',
  weekend_overtime_rate NUMERIC(4,2) DEFAULT 1.50,
  weekday_overtime_rate NUMERIC(4,2) DEFAULT 1.25,
  daily_work_threshold_minutes INTEGER DEFAULT 498,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id)
);

-- ============================================
-- EXPENSES (replaces ExpenseModel Isar)
-- ============================================
CREATE TABLE public.expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('mileage', 'meals', 'accommodation', 'transport', 'parking', 'supplies', 'other')),
  description TEXT,
  currency TEXT DEFAULT 'CHF',
  amount NUMERIC(10,2) NOT NULL,
  mileage_rate NUMERIC(4,2),
  distance_km INTEGER,
  departure_location TEXT,
  arrival_location TEXT,
  attachment_url TEXT,
  is_approved BOOLEAN DEFAULT false,
  approved_by UUID REFERENCES public.profiles(id),
  manager_comment TEXT,
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_expenses_user_date ON public.expenses(user_id, date);

-- ============================================
-- VALIDATION REQUESTS (replaces Serverpod validation_requests)
-- ============================================
CREATE TABLE public.validation_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES public.profiles(id),
  manager_id UUID NOT NULL REFERENCES public.profiles(id),
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'expired')),
  pdf_url TEXT,
  employee_signature_url TEXT,
  manager_signature_url TEXT,
  manager_comment TEXT,
  validated_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ DEFAULT (now() + interval '30 days'),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_validations_employee ON public.validation_requests(employee_id);
CREATE INDEX idx_validations_manager ON public.validation_requests(manager_id);
CREATE INDEX idx_validations_status ON public.validation_requests(status);

-- ============================================
-- NOTIFICATIONS (replaces Serverpod notifications)
-- ============================================
CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('validation_created', 'validation_approved', 'validation_rejected', 'validation_expiring', 'validation_reminder', 'expense_approved', 'expense_rejected', 'clock_reminder')),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  data JSONB,
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_notifications_user ON public.notifications(user_id);
CREATE INDEX idx_notifications_unread ON public.notifications(user_id, is_read) WHERE is_read = false;

-- ============================================
-- GENERATED PDFS (replaces GeneratedPdfModel Isar)
-- ============================================
CREATE TABLE public.generated_pdfs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_url TEXT NOT NULL,
  generated_date TIMESTAMPTZ DEFAULT now(),
  month INTEGER,
  year INTEGER
);

CREATE INDEX idx_pdfs_user ON public.generated_pdfs(user_id);

-- ============================================
-- MANAGER-EMPLOYEE RELATIONSHIPS
-- ============================================
CREATE TABLE public.manager_employees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  manager_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  employee_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(manager_id, employee_id)
);

-- ============================================
-- TRIGGER: auto-update updated_at
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_profiles_updated BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER tr_timesheet_updated BEFORE UPDATE ON public.timesheet_entries
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER tr_expenses_updated BEFORE UPDATE ON public.expenses
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER tr_validations_updated BEFORE UPDATE ON public.validation_requests
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER tr_overtime_updated BEFORE UPDATE ON public.overtime_configurations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================
-- TRIGGER: auto-create profile on signup
-- ============================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, first_name, last_name, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
    NEW.email
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- PUBLICATION for PowerSync replication
-- ============================================
CREATE PUBLICATION powersync FOR ALL TABLES;
