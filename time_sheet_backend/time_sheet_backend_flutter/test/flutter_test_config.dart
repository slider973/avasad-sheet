import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_sheet/features/preference/domain/repositories/overtime_configuration_repository.dart';
import 'package:time_sheet/features/preference/domain/use_cases/get_user_preference_use_case.dart';
import 'package:time_sheet/features/preference/domain/use_cases/set_user_preference_use_case.dart';

import 'test_utils.dart';

/// Configuration globale des tests (exécutée une fois par fichier de test).
///
/// Depuis la migration Isar -> PowerSync, plusieurs services de prod
/// (TimerService, OvertimeConfigurationService, WeekendDetectionService...)
/// résolvent OvertimeConfigurationRepository via GetIt. En environnement de
/// test, aucune injection n'est faite : on enregistre ici un fake en mémoire
/// pour que ces services fonctionnent sans base de données.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Binding requis par SharedPreferences (WeekendDetectionService, etc.)
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  // Données de locale fr pour DateFormat (PointageHeader, etc.)
  await initializeDateFormatting('fr');
  await initializeDateFormatting('fr_FR');

  final getIt = GetIt.instance;
  if (!getIt.isRegistered<OvertimeConfigurationRepository>()) {
    getIt.registerLazySingleton<OvertimeConfigurationRepository>(
      () => FakeOvertimeConfigurationRepository(),
    );
  }
  if (!getIt.isRegistered<SetUserPreferenceUseCase>()) {
    getIt.registerLazySingleton<SetUserPreferenceUseCase>(
      () => SetUserPreferenceUseCase(FakeUserPreferencesRepository()),
    );
  }
  if (!getIt.isRegistered<GetUserPreferenceUseCase>()) {
    getIt.registerLazySingleton<GetUserPreferenceUseCase>(
      () => GetUserPreferenceUseCase(FakeUserPreferencesRepository()),
    );
  }
  await testMain();
}
