import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

import '../../../../core/error/failures.dart';
import '../../../../enum/absence_motif.dart';
import '../../../../enum/absence_period.dart';
import '../../../absence/domain/value_objects/absence_type.dart';
import '../../../../services/logger_service.dart';
import '../../../preference/domain/entities/user.dart';
import '../../../preference/domain/use_cases/get_signature_usecase.dart';
import '../../../preference/domain/use_cases/get_user_preference_use_case.dart';
import '../../../preference/domain/repositories/overtime_configuration_repository.dart';
import '../entities/generated_pdf.dart';
import '../repositories/timesheet_repository.dart';
import '../entities/work_week.dart';
import '../entities/work_day.dart';
import '../entities/timesheet_entry.dart';
import 'generate_week_usecase.dart';
import '../services/anomaly_detection_service.dart';
import 'calculate_overtime_hours_use_case.dart';
import 'generate_pdf_params.dart';

/// Use case for generating PDF timesheets with overtime calculations
///
/// This use case handles PDF generation by:
/// - Loading overtime configuration (daily threshold, rates) from OvertimeConfiguration
/// - Organizing timesheet entries into weeks
/// - Calculating overtime hours with deficit compensation
/// - Generating a formatted PDF with signatures
///
/// The daily work threshold is loaded from OvertimeConfiguration with a fallback
/// to the default value (8h18) if configuration loading fails.
class GeneratePdfUseCase {
  final TimesheetRepository repository;
  final GetSignatureUseCase getSignatureUseCase;
  final GetUserPreferenceUseCase getUserPreferenceUseCase;
  final AnomalyDetectionService anomalyDetectionService;
  final CalculateOvertimeHoursUseCase calculateOvertimeHoursUseCase;
  final OvertimeConfigurationRepository configRepository;

  GeneratePdfUseCase({
    required this.repository,
    required this.getSignatureUseCase,
    required this.getUserPreferenceUseCase,
    required this.anomalyDetectionService,
    required this.calculateOvertimeHoursUseCase,
    required this.configRepository,
  });

  final headerColor = PdfColor.fromHex('#D9D9D9'); // Gris clair pour l'en-tête
  final totalRowColor =
      PdfColor.fromHex('#F2F2F2'); // Gris très clair pour les totaux

  /// Call method pour la compatibilité avec les BLoCs de validation
  Future<Either<Failure, Uint8List>> call(GeneratePdfParams params) async {
    logger.i('🔍 PDF Generation called with params:');
    logger.i('   - monthNumber: ${params.monthNumber}');
    logger.i('   - year: ${params.year}');
    logger.i(
        '   - managerSignature: ${params.managerSignature != null ? "PROVIDED (${params.managerSignature!.length} chars)" : "NULL"}');
    logger.i('   - managerName: ${params.managerName ?? "NULL"}');

    // Load configuration at the beginning with error handling
    try {
      final config = await configRepository.getOrCreateDefaultConfiguration();
      logger.i(
          '✅ Configuration loaded: dailyThreshold=${config.dailyWorkThreshold}, weekdayRate=${config.weekdayOvertimeRate}, weekendRate=${config.weekendOvertimeRate}');
    } catch (e) {
      logger.w(
          '⚠️ Failed to load configuration, will use defaults (8h18, rates 1.25/1.5): $e');
    }

    final result = await executeWithParams(params);

    if (result.isLeft()) {
      return Left(GeneralFailure(result.fold((l) => l, (r) => '')));
    }

    final pdfPath = result.fold((l) => '', (r) => r);
    try {
      final file = File(pdfPath);
      final bytes = await file.readAsBytes();
      return Right(bytes);
    } catch (e) {
      return Left(GeneralFailure('Impossible de lire le fichier PDF: $e'));
    }
  }

  Future<Either<String, String>> execute(int monthNumber, int year) async {
    try {
      final result = await _generatePdf(monthNumber, year, null, null);

      // Pour la méthode execute(), sauvegarder les métadonnées
      if (result.isRight()) {
        final pdfPath = result.fold((l) => '', (r) => r);
        final generatedPdf = GeneratedPdf(
          fileName: pdfPath.split('/').last,
          filePath: pdfPath,
          generatedDate: DateTime.now(),
        );
        await repository.saveGeneratedPdf(generatedPdf);
      }

      return result;
    } catch (e) {
      return Left("Erreur lors de la génération du PDF: ${e.toString()}");
    }
  }

