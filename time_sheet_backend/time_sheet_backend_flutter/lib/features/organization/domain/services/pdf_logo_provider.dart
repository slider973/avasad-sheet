import 'dart:typed_data';

import '../../../../services/logger_service.dart';
import '../repositories/organization_repository.dart';

/// Fournit le logo à incruster dans l'en-tête des PDF (relevé d'heures et note
/// de frais).
///
/// Source de vérité unique : le logo configuré par un super_admin depuis
/// l'interface web (`/admin/organizations/:id`, bucket `org-logos`, colonne
/// `organizations.logo_url`).
///
/// Retourne `null` quand l'organisation n'a pas de logo, que le téléchargement
/// échoue ou que les octets reçus ne sont pas décodables : l'en-tête est alors
/// rendu sans image. Aucun logo de repli n'est embarqué — un document ne doit
/// jamais porter la marque d'une société qui n'est pas celle de l'employé.
class PdfLogoProvider {
  final OrganizationRepository? organizationRepository;

  const PdfLogoProvider({this.organizationRepository});

  Future<Uint8List?> load() async {
    try {
      final orgLogo = await organizationRepository?.getMyOrganizationLogo();
      if (orgLogo != null && isRasterImage(orgLogo)) {
        return orgLogo;
      }
    } catch (e) {
      logger.w('Logo organisation indisponible, PDF généré sans logo: $e');
    }
    return null;
  }

  /// `pw.MemoryImage` ne décode que le PNG et le JPEG : on vérifie la signature
  /// des octets plutôt que de faire confiance à l'extension du fichier.
  static bool isRasterImage(Uint8List bytes) {
    if (bytes.length < 4) return false;
    final isPng = bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;
    final isJpeg = bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
    return isPng || isJpeg;
  }
}
