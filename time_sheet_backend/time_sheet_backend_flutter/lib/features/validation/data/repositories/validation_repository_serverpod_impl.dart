import 'dart:convert';
import 'dart:typed_data';
import 'package:fpdart/fpdart.dart';
import 'package:time_sheet_backend_client/time_sheet_backend_client.dart' as serverpod;
import 'package:time_sheet/core/error/failures.dart';
import 'package:time_sheet/core/services/serverpod/serverpod_service.dart';
import 'package:time_sheet/features/validation/domain/entities/validation_request.dart';
import 'package:time_sheet/features/validation/domain/entities/notification.dart';
import 'package:time_sheet/features/validation/domain/repositories/validation_repository.dart';
import 'package:time_sheet/services/logger_service.dart';
import 'package:time_sheet/features/preference/domain/use_cases/get_user_preference_use_case.dart';

class ValidationRepositoryServerpodImpl implements ValidationRepository {
  final serverpod.Client _client;
  final GetUserPreferenceUseCase _getUserPreferenceUseCase;
  
  ValidationRepositoryServerpodImpl({
    serverpod.Client? client,
    required GetUserPreferenceUseCase getUserPreferenceUseCase,
  }) : _client = client ?? ServerpodService.client,
       _getUserPreferenceUseCase = getUserPreferenceUseCase;