  Future<Either<String, String>> executeWithParams(
      GeneratePdfParams params) async {
    try {
      return await _generatePdf(
        params.monthNumber,
        params.year,
        params.managerSignature,
        params.managerName,
      );
    } catch (e) {
      return Left("Erreur lors de la génération du PDF: ${e.toString()}");
    }
  }

  /// Génère un PDF directement à partir d'entries fournies (pour les validations)
  Future<Either<Failure, Uint8List>> generateFromEntries({
    required List<TimesheetEntry> entries,
    required int monthNumber,
    required int year,
    String? employeeName, // Nom de l'employé depuis BDD
    String? employeeCompany, // Entreprise depuis BDD
    String? employeeSignature, // Signature de l'employé en base64
    String? managerSignature,
    String? managerName,
  }) async {
    try {
      debugPrint('🚀 Génération du PDF à partir d\'entries fournies');
      debugPrint('📊 ${entries.length} entrées fournies');

      // Génération des semaines
      debugPrint('📅 Organisation des entrées par semaine...');
      final weeks = WeekGeneratorUseCase().execute(entries);
      debugPrint('✅ ${weeks.length} semaines générées');

      // Récupération des préférences utilisateur
      debugPrint('👤 Récupération des préférences utilisateur...');

      // Décoder la signature de l'employé si elle est fournie
      Uint8List? employeeSignatureBytes;
      if (employeeSignature != null && employeeSignature.isNotEmpty) {
        try {
          employeeSignatureBytes = base64Decode(employeeSignature);
          debugPrint('📝 Signature de l\'employé décodée avec succès');
        } catch (e) {
          logger.e('Erreur lors du décodage de la signature de l\'employé: $e');
        }
      }

      // Créer l'objet User avec les données de la BDD (nom, entreprise) et la signature de l'employé
      // Si les données BDD ne sont pas fournies, utiliser celles depuis les préférences comme fallback
      String finalEmployeeName = employeeName ?? '';
      String finalEmployeeCompany = employeeCompany ?? 'Avasad';

      if (finalEmployeeName.isEmpty) {
        // Fallback vers les préférences si pas de nom fourni
        final firstName =
            await getUserPreferenceUseCase.execute('firstName') ?? '';
        final lastName =
            await getUserPreferenceUseCase.execute('lastName') ?? '';
        finalEmployeeName = '$firstName $lastName'.trim();
      }

      if (finalEmployeeCompany.isEmpty) {
        finalEmployeeCompany =
            await getUserPreferenceUseCase.execute('company') ?? 'Avasad';
      }

      // Extraire prénom et nom de famille depuis le nom complet
      final nameParts = finalEmployeeName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      final user = User(
        firstName: firstName,
        lastName: lastName,
        company: finalEmployeeCompany,
        signature: employeeSignatureBytes, // Signature de l'employé depuis BDD
        isDeliveryManager: false, // Pour l'employé, pas important
      );
      debugPrint(
          '✅ Données utilisateur (depuis BDD): ${user.firstName} ${user.lastName} - ${user.company}');

      // Load overtime configuration with error handling
      debugPrint(
          '⚙️ Chargement de la configuration des heures supplémentaires...');
      try {
        final config = await configRepository.getOrCreateDefaultConfiguration();
        debugPrint(
            '✅ Configuration chargée: dailyThreshold=${config.dailyWorkThreshold}, weekdayRate=${config.weekdayOvertimeRate}, weekendRate=${config.weekendOvertimeRate}');
      } catch (e) {
        logger.w(
            'Échec du chargement de la configuration pour generateFromEntries, utilisation des valeurs par défaut (8h18, rates 1.25/1.5): $e');
        debugPrint(
            '⚠️ Erreur lors du chargement de la configuration, utilisation des valeurs par défaut (8h18, rates 1.25/1.5): $e');
      }

      // Récupérer la signature et le nom du manager depuis les préférences locales
      Uint8List? managerSignatureBytes;
      String? finalManagerName = managerName;

      logger.i('🔍 RÉCUPÉRATION DONNÉES MANAGER DEPUIS PRÉFÉRENCES:');

      // Si pas de nom manager fourni, récupérer depuis les préférences
      if (finalManagerName == null || finalManagerName.isEmpty) {
        final firstName =
            await getUserPreferenceUseCase.execute('firstName') ?? '';
        final lastName =
            await getUserPreferenceUseCase.execute('lastName') ?? '';
        finalManagerName = '$firstName $lastName'.trim();

        // Si les préférences sont vides aussi, utiliser le nom par défaut
        if (finalManagerName.isEmpty) {
          finalManagerName = 'Sovattha Sok';
          logger.i('   - Nom manager par défaut: $finalManagerName');
        } else {
          logger.i('   - Nom manager depuis préférences: $finalManagerName');
        }
      } else {
        logger.i('   - Nom manager fourni: $finalManagerName');
      }

      // Ne récupérer la signature manager que si elle est explicitement fournie
      if (managerSignature != null && managerSignature.isNotEmpty) {
        logger.i('   - Signature manager fournie, décodage...');
        try {
          if (managerSignature.startsWith('data:image/')) {
            final base64Part = managerSignature.split(',').last;
            managerSignatureBytes = base64Decode(base64Part);
          } else {
            managerSignatureBytes = base64Decode(managerSignature);
          }
          logger.i(
              '✅ Signature manager décodée: ${managerSignatureBytes.length} octets');
        } catch (e) {
          logger.e('❌ Erreur décodage signature: $e');
        }
      } else {
        logger.i(
            '   - Pas de signature manager fournie, génération sans signature manager');
      }

      // Génération du PDF
      debugPrint('📄 Génération du fichier PDF...');
      final pdfFile = await generatePdf(
        weeks,
        monthNumber,
        user,
        entries,
        managerSignature: managerSignatureBytes,
        managerName: finalManagerName,
      );

      // Lire le fichier et retourner les bytes
      final bytes = await pdfFile.readAsBytes();
      debugPrint('✅ PDF généré avec succès: ${bytes.length} octets');

      return Right(bytes);
    } catch (e) {
      debugPrint('❌ Erreur lors de la génération du PDF: $e');
      return Left(GeneralFailure('Erreur lors de la génération du PDF: $e'));
    }
  }

