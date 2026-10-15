/**
 * Helpers partages entre la page Pointages et la carte de pointage rapide.
 */

/**
 * PostgreSQL applique `''::text` par defaut sur les quatre colonnes horaires
 * de `timesheet_entries` : une heure absente peut donc arriver en `null` OU
 * en chaine vide. Les deux cas comptent comme « pas encore pointe ».
 */
export function isFilled(value?: string | null): value is string {
  return typeof value === 'string' && value.trim() !== ''
}

/**
 * Rend un demi-journee sous la forme « debut - fin ».
 *
 * Une journee en cours n'a que son heure de debut : elle doit rester VISIBLE
 * (auparavant la condition `start && end` masquait le pointage tant que la
 * fin n'etait pas saisie, ce qui donnait l'impression que rien n'avait ete
 * enregistre). Retourne `null` quand aucune des deux heures n'est renseignee,
 * seul cas ou la cellule affiche un tiret.
 */
export function formatSlot(
  start?: string | null,
  end?: string | null,
): string | null {
  const hasStart = isFilled(start)
  const hasEnd = isFilled(end)

  if (!hasStart && !hasEnd) return null
  if (hasStart && hasEnd) return `${start} - ${end}`
  if (hasStart) return `${start} - …`
  return `… - ${end}`
}

/**
 * Libelle exact stocke dans `timesheet_entries.period` pour une absence qui ne
 * couvre qu'une moitie de journee (enum Dart `AbsencePeriod.halfDay`).
 */
export const DEMI_JOURNEE = 'Demi journée'

/**
 * Une absence d'une demi-journee ne doit pas compter pour un jour entier.
 *
 * La duree est portee par `period` sur `timesheet_entries` ; la table
 * `absences` ne porte AUCUNE periode, donc tout comptage fonde sur elle
 * confond un conge d'un jour et un conge d'une demi-journee.
 */
export function isHalfDayAbsence(entry: {
  absence_reason?: string | null
  period?: string | null
}): boolean {
  return isFilled(entry.absence_reason) && entry.period === DEMI_JOURNEE
}

/** Poids d'une absence en jours : 0,5 pour une demi-journee, 1 sinon. */
export function absenceWeight(entry: {
  absence_reason?: string | null
  period?: string | null
}): number {
  return isHalfDayAbsence(entry) ? 0.5 : 1
}

/**
 * Total des absences d'une liste d'entrees, en jours (demi-journees ponderees).
 * Formate en locale suisse : « 1,5 » et non « 1.5 ».
 */
export function formatAbsenceTotal(
  entries: ReadonlyArray<{ absence_reason?: string | null; period?: string | null }>,
): string {
  const total = entries
    .filter((e) => isFilled(e.absence_reason))
    .reduce((sum, e) => sum + absenceWeight(e), 0)
  return total.toLocaleString('fr-CH', { maximumFractionDigits: 1 })
}
