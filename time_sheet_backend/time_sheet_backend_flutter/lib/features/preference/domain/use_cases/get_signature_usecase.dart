import 'dart:convert';
import 'dart:typed_data';

import '../repositories/user_preference_repository.dart';

class GetSignatureUseCase {
  final UserPreferencesRepository repository;

  GetSignatureUseCase(this.repository);

  Future<Uint8List?> execute() async {
    final signatureBase64 = await repository.getPreference('signature');
    if (signatureBase64 != null) {
      return base64Decode(signatureBase64);
    }
    return null;
  }
}