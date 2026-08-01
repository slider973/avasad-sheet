/// Paramètres d'une organisation, configurés par un super_admin depuis
/// l'application web (migration SQL 00023).
///
/// Côté mobile ces données sont en lecture seule : elles arrivent par la
/// bucket de synchronisation PowerSync `org_data`.
class OrganizationSettings {
  final String id;
  final String name;
  final String? slug;
  final String? logoUrl;
  final String? contactFirstName;
  final String? contactLastName;
  final String? contactEmail;
  final String? contactPhone;
  final String? address;

  /// Manager responsable des relevés d'heures de l'organisation.
  /// Sert à pré-sélectionner le destinataire d'une demande de validation.
  final String? defaultManagerId;

  const OrganizationSettings({
    required this.id,
    required this.name,
    this.slug,
    this.logoUrl,
    this.contactFirstName,
    this.contactLastName,
    this.contactEmail,
    this.contactPhone,
    this.address,
    this.defaultManagerId,
  });

  /// Nom complet de la personne de contact, `null` si aucune n'est renseignée.
  String? get contactFullName {
    final parts = [contactFirstName, contactLastName]
        .where((p) => p != null && p.trim().isNotEmpty)
        .map((p) => p!.trim());
    return parts.isEmpty ? null : parts.join(' ');
  }

  factory OrganizationSettings.fromRow(Map<String, dynamic> row) {
    return OrganizationSettings(
      id: row['id'] as String,
      name: (row['name'] as String?) ?? '',
      slug: row['slug'] as String?,
      logoUrl: row['logo_url'] as String?,
      contactFirstName: row['contact_first_name'] as String?,
      contactLastName: row['contact_last_name'] as String?,
      contactEmail: row['contact_email'] as String?,
      contactPhone: row['contact_phone'] as String?,
      address: row['address'] as String?,
      defaultManagerId: row['default_manager_id'] as String?,
    );
  }
}