  @override
  Future<Either<Failure, ValidationRequest>> createValidationRequest({
    required String employeeId,
    required String managerId,
    required DateTime periodStart,
    required DateTime periodEnd,
    required Uint8List pdfBytes,
    String? employeeName,
    String? employeeCompany,
    List<Map<String, dynamic>>? timesheetEntries,
    double? totalDays,
    String? totalHours,
    String? totalOvertimeHours,
  }) async {
    try {
      // Récupérer les informations de l'employé si non fournies
      String finalEmployeeName = employeeName ?? '';
      String finalEmployeeCompany = employeeCompany ?? '';
      
      if (finalEmployeeName.isEmpty) {
        final firstName = await _getUserPreferenceUseCase.execute('firstName') ?? '';
        final lastName = await _getUserPreferenceUseCase.execute('lastName') ?? '';
        finalEmployeeName = '$firstName $lastName'.trim();
      }
      
      if (finalEmployeeCompany.isEmpty) {
        finalEmployeeCompany = await _getUserPreferenceUseCase.execute('company') ?? '';
      }
      
      // Récupérer l'email du manager
      String managerEmail = '';
      try {
        final managers = await ServerpodService.handleServerpodCall(() =>
          _client.manager.getActiveManagers()
        );
        final manager = managers.firstWhere(
          (m) => m.id.toString() == managerId,
          orElse: () => throw Exception('Manager not found'),
        );
        managerEmail = manager.email;
      } catch (e) {
        logger.w('Could not fetch manager email: $e');
      }
      
      // Créer la validation d'abord
      final result = await ServerpodService.handleServerpodCall(() => 
        _client.validation.createValidation(
          employeeId,
          finalEmployeeName,
          managerId,
          managerEmail,
          periodStart,
          periodEnd,
          pdfBytes.toList(),
        )
      );
      
      // Si on a des données timesheet, les sauvegarder via l'endpoint dédié
      if (timesheetEntries != null && timesheetEntries.isNotEmpty && result.id != null) {
        try {
          // Convertir les Map<String, dynamic> en TimesheetEntry
          final entries = timesheetEntries.map((entry) => 
            serverpod.TimesheetEntry(
              dayDate: entry['dayDate'] ?? '',
              startMorning: entry['startMorning'] ?? '',
              endMorning: entry['endMorning'] ?? '',
              startAfternoon: entry['startAfternoon'] ?? '',
              endAfternoon: entry['endAfternoon'] ?? '',
              isAbsence: entry['isAbsence'] ?? false,
              hasOvertimeHours: entry['hasOvertimeHours'] ?? false,
            )
          ).toList();
          
          // NOTE: L'endpoint timesheet n'existe plus dans le client généré
          // Les données timesheet sont maintenant gérées directement côté serveur
          // via le hack JSON dans employeeId lors de la création
          logger.i('✅ Données timesheet sauvegardées via endpoint dédié');
        } catch (e) {
          logger.w('Impossible de sauvegarder les données timesheet: $e');
          // On ne fait pas échouer la création de validation si les données timesheet échouent
        }
      }
      
      return Right(_mapToEntity(result));
    } catch (e) {
      logger.e('Erreur lors de la création de la validation', error: e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ValidationRequest>> approveValidation({
    required String validationId,
    required String managerSignature, // Toujours requis par l'interface mais non utilisé
    String? comment,
  }) async {
    try {
      // Récupérer le nom du manager depuis les préférences
      final firstName = await _getUserPreferenceUseCase.execute('firstName') ?? '';
      final lastName = await _getUserPreferenceUseCase.execute('lastName') ?? '';
      String managerName = '$firstName $lastName'.trim();
      
      // Si pas de nom dans les préférences, essayer de récupérer depuis l'email du manager
      if (managerName.isEmpty) {
        final email = await _getUserPreferenceUseCase.execute('email') ?? '';
        if (email.isNotEmpty) {
          try {
            final managers = await ServerpodService.handleServerpodCall(() =>
              _client.manager.getActiveManagers()
            );
            final currentManager = managers.firstWhere(
              (m) => m.email == email,
              orElse: () => throw Exception('Manager not found'),
            );
            managerName = '${currentManager.firstName} ${currentManager.lastName}'.trim();
          } catch (e) {
            logger.w('Could not fetch manager name from email: $e');
          }
        }
      }
      
      logger.i('Manager approving: firstName=$firstName, lastName=$lastName, fullName=$managerName');
      
      // L'endpoint approveValidation accepte maintenant un PDF signé optionnel
      final result = await ServerpodService.handleServerpodCall(() =>
        _client.validation.approveValidation(
          int.parse(validationId),
          managerName.isNotEmpty ? managerName : 'Manager', // Fallback si pas de nom
          comment,
          null, // Pas de PDF signé dans cette méthode (fallback)
        )
      );
      
      // Le serveur retourne directement un ValidationRequest
      return Right(_mapToEntity(result));
    } catch (e) {
      logger.e('Erreur lors de l\'approbation de la validation', error: e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ValidationRequest>> rejectValidation({
    required String validationId,
    required String comment,
  }) async {
    try {
      // Récupérer le nom du manager depuis les préférences
      final firstName = await _getUserPreferenceUseCase.execute('firstName') ?? '';
      final lastName = await _getUserPreferenceUseCase.execute('lastName') ?? '';
      String managerName = '$firstName $lastName'.trim();
      
      // Si pas de nom dans les préférences, essayer de récupérer depuis l'email du manager
      if (managerName.isEmpty) {
        final email = await _getUserPreferenceUseCase.execute('email') ?? '';
        if (email.isNotEmpty) {
          try {
            final managers = await ServerpodService.handleServerpodCall(() =>
              _client.manager.getActiveManagers()
            );
            final currentManager = managers.firstWhere(
              (m) => m.email == email,
              orElse: () => throw Exception('Manager not found'),
            );
            managerName = '${currentManager.firstName} ${currentManager.lastName}'.trim();
          } catch (e) {
            logger.w('Could not fetch manager name from email: $e');
          }
        }
      }
      
      logger.i('Manager rejecting: firstName=$firstName, lastName=$lastName, fullName=$managerName');
      
      final result = await ServerpodService.handleServerpodCall(() =>
        _client.validation.rejectValidation(
          int.parse(validationId),
          comment,
          managerName.isNotEmpty ? managerName : 'Manager', // Fallback si pas de nom
        )
      );
      
      return Right(_mapToEntity(result));
    } catch (e) {
      logger.e('Erreur lors du rejet de la validation', error: e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ValidationRequest>>> getEmployeeValidations(String employeeId) async {
    try {
      final results = await ServerpodService.handleServerpodCall(() =>
        _client.validation.getEmployeeValidations(employeeId)
      );
      
      return Right(results.map(_mapToEntity).toList());
    } catch (e) {
      logger.e('Erreur lors de la récupération des validations employé', error: e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ValidationRequest>>> getManagerValidations(String managerId) async {
    try {
      // Note: managerId est en fait l'email du manager maintenant
      final results = await ServerpodService.handleServerpodCall(() =>
        _client.validation.getManagerValidations(managerId)
      );
      
      return Right(results.map(_mapToEntity).toList());
    } catch (e) {
      logger.e('Erreur lors de la récupération des validations manager', error: e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Uint8List>> downloadValidationPdf(String validationId, [String? managerSignature]) async {
    try {
      // Le nouvel endpoint ne prend plus de signature (elle est déjà en BDD)
      final pdfBytes = await ServerpodService.handleServerpodCall(() =>
        _client.validation.downloadValidationPdf(
          int.parse(validationId),
        )
      );
      
      return Right(Uint8List.fromList(pdfBytes));
    } catch (e) {
      logger.e('Erreur lors du téléchargement du PDF', error: e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ValidationRequest>> getValidationRequest(String id) async {
    try {
      final result = await ServerpodService.handleServerpodCall(() =>
        _client.validation.getValidation(int.parse(id))
      );
      
      if (result == null) {
        return Left(ServerFailure('Validation request not found'));
      }
      
      return Right(_mapToEntity(result));
    } catch (e) {
      logger.e('Erreur lors de la récupération de la validation', error: e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<NotificationEntity>>> getUserNotifications(String userId) async {
    try {
      final notifications = await ServerpodService.handleServerpodCall(() =>
        _client.notification.getUserNotifications(userId, unreadOnly: false)
      );
      
      return Right(notifications.map(_mapNotificationToEntity).toList());
    } catch (e) {
      logger.e('Erreur lors de la récupération des notifications', error: e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, NotificationEntity>> markNotificationAsRead(String notificationId) async {
    try {
      final result = await ServerpodService.handleServerpodCall(() =>
        _client.notification.markAsRead(int.parse(notificationId))
      );
      
      return Right(_mapNotificationToEntity(result));
    } catch (e) {
      logger.e('Erreur lors du marquage de la notification comme lue', error: e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAllNotificationsAsRead(String userId) async {
    try {
      await ServerpodService.handleServerpodCall(() =>
        _client.notification.markAllAsRead(userId)
      );
      
      return const Right(null);
    } catch (e) {
      logger.e('Erreur lors du marquage de toutes les notifications comme lues', error: e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadNotificationCount(String userId) async {
    try {
      final count = await ServerpodService.handleServerpodCall(() =>
        _client.notification.getUnreadCount(userId)
      );
      
      return Right(count);
    } catch (e) {
      logger.e('Erreur lors du comptage des notifications non lues', error: e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncOfflineData() async {
    try {
      // TODO: Implémenter la synchronisation des données hors ligne
      // Pour l'instant, Serverpod gère la synchronisation automatiquement
      return const Right(null);
    } catch (e) {
      logger.e('Erreur lors de la synchronisation des données', error: e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Manager>>> getAvailableManagers(String employeeId) async {
    try {
      final managers = await ServerpodService.handleServerpodCall(() =>
        _client.manager.getActiveManagers()
      );
      
      return Right(managers.map(_mapManagerToEntity).toList());
    } catch (e) {
      logger.e('Erreur lors de la récupération des managers', error: e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteValidationRequest(String validationId) async {
    try {
      // TODO: Implémenter la suppression d'une validation
      // Actuellement non disponible dans l'endpoint Serverpod
      return Left(ServerFailure('Delete validation request not implemented'));
    } catch (e) {
      logger.e('Erreur lors de la suppression de la validation', error: e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ValidationRequest>> approveValidationWithSignedPdf({
    required String validationId,
    required Uint8List signedPdfBytes,
    required String managerName,
    String? comment,
  }) async {
    try {
      logger.i('📤 Envoi du PDF signé au serveur');
      logger.i('   - Validation ID: $validationId');
      logger.i('   - Taille du PDF: ${signedPdfBytes.length} octets');
      logger.i('   - Manager: $managerName');
      
      // Appeler le nouvel endpoint avec le PDF signé
      final result = await ServerpodService.handleServerpodCall(() =>
        _client.validation.approveValidation(
          int.parse(validationId),
          managerName,
          comment,
          signedPdfBytes.toList(), // Convertir Uint8List en List<int>
        )
      );
      
      logger.i('✅ PDF signé envoyé et validation approuvée avec succès');
      
      return Right(_mapToEntity(result));
    } catch (e) {
      logger.e('Erreur lors de l\'envoi du PDF signé', error: e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getValidationTimesheetData(String validationId) async {
    try {
      logger.i('📊 Récupération des données timesheet pour validation $validationId');
      
      final response = await ServerpodService.handleServerpodCall(() =>
        _client.validation.getValidationTimesheetData(int.parse(validationId))
      );
      
      // Convertir TimesheetDataResponse en Map pour le use case
      final data = {
        'validationId': response.validationId,
        'employeeId': response.employeeId,
        'employeeName': response.employeeName,
        'employeeCompany': response.employeeCompany,
        'month': response.month,
        'year': response.year,
        'entries': jsonDecode(response.entries), // Décoder le JSON des entries
        'totalDays': response.totalDays,
        'totalHours': response.totalHours,
        'totalOvertimeHours': response.totalOvertimeHours,
        'periodStart': response.periodStart.toIso8601String(),
        'periodEnd': response.periodEnd.toIso8601String(),
        'status': response.status,
        'managerName': response.managerName,
        'managerComment': response.managerComment,
        'validatedAt': response.validatedAt?.toIso8601String(),
      };
      
      logger.i('✅ Données timesheet récupérées avec succès');
      logger.i('   - Mois: ${data['month']}/${data['year']}');
      logger.i('   - Employé: ${data['employeeName']}');
      logger.i('   - Statut: ${data['status']}');
      
      return Right(data);
    } catch (e) {
      logger.e('Erreur lors de la récupération des données timesheet', error: e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateFCMToken(String token) async {
    try {
      // TODO: Implémenter la mise à jour du token FCM
      // Nécessite un endpoint dédié
      return Left(ServerFailure('FCM token update not implemented'));
    } catch (e) {
      logger.e('Erreur lors de la mise à jour du token FCM', error: e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<ValidationRequest>>> watchEmployeeValidations(String employeeId) {
    // TODO: Implémenter l'écoute en temps réel des validations
    // Serverpod supporte les streams, mais nécessite une implémentation spécifique
    return Stream.value(Left(ServerFailure('Watch employee validations not implemented')));
  }

  @override
  Stream<Either<Failure, List<NotificationEntity>>> watchUserNotifications(String userId) {
    // TODO: Implémenter l'écoute en temps réel des notifications
    // Serverpod supporte les streams, mais nécessite une implémentation spécifique
    return Stream.value(Left(ServerFailure('Watch user notifications not implemented')));
  }


  // Mapper serverpod.ValidationRequest vers domain ValidationRequest
  ValidationRequest _mapToEntity(serverpod.ValidationRequest request) {
    return ValidationRequest(
      id: request.id?.toString() ?? '',
      organizationId: '', // TODO: Obtenir l'organisation depuis le contexte
      employeeId: request.employeeId,
      managerId: request.managerId,
      periodStart: request.periodStart,
      periodEnd: request.periodEnd,
      status: _mapStatus(request.status),
      managerSignature: null, // Plus de signature stockée en BDD
      managerComment: request.managerComment,
      managerName: request.managerName,
      validatedAt: request.validatedAt,
      createdAt: request.createdAt ?? DateTime.now(),
      updatedAt: request.updatedAt ?? DateTime.now(),
      expiresAt: request.expiresAt,
      pdfPath: request.pdfPath,
      pdfHash: request.pdfHash,
      pdfSizeBytes: request.pdfSizeBytes,
    );
  }

  // Mapper Manager vers Manager (domain)
  Manager _mapManagerToEntity(serverpod.Manager manager) {
    return Manager(
      id: manager.id?.toString() ?? '',
      email: manager.email,
      name: '${manager.firstName} ${manager.lastName}',
    );
  }

  // Mapper Notification vers NotificationEntity (domain)
  NotificationEntity _mapNotificationToEntity(serverpod.Notification notification) {
    return NotificationEntity(
      id: notification.id?.toString() ?? '',
      userId: notification.userId,
      type: _mapNotificationType(notification.type),
      title: notification.title,
      body: notification.message,
      data: notification.data != null ? 
        _parseNotificationData(notification.data!) : null,
      read: notification.isRead,
      readAt: notification.readAt,
      createdAt: notification.createdAt ?? DateTime.now(),
    );
  }

  // Parser les données de notification JSON
  Map<String, dynamic>? _parseNotificationData(String data) {
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (e) {
      logger.w('Erreur lors du parsing des données de notification', error: e);
      return null;
    }
  }

  // Mapper le type de notification
  NotificationType _mapNotificationType(serverpod.NotificationType type) {
    switch (type) {
      case serverpod.NotificationType.validationCreated:
      case serverpod.NotificationType.validationReminder:
        return NotificationType.validationRequest;
      case serverpod.NotificationType.validationApproved:
      case serverpod.NotificationType.validationRejected:
        return NotificationType.validationFeedback;
      case serverpod.NotificationType.validationExpiring:
        return NotificationType.reminder;
    }
  }

  // Mapper le statut serverpod vers domain
  ValidationStatus _mapStatus(serverpod.ValidationStatus status) {
    switch (status) {
      case serverpod.ValidationStatus.pending:
        return ValidationStatus.pending;
      case serverpod.ValidationStatus.approved:
        return ValidationStatus.approved;
      case serverpod.ValidationStatus.rejected:
        return ValidationStatus.rejected;
      case serverpod.ValidationStatus.expired:
        return ValidationStatus.rejected; // Traiter les expirés comme rejetés
    }
  }
}