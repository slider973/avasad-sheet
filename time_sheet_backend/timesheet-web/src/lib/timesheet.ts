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
