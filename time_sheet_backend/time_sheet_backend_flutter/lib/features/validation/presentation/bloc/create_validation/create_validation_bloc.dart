import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:time_sheet/core/error/failures.dart';
import 'package:time_sheet/features/validation/domain/entities/validation_request.dart';
import 'package:time_sheet/features/validation/domain/use_cases/create_validation_request_usecase.dart';
import 'package:time_sheet/features/validation/domain/use_cases/get_available_managers_usecase.dart';
import 'package:time_sheet/features/validation/domain/repositories/validation_repository.dart';
import 'package:time_sheet/features/preference/domain/use_cases/get_user_preference_use_case.dart';
import 'package:time_sheet/features/pointage/domain/entities/generated_pdf.dart';
import 'package:time_sheet/features/pointage/domain/use_cases/get_generated_pdfs_usecase.dart';
import 'dart:io';
import 'package:time_sheet/services/logger_service.dart';
import 'package:time_sheet/features/pointage/domain/use_cases/get_monthly_timesheet_entries_usecase.dart';

part 'create_validation_event.dart';
part 'create_validation_state.dart';

/// BLoC pour créer une demande de validation
class CreateValidationBloc extends Bloc<CreateValidationEvent, CreateValidationState> {
  final CreateValidationRequestUseCase createValidationRequest;
  final GetAvailableManagersUseCase getAvailableManagers;
  final GetUserPreferenceUseCase getUserPreference;
  final GetGeneratedPdfsUseCase getGeneratedPdfs;
  final GetMonthlyTimesheetEntriesUseCase getMonthlyTimesheetEntries;

  CreateValidationBloc({
    required this.createValidationRequest,
    required this.getAvailableManagers,
    required this.getUserPreference,
    required this.getGeneratedPdfs,
    required this.getMonthlyTimesheetEntries,
  }) : super(CreateValidationInitial()) {
    on<LoadManagers>(_onLoadManagers);
    on<SelectManager>(_onSelectManager);
    on<SelectPeriod>(_onSelectPeriod);
    on<SelectGeneratedPdf>(_onSelectGeneratedPdf);
    on<SetPdfData>(_onSetPdfData);
    on<SubmitValidation>(_onSubmitValidation);
    on<ResetForm>(_onResetForm);
  }

  Future<void> _onLoadManagers(
    LoadManagers event,
    Emitter<CreateValidationState> emit,
  ) async {
    emit(CreateValidationLoading());

    try {
      // Récupérer l'ID utilisateur depuis les préférences
      final firstName = await getUserPreference.execute('firstName') ?? '';
      final lastName = await getUserPreference.execute('lastName') ?? '';

      if (firstName.isEmpty || lastName.isEmpty) {
        emit(const CreateValidationError('Veuillez configurer votre nom dans les paramètres'));
        return;
      }

      // Utiliser email comme ID unique
      final userId = '${firstName.toLowerCase()}_${lastName.toLowerCase()}';

      final result = await getAvailableManagers(userId);

      if (result.isLeft()) {
        final failure = result.fold((l) => l, (r) => null);
        emit(CreateValidationError((failure as Failure).message));
        return;
      }

      final managers = result.fold((l) => <Manager>[], (r) => r);

      if (managers.isEmpty) {
        emit(const CreateValidationError('Aucun manager disponible'));
        return;
      }

      // Charger aussi les PDFs disponibles
      final pdfs = await getGeneratedPdfs.execute();
      emit(CreateValidationForm(
        availableManagers: managers,
        availablePdfs: pdfs,
      ));
    } catch (e) {
      emit(CreateValidationError('Erreur inattendue: $e'));
    }
  }

  void _onSelectManager(
    SelectManager event,
    Emitter<CreateValidationState> emit,
  ) {
    if (state is CreateValidationForm) {
      final currentState = state as CreateValidationForm;
      emit(currentState.copyWith(selectedManager: event.manager));
    }
  }

  void _onSelectPeriod(
    SelectPeriod event,
    Emitter<CreateValidationState> emit,
  ) {
    if (state is CreateValidationForm) {
      final currentState = state as CreateValidationForm;

      // Valider les dates
      if (event.endDate.isBefore(event.startDate)) {
        emit(currentState.copyWith(
          error: 'La date de fin doit être après la date de début',
        ));
        return;
      }

      emit(currentState.copyWith(
        periodStart: event.startDate,
        periodEnd: event.endDate,
        error: null,
      ));
    }
  }

