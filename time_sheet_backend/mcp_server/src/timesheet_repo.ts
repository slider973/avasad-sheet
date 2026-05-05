import { supabase } from './supabase.js';
import {
  TimesheetEntry,
  formatDayDate,
  formatDayOfWeek,
} from './pointage_logic.js';

export async function getOrCreateTodayEntry(
  userId: string,
  now: Date,
  timeZone: string,
): Promise<TimesheetEntry> {
  const dayDate = formatDayDate(now, timeZone);
  const sb = supabase();

  const { data, error } = await sb
    .from('timesheet_entries')
    .select('*')
    .eq('user_id', userId)
    .eq('day_date', dayDate)
    .maybeSingle();

  if (error) throw error;
  if (data) return data as TimesheetEntry;

  const fresh = {
    user_id: userId,
    day_date: dayDate,
    day_of_week: formatDayOfWeek(now, timeZone),
    start_morning: '',
    end_morning: '',
    start_afternoon: '',
    end_afternoon: '',
  };

  const { data: inserted, error: insErr } = await sb
    .from('timesheet_entries')
    .insert(fresh)
    .select('*')
    .single();

  if (insErr) throw insErr;
  return inserted as TimesheetEntry;
}

export async function updateSlot(
  entryId: string,
  slot: string,
  value: string,
): Promise<TimesheetEntry> {
  const { data, error } = await supabase()
    .from('timesheet_entries')
    .update({ [slot]: value })
    .eq('id', entryId)
    .select('*')
    .single();
  if (error) throw error;
  return data as TimesheetEntry;
}
