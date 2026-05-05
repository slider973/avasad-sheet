// Réplique fidèle de la logique de pointage Flutter.
// Source : lib/features/pointage/domain/entities/timesheet_entry.dart

export type SlotKey =
  | 'start_morning'
  | 'end_morning'
  | 'start_afternoon'
  | 'end_afternoon';

export type PunchState =
  | 'Non commencé'
  | 'Entrée'
  | 'Pause'
  | 'Reprise'
  | 'Sortie';

export interface TimesheetEntry {
  id?: string;
  user_id: string;
  day_date: string;
  day_of_week: string | null;
  start_morning: string | null;
  end_morning: string | null;
  start_afternoon: string | null;
  end_afternoon: string | null;
}

const isEmpty = (v: string | null | undefined): boolean =>
  v === null || v === undefined || v === '';

export function currentState(e: Partial<TimesheetEntry>): PunchState {
  if (isEmpty(e.start_morning)) return 'Non commencé';
  if (isEmpty(e.end_morning)) return 'Entrée';
  if (isEmpty(e.start_afternoon)) return 'Pause';
  if (isEmpty(e.end_afternoon)) return 'Reprise';
  return 'Sortie';
}

// Le prochain slot à remplir, dans l'ordre strict matin → après-midi.
// null = la journée est complète (4 slots remplis).
export function nextSlot(e: Partial<TimesheetEntry>): SlotKey | null {
  if (isEmpty(e.start_morning)) return 'start_morning';
  if (isEmpty(e.end_morning)) return 'end_morning';
  if (isEmpty(e.start_afternoon)) return 'start_afternoon';
  if (isEmpty(e.end_afternoon)) return 'end_afternoon';
  return null;
}

// Indique si le prochain slot est un "punch in" (entrée/reprise) ou "punch out" (pause/sortie).
export function nextSlotKind(slot: SlotKey): 'in' | 'out' {
  return slot === 'start_morning' || slot === 'start_afternoon' ? 'in' : 'out';
}

// Formate une Date dans un fuseau donné en "HH:mm" (24h, sans secondes).
// Identique à DateFormat('HH:mm').format(now) côté Flutter.
export function formatHHmm(date: Date, timeZone: string): string {
  const fmt = new Intl.DateTimeFormat('fr-CH', {
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
    timeZone,
  });
  // fr-CH peut produire "09:30" ou "09 h 30" selon ICU ; on normalise.
  const parts = fmt.formatToParts(date);
  const h = parts.find(p => p.type === 'hour')?.value ?? '00';
  const m = parts.find(p => p.type === 'minute')?.value ?? '00';
  return `${h.padStart(2, '0')}:${m.padStart(2, '0')}`;
}

// "YYYY-MM-DD" dans un fuseau donné, pour la colonne day_date (DATE PostgreSQL).
export function formatDayDate(date: Date, timeZone: string): string {
  const fmt = new Intl.DateTimeFormat('en-CA', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    timeZone,
  });
  return fmt.format(date); // en-CA donne YYYY-MM-DD
}

// Nom anglais complet du jour, identique à DateFormat.EEEE() (Locale par défaut).
export function formatDayOfWeek(date: Date, timeZone: string): string {
  return new Intl.DateTimeFormat('en-US', {
    weekday: 'long',
    timeZone,
  }).format(date);
}

// Calcule la durée travaillée en minutes à partir des 4 slots "HH:mm".
// Réplique calculateDailyTotal() de timesheet_entry.dart.
export function dailyMinutes(e: Partial<TimesheetEntry>): number {
  const diff = (a?: string | null, b?: string | null): number => {
    if (isEmpty(a) || isEmpty(b)) return 0;
    const [ah, am] = (a as string).split(':').map(Number);
    const [bh, bm] = (b as string).split(':').map(Number);
    return Math.max(0, bh * 60 + bm - (ah * 60 + am));
  };
  return (
    diff(e.start_morning, e.end_morning) +
    diff(e.start_afternoon, e.end_afternoon)
  );
}

export function formatMinutes(total: number): string {
  const h = Math.floor(total / 60);
  const m = total % 60;
  return `${h}h${m.toString().padStart(2, '0')}`;
}

// Étiquette humaine de l'action que représente le prochain pointage.
export function actionLabel(slot: SlotKey): string {
  switch (slot) {
    case 'start_morning':
      return 'arrivée matin';
    case 'end_morning':
      return 'pause midi';
    case 'start_afternoon':
      return 'reprise après-midi';
    case 'end_afternoon':
      return 'fin de journée';
  }
}
