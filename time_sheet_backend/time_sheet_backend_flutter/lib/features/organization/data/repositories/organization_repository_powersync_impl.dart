import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:powersync/powersync.dart';

import '../../../../core/services/supabase/supabase_service.dart';
import '../../../../services/logger_service.dart';
import '../../domain/entities/organization_settings.dart';
import '../../domain/repositories/organization_repository.dart';

/// Lecture des paramètres d'organisation depuis la base locale PowerSync
/// (table `organizations`, synchronisée par la bucket `org_data`).
///
/// Le logo est téléchargé depuis le bucket Storage public `org-logos` et gardé
/// en cache mémoire pour la durée de la session : la génération d'un PDF ne
/// doit pas dépendre d'un aller-retour réseau à chaque page.
class OrganizationRepositoryPowerSyncImpl implements OrganizationRepository {
  final PowerSyncDatabase db;
  final http.Client httpClient;

  OrganizationRepositoryPowerSyncImpl({
    required this.db,
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  /// Cache mémoire : clé = URL du logo, valeur = octets (ou null si échec).
  final Map<String, Uint8List?> _logoCache = {};

  String? get _userId => SupabaseService.instance.currentUserId;

  @override
  Future<OrganizationSettings?> getMyOrganization() async {
    final userId = _userId;
    if (userId == null) return null;

    try {
      final row = await db.getOptional(
        '''SELECT o.* FROM organizations o
             JOIN profiles p ON p.organization_id = o.id
            WHERE p.id = ?''',
        [userId],
      );
      if (row == null) return null;
      return OrganizationSettings.fromRow(row);
    } catch (e) {
      logger.e('Lecture de l\'organisation impossible: $e');
      return null;
    }
  }

  @override
  Future<Uint8List?> getMyOrganizationLogo() async {
    final org = await getMyOrganization();
    final url = org?.logoUrl;
    if (url == null || url.trim().isEmpty) return null;

    if (_logoCache.containsKey(url)) return _logoCache[url];

    try {
      final response = await httpClient
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        logger.w('Logo organisation indisponible (HTTP ${response.statusCode})');
        _logoCache[url] = null;
        return null;
      }
      _logoCache[url] = response.bodyBytes;
      return response.bodyBytes;
    } catch (e) {
      logger.w('Téléchargement du logo organisation échoué: $e');
      _logoCache[url] = null;
      return null;
    }
  }
}
