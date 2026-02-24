import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import '../core/auth/auth_repository.dart';
import '../core/auth/auth_repository_impl.dart';
import '../core/database/powersync_database.dart';
import '../core/services/supabase/supabase_service.dart';
import '../features/auth/domain/use_cases/sign_in_usecase.dart';
import '../features/auth/domain/use_cases/sign_up_usecase.dart';
import '../features/auth/domain/use_cases/sign_out_usecase.dart';
import '../features/auth/domain/use_cases/get_current_user_usecase.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/pointage/data/data_sources/local_powersync.dart';
import '../features/pointage/data/data_sources/timesheet_data_source.dart';
import '../features/pointage/data/repositories/anomaly_repository_impl.dart';
import '../features/pointage/data/repositories/anomaly_repository_powersync_impl.dart';
import '../features/pointage/domain/factories/anomaly_detector_factory.dart';
import '../features/pointage/domain/use_cases/delete_timesheet_entry_usecase.dart';
import '../features/pointage/domain/use_cases/detect_anomalies_usecase.dart';
import '../features/pointage/domain/use_cases/find_pointed_list_usecase.dart';
import '../features/pointage/domain/use_cases/generate_monthly_timesheet_usease.dart';
import '../features/pointage/domain/use_cases/generate_pdf_usecase.dart';
import '../features/pointage/domain/use_cases/generate_excel_usecase.dart';
import '../features/pointage/domain/use_cases/get_generated_pdfs_usecase.dart';
import '../features/pointage/domain/use_cases/get_monthly_timesheet_entries_usecase.dart';
import '../features/pointage/domain/use_cases/get_overtime_hours_usecase.dart';
import '../features/pointage/domain/use_cases/get_remaining_vacation_days_usecase.dart';
import '../features/pointage/domain/use_cases/get_today_timesheet_entry_use_case.dart';
import '../features/pointage/domain/use_cases/get_weekly_work_time_usecase.dart';
import '../features/pointage/domain/use_cases/detect_anomalies_with_compensation_usecase.dart';
import '../features/pointage/domain/use_cases/save_timesheet_entry_usecase.dart';
import '../features/pointage/domain/use_cases/signaler_absence_periode_usecase.dart';
import '../features/preference/data/repositories/user_preference_repository_powersync_impl.dart';
import '../features/preference/data/repositories/overtime_configuration_repository_powersync_impl.dart';
import '../features/preference/domain/repositories/overtime_configuration_repository.dart';
import '../features/preference/domain/repositories/user_preference_repository.dart';
import 'anomaly/anomaly_service_powersync.dart';
import 'watch_service.dart';
import 'clock_reminder_service.dart';
import 'overtime_configuration_service.dart';
import 'weekend_overtime_calculator.dart';
import 'weekend_detection_service.dart';
import 'timer_service.dart';
import '../features/preference/domain/use_cases/get_signature_usecase.dart';
import '../features/preference/domain/use_cases/get_user_preference_use_case.dart';
import '../features/preference/domain/use_cases/set_user_preference_use_case.dart';
import '../features/preference/domain/use_cases/register_manager_use_case.dart';
import '../features/preference/domain/use_cases/unregister_manager_use_case.dart';
import '../features/pointage/data/repositories/timesheet_repository_impl.dart';
import '../features/pointage/domain/repositories/timesheet_repository.dart';
import '../features/pointage/domain/services/anomaly_detection_service.dart';
import '../features/pointage/domain/use_cases/toggle_overtime_hours_use_case.dart';
import '../features/pointage/domain/use_cases/calculate_overtime_hours_use_case.dart';
import '../features/pointage/domain/use_cases/get_days_with_overtime_use_case.dart';
import '../features/validation/domain/use_cases/create_validation_request_usecase.dart';
import '../features/validation/domain/use_cases/approve_validation_usecase.dart';
import '../features/validation/domain/use_cases/reject_validation_usecase.dart';
import '../features/validation/domain/use_cases/get_employee_validations_usecase.dart';
import '../features/validation/domain/use_cases/get_manager_validations_usecase.dart';
import '../features/validation/domain/use_cases/download_validation_pdf_usecase.dart';
import '../features/validation/domain/use_cases/get_available_managers_usecase.dart';
import '../features/validation/domain/use_cases/get_validation_timesheet_data_usecase.dart';
import '../features/validation/domain/use_cases/get_signing_url_usecase.dart';
import '../features/validation/data/repositories/validation_repository_supabase_impl.dart';
import '../features/validation/presentation/bloc/validation_list/validation_list_bloc.dart';
import '../features/validation/presentation/bloc/create_validation/create_validation_bloc.dart';
import '../features/validation/presentation/bloc/validation_detail/validation_detail_bloc.dart';
import '../features/validation/domain/repositories/validation_repository.dart';
import '../features/expense/data/data_sources/expense_data_source.dart';
import '../features/expense/data/data_sources/expense_powersync_data_source.dart';
import '../features/expense/data/repositories/expense_repository_impl.dart';
import '../features/expense/domain/repositories/expense_repository.dart';
import '../features/expense/domain/use_cases/create_expense_usecase.dart';
import '../features/expense/domain/use_cases/get_expenses_usecase.dart';
import '../features/expense/domain/use_cases/update_expense_usecase.dart';
import '../features/expense/domain/use_cases/delete_expense_usecase.dart';
import '../features/expense/domain/use_cases/calculate_mileage_usecase.dart';
import '../features/expense/domain/use_cases/get_monthly_report_usecase.dart';
import '../features/expense/domain/use_cases/generate_expense_pdf_usecase.dart';
import '../features/expense/presentation/bloc/expense_list/expense_list_bloc.dart';
import '../features/manager/presentation/bloc/manager_dashboard_bloc.dart';
final getIt = GetIt.instance;

