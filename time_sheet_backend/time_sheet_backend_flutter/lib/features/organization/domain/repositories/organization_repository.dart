import 'dart:typed_data';

import '../entities/organization_settings.dart';

/// Accès en lecture aux paramètres de l'organisation de l'utilisateur courant.
abstract class OrganizationRepository {
  /// Organisation de l'utilisateur connecté, `null` s'il n'en a aucune.
  Future<OrganizationSettings?> getMyOrganization();

  /// Logo de l'organisation de l'utilisateur connecté, en octets.
  ///
  /// Retourne `null` si aucun logo n'est configuré ou si le téléchargement
  /// échoue — l'appelant retombe alors sur le logo par défaut.
  Future<Uint8List?> getMyOrganizationLogo();
}
