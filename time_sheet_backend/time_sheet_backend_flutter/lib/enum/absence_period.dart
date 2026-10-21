enum AbsencePeriod {
  fullDay("Journée complète"),
  halfDay("Demi journée");

  final String value;

  const AbsencePeriod(this.value);

  /// Reconnaît une période telle qu'elle est RÉELLEMENT stockée.
  ///
  /// La colonne `timesheet_entries.period` contient le libellé (`value`), pas
  /// le nom de la constante : un `period == 'fullDay'` ne matche donc jamais
  /// les données de production. Ce piège a déjà coûté deux bugs — le compteur
  /// d'absences du manager côté web, et le seuil d'heures supplémentaires
  /// appliqué en plein sur une demi-journée.
  ///
  /// Tolère les deux écritures (libellé et nom de constante) : d'anciennes
  /// lignes ont pu être écrites par du code qui stockait `name`.
  static AbsencePeriod? tryParse(String? raw) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) return null;

    for (final period in AbsencePeriod.values) {
      if (normalized == period.value || normalized == period.name) {
        return period;
      }
    }
    return null;
  }

  /// Part de la journée due. Sert à proratiser le seuil quotidien : une
  /// demi-journée d'absence ne doit pas se voir réclamer 8h18 de travail.
  double get dayFraction => this == AbsencePeriod.halfDay ? 0.5 : 0.0;
}