Future<void> setup() async {
  final db = PowerSyncDatabaseManager.database;

  // Enregistrer le Logger
  getIt.registerLazySingleton<Logger>(() => Logger());

  // ============ AUTHENTICATION ============
  final supabaseClient = SupabaseService.instance.client;

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(supabaseClient: supabaseClient),
  );

  getIt.registerLazySingleton<SignInUseCase>(
    () => SignInUseCase(getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton<SignUpUseCase>(
    () => SignUpUseCase(getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton<SignOutUseCase>(
    () => SignOutUseCase(getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton<GetCurrentUserUseCase>(
    () => GetCurrentUserUseCase(getIt<AuthRepository>()),
  );

  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: getIt<AuthRepository>()),
  );

  // ============ DATA SOURCES (PowerSync) ============

  getIt.registerLazySingleton<LocalDataSource>(
      () => LocalDatasourcePowerSyncImpl(db));

  // ============ USER PREFERENCES (local-only SQLite table) ============

  final userPrefsRepo = UserPreferencesRepositoryPowerSyncImpl(db);
  await userPrefsRepo.initialize();
  getIt.registerLazySingleton<UserPreferencesRepository>(() => userPrefsRepo);

  // ============ OVERTIME CONFIGURATION ============

  getIt.registerLazySingleton<OvertimeConfigurationRepository>(
      () => OvertimeConfigurationRepositoryPowerSyncImpl(db));

  // ============ TIMESHEET ============

  getIt.registerLazySingleton<TimesheetRepositoryImpl>(
      () => TimesheetRepositoryImpl(getIt<LocalDataSource>()));
  getIt.registerLazySingleton<TimesheetRepository>(
      () => getIt<TimesheetRepositoryImpl>());
  getIt.registerLazySingleton<SaveTimesheetEntryUseCase>(
      () => SaveTimesheetEntryUseCase(getIt<TimesheetRepositoryImpl>()));
  getIt.registerLazySingleton<DeleteTimesheetEntryUsecase>(
      () => DeleteTimesheetEntryUsecase(getIt<TimesheetRepositoryImpl>()));
  getIt.registerLazySingleton<FindPointedListUseCase>(
      () => FindPointedListUseCase(getIt<TimesheetRepositoryImpl>()));
  getIt.registerLazySingleton<GetUserPreferenceUseCase>(
      () => GetUserPreferenceUseCase(getIt<UserPreferencesRepository>()));
  getIt.registerLazySingleton<SetUserPreferenceUseCase>(
      () => SetUserPreferenceUseCase(getIt<UserPreferencesRepository>()));
  getIt.registerLazySingleton<GetSignatureUseCase>(
      () => GetSignatureUseCase(getIt<UserPreferencesRepository>()));

  // Use cases pour la gestion des managers dans Supabase
  getIt.registerLazySingleton<RegisterManagerUseCase>(
      () => RegisterManagerUseCase());
  getIt.registerLazySingleton<UnregisterManagerUseCase>(
      () => UnregisterManagerUseCase());
  getIt.registerLazySingleton<GetTodayTimesheetEntryUseCase>(
      () => GetTodayTimesheetEntryUseCase(getIt<TimesheetRepositoryImpl>()));
  getIt.registerLazySingleton<SignalerAbsencePeriodeUsecase>(() =>
      SignalerAbsencePeriodeUsecase(
        getTodayTimesheetEntryUseCase: getIt<GetTodayTimesheetEntryUseCase>(),
        saveTimesheetEntryUseCase: getIt<SaveTimesheetEntryUseCase>(),
      ));
  getIt.registerLazySingleton<GenerateMonthlyTimesheetUseCase>(
      () => GenerateMonthlyTimesheetUseCase(getIt<TimesheetRepositoryImpl>()));
  getIt.registerLazySingleton<GetRemainingVacationDaysUseCase>(
      () => GetRemainingVacationDaysUseCase(getIt<TimesheetRepositoryImpl>()));
  getIt.registerLazySingleton<GetMonthlyTimesheetEntriesUseCase>(() =>
      GetMonthlyTimesheetEntriesUseCase(getIt<TimesheetRepositoryImpl>()));
  getIt.registerLazySingleton<GetWeeklyWorkTimeUseCase>(
      () => GetWeeklyWorkTimeUseCase(getIt<TimesheetRepositoryImpl>()));
  getIt.registerLazySingleton<GetOvertimeHoursUseCase>(
      () => GetOvertimeHoursUseCase());
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
    () => CalculateOvertimeHoursUseCase(
      configRepository: getIt<OvertimeConfigurationRepository>(),
    ),
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
        configRepository: getIt<OvertimeConfigurationRepository>(),
      ));
  getIt.registerLazySingleton<GenerateExcelUseCase>(
      () => GenerateExcelUseCase(getIt<TimesheetRepositoryImpl>()));
  getIt.registerLazySingleton<GetGeneratedPdfsUseCase>(
      () => GetGeneratedPdfsUseCase(getIt<TimesheetRepositoryImpl>()));

  // ============ ANOMALY ============

  getIt.registerLazySingleton<AnomalyRepository>(
      () => AnomalyRepositoryPowerSyncImpl(db));

  final anomalyService = AnomalyServicePowerSync(db);
  getIt.registerSingleton<AnomalyServicePowerSync>(anomalyService);

  // Enregistrer le nouveau service de détection d'anomalies
  getIt.registerLazySingleton<AnomalyDetectionService>(
      () => AnomalyDetectionService());

  // Enregistrer le use case de détection avec compensation
  getIt.registerLazySingleton<DetectAnomaliesWithCompensationUseCase>(
    () => DetectAnomaliesWithCompensationUseCase(
      getIt<TimesheetRepositoryImpl>(),
      AnomalyDetectorFactory.getAllDetectors().values.toList(),
      AnomalyDetectorFactory.getWeeklyCompensationDetector(),
    ),
  );

  // ============ SERVICES ============

  // Enregistrer le service Watch
  getIt.registerLazySingleton<WatchService>(() => WatchService());

  // Enregistrer le service de configuration des heures supplémentaires
  getIt.registerLazySingleton<OvertimeConfigurationService>(
      () => OvertimeConfigurationService());

  // Enregistrer le service de détection des weekends
  getIt.registerLazySingleton<WeekendDetectionService>(
      () => WeekendDetectionService());

  // Enregistrer le calculateur d'heures supplémentaires weekend
  getIt.registerLazySingleton<WeekendOvertimeCalculator>(
      () => WeekendOvertimeCalculator(
            weekendDetectionService: getIt<WeekendDetectionService>(),
          ));

  // Enregistrer le TimerService comme singleton
  if (!getIt.isRegistered<TimerService>()) {
    getIt.registerLazySingleton<TimerService>(() => TimerService());
  }

  // Enregistrer le service de rappels d'horloge
  getIt.registerLazySingleton<ClockReminderService>(
      () => ClockReminderService());

  // Créer les anomalies pour le mois courant (en arrière-plan, non bloquant)
  anomalyService.createAnomaliesForCurrentMonth();

  // Initialiser le service Watch
  await getIt<WatchService>().initialize();

  // Initialiser le service de rappels d'horloge avec TimerService
  await getIt<ClockReminderService>().initialize(
    timerService: getIt<TimerService>(),
  );

  // ============ VALIDATION ============

  getIt.registerLazySingleton<ValidationRepository>(
    () => ValidationRepositorySupabaseImpl(),
  );

  // Enregistrer les use cases de validation
  getIt.registerLazySingleton<CreateValidationRequestUseCase>(
    () => CreateValidationRequestUseCase(getIt<ValidationRepository>()),
  );

  getIt.registerLazySingleton<ApproveValidationUseCase>(
    () => ApproveValidationUseCase(
      getIt<ValidationRepository>(),
      getIt<GetUserPreferenceUseCase>(),
    ),
  );

  getIt.registerLazySingleton<RejectValidationUseCase>(
    () => RejectValidationUseCase(getIt<ValidationRepository>()),
  );

  getIt.registerLazySingleton<GetEmployeeValidationsUseCase>(
    () => GetEmployeeValidationsUseCase(getIt<ValidationRepository>()),
  );

  getIt.registerLazySingleton<GetManagerValidationsUseCase>(
    () => GetManagerValidationsUseCase(getIt<ValidationRepository>()),
  );

  getIt.registerLazySingleton<DownloadValidationPdfUseCase>(
    () => DownloadValidationPdfUseCase(
      getIt<ValidationRepository>(),
      getIt<GeneratePdfUseCase>(),
      getIt<GetSignatureUseCase>(),
      getIt<GetUserPreferenceUseCase>(),
    ),
  );

  getIt.registerLazySingleton<GetAvailableManagersUseCase>(
    () => GetAvailableManagersUseCase(getIt<ValidationRepository>()),
  );

  getIt.registerLazySingleton<GetValidationTimesheetDataUseCase>(
    () => GetValidationTimesheetDataUseCase(getIt<ValidationRepository>()),
  );

  getIt.registerLazySingleton<GetSigningUrlUseCase>(
    () => GetSigningUrlUseCase(getIt<ValidationRepository>()),
  );

  // Enregistrer les BLoCs de validation
  getIt.registerFactory<ValidationListBloc>(
    () => ValidationListBloc(
      getEmployeeValidations: getIt<GetEmployeeValidationsUseCase>(),
      getManagerValidations: getIt<GetManagerValidationsUseCase>(),
    ),
  );

  getIt.registerFactory<CreateValidationBloc>(
    () => CreateValidationBloc(
      createValidationRequest: getIt<CreateValidationRequestUseCase>(),
      getAvailableManagers: getIt<GetAvailableManagersUseCase>(),
      getUserPreference: getIt<GetUserPreferenceUseCase>(),
      getGeneratedPdfs: getIt<GetGeneratedPdfsUseCase>(),
      getMonthlyTimesheetEntries: getIt<GetMonthlyTimesheetEntriesUseCase>(),
    ),
  );

  getIt.registerFactory<ValidationDetailBloc>(
    () => ValidationDetailBloc(
      repository: getIt<ValidationRepository>(),
      approveValidation: getIt<ApproveValidationUseCase>(),
      rejectValidation: getIt<RejectValidationUseCase>(),
      downloadPdf: getIt<DownloadValidationPdfUseCase>(),
      getTimesheetData: getIt<GetValidationTimesheetDataUseCase>(),
      getSigningUrl: getIt<GetSigningUrlUseCase>(),
    ),
  );

  // ============ EXPENSE MANAGEMENT ============

  // Data sources
  getIt.registerLazySingleton<ExpenseDataSource>(
    () => ExpensePowerSyncDataSource(db: db),
  );

  // Repositories
  getIt.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepositoryImpl(
      localDataSource: getIt<ExpenseDataSource>(),
    ),
  );

  // Use cases
  getIt.registerLazySingleton<CreateExpenseUseCase>(
    () => CreateExpenseUseCase(repository: getIt<ExpenseRepository>()),
  );

  getIt.registerLazySingleton<GetExpensesUseCase>(
    () => GetExpensesUseCase(repository: getIt<ExpenseRepository>()),
  );

  getIt.registerLazySingleton<UpdateExpenseUseCase>(
    () => UpdateExpenseUseCase(repository: getIt<ExpenseRepository>()),
  );

  getIt.registerLazySingleton<DeleteExpenseUseCase>(
    () => DeleteExpenseUseCase(repository: getIt<ExpenseRepository>()),
  );

  getIt.registerLazySingleton<CalculateMileageUseCase>(
    () => CalculateMileageUseCase(),
  );

  getIt.registerLazySingleton<GetMonthlyReportUseCase>(
    () => GetMonthlyReportUseCase(repository: getIt<ExpenseRepository>()),
  );

  getIt.registerLazySingleton<GenerateExpensePdfUseCase>(
    () => GenerateExpensePdfUseCase(
      repository: getIt<ExpenseRepository>(),
      getSignatureUseCase: getIt<GetSignatureUseCase>(),
      getUserPreferenceUseCase: getIt<GetUserPreferenceUseCase>(),
    ),
  );

  // BLoCs
  getIt.registerFactory<ExpenseListBloc>(
    () => ExpenseListBloc(
      getMonthlyReport: getIt<GetMonthlyReportUseCase>(),
      deleteExpense: getIt<DeleteExpenseUseCase>(),
    ),
  );

  // ============ MANAGER DASHBOARD ============
  getIt.registerFactory<ManagerDashboardBloc>(
    () => ManagerDashboardBloc(),
  );
}