  // Future<Either<String, String>> _generatePdf(int monthNumber) async {
  //   final timesheetEntryList =
  //       await repository.findEntriesFromMonthOf(monthNumber);
  //   final weeks = WeekGeneratorUseCase().execute(timesheetEntryList);
  //
  //   final userEither = await _getUserFromPreferences();
  //   if (userEither.isLeft()) {
  //     return Left(userEither.getLeft().getOrElse(() =>
  //         "Erreur inconnue lors de la récupération des préférences utilisateur"));
  //   }
  //   final user = userEither.getRight().getOrElse(() =>
  //       throw ("Erreur inconnue lors de la récupération des préférences utilisateur"));
  //
  //   final pdfFile = await generatePdf(weeks, monthNumber, user);
  //   final generatedPdf = GeneratedPdfModel(
  //     fileName: pdfFile.path.split('/').last,
  //     filePath: pdfFile.path,
  //     generatedDate: DateTime.now(),
  //   );
  //
  //   await repository.saveGeneratedPdf(generatedPdf);
  //   return Right(pdfFile.path);
  // }

  Future<Either<String, String>> _generatePdf(
    int monthNumber,
    int year,
    String? managerSignature,
    String? managerName,
  ) async {
    debugPrint('🚀 Début de la génération du PDF pour le mois $monthNumber');
    try {
      // Récupération des entrées
      debugPrint('📊 Récupération des entrées du timesheet...');
      final timesheetEntryList =
          await repository.findEntriesFromMonthOf(monthNumber, year);
      debugPrint('✅ ${timesheetEntryList.length} entrées récupérées');

      // Génération des semaines
      debugPrint('📅 Organisation des entrées par semaine...');
      final weeks = WeekGeneratorUseCase().execute(timesheetEntryList);
      debugPrint('✅ ${weeks.length} semaines générées');

      // Note: La vérification des anomalies est maintenant gérée par l'UI avant d'appeler ce use case
      debugPrint('📄 Génération du PDF (anomalies déjà vérifiées par l\'UI)');

      // Récupération des préférences utilisateur
      debugPrint('👤 Récupération des préférences utilisateur...');
      final userEither = await _getUserFromPreferences();

      if (userEither.isLeft()) {
        final errorMessage = userEither.getLeft().getOrElse(() =>
            "Erreur inconnue lors de la récupération des préférences utilisateur");
        debugPrint('❌ Échec de récupération des préférences: $errorMessage');
        return Left(errorMessage);
      }

      final user = userEither.getRight().getOrElse(() {
        debugPrint(
            '❌ Erreur critique: impossible d\'extraire les données utilisateur');
        throw "Erreur inconnue lors de la récupération des préférences utilisateur";
      });
      debugPrint(
          '✅ Préférences utilisateur récupérées pour: ${user.firstName} ${user.lastName}');

      // Load overtime configuration with error handling
      debugPrint(
          '⚙️ Chargement de la configuration des heures supplémentaires...');
      try {
        final config = await configRepository.getOrCreateDefaultConfiguration();
        debugPrint(
            '✅ Configuration chargée: dailyThreshold=${config.dailyWorkThreshold}, weekdayRate=${config.weekdayOvertimeRate}, weekendRate=${config.weekendOvertimeRate}');
      } catch (e) {
        logger.w(
            'Échec du chargement de la configuration pour _generatePdf, utilisation des valeurs par défaut (8h18, rates 1.25/1.5): $e');
        debugPrint(
            '⚠️ Erreur lors du chargement de la configuration, utilisation des valeurs par défaut (8h18, rates 1.25/1.5): $e');
      }

      // Génération du PDF
      debugPrint('📄 Génération du fichier PDF...');
      // Décoder la signature du manager si elle est fournie
      Uint8List? managerSignatureBytes;
      if (managerSignature != null && managerSignature.isNotEmpty) {
        try {
          managerSignatureBytes = base64Decode(managerSignature);
          debugPrint('📝 Signature du manager décodée avec succès');
        } catch (e) {
          logger.e('Erreur lors du décodage de la signature du manager: $e');
        }
      }

      final pdfFile = await generatePdf(
        weeks,
        monthNumber,
        user,
        timesheetEntryList,
        managerSignature: managerSignatureBytes,
        managerName: managerName,
      );
      debugPrint('✅ PDF généré avec succès: ${pdfFile.path}');

      // Note: La sauvegarde des métadonnées est maintenant gérée par PdfBloc
      // pour éviter la duplication lors de l'utilisation via call()

      debugPrint('🎉 Génération du PDF terminée avec succès');
      return Right(pdfFile.path);
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors de la génération du PDF: $e');
      debugPrint('📑 Stack trace: $stackTrace');
      return Left('Erreur lors de la génération du PDF: $e');
    }
  }

