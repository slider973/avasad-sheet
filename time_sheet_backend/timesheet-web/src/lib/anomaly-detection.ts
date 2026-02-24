import type { TimesheetEntry } from '@/types/database'

export type AnomalySeverity = 'low' | 'medium' | 'high' | 'critical'

export interface DetectedAnomaly {
  type: string
  label: string
  severity: AnomalySeverity
  description: string
  entryId: string
  date: string
}

function timeToMinutes(time: string): number {
  if (!time || !time.includes(':')) return 0
  const [h, m] = time.split(':').map(Number)
  if (isNaN(h) || isNaN(m)) return 0
  return h * 60 + m
}

function totalWorkedMinutes(entry: TimesheetEntry): number {
  let total = 0
  if (entry.start_morning && entry.end_morning) {
    const diff = timeToMinutes(entry.end_morning) - timeToMinutes(entry.start_morning)
    if (diff > 0) total += diff
  }
  if (entry.start_afternoon && entry.end_afternoon) {
    const diff = timeToMinutes(entry.end_afternoon) - timeToMinutes(entry.start_afternoon)
    if (diff > 0) total += diff
  }
  return total
}

function formatMinutes(mins: number): string {
  const h = Math.floor(mins / 60)
  const m = mins % 60
  return m > 0 ? `${h}h${String(m).padStart(2, '0')}` : `${h}h`
}

// --- Rule 1: Insufficient Hours ---
function checkInsufficientHours(entry: TimesheetEntry): DetectedAnomaly | null {
  const required = 8 * 60 + 18 // 8h18 = 498 min
  const tolerance = 5
  const worked = totalWorkedMinutes(entry)
  if (worked >= required - tolerance) return null
  const shortfall = required - worked
  let severity: AnomalySeverity = 'low'
  if (shortfall >= 120) severity = 'high'
  else if (shortfall >= 60) severity = 'medium'
  return {
    type: 'insufficientHours',
    label: 'Heures insuffisantes',
    severity,
    description: `${formatMinutes(worked)} travaillees sur ${formatMinutes(required)} requises (-${formatMinutes(shortfall)})`,
    entryId: entry.id,
    date: entry.day_date,
  }
}

// --- Rule 2: Excessive Hours ---
function checkExcessiveHours(entry: TimesheetEntry): DetectedAnomaly | null {
  const max = 12 * 60 // 720 min
  const tolerance = 15
  const worked = totalWorkedMinutes(entry)
  if (worked <= max + tolerance) return null
  const excess = worked - max
  let severity: AnomalySeverity = 'low'
  if (excess >= 180) severity = 'critical'
  else if (excess >= 120) severity = 'high'
  else if (excess >= 60) severity = 'medium'
  return {
    type: 'excessiveHours',
    label: 'Heures excessives',
    severity,
    description: `${formatMinutes(worked)} travaillees, maximum ${formatMinutes(max)} (+${formatMinutes(excess)})`,
    entryId: entry.id,
    date: entry.day_date,
  }
}

// --- Rule 3: Invalid Times ---
function checkInvalidTimes(entry: TimesheetEntry): DetectedAnomaly | null {
  const issues: string[] = []

  if (entry.start_morning && entry.end_morning) {
    if (timeToMinutes(entry.end_morning) <= timeToMinutes(entry.start_morning)) {
      issues.push('Fin de matinee avant ou egale au debut')
    }
  }
  if (entry.start_afternoon && entry.end_afternoon) {
    if (timeToMinutes(entry.end_afternoon) <= timeToMinutes(entry.start_afternoon)) {
      issues.push("Fin d'apres-midi avant ou egale au debut")
    }
  }

  // Check break logic
  if (entry.end_morning && entry.start_afternoon) {
    const breakMins = timeToMinutes(entry.start_afternoon) - timeToMinutes(entry.end_morning)
    if (breakMins < 15) issues.push(`Pause trop courte: ${breakMins}min (minimum 15min)`)
    if (breakMins > 120) issues.push(`Pause trop longue: ${breakMins}min (maximum 120min)`)
  }

  // Check incomplete entries (has start but no end, or vice versa)
  if (entry.start_morning && !entry.end_morning) issues.push('Heure de fin matinee manquante')
  if (!entry.start_morning && entry.end_morning) issues.push('Heure de debut matinee manquante')
  if (entry.start_afternoon && !entry.end_afternoon) issues.push("Heure de fin apres-midi manquante")
  if (!entry.start_afternoon && entry.end_afternoon) issues.push("Heure de debut apres-midi manquante")

  if (issues.length === 0) return null
  let severity: AnomalySeverity = 'low'
  if (issues.length >= 3) severity = 'high'
  else if (issues.length >= 2) severity = 'medium'
  return {
    type: 'invalidTimes',
    label: 'Horaires invalides',
    severity,
    description: issues.join('; '),
    entryId: entry.id,
    date: entry.day_date,
  }
}

