import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/organization/domain/entities/organization_settings.dart';
import 'package:time_sheet/features/organization/domain/repositories/organization_repository.dart';
import 'package:time_sheet/features/organization/domain/services/pdf_logo_provider.dart';

/// Repository de test : renvoie les octets fournis, ou lève si [throws].
class _FakeOrganizationRepository implements OrganizationRepository {
  final Uint8List? logo;
  final bool throws;

  _FakeOrganizationRepository({this.logo, this.throws = false});

  @override
  Future<OrganizationSettings?> getMyOrganization() async => null;

  @override
  Future<Uint8List?> getMyOrganizationLogo() async {
    if (throws) throw Exception('réseau indisponible');
    return logo;
  }
}

/// En-tête PNG minimal (signature de 8 octets + un peu de charge utile).
Uint8List _pngBytes() => Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x01,
    ]);

Uint8List _jpegBytes() => Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfLogoProvider.isRasterImage', () {
    test('accepte le PNG et le JPEG', () {
      expect(PdfLogoProvider.isRasterImage(_pngBytes()), isTrue);
      expect(PdfLogoProvider.isRasterImage(_jpegBytes()), isTrue);
    });

    test('refuse un SVG, un contenu vide ou trop court', () {
      final svg = Uint8List.fromList('<svg xmlns='.codeUnits);
      expect(PdfLogoProvider.isRasterImage(svg), isFalse);
      expect(PdfLogoProvider.isRasterImage(Uint8List(0)), isFalse);
      expect(PdfLogoProvider.isRasterImage(Uint8List.fromList([0x89])), isFalse);
    });
  });

  group('PdfLogoProvider.load', () {
    test('utilise le logo de l\'organisation quand il est exploitable',
        () async {
      final logo = _pngBytes();
      final provider = PdfLogoProvider(
        organizationRepository: _FakeOrganizationRepository(logo: logo),
      );

      expect(await provider.load(), equals(logo));
    });

    test('ne renvoie aucun logo quand l\'organisation n\'en a pas', () async {
      final provider = PdfLogoProvider(
        organizationRepository: _FakeOrganizationRepository(logo: null),
      );

      expect(await provider.load(), isNull);
    });

    test('ne renvoie aucun logo si les octets ne sont pas décodables',
        () async {
      final provider = PdfLogoProvider(
        organizationRepository: _FakeOrganizationRepository(
          logo: Uint8List.fromList('<svg xmlns='.codeUnits),
        ),
      );

      expect(await provider.load(), isNull);
    });

    test('ne renvoie aucun logo si la récupération échoue', () async {
      final provider = PdfLogoProvider(
        organizationRepository: _FakeOrganizationRepository(throws: true),
      );

      expect(await provider.load(), isNull);
    });

    test('ne renvoie aucun logo sans repository', () async {
      const provider = PdfLogoProvider();

      expect(await provider.load(), isNull);
    });
  });
}
