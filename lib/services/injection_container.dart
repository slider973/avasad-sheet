import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:time_sheet/features/pointage/data/models/anomalies/anomalies.dart';

import '../features/absence/data/models/absence.dart';
import '../features/pointage/data/repositories/anomaly_repository_impl.dart';
import '../features/pointage/domain/factories/anomaly_detector_factory.dart';
import '../features/pointage/domain/use_cases/delete_timesheet_entry_usecase.dart';
import '../features/pointage/domain/use_cases/detect_anomalies_usecase.dart';
import '../features/pointage/domain/use_cases/find_pointed_list_usecase.dart';
import '../features/pointage/domain/use_cases/generate_monthly_timesheet_usease.dart';
import '../features/pointage/domain/use_cases/generate_pdf_usecase.dart';
import '../features/pointage/domain/use_cases/generate_excel_usecase.dart';
import '../features/pointage/domain/use_cases/get_monthly_timesheet_entries_usecase.dart';
import '../features/pointage/domain/use_cases/get_overtime_hours_usecase.dart';
import '../features/pointage/domain/use_cases/get_remaining_vacation_days_usecase.dart';
import '../features/pointage/domain/use_cases/get_today_timesheet_entry_use_case.dart';
import '../features/pointage/domain/use_cases/get_weekly_work_time_usecase.dart';
import '../features/pointage/domain/use_cases/insufficient_hours_detector.dart';
import '../features/pointage/domain/use_cases/detect_anomalies_with_compensation_usecase.dart';
import '../features/pointage/domain/use_cases/save_timesheet_entry_usecase.dart';
import '../features/pointage/domain/use_cases/signaler_absence_periode_usecase.dart';
import '../features/preference/data/models/user_preference.dart';
import '../features/preference/data/repositories/user_preference_repository.impl.dart';
import '../features/preference/presentation/manager/preferences_bloc.dart';
import 'anomaly/anomaly_service.dart';
import 'backup.dart';
import 'watch_service.dart';
import '../features/preference/domain/use_cases/get_signature_usecase.dart';
import '../features/preference/domain/use_cases/get_user_preference_use_case.dart';
import '../features/preference/domain/use_cases/set_user_preference_use_case.dart';
import '../features/pointage/data/data_sources/local.dart';
import '../features/pointage/data/models/generated_pdf/generated_pdf.dart';
import '../features/pointage/data/models/timesheet_entry/timesheet_entry.dart';
import '../features/pointage/data/repositories/timesheet_repository_impl.dart';
import '../features/pointage/domain/services/anomaly_detection_service.dart';
import '../features/pointage/domain/use_cases/toggle_overtime_hours_use_case.dart';
import '../features/pointage/domain/use_cases/calculate_overtime_hours_use_case.dart';
import '../features/pointage/domain/use_cases/get_days_with_overtime_use_case.dart';


