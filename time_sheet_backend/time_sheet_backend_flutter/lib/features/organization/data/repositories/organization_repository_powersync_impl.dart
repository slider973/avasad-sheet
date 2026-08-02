import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';

import '../../../../core/services/supabase/supabase_service.dart';
import '../../../../services/logger_service.dart';
import '../../domain/entities/organization_settings.dart';
import '../../domain/repositories/organization_repository.dart';

/// Lecture des paramètres d'organisation depuis la base locale PowerSync
/// (table `organizations`, synchronisée par la bucket `org_data`).
///
/// Le logo est téléchargé depuis le bucket Storage public `org-logos` puis
/// conservé à deux niveaux :
///   - en mémoire, pour ne pas refaire d'aller-retour réseau à chaque PDF ;
///   - **sur disque**, pour que la génération d'un PDF hors ligne utilise bien
///     le logo configuré depuis l'interface web et non le logo de repli.
///
/// L'URL stockée dans `organizations.logo_url` porte un paramètre `?v=`
/// renouvelé à chaque téléversement : elle sert donc de clé de fraîcheur du
/// cache disque. Pas de cache disque sur le web (pas de système de fichiers).
///
/// ⚠️ Le téléchargement passe par le **client Storage de Supabase**, pas par un
/// GET nu sur l'URL publique : la passerelle Kong protège tout `/storage/v1/`
/// par le plugin `key-auth`, y compris la route `/object/public/`. Un GET sans
/// en-tête `apikey` reçoit un 401 (vérifié en prod le 2026-08-02), et le PDF
/// retomberait silencieusement sur le logo par défaut. Le client Storage
/// attache la clé et la session automatiquement.
class OrganizationRepositoryPowerSyncImpl implements OrganizationRepository {
  static const String _cacheDirName = 'org_logo';
  static const String _logoBucket = 'org-logos';

  final PowerSyncDatabase db;

  OrganizationRepositoryPowerSyncImpl({required this.db});

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

    // 1. Cache disque, s'il correspond à l'URL courante
    final cached = await _readFromDisk(url);
    if (cached != null) {
      _logoCache[url] = cached;
      return cached;
    }

    // 2. Téléchargement via le client Storage (qui porte la clé API)
    final path = _storagePath(url);
    if (path == null) {
      logger.w('URL de logo inattendue, téléchargement ignoré: $url');
      _logoCache[url] = null;
      return null;
    }

    try {
      final bytes = await SupabaseService.instance.client.storage
          .from(_logoBucket)
          .download(path)
          .timeout(const Duration(seconds: 10));
      if (bytes.isEmpty) {
        _logoCache[url] = null;
        return null;
      }
      await _writeToDisk(url, bytes);
      _logoCache[url] = bytes;
      return bytes;
    } catch (e) {
      // Hors ligne et rien en cache : l'appelant retombe sur le logo embarqué.
      logger.w('Téléchargement du logo organisation échoué: $e');
      _logoCache[url] = null;
      return null;
    }
  }

  /// Chemin dans le bucket (`{orgId}/logo.png`) extrait de l'URL publique
  /// stockée en base, paramètre `?v=` retiré. `null` si l'URL ne pointe pas
  /// sur le bucket attendu.
  String? _storagePath(String url) {
    const marker = '/$_logoBucket/';
    final index = url.indexOf(marker);
    if (index == -1) return null;
    final path = url.substring(index + marker.length).split('?').first;
    return path.isEmpty ? null : path;
  }

  /// Répertoire de cache, `null` sur le web ou si l'accès disque échoue.
  Future<Directory?> _cacheDir() async {
    if (kIsWeb) return null;
    try {
      final base = await getApplicationDocumentsDirectory();
      final dir = Directory('${base.path}/$_cacheDirName');
      if (!await dir.exists()) await dir.create(recursive: true);
      return dir;
    } catch (e) {
      logger.w('Cache disque du logo indisponible: $e');
      return null;
    }
  }

  Future<Uint8List?> _readFromDisk(String url) async {
    final dir = await _cacheDir();
    if (dir == null) return null;
    try {
      final marker = File('${dir.path}/logo.url');
      if (!await marker.exists()) return null;
      if ((await marker.readAsString()).trim() != url.trim()) return null;

      final file = File('${dir.path}/logo.img');
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      return bytes.isEmpty ? null : bytes;
    } catch (e) {
      logger.w('Lecture du logo en cache échouée: $e');
      return null;
    }
  }

  Future<void> _writeToDisk(String url, Uint8List bytes) async {
    final dir = await _cacheDir();
    if (dir == null) return;
    try {
      await File('${dir.path}/logo.img').writeAsBytes(bytes, flush: true);
      await File('${dir.path}/logo.url').writeAsString(url, flush: true);
    } catch (e) {
      logger.w('Écriture du logo en cache échouée: $e');
    }
  }
}