// --- Rule 4: Missing Break ---
function checkMissingBreak(entry: TimesheetEntry): DetectedAnomaly | null {
  const worked = totalWorkedMinutes(entry)
  if (worked < 6 * 60) return null // short day, no break required

  if (!entry.end_morning || !entry.start_afternoon) {
    const h = Math.floor(worked / 60)
    const m = worked % 60
    return {
      type: 'missingBreak',
      label: 'Pause manquante',
      severity: 'medium',
      description: `Aucune pause detectee pour une journee de ${h}h${String(m).padStart(2, '0')}`,
      entryId: entry.id,
      date: entry.day_date,
    }
  }

  const breakMins = timeToMinutes(entry.start_afternoon) - timeToMinutes(entry.end_morning)
  if (breakMins < 30) {
    return {
      type: 'missingBreak',
      label: 'Pause manquante',
      severity: 'low',
      description: `Pause trop courte: ${breakMins}min (minimum 30min requis)`,
      entryId: entry.id,
      date: entry.day_date,
    }
  }

  return null
}

// --- Rule 5: Schedule Consistency ---
function checkScheduleConsistency(entry: TimesheetEntry): DetectedAnomaly | null {
  const issues: string[] = []
  let hasHighIssue = false

  if (entry.start_morning) {
    const start = timeToMinutes(entry.start_morning)
    if (start < timeToMinutes('06:00')) {
      issues.push(`Debut trop tot: ${entry.start_morning} (avant 06:00)`)
      hasHighIssue = true
    }
  }

  if (entry.end_afternoon) {
    const end = timeToMinutes(entry.end_afternoon)
    if (end > timeToMinutes('22:00')) {
      issues.push(`Fin trop tard: ${entry.end_afternoon} (apres 22:00)`)
      hasHighIssue = true
    }
  }

  // Check unusual break times
  if (entry.end_morning) {
    const endM = timeToMinutes(entry.end_morning)
    if (endM < timeToMinutes('11:00') || endM > timeToMinutes('14:00')) {
      issues.push(`Debut de pause inhabituel: ${entry.end_morning}`)
    }
  }
  if (entry.start_afternoon) {
    const startA = timeToMinutes(entry.start_afternoon)
    if (startA < timeToMinutes('12:00') || startA > timeToMinutes('15:00')) {
      issues.push(`Fin de pause inhabituelle: ${entry.start_afternoon}`)
    }
  }

  if (issues.length === 0) return null
  let severity: AnomalySeverity = 'low'
  if (hasHighIssue) severity = 'high'
  else if (issues.length >= 2) severity = 'medium'
  return {
    type: 'scheduleInconsistency',
    label: 'Incoherence horaire',
    severity,
    description: issues.join('; '),
    entryId: entry.id,
    date: entry.day_date,
  }
}

// --- Main detection function ---
export function detectAnomalies(entry: TimesheetEntry): DetectedAnomaly[] {
  // Skip entries with absence
  if (entry.absence_reason) return []

  // Skip entries with no time data at all
  if (!entry.start_morning && !entry.end_morning && !entry.start_afternoon && !entry.end_afternoon) {
    return []
  }

  const results: DetectedAnomaly[] = []

  const checks = [
    checkInvalidTimes,
    checkInsufficientHours,
    checkExcessiveHours,
    checkMissingBreak,
    checkScheduleConsistency,
  ]

  for (const check of checks) {
    const result = check(entry)
    if (result) results.push(result)
  }

  // Sort by severity (critical first)
  const severityOrder: Record<AnomalySeverity, number> = { critical: 4, high: 3, medium: 2, low: 1 }
  results.sort((a, b) => severityOrder[b.severity] - severityOrder[a.severity])

  return results
}

export function detectAnomaliesForEntries(entries: TimesheetEntry[]): Map<string, DetectedAnomaly[]> {
  const map = new Map<string, DetectedAnomaly[]>()
  for (const entry of entries) {
    const anomalies = detectAnomalies(entry)
    if (anomalies.length > 0) {
      map.set(entry.day_date, anomalies)
    }
  }
  return map
}

export const severityLabels: Record<AnomalySeverity, string> = {
  low: 'Faible',
  medium: 'Moyenne',
  high: 'Elevee',
  critical: 'Critique',
}

export const severityColors: Record<AnomalySeverity, string> = {
  low: 'text-yellow-700 bg-yellow-50 border-yellow-200',
  medium: 'text-orange-700 bg-orange-50 border-orange-200',
  high: 'text-red-700 bg-red-50 border-red-200',
  critical: 'text-red-900 bg-red-100 border-red-300',
}
