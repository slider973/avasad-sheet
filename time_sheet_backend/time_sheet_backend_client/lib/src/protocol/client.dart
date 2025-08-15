/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'dart:async' as _i2;
import 'package:time_sheet_backend_client/src/protocol/manager.dart' as _i3;
import 'package:time_sheet_backend_client/src/protocol/notification.dart'
    as _i4;
import 'package:time_sheet_backend_client/src/protocol/notification_type.dart'
    as _i5;
import 'package:time_sheet_backend_client/src/protocol/timesheet_data.dart'
    as _i6;
import 'package:time_sheet_backend_client/src/protocol/timesheet_entry.dart'
    as _i7;
import 'package:time_sheet_backend_client/src/protocol/validation_request.dart'
    as _i8;
import 'package:time_sheet_backend_client/src/protocol/timesheet_data_response.dart'
    as _i9;
import 'package:time_sheet_backend_client/src/protocol/greeting.dart' as _i10;
import 'protocol.dart' as _i11;

/// {@category Endpoint}
class EndpointManager extends _i1.EndpointRef {
  EndpointManager(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'manager';

  /// Créer un nouveau manager
  _i2.Future<_i3.Manager> createManager(
    String email,
    String firstName,
    String lastName,
    String company,
    String? signature,
  ) =>
      caller.callServerEndpoint<_i3.Manager>(
        'manager',
        'createManager',
        {
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
          'company': company,
          'signature': signature,
        },
      );

  /// Mettre à jour un manager
  _i2.Future<_i3.Manager> updateManager(
    int managerId,
    String firstName,
    String lastName,
    String company,
    String? signature,
    bool isActive,
  ) =>
      caller.callServerEndpoint<_i3.Manager>(
        'manager',
        'updateManager',
        {
          'managerId': managerId,
          'firstName': firstName,
          'lastName': lastName,
          'company': company,
          'signature': signature,
          'isActive': isActive,
        },
      );

  /// Obtenir tous les managers actifs
  _i2.Future<List<_i3.Manager>> getActiveManagers() =>
      caller.callServerEndpoint<List<_i3.Manager>>(
        'manager',
        'getActiveManagers',
        {},
      );

  /// Obtenir un manager par son ID
  _i2.Future<_i3.Manager?> getManagerById(int managerId) =>
      caller.callServerEndpoint<_i3.Manager?>(
        'manager',
        'getManagerById',
        {'managerId': managerId},
      );

  /// Obtenir un manager par son email
  _i2.Future<_i3.Manager?> getManagerByEmail(String email) =>
      caller.callServerEndpoint<_i3.Manager?>(
        'manager',
        'getManagerByEmail',
        {'email': email},
      );

  /// Désactiver un manager
  _i2.Future<void> deactivateManager(int managerId) =>
      caller.callServerEndpoint<void>(
        'manager',
        'deactivateManager',
        {'managerId': managerId},
      );

  /// Activer un manager
  _i2.Future<void> activateManager(int managerId) =>
      caller.callServerEndpoint<void>(
        'manager',
        'activateManager',
        {'managerId': managerId},
      );

  /// Créer ou réactiver un manager
  _i2.Future<_i3.Manager> createOrActivateManager(
    String email,
    String firstName,
    String lastName,
    String company,
    String? signature,
  ) =>
      caller.callServerEndpoint<_i3.Manager>(
        'manager',
        'createOrActivateManager',
        {
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
          'company': company,
          'signature': signature,
        },
      );

  /// Obtenir les statistiques de validation d'un manager
  _i2.Future<Map<String, dynamic>> getManagerStatistics(int managerId) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'manager',
        'getManagerStatistics',
        {'managerId': managerId},
      );

  /// Rechercher des managers
  _i2.Future<List<_i3.Manager>> searchManagers(String query) =>
      caller.callServerEndpoint<List<_i3.Manager>>(
        'manager',
        'searchManagers',
        {'query': query},
      );

