import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:time_sheet/features/preference/domain/use_cases/get_user_preference_use_case.dart';
import 'package:time_sheet/features/preference/domain/use_cases/register_manager_use_case.dart';
import 'package:time_sheet/features/preference/domain/use_cases/set_user_preference_use_case.dart';
import 'package:time_sheet/features/preference/domain/use_cases/unregister_manager_use_case.dart';
import 'package:time_sheet/features/preference/presentation/manager/preferences_bloc.dart';

import '../../test_utils.dart';

class _FakeRegisterManagerUseCase extends Fake
    implements RegisterManagerUseCase {}

class _FakeUnregisterManagerUseCase extends Fake
    implements UnregisterManagerUseCase {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Time Sheet',
      packageName: 'com.jonathanlemaine.timeSheet',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
      installerStore: null,
    );
  });

  Future<(PreferencesBloc, FakeUserPreferencesRepository)> buildBloc({
    String? clientSignerName,
  }) async {
    final repository = FakeUserPreferencesRepository();
    // Préférences complètes pour éviter la récupération Supabase
    // (chemin `needsRecovery` de _onLoadPreferences).
    await repository.setPreference('firstName', 'Jonathan');
    await repository.setPreference('lastName', 'Lemaine');
    await repository.setPreference('company', 'Avasad');
    await repository.setPreference(
        'signature', base64Encode(Uint8List.fromList([1, 2, 3])));
    if (clientSignerName != null) {
      await repository.setPreference('clientSignerName', clientSignerName);
    }

    final bloc = PreferencesBloc(
      getUserPreferenceUseCase: GetUserPreferenceUseCase(repository),
      setUserPreferenceUseCase: SetUserPreferenceUseCase(repository),
      registerManagerUseCase: _FakeRegisterManagerUseCase(),
      unregisterManagerUseCase: _FakeUnregisterManagerUseCase(),
      userPreferencesRepository: repository,
    );
    return (bloc, repository);
  }

  group('PreferencesBloc - clientSignerName', () {
    test('LoadPreferences expose la préférence clientSignerName', () async {
      final (bloc, _) = await buildBloc(clientSignerName: 'Jane Doe');

      bloc.add(LoadPreferences());
      final state =
          await bloc.stream.firstWhere((s) => s is PreferencesLoaded);

      expect((state as PreferencesLoaded).clientSignerName, 'Jane Doe');
      await bloc.close();
    });

    test('LoadPreferences retourne une chaîne vide sans préférence', () async {
      final (bloc, _) = await buildBloc();

      bloc.add(LoadPreferences());
      final state =
          await bloc.stream.firstWhere((s) => s is PreferencesLoaded);

      expect((state as PreferencesLoaded).clientSignerName, '');
      await bloc.close();
    });

    test('SavePreferences persiste clientSignerName et met à jour l\'état',
        () async {
      final (bloc, repository) = await buildBloc();

      bloc.add(SavePreferences(
        firstName: 'Jonathan',
        lastName: 'Lemaine',
        company: 'Avasad',
        clientSignerName: 'Nouveau Signataire',
      ));
      final state =
          await bloc.stream.firstWhere((s) => s is PreferencesLoaded);

      expect((state as PreferencesLoaded).clientSignerName,
          'Nouveau Signataire');
      expect(await repository.getPreference('clientSignerName'),
          'Nouveau Signataire');
      await bloc.close();
    });

    test(
        'SavePreferences sans clientSignerName ne modifie pas la valeur enregistrée',
        () async {
      final (bloc, repository) =
          await buildBloc(clientSignerName: 'Signataire Existant');

      bloc.add(SavePreferences(
        firstName: 'Jonathan',
        lastName: 'Lemaine',
        company: 'Avasad',
      ));
      await bloc.stream.firstWhere((s) => s is PreferencesLoaded);

      expect(await repository.getPreference('clientSignerName'),
          'Signataire Existant');
      await bloc.close();
    });
  });
}