final getIt = GetIt.instance;
Future<String> getInstallationPath() async {
  if (Platform.isWindows) {
    String localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
    String configDir = path.join(localAppData, 'TimeSheet');
    String configPath = path.join(configDir, 'config.txt');
    String databaseDir = path.join(configDir, 'Database');

    if (await Directory(configDir).exists()) {
      // Le répertoire de configuration existe déjà
      return databaseDir;
    } else {
      // Première exécution de l'application
      String exePath = Platform.resolvedExecutable;
      String installDir = path.dirname(exePath);

      // Créer le répertoire de configuration
      await Directory(configDir).create(recursive: true);

      // Écrire le chemin d'installation dans le fichier de configuration
      await File(configPath).writeAsString(installDir);

      // Créer le répertoire de la base de données
      await Directory(databaseDir).create();
      return databaseDir;
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
  // Fonction pour obtenir l'instance Isar
  Future<Isar> getIsarInstance() async {
    if (!getIt.isRegistered<Isar>()) {
      final isar = await Isar.open(
        [TimeSheetEntryModelSchema, GeneratedPdfModelSchema, UserPreferencesSchema, AbsenceSchema, AnomalyModelSchema],
        directory: dir,
      );
      getIt.registerSingleton<Isar>(isar);
    }
    return getIt<Isar>();
  }

  // Fonction pour fermer l'instance Isar
  Future<void> closeIsarInstance() async {
    if (getIt.isRegistered<Isar>()) {
      final isar = getIt<Isar>();
      await isar.close();
      getIt.unregister<Isar>();
    }
  }

  // Fonction pour rouvrir l'instance Isar
  Future<Isar> reopenIsarInstance() async {
    await closeIsarInstance();
    return await getIsarInstance();
  }

  // Enregistrer le BackupService avec les nouvelles fonctions
  getIt.registerLazySingleton<BackupService>(() => BackupService(
    getIsarInstance: getIsarInstance,
    closeIsarInstance: closeIsarInstance,
    reopenIsarInstance: reopenIsarInstance,
  ));


  // Initialiser l'instance Isar
  await getIsarInstance();
  
  // Enregistrer le Logger
  getIt.registerLazySingleton<Logger>(() => Logger());
  
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
  getIt.registerLazySingleton<SignalerAbsencePeriodeUsecase>(() => SignalerAbsencePeriodeUsecase(
    getTodayTimesheetEntryUseCase: getIt<GetTodayTimesheetEntryUseCase>(),
    saveTimesheetEntryUseCase: getIt<SaveTimesheetEntryUseCase>(),
  ));
  getIt.registerLazySingleton<GenerateMonthlyTimesheetUseCase>(() => GenerateMonthlyTimesheetUseCase(getIt<TimesheetRepositoryImpl>()));
  getIt.registerLazySingleton<GetRemainingVacationDaysUseCase>(() => GetRemainingVacationDaysUseCase(getIt<TimesheetRepositoryImpl>()));
  getIt.registerLazySingleton<GetMonthlyTimesheetEntriesUseCase>(() => GetMonthlyTimesheetEntriesUseCase(getIt<TimesheetRepositoryImpl>()));
  getIt.registerLazySingleton<GetWeeklyWorkTimeUseCase>(() => GetWeeklyWorkTimeUseCase(getIt<TimesheetRepositoryImpl>()));
  getIt.registerLazySingleton<GetOvertimeHoursUseCase>(() => GetOvertimeHoursUseCase());
  getIt.registerLazySingleton<DetectAnomaliesUseCase>(() {
    final allDetectors = AnomalyDetectorFactory.getAllDetectors();
    return DetectAnomaliesUseCase(
      getIt<TimesheetRepositoryImpl>(),
      allDetectors.values.toList(),
    );
  });
  // Enregistrer les nouveaux use cases pour les heures supplémentaires
  getIt.registerLazySingleton<ToggleOvertimeHoursUseCase>(
    () => ToggleOvertimeHoursUseCase(getIt<TimesheetRepositoryImpl>()),
  );
  
  getIt.registerLazySingleton<CalculateOvertimeHoursUseCase>(
    () => CalculateOvertimeHoursUseCase(),
  );
  
  getIt.registerLazySingleton<GetDaysWithOvertimeUseCase>(
    () => GetDaysWithOvertimeUseCase(getIt<TimesheetRepositoryImpl>()),
  );

  getIt.registerLazySingleton<GeneratePdfUseCase>(() => GeneratePdfUseCase(
    repository: getIt<TimesheetRepositoryImpl>(),
    getSignatureUseCase: getIt<GetSignatureUseCase>(),
    getUserPreferenceUseCase: getIt<GetUserPreferenceUseCase>(),
    anomalyDetectionService: getIt<AnomalyDetectionService>(),
    calculateOvertimeHoursUseCase: getIt<CalculateOvertimeHoursUseCase>(),
  ));
  getIt.registerLazySingleton<GenerateExcelUseCase>(() => GenerateExcelUseCase(getIt<TimesheetRepositoryImpl>()));
  getIt.registerLazySingleton<AnomalyRepository>(
          () => AnomalyRepositoryImpl(getIt<Isar>())
  );

  // Enregistrez AnomalyService
  final anomalyService = AnomalyService(getIt<Isar>());
  GetIt.instance.registerSingleton<AnomalyService>(anomalyService);
  
  // Enregistrer le nouveau service de détection d'anomalies
  getIt.registerLazySingleton<AnomalyDetectionService>(() => AnomalyDetectionService());
  
  // Enregistrer le use case de détection avec compensation
  getIt.registerLazySingleton<DetectAnomaliesWithCompensationUseCase>(
    () => DetectAnomaliesWithCompensationUseCase(
      getIt<TimesheetRepositoryImpl>(),
      AnomalyDetectorFactory.getAllDetectors().values.toList(),
      AnomalyDetectorFactory.getWeeklyCompensationDetector(),
    ),
  );
  
  // Enregistrer le service Watch
  getIt.registerLazySingleton<WatchService>(() => WatchService());

  // Initialisez le service des anomalies
  await anomalyService.createAnomaliesForCurrentMonth();
  
  // Initialiser le service Watch
  await getIt<WatchService>().initialize();



}