  /// Importer plusieurs managers depuis une liste
  _i2.Future<List<_i3.Manager>> importManagers(
          List<Map<String, dynamic>> managersData) =>
      caller.callServerEndpoint<List<_i3.Manager>>(
        'manager',
        'importManagers',
        {'managersData': managersData},
      );
}

/// {@category Endpoint}
class EndpointNotification extends _i1.EndpointRef {
  EndpointNotification(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'notification';

  /// Obtenir les notifications d'un utilisateur
  _i2.Future<List<_i4.Notification>> getUserNotifications(
    String userId, {
    required bool unreadOnly,
  }) =>
      caller.callServerEndpoint<List<_i4.Notification>>(
        'notification',
        'getUserNotifications',
        {
          'userId': userId,
          'unreadOnly': unreadOnly,
        },
      );

  /// Marquer une notification comme lue
  _i2.Future<_i4.Notification> markAsRead(int notificationId) =>
      caller.callServerEndpoint<_i4.Notification>(
        'notification',
        'markAsRead',
        {'notificationId': notificationId},
      );

  /// Marquer toutes les notifications d'un utilisateur comme lues
  _i2.Future<int> markAllAsRead(String userId) =>
      caller.callServerEndpoint<int>(
        'notification',
        'markAllAsRead',
        {'userId': userId},
      );

  /// Supprimer une notification
  _i2.Future<void> deleteNotification(int notificationId) =>
      caller.callServerEndpoint<void>(
        'notification',
        'deleteNotification',
        {'notificationId': notificationId},
      );

  /// Supprimer toutes les notifications lues d'un utilisateur
  _i2.Future<int> deleteReadNotifications(String userId) =>
      caller.callServerEndpoint<int>(
        'notification',
        'deleteReadNotifications',
        {'userId': userId},
      );

  /// Obtenir le nombre de notifications non lues
  _i2.Future<int> getUnreadCount(String userId) =>
      caller.callServerEndpoint<int>(
        'notification',
        'getUnreadCount',
        {'userId': userId},
      );

  /// Créer une notification personnalisée
  _i2.Future<_i4.Notification> createNotification(
    String userId,
    _i5.NotificationType type,
    String title,
    String message,
    Map<String, dynamic>? data,
  ) =>
      caller.callServerEndpoint<_i4.Notification>(
        'notification',
        'createNotification',
        {
          'userId': userId,
          'type': type,
          'title': title,
          'message': message,
          'data': data,
        },
      );

  /// Envoyer une notification à plusieurs utilisateurs
  _i2.Future<List<_i4.Notification>> createBulkNotifications(
    List<String> userIds,
    _i5.NotificationType type,
    String title,
    String message,
    Map<String, dynamic>? data,
  ) =>
      caller.callServerEndpoint<List<_i4.Notification>>(
        'notification',
        'createBulkNotifications',
        {
          'userIds': userIds,
          'type': type,
          'title': title,
          'message': message,
          'data': data,
        },
      );

  /// Nettoyer les anciennes notifications
  _i2.Future<void> cleanupOldNotifications() => caller.callServerEndpoint<void>(
        'notification',
        'cleanupOldNotifications',
        {},
      );

  /// Obtenir les notifications groupées par type
  _i2.Future<Map<_i5.NotificationType, List<_i4.Notification>>>
      getNotificationsByType(String userId) => caller.callServerEndpoint<
              Map<_i5.NotificationType, List<_i4.Notification>>>(
            'notification',
            'getNotificationsByType',
            {'userId': userId},
          );

  /// Envoyer des rappels pour les validations en attente
  _i2.Future<void> sendValidationReminders() => caller.callServerEndpoint<void>(
        'notification',
        'sendValidationReminders',
        {},
      );
}

/// {@category Endpoint}
class EndpointPdfProcessor extends _i1.EndpointRef {
  EndpointPdfProcessor(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'pdfProcessor';

  /// Traiter la queue de régénération PDF
  _i2.Future<void> processPdfQueue() => caller.callServerEndpoint<void>(
        'pdfProcessor',
        'processPdfQueue',
        {},
      );

  /// Nettoyer les anciens jobs de la queue
  _i2.Future<void> cleanupOldJobs() => caller.callServerEndpoint<void>(
        'pdfProcessor',
        'cleanupOldJobs',
        {},
      );
}

/// {@category Endpoint}
class EndpointTimesheet extends _i1.EndpointRef {
  EndpointTimesheet(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'timesheet';

  /// Endpoint unique et professionnel pour gérer toutes les opérations timesheet
  ///
  /// Cette méthode gère toutes les opérations via un paramètre 'action':
  /// - 'save': Sauvegarder des données timesheet
  /// - 'get': Récupérer des données timesheet
  /// - 'update': Mettre à jour des données existantes
  /// - 'generatePdf': Générer un PDF avec signatures
  _i2.Future<Map<String, dynamic>> processTimesheet(
    String action,
    Map<String, dynamic> data,
  ) =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'timesheet',
        'processTimesheet',
        {
          'action': action,
          'data': data,
        },
      );