  Future<void> _onSelectGeneratedPdf(
    SelectGeneratedPdf event,
    Emitter<CreateValidationState> emit,
  ) async {
    if (state is CreateValidationForm) {
      final currentState = state as CreateValidationForm;

      try {
        // Lire le fichier PDF
        final file = File(event.pdf.filePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();

          // Extraire la période du nom du fichier (format: MonthName_YYYY.pdf)
          final fileName = event.pdf.fileName;
          logger.i('Nom du fichier PDF sélectionné: $fileName');

          // Mapping des noms de mois français vers numéros (accepte majuscules et minuscules)
          final monthMap = {
            'Janvier': 1,
            'janvier': 1,
            'Février': 2,
            'février': 2,
            'Mars': 3,
            'mars': 3,
            'Avril': 4,
            'avril': 4,
            'Mai': 5,
            'mai': 5,
            'Juin': 6,
            'juin': 6,
            'Juillet': 7,
            'juillet': 7,
            'Août': 8,
            'août': 8,
            'Septembre': 9,
            'septembre': 9,
            'Octobre': 10,
            'octobre': 10,
            'Novembre': 11,
            'novembre': 11,
            'Décembre': 12,
            'décembre': 12
          };

          // Regex pour extraire le nom du mois et l'année
          final regex = RegExp(r'(\w+)_(\d{4})\.pdf');
          final match = regex.firstMatch(fileName);

          if (match != null) {
            final monthName = match.group(1)!;
            final year = int.parse(match.group(2)!);
            final month = monthMap[monthName];

            if (month != null) {
              // Règle métier : du 21 du mois précédent au 20 du mois sélectionné
              final startDate = month == 1
                  ? DateTime(year - 1, 12, 21) // Si janvier, prendre décembre de l'année précédente
                  : DateTime(year, month - 1, 21);
              final endDate = DateTime(year, month, 20);

              logger.i('Mois extrait: $monthName -> $month');
              logger.i('Période extraite du nom de fichier: $month/$year');
              logger.i('Date début: $startDate (21 du mois précédent)');
              logger.i('Date fin: $endDate (20 du mois sélectionné)');

              emit(currentState.copyWith(
                selectedPdf: event.pdf,
                periodStart: startDate,
                periodEnd: endDate,
                pdfBytes: bytes,
                pdfFileName: fileName,
                error: null,
              ));
            } else {
              logger.w('Nom de mois non reconnu: $monthName');
              // Utiliser la date de génération comme fallback avec la règle métier
              final month = event.pdf.generatedDate.month;
              final year = event.pdf.generatedDate.year;
              final startDate = month == 1 ? DateTime(year - 1, 12, 21) : DateTime(year, month - 1, 21);
              final endDate = DateTime(year, month, 20);

              emit(currentState.copyWith(
                selectedPdf: event.pdf,
                periodStart: startDate,
                periodEnd: endDate,
                pdfBytes: bytes,
                pdfFileName: fileName,
                error: null,
              ));
            }
          } else {
            // Si on ne peut pas extraire la période, utiliser la date de génération avec la règle métier
            final month = event.pdf.generatedDate.month;
            final year = event.pdf.generatedDate.year;
            final startDate = month == 1 ? DateTime(year - 1, 12, 21) : DateTime(year, month - 1, 21);
            final endDate = DateTime(year, month, 20);

            emit(currentState.copyWith(
              selectedPdf: event.pdf,
              periodStart: startDate,
              periodEnd: endDate,
              pdfBytes: bytes,
              pdfFileName: fileName,
              error: null,
            ));
          }
        } else {
          emit(currentState.copyWith(
            error: 'Le fichier PDF n\'existe plus',
          ));
        }
      } catch (e) {
        emit(currentState.copyWith(
          error: 'Erreur lors de la lecture du PDF: $e',
        ));
      }
    }
  }

  void _onSetPdfData(
    SetPdfData event,
    Emitter<CreateValidationState> emit,
  ) {
    if (state is CreateValidationForm) {
      final currentState = state as CreateValidationForm;
      emit(currentState.copyWith(
        pdfBytes: event.pdfBytes,
        pdfFileName: event.fileName,
      ));
    }
  }