  Future<Either<String, User>> _getUserFromPreferences() async {
    final firstName = await getUserPreferenceUseCase.execute('firstName') ?? '';
    final lastName = await getUserPreferenceUseCase.execute('lastName') ?? '';
    final isDeliveryManagerString =
        await getUserPreferenceUseCase.execute('isDeliveryManager') ?? 'false';
    final isDeliveryManager = isDeliveryManagerString.toLowerCase() == 'true';
    final company =
        await getUserPreferenceUseCase.execute('company') ?? 'Avasad';

    // Récupérer le seuil d'heures normales depuis les préférences (défaut: 8.3 = 8h18)
    final normalHoursThresholdString =
        await getUserPreferenceUseCase.execute('normalHoursThreshold') ?? '8.3';
    final normalHoursThreshold =
        double.tryParse(normalHoursThresholdString) ?? 8.3;

    return Right(
      User(
        firstName: firstName,
        lastName: lastName,
        company: company,
        signature: await getSignatureUseCase.execute(),
        isDeliveryManager: isDeliveryManager,
        normalHoursThreshold: normalHoursThreshold,
      ),
    );
  }

  Future<File> generatePdf(List<WorkWeek> weeks, int monthNumber, User user,
      List<TimesheetEntry> entries,
      {Uint8List? managerSignature, String? managerName}) async {
    logger.i('start generatedPdf');
    logger.i('DEBUG - managerSignature is null: ${managerSignature == null}');
    logger.i('DEBUG - managerName: $managerName');
    logger.i('DEBUG - user.isDeliveryManager: ${user.isDeliveryManager}');
    logger.i(
        'DEBUG - user.firstName: ${user.firstName}, user.lastName: ${user.lastName}');
    final pdf = pw.Document();

    // Chargez la police Helvetica
    final fontData = await rootBundle.load("assets/fonts/helvetica.ttf");
    final ttf = pw.Font.ttf(fontData.buffer.asByteData());

    // Chargez le logo
    final logoImage = pw.MemoryImage(await _loadImage());

    // Convertissez la signature en pw.Image si elle existe
    pw.Image? signatureImage;
    if (user.signature != null) {
      signatureImage = pw.Image(pw.MemoryImage(user.signature!));
    }

    // Signature du manager si fournie
    pw.Image? managerSignatureImage;
    logger.i(
        '🔍 Dans generatePdf - managerSignature: ${managerSignature != null ? '${managerSignature.length} octets' : 'NULL'}');
    logger.i('🔍 Dans generatePdf - managerName: $managerName');

    // Utiliser le nom par défaut si aucun nom de manager n'est fourni
    String finalManagerName = managerName ?? '';
    if (finalManagerName.isEmpty) {
      finalManagerName = 'Sovattha Sok';
      logger
          .i('🔧 Utilisation du nom de manager par défaut: $finalManagerName');
    }

    if (managerSignature != null) {
      managerSignatureImage = pw.Image(pw.MemoryImage(managerSignature));
      logger.i('✅ Image signature manager créée');
    } else {
      logger.w('⚠️ Pas de signature manager, image non créée');
    }

    double totalDays = weeks.fold(
        0.0,
        (sum, week) =>
            sum +
            week.workday.fold(0.0, (daySum, day) {
              if (day.entry.period == AbsencePeriod.halfDay.value) {
                return daySum + 0.5;
              } else if (!day.isAbsence()) {
                return daySum + 1;
              }
              return daySum;
            }));
    final totalHours = weeks.fold(
        Duration.zero, (sum, week) => sum + week.calculateTotalWeekHours());

    // Calcul des heures supplémentaires avec compensation mensuelle
    Duration totalOvertimeHours = Duration.zero;
    Map<String, Duration> overtimeByDay = {};

    // Utiliser le calcul mensuel avec compensation des déficits
    final monthlyOvertimeResult =
        await calculateOvertimeHoursUseCase.executeMonthly(
      entries: entries,
      normalHoursThreshold: user.normalHoursThreshold,
    );

    totalOvertimeHours = monthlyOvertimeResult.totalOvertime;
    overtimeByDay = monthlyOvertimeResult.overtimeByDay;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginBottom: 10,
          marginTop: 10,
          marginLeft: 10,
          marginRight: 10,
        ),
        build: (pw.Context context) => [
          _buildHeader(logoImage),
          _buildInfoTable(monthNumber, user),
          ...weeks.map(
              (week) => _buildWeekTable(week, user, entries, overtimeByDay)),
          _buildMonthTotal(totalHours, totalDays, totalOvertimeHours),
          _buildFooter(
              signatureImage, user, managerSignatureImage, finalManagerName),
        ],
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: ttf,
        ),
      ),
    );
    Directory directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/extract-time-sheet/${user.company}';
    try {
      await Directory(path).create(recursive: true);
    } catch (e) {
      logger.e('Erreur lors de la création du répertoire: $e');
      // Fallback vers un répertoire plus simple
      final fallbackPath = '${directory.path}/timesheet_pdfs';
      await Directory(fallbackPath).create(recursive: true);
      final fileName =
          '${DateFormat('MMMM', 'fr_FR').format(DateTime(DateTime.now().year, monthNumber))}_${DateTime.now().year}.pdf';
      final file = File('$fallbackPath/$fileName');
      return file.writeAsBytes(await pdf.save());
    }
    // Obtenir le nom du mois en français
    final monthName = DateFormat('MMMM', 'fr_FR')
        .format(DateTime(DateTime.now().year, monthNumber));
    // Créer le nom du fichier avec le mois et l'année
    final fileName = '${monthName}_${DateTime.now().year}.pdf';
    final file = File('$path/$fileName');
    logger.i('end generatedPdf ${file.path}');
    return file.writeAsBytes(await pdf.save());
  }

  pw.Widget _buildInfoTable(int monthNumber, User user) {
    final monthName = DateFormat('MMMM', 'fr_FR')
        .format(DateTime(DateTime.now().year, monthNumber));
    final year = DateTime.now().year;

    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('Entreprise de mission (Company): ${user.company}',
                  style: const pw.TextStyle(fontSize: 8)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('Travailleur: ${user.fullName}',
                  style: const pw.TextStyle(fontSize: 8)),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('Mois: $monthName-$year',
                  style: const pw.TextStyle(fontSize: 8)),
            ),
            pw.Container(),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildHeader(pw.MemoryImage logoImage) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        color: headerColor,
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Note de temps',
              style:
                  pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.Image(logoImage, width: 70),
        ],
      ),
    );
  }

  bool _isWeekday(String dateString) {
    final date = DateFormat('dd-MMM-yy', 'en_US').parse(dateString);
    return date.weekday >= 1 &&
        date.weekday <= 5; // Du lundi (1) au vendredi (5)
  }

  pw.Widget _buildWeekTable(WorkWeek week, User user,
      List<TimesheetEntry> entries, Map<String, Duration> overtimeByDay) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Table(
        border: pw.TableBorder.all(),
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(1),
          2: const pw.FlexColumnWidth(1),
          3: const pw.FlexColumnWidth(1),
          4: const pw.FlexColumnWidth(1),
          5: const pw.FlexColumnWidth(1.5),
          6: const pw.FlexColumnWidth(1.5),
          7: const pw.FlexColumnWidth(2.5),
        },
        children: [
          _buildTableHeader(),
          ...week.workday.map((day) => _buildDayRow(
              day,
              _isWeekday(day.entry.dayDate),
              user,
              entries,
              overtimeByDay,
              week)),
          _buildWeekTotal(week, overtimeByDay, user),
        ],
      ),
    );
  }

  pw.TableRow _buildTableHeader() {
    return pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          _centeredHeaderText('Date'),
          _centeredHeaderText('de'),
          _centeredHeaderText('à'),
          _centeredHeaderText('de'),
          _centeredHeaderText('à'),
          _centeredHeaderText('Total heures\ntravaillées'),
          _centeredHeaderText('Dont heures\nsupplémentaires'),
          _centeredHeaderText('Commentaires'),
          _centeredHeaderText('Jour\ntravaillé'),
        ]);
  }

  pw.TableRow _buildDayRow(
      Workday day,
      bool isWeekday,
      User user,
      List<TimesheetEntry> entries,
      Map<String, Duration> overtimeByDay,
      WorkWeek week) {
    bool isHalfDayAbsence = day.entry.period == AbsencePeriod.halfDay.value;
    bool isFullDayAbsence = day.isAbsence() && !isHalfDayAbsence;
    Duration workDuration = day.calculateTotalHours();
    String formattedDuration =
        isFullDayAbsence ? '0h00' : _formatDuration(workDuration);

    String daysWorked =
        isFullDayAbsence ? '0' : (isHalfDayAbsence ? '0.5' : '1');

    // Calcul des heures supplémentaires OU déficit pour ce jour
    String overtimeHours = '';

    if (!isFullDayAbsence) {
      // Calculer le seuil journalier en Duration
      final thresholdMinutes = (user.normalHoursThreshold * 60).round();
      final thresholdDuration = Duration(minutes: thresholdMinutes);

      if (overtimeByDay.containsKey(day.entry.dayDate)) {
        // Il y a des heures supplémentaires (surplus brut ou heures weekend)
        overtimeHours = _formatDuration(overtimeByDay[day.entry.dayDate]!);
      } else if (isWeekday && workDuration < thresholdDuration &&
          workDuration > Duration.zero) {
        // Il y a un déficit (travaillé moins que le seuil)
        // Afficher le déficit brut pour information (même s'il est compensé mensuellement)
        final deficit = thresholdDuration - workDuration;
        overtimeHours = '-${_formatDuration(deficit)}';
      }
    }

    return pw.TableRow(
      children: [
        pw.Center(
          child: pw.Padding(
              padding: const pw.EdgeInsets.only(left: 5, right: 5),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(_dayOfWeek(day.entry.dayDate),
                      style: const pw.TextStyle(fontSize: 6)),
                  pw.Text(_formatDate(day.entry.dayDate),
                      style: const pw.TextStyle(fontSize: 6)),
                ],
              )),
        ),
        pw.Center(
            child: pw.Text(day.entry.startMorning,
                style: const pw.TextStyle(fontSize: 6))),
        pw.Center(
            child: pw.Text(day.entry.endMorning,
                style: const pw.TextStyle(fontSize: 6))),
        pw.Center(
            child: pw.Text(day.entry.startAfternoon,
                style: const pw.TextStyle(fontSize: 6))),
        pw.Center(
            child: pw.Text(day.entry.endAfternoon,
                style: const pw.TextStyle(fontSize: 6))),
        pw.Center(
            child: pw.Text(formattedDuration,
                style: const pw.TextStyle(fontSize: 6))),
        pw.Center(
            child: pw.Text(overtimeHours,
                style: pw.TextStyle(
                    fontSize: 6,
                    color: overtimeHours.startsWith('-')
                        ? PdfColors.red
                        : PdfColors.orange))),
        pw.Center(
            child: pw.Text(_getCommentaire(day),
                style: const pw.TextStyle(fontSize: 6))),
        pw.Center(
            child: pw.Text(daysWorked, style: const pw.TextStyle(fontSize: 6))),
      ]
          .map((widget) =>
              pw.Padding(padding: const pw.EdgeInsets.all(3), child: widget))
          .toList(),
    );
  }

  String _getCommentaire(Workday day) {
    if (day.isAbsence()) {
      return day.entry.absence!.type == AbsenceType.other
          ? day.entry.absence!.motif
          : _getMotifFromType(day.entry.absence!.type) ?? '';
    }
    return '';
  }

  String _getMotifFromType(AbsenceType absenceType) {
    switch (absenceType) {
      case AbsenceType.vacation:
        return AbsenceMotif.leaveDay.value;
      case AbsenceType.publicHoliday:
        return AbsenceMotif.other.value;
      case AbsenceType.sickLeave:
        return AbsenceMotif.sickness.value;
      case AbsenceType.other:
        return AbsenceMotif.other.value;
    }
  }

  pw.TableRow _buildWeekTotal(
      WorkWeek week, Map<String, Duration> overtimeByDay, User user) {
    double daysWorked = week.workday.fold(0.0, (sum, day) {
      if (day.entry.period == AbsencePeriod.halfDay.value) {
        return sum + 0.5;
      } else if (!day.isAbsence()) {
        return sum + 1;
      }
      return sum;
    });

    // Calculer le total des surplus et déficits pour cette semaine
    Duration weekSurplusTotal = Duration.zero;
    Duration weekDeficitTotal = Duration.zero;

    final thresholdMinutes = (user.normalHoursThreshold * 60).round();
    final thresholdDuration = Duration(minutes: thresholdMinutes);

    for (final day in week.workday) {
      if (day.isAbsence()) continue;

      final workDuration = day.calculateTotalHours();
      final isWeekday = _isWeekday(day.entry.dayDate);

      if (overtimeByDay.containsKey(day.entry.dayDate)) {
        // Ce jour a un surplus (weekday ou weekend)
        weekSurplusTotal += overtimeByDay[day.entry.dayDate]!;
      } else if (isWeekday && workDuration < thresholdDuration &&
                 workDuration > Duration.zero) {
        // Jour de semaine avec déficit
        weekDeficitTotal += (thresholdDuration - workDuration);
      }
    }

    // Calculer le net de la semaine (surplus - déficits)
    Duration netWeekOvertime = weekSurplusTotal - weekDeficitTotal;

    String formattedDaysWorked = daysWorked.truncateToDouble() == daysWorked
        ? daysWorked.toStringAsFixed(0)
        : daysWorked.toStringAsFixed(1);

    // Afficher le net de la semaine (peut être positif, négatif ou zéro)
    String weekOvertimeDisplay = '';
    if (netWeekOvertime.isNegative) {
      weekOvertimeDisplay = '-${_formatDuration(netWeekOvertime.abs())}';
    } else if (netWeekOvertime > Duration.zero) {
      weekOvertimeDisplay = _formatDuration(netWeekOvertime);
    } else if (weekSurplusTotal > Duration.zero || weekDeficitTotal > Duration.zero) {
      // Afficher 0h00 seulement si la semaine a des surplus ou déficits qui se compensent
      weekOvertimeDisplay = '0h00';
    }
    // Sinon, laisser vide (pas de surplus ni déficit cette semaine)

    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        pw.Text('Total de la semaine:',
            style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold)),
        pw.Text(''),
        pw.Text(''),
        pw.Text(''),
        pw.Text(''),
        pw.Center(
            child: pw.Text(week.formatDuration(week.calculateTotalWeekHours()),
                style:
                    pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold))),
        pw.Center(
            child: pw.Text(weekOvertimeDisplay,
                style: pw.TextStyle(
                    fontSize: 6,
                    fontWeight: pw.FontWeight.bold,
                    color: weekOvertimeDisplay.startsWith('-')
                        ? PdfColors.red
                        : PdfColors.orange))),
        pw.Text(''),
        pw.Center(
            child: pw.Text(
                '$formattedDaysWorked jour${daysWorked > 1 ? 's' : ''}',
                style:
                    pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold))),
      ]
          .map((widget) =>
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: widget))
          .toList(),
    );
  }

  pw.Widget _buildMonthTotal(
      Duration totalHours, double totalDays, Duration totalOvertimeHours) {
    String formattedTotalDays = totalDays.truncateToDouble() == totalDays
        ? totalDays.toStringAsFixed(0)
        : totalDays.toStringAsFixed(1);
    return pw.Container(
      color: totalRowColor,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Total du mois: ${_formatDuration(totalHours)}',
                  style: pw.TextStyle(
                      fontSize: 8, fontWeight: pw.FontWeight.bold)),
              if (totalOvertimeHours > Duration.zero)
                pw.Text(
                    'Heures supplémentaires: ${_formatDuration(totalOvertimeHours)}',
                    style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Jours travaillés:',
                  style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text(formattedTotalDays,
                  style: pw.TextStyle(
                      fontSize: 15, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Image? signatureImage, User user,
      pw.Image? managerSignatureImage, String? managerName) {
    logger.i('DEBUG _buildFooter - managerName: $managerName');
    logger.i(
        'DEBUG _buildFooter - managerSignatureImage is null: ${managerSignatureImage == null}');
    logger.i('DEBUG _buildFooter - user.fullName: ${user.fullName}');
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 15),
      child: pw.Column(
        children: [
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(
                children: [
                  _buildSignatureColumn(
                      'Travailleur', user.fullName, signatureImage),
                  _buildSignatureColumn('Entreprise de mission', 'Nadia Aepli'),
                  _buildSignatureColumn('Delivery manager', managerName ?? '',
                      managerSignatureImage),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                  'Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 8)),
              pw.Text(
                  'Je certifie sur l\'honneur que j\'ai travaillé durant ces horaires et heures travaillées',
                  style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    final date = DateFormat('dd-MMM-yy', 'en_US').parse(dateString);
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatDuration(Duration duration) {
    return '${duration.inHours}h ${duration.inMinutes.remainder(60)}min';
  }

  Future<File> _savePdf(
      pw.Document pdf, String company, int monthNumber) async {
    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/timesheet_${company}_$monthNumber.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _centeredHeaderText(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(2),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  String _dayOfWeek(String dateString) {
    try {
      final date = DateFormat('dd-MMM-yy', 'en_US').parse(dateString);
      return DateFormat('EEEE', 'fr_FR').format(date);
    } catch (e) {
      print('Erreur lors du formatage de la date: $e');
      return dateString;
    }
  }

  pw.Widget _buildSignatureColumn(String title, String name,
      [pw.Image? signatureImage]) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          if (signatureImage != null)
            pw.Container(
              height: 30, // Ajustez la taille selon vos besoins
              width: 300, // Ajustez la taille selon vos besoins
              child: signatureImage,
            )
          else
            pw.SizedBox(height: 25), // Espace pour la signature
          pw.Container(
            width: 100,
            height: 1,
            color: PdfColors.black,
          ),
          pw.SizedBox(height: 5),
          pw.Text(name, style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  Future<Uint8List> _loadImage() async {
    final byteData = await rootBundle.load('assets/images/logo-sonrysa.png');
    return byteData.buffer.asUint8List();
  }
}