  /// Sauvegarder les données du timesheet (compatibilité)
  _i2.Future<_i6.TimesheetData> saveTimesheetData(
    int validationRequestId,
    String employeeId,
    String employeeName,
    String employeeCompany,
    int month,
    int year,
    List<_i7.TimesheetEntry> entries,
    double totalDays,
    String totalHours,
    String totalOvertimeHours,
  ) =>
      caller.callServerEndpoint<_i6.TimesheetData>(
        'timesheet',
        'saveTimesheetData',
        {
          'validationRequestId': validationRequestId,
          'employeeId': employeeId,
          'employeeName': employeeName,
          'employeeCompany': employeeCompany,
          'month': month,
          'year': year,
          'entries': entries,
          'totalDays': totalDays,
          'totalHours': totalHours,
          'totalOvertimeHours': totalOvertimeHours,
        },
      );

  /// Récupérer les données du timesheet (compatibilité)
  _i2.Future<_i6.TimesheetData?> getTimesheetData(int validationRequestId) =>
      caller.callServerEndpoint<_i6.TimesheetData?>(
        'timesheet',
        'getTimesheetData',
        {'validationRequestId': validationRequestId},
      );

  /// Générer un PDF avec signature (compatibilité)
  _i2.Future<List<int>> generateSignedPdf(
    int validationRequestId,
    String? employeeSignature,
    String? managerSignature,
    String? managerName,
  ) =>
      caller.callServerEndpoint<List<int>>(
        'timesheet',
        'generateSignedPdf',
        {
          'validationRequestId': validationRequestId,
          'employeeSignature': employeeSignature,
          'managerSignature': managerSignature,
          'managerName': managerName,
        },
      );
}

/// {@category Endpoint}
class EndpointValidation extends _i1.EndpointRef {
  EndpointValidation(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'validation';

  /// Créer une nouvelle demande de validation
  _i2.Future<_i8.ValidationRequest> createValidation(
    String employeeId,
    String employeeName,
    String managerId,
    String managerEmail,
    DateTime periodStart,
    DateTime periodEnd,
    List<int> pdfBytes,
    String? employeeCompany,
  ) =>
      caller.callServerEndpoint<_i8.ValidationRequest>(
        'validation',
        'createValidation',
        {
          'employeeId': employeeId,
          'employeeName': employeeName,
          'managerId': managerId,
          'managerEmail': managerEmail,
          'periodStart': periodStart,
          'periodEnd': periodEnd,
          'pdfBytes': pdfBytes,
          'employeeCompany': employeeCompany,
        },
      );

  /// Mettre à jour les données timesheet d'une validation
  _i2.Future<void> updateTimesheetData(
    int validationId,
    String entries,
    double totalDays,
    String totalHours,
    String totalOvertimeHours,
  ) =>
      caller.callServerEndpoint<void>(
        'validation',
        'updateTimesheetData',
        {
          'validationId': validationId,
          'entries': entries,
          'totalDays': totalDays,
          'totalHours': totalHours,
          'totalOvertimeHours': totalOvertimeHours,
        },
      );

  /// Approuver une validation
  _i2.Future<_i8.ValidationRequest> approveValidation(
    int validationId,
    String managerName,
    String? comment,
    List<int>? signedPdfBytes,
  ) =>
      caller.callServerEndpoint<_i8.ValidationRequest>(
        'validation',
        'approveValidation',
        {
          'validationId': validationId,
          'managerName': managerName,
          'comment': comment,
          'signedPdfBytes': signedPdfBytes,
        },
      );

  /// Rejeter une validation
  _i2.Future<_i8.ValidationRequest> rejectValidation(
    int validationId,
    String comment,
    String managerName,
  ) =>
      caller.callServerEndpoint<_i8.ValidationRequest>(
        'validation',
        'rejectValidation',
        {
          'validationId': validationId,
          'comment': comment,
          'managerName': managerName,
        },
      );

  /// Obtenir les validations d'un employé
  _i2.Future<List<_i8.ValidationRequest>> getEmployeeValidations(
          String employeeId) =>
      caller.callServerEndpoint<List<_i8.ValidationRequest>>(
        'validation',
        'getEmployeeValidations',
        {'employeeId': employeeId},
      );

  /// Obtenir les validations à traiter par un manager
  _i2.Future<List<_i8.ValidationRequest>> getManagerValidations(
          String managerEmail) =>
      caller.callServerEndpoint<List<_i8.ValidationRequest>>(
        'validation',
        'getManagerValidations',
        {'managerEmail': managerEmail},
      );

  /// Obtenir une validation spécifique
  _i2.Future<_i8.ValidationRequest?> getValidation(int validationId) =>
      caller.callServerEndpoint<_i8.ValidationRequest?>(
        'validation',
        'getValidation',
        {'validationId': validationId},
      );

  /// Télécharger le PDF d'une validation
  _i2.Future<List<int>> downloadValidationPdf(int validationId) =>
      caller.callServerEndpoint<List<int>>(
        'validation',
        'downloadValidationPdf',
        {'validationId': validationId},
      );

  /// Obtenir les données timesheet pour une validation
  _i2.Future<_i9.TimesheetDataResponse> getValidationTimesheetData(
          int validationId) =>
      caller.callServerEndpoint<_i9.TimesheetDataResponse>(
        'validation',
        'getValidationTimesheetData',
        {'validationId': validationId},
      );

  /// Vérifier et marquer les validations expirées
  _i2.Future<void> checkExpiredValidations() => caller.callServerEndpoint<void>(
        'validation',
        'checkExpiredValidations',
        {},
      );
}

/// This is an example endpoint that returns a greeting message through
/// its [hello] method.
/// {@category Endpoint}
class EndpointGreeting extends _i1.EndpointRef {
  EndpointGreeting(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  /// Returns a personalized greeting message: "Hello {name}".
  _i2.Future<_i10.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i10.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

class Client extends _i1.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    _i1.AuthenticationKeyManager? authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i1.MethodCallContext,
      Object,
      StackTrace,
    )? onFailedCall,
    Function(_i1.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
          host,
          _i11.Protocol(),
          securityContext: securityContext,
          authenticationKeyManager: authenticationKeyManager,
          streamingConnectionTimeout: streamingConnectionTimeout,
          connectionTimeout: connectionTimeout,
          onFailedCall: onFailedCall,
          onSucceededCall: onSucceededCall,
          disconnectStreamsOnLostInternetConnection:
              disconnectStreamsOnLostInternetConnection,
        ) {
    manager = EndpointManager(this);
    notification = EndpointNotification(this);
    pdfProcessor = EndpointPdfProcessor(this);
    timesheet = EndpointTimesheet(this);
    validation = EndpointValidation(this);
    greeting = EndpointGreeting(this);
  }

  late final EndpointManager manager;

  late final EndpointNotification notification;

  late final EndpointPdfProcessor pdfProcessor;

  late final EndpointTimesheet timesheet;

  late final EndpointValidation validation;

  late final EndpointGreeting greeting;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
        'manager': manager,
        'notification': notification,
        'pdfProcessor': pdfProcessor,
        'timesheet': timesheet,
        'validation': validation,
        'greeting': greeting,
      };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {};
}
