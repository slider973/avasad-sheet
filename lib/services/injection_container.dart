import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../features/pointage/domain/use_cases/delete_timesheet_entry_usecase.dart';
import '../features/pointage/domain/use_cases/generate_monthly_timesheet_usease.dart';
import '../features/pointage/domain/use_cases/get_overtime_hours_usecase.dart';
import '../features/pointage/domain/use_cases/get_remaining_vacation_days_usecase.dart';
import '../features/pointage/domain/use_cases/get_weekly_work_time_usecase.dart';
import '../features/preference/data/models/user_preference.dart';
import '../features/preference/data/repositories/user_preference_repository.impl.dart';
import '../features/preference/domain/use_cases/get_signature_usecase.dart';
import '../features/preference/domain/use_cases/get_user_preference_use_case.dart';
import '../features/preference/domain/use_cases/set_user_preference_use_case.dart';
import '../features/pointage/data/data_sources/local.dart';
import '../features/pointage/data/data_sources/test_data_inserter.dart';
import '../features/pointage/data/models/generated_pdf/generated_pdf.dart';
import '../features/pointage/data/models/timesheet_entry/timesheet_entry.dart';
import '../features/pointage/data/repositories/timesheet_repository_impl.dart';
import '../features/pointage/domain/use_cases/find_pointed_list_usecase.dart';
import '../features/pointage/domain/use_cases/get_today_timesheet_entry_use_case.dart';
import '../features/pointage/domain/use_cases/save_timesheet_entry_usecase.dart';

final getIt = GetIt.instance;
Future<String> getInstallationPath() async {
  if (Platform.isWindows) {
    String localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
    String configDir = path.join(localAppData, 'TimeSheet');
    String configPath = path.join(configDir, 'config.txt');

    Directory(configDir).createSync(recursive: true);

    if (File(configPath).existsSync()) {
      String installPath = await File(configPath).readAsString();
      return path.join(installPath, 'Database');
    } else {
      // L'application est lancée pour la première fois, on utilise le chemin d'exécution
      String exePath = Platform.resolvedExecutable;
      String installDir = path.dirname(exePath);
      await File(configPath).writeAsString(installDir);
      return path.join(installDir, 'Database');
    }
  } else {
    // Pour les autres plateformes, utilisez le dossier de documents par défaut
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }
}

Future<void> setup() async {
  final dir = await getInstallationPath();
  Directory(dir).createSync(recursive: true);
  final isar = await Isar.open(
    [TimeSheetEntryModelSchema, GeneratedPdfModelSchema, UserPreferencesSchema],
    directory: dir,
  );
  // a decommenter pour insérer des données de test

  //TestDataInserter(isar).insertTestData();

  getIt.registerSingleton<Isar>(isar);
  getIt.registerLazySingleton<LocalDatasourceImpl>(() => LocalDatasourceImpl(getIt<Isar>()));
  getIt.registerLazySingleton<UserPreferencesRepositoryImpl>(() => UserPreferencesRepositoryImpl(getIt<Isar>()));
  getIt.registerLazySingleton<TimesheetRepositoryImpl>(() => TimesheetRepositoryImpl(getIt<LocalDatasourceImpl>()));
  getIt.registerLazySingleton<SaveTimesheetEntryUseCase>(() => SaveTimesheetEntryUseCase(getIt<TimesheetRepositoryImpl>()));
  getIt.registerLazySingleton<DeleteTimesheetEntryUsecase>(() => DeleteTimesheetEntryUsecase(getIt<TimesheetRepositoryImpl>()));
  getIt.registerLazySingleton<FindPointedListUseCase>(() => FindPointedListUseCase(getIt<TimesheetRepositoryImpl>()));
  getIt.registerLazySingleton<GetUserPreferenceUseCase>(() => GetUserPreferenceUseCase(getIt<UserPreferencesRepositoryImpl>()));
  getIt.registerLazySingleton<SetUserPreferenceUseCase>(() => SetUserPreferenceUseCase(getIt<UserPreferencesRepositoryImpl>()));
  getIt.registerLazySingleton<GetSignatureUseCase>(() => GetSignatureUseCase(getIt<UserPreferencesRepositoryImpl>()));
  getIt.registerLazySingleton<GetTodayTimesheetEntryUseCase>(() => GetTodayTimesheetEntryUseCase(getIt<TimesheetRepositoryImpl>()));
  getIt.registerLazySingleton<GenerateMonthlyTimesheetUseCase>(() => GenerateMonthlyTimesheetUseCase(getIt<TimesheetRepositoryImpl>()));
  getIt.registerLazySingleton<GetRemainingVacationDaysUseCase>(() => GetRemainingVacationDaysUseCase(getIt<TimesheetRepositoryImpl>()));
  getIt.registerLazySingleton<GetWeeklyWorkTimeUseCase>(() => GetWeeklyWorkTimeUseCase(getIt<TimesheetRepositoryImpl>()));
  getIt.registerLazySingleton<GetOvertimeHoursUseCase>(() => GetOvertimeHoursUseCase());
}
