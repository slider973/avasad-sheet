import 'dart:typed_data';
import 'package:fpdart/fpdart.dart';
import 'package:time_sheet/core/error/failures.dart';
import '../entities/validation_request.dart';
import '../entities/notification.dart';

/// Repository abstrait pour la gestion des validations
abstract class ValidationRepository {
  /// Crée une nouvelle demande de validation
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
  });
  
  /// Récupère une demande de validation par ID
  Future<Either<Failure, ValidationRequest>> getValidationRequest(String id);
  
  /// Récupère toutes les demandes de validation pour un employé
  Future<Either<Failure, List<ValidationRequest>>> getEmployeeValidations(String employeeId);
  
  /// Récupère toutes les demandes de validation qu'un manager doit traiter
  Future<Either<Failure, List<ValidationRequest>>> getManagerValidations(String managerId);
  
  /// Approuve une demande de validation
  Future<Either<Failure, ValidationRequest>> approveValidation({
    required String validationId,
    required String managerSignature,
    String? comment,
  });
  
  /// Rejette une demande de validation
  Future<Either<Failure, ValidationRequest>> rejectValidation({
    required String validationId,
    required String comment,
  });
  
  /// Télécharge le PDF déchiffré d'une validation (avec signature optionnelle pour les managers)
  Future<Either<Failure, Uint8List>> downloadValidationPdf(String validationId, [String? managerSignature]);
  
  /// Récupère les notifications de l'utilisateur
  Future<Either<Failure, List<NotificationEntity>>> getUserNotifications(String userId);
  
  /// Marque une notification comme lue
  Future<Either<Failure, NotificationEntity>> markNotificationAsRead(String notificationId);
  
  /// Marque toutes les notifications comme lues
  Future<Either<Failure, void>> markAllNotificationsAsRead(String userId);
  
  /// Récupère le nombre de notifications non lues
  Future<Either<Failure, int>> getUnreadNotificationCount(String userId);
  
  /// Synchronise les données locales avec le serveur
  Future<Either<Failure, void>> syncOfflineData();
  
  /// Récupère les managers disponibles pour un employé
  Future<Either<Failure, List<Manager>>> getAvailableManagers(String employeeId);
  
  /// Supprime une demande de validation (si en attente)
  Future<Either<Failure, void>> deleteValidationRequest(String validationId);
  
  /// Met à jour le token FCM de l'utilisateur
  Future<Either<Failure, void>> updateFCMToken(String token);
  
  /// Écoute les changements de validations en temps réel
  Stream<Either<Failure, List<ValidationRequest>>> watchEmployeeValidations(String employeeId);
  
  /// Écoute les changements de notifications en temps réel
  Stream<Either<Failure, List<NotificationEntity>>> watchUserNotifications(String userId);
}

/// Modèle simple pour les managers
class Manager {
  final String id;
  final String email;
  final String? name;
  
  const Manager({
    required this.id,
    required this.email,
    this.name,
  });
}