  Future<void> _onSubmitValidation(
    SubmitValidation event,
    Emitter<CreateValidationState> emit,
  ) async {
    if (state is CreateValidationForm) {
      final currentState = state as CreateValidationForm;

      // Valider le formulaire
      if (currentState.selectedManager == null) {
        emit(currentState.copyWith(error: 'Veuillez sélectionner un manager'));
        return;
      }

      if (currentState.selectedPdf == null) {
        emit(currentState.copyWith(error: 'Veuillez sélectionner un PDF'));
        return;
      }

      if (currentState.pdfBytes == null) {
        emit(currentState.copyWith(error: 'Erreur lors de la lecture du PDF'));
        return;
      }

      emit(CreateValidationSubmitting());

      try {
        // Récupérer l'ID utilisateur depuis les préférences
        final firstName = await getUserPreference.execute('firstName') ?? '';
        final lastName = await getUserPreference.execute('lastName') ?? '';
        final company = await getUserPreference.execute('company') ?? '';

        if (firstName.isEmpty || lastName.isEmpty) {
          emit(const CreateValidationError('Veuillez configurer votre nom dans les paramètres'));
          return;
        }

        // Vérifier que l'utilisateur a une signature
        final userSignature = await getUserPreference.execute('signature');
        if (userSignature == null || userSignature.toString().isEmpty) {
          emit(const CreateValidationError(
              'Veuillez configurer votre signature dans les paramètres avant de créer une validation'));
          return;
        }
        logger.i('✅ Signature utilisateur trouvée dans les préférences');

        // Utiliser email comme ID unique
        final userId = '${firstName.toLowerCase()}_${lastName.toLowerCase()}';
        final employeeName = '$firstName $lastName';

        // Récupérer les données timesheet pour la période
        List<Map<String, dynamic>>? timesheetEntries;
        double totalDays = 0.0;
        String totalHours = '0:00';
        String totalOvertimeHours = '0:00';

        logger.i('État actuel - periodStart: ${currentState.periodStart}, periodEnd: ${currentState.periodEnd}');
        logger.i('PDF sélectionné: ${currentState.pdfFileName}');

        if (currentState.periodStart != null && currentState.periodEnd != null) {
          try {
            // Extraire le mois de la période (le mois du 20, qui est le mois sélectionné)
            final month = currentState.periodEnd!.month;

            logger.i('Récupération des entrées timesheet pour le mois $month');

            // Utiliser le use case qui applique automatiquement la règle métier du 21 au 20
            final entries = await getMonthlyTimesheetEntries.execute(month);

            logger.i('Nombre d\'entrées trouvées: ${entries.length}');

            if (entries.isEmpty) {
              logger.w('Aucune entrée timesheet trouvée pour la période');
            } else {
              // Log quelques entrées pour debug
              for (var i = 0; i < 3 && i < entries.length; i++) {
                logger.i(
                    'Entrée $i: date=${entries[i].dayDate}, matin=${entries[i].startMorning}-${entries[i].endMorning}, après-midi=${entries[i].startAfternoon}-${entries[i].endAfternoon}');
              }
            }

            // Convertir en format TimesheetEntryData (Serverpod)
            // Pour l'instant, on garde le format Map<String, dynamic> côté client
            // TODO: Utiliser TimesheetEntryData une fois les modèles régénérés
            timesheetEntries = entries
                .map((entry) => {
                      'dayDate': entry.dayDate, // dayDate est déjà une String au format "dd-MMM-yy"
                      'startMorning': entry.startMorning,
                      'endMorning': entry.endMorning,
                      'startAfternoon': entry.startAfternoon,
                      'endAfternoon': entry.endAfternoon,
                      'isAbsence': entry.absence != null,
                      'absenceType': entry.absence?.type.name ?? '',
                      'absenceMotif': entry.absenceReason ?? '',
                      'absencePeriod': entry.period ?? '',
                      'hasOvertimeHours': entry.hasOvertimeHours,
                      'overtimeHours': entry.hasOvertimeHours
                          ? '${entry.calculateDailyTotal().inHours - 8}:${((entry.calculateDailyTotal().inMinutes - 480) % 60).toString().padLeft(2, '0')}'
                          : null,
                    })
                .toList();

            // Calculer les totaux
            totalDays = entries
                .where((e) => e.absence == null && (e.startMorning.isNotEmpty || e.startAfternoon.isNotEmpty))
                .length
                .toDouble();

            // Calculer total heures
            Duration totalDuration = Duration.zero;
            for (final entry in entries) {
              if (entry.absence == null) {
                totalDuration += entry.calculateDailyTotal();
              }
            }
            totalHours = '${totalDuration.inHours}:${(totalDuration.inMinutes % 60).toString().padLeft(2, '0')}';

            // Calculer heures supplémentaires
            Duration totalOvertimeDuration = Duration.zero;
            for (final entry in entries) {
              if (entry.hasOvertimeHours && entry.absence == null) {
                final dailyTotal = entry.calculateDailyTotal();
                // Considérer les heures au-delà de 8h comme supplémentaires
                if (dailyTotal > const Duration(hours: 8)) {
                  totalOvertimeDuration += dailyTotal - const Duration(hours: 8);
                }
              }
            }
            totalOvertimeHours =
                '${totalOvertimeDuration.inHours}:${(totalOvertimeDuration.inMinutes % 60).toString().padLeft(2, '0')}';
          } catch (e) {
            logger.w('Impossible de récupérer les données timesheet: $e');
            // On continue sans les données timesheet
          }
        }

        logger.i('Création des paramètres de validation:');
        logger.i('- timesheetEntries: ${timesheetEntries?.length ?? 0} entrées');
        logger.i('- totalDays: $totalDays');
        logger.i('- totalHours: $totalHours');
        logger.i('- totalOvertimeHours: $totalOvertimeHours');

        final params = CreateValidationParams(
          employeeId: userId,
          managerId: currentState.selectedManager!.id,
          periodStart: currentState.periodStart!,
          periodEnd: currentState.periodEnd!,
          pdfBytes: currentState.pdfBytes!,
          employeeName: employeeName,
          employeeCompany: company,
          timesheetEntries: timesheetEntries,
          totalDays: totalDays,
          totalHours: totalHours,
          totalOvertimeHours: totalOvertimeHours,
        );

        final result = await createValidationRequest(params);

        result.fold(
          (failure) => emit(CreateValidationError((failure).message)),
          (validation) => emit(CreateValidationSuccess(validation)),
        );
      } catch (e) {
        emit(CreateValidationError('Erreur inattendue: $e'));
      }
    }
  }

  void _onResetForm(
    ResetForm event,
    Emitter<CreateValidationState> emit,
  ) {
    add(LoadManagers());
  }
}
