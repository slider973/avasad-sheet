import 'dart:typed_data';
import 'package:fpdart/fpdart.dart';
import 'package:flutter/foundation.dart';
import 'package:time_sheet/core/error/failures.dart';
import 'package:time_sheet/core/error/exceptions.dart';
import 'package:time_sheet/core/services/supabase/supabase_service.dart';
import 'package:time_sheet/features/validation/domain/entities/notification.dart';
import 'package:time_sheet/features/validation/domain/entities/validation_request.dart';
import 'package:time_sheet/features/validation/domain/repositories/validation_repository.dart';
import 'package:time_sheet/features/preference/domain/use_cases/get_user_preference_use_case.dart';
import 'package:time_sheet/services/injection_container.dart' as di;
import '../models/validation_request_model.dart';
import '../models/notification_model.dart';
import '../data_sources/validation_remote_data_source.dart';
import '../data_sources/validation_local_data_source.dart';
import 'package:crypto/crypto.dart';

/// Implémentation simplifiée du repository de validation (sans encryption)
class ValidationRepositoryImpl implements ValidationRepository {
  final ValidationRemoteDataSource remoteDataSource;
  final ValidationLocalDataSource localDataSource;
  final SupabaseService supabaseService;
  
  const ValidationRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.supabaseService,
  });
  
  @override
  Future<Either<Failure, ValidationRequest>> createValidationRequest({
    required String employeeId,
    required String managerId,
    required DateTime periodStart,
    required DateTime periodEnd,
    required Uint8List pdfBytes,
  }) async {
    try {
      // Utiliser un identifiant d'organisation par défaut pour le mode sans auth
      final organizationId = 'default_org';
      
      // Calculer le hash du PDF pour l'intégrité
      final pdfHash = sha256.convert(pdfBytes).toString();
      
      // Générer un nom de fichier unique
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'timesheets/${organizationId}/${employeeId}/${timestamp}_${periodStart.month}_${periodStart.year}.pdf';
      
      // Upload du PDF vers Supabase Storage (accessible publiquement)
      try {
        await supabaseService.client.storage
            .from('validation-pdfs')
            .uploadBinary(fileName, pdfBytes);
      } catch (e) {
        debugPrint('Error uploading PDF: $e');
        return Left(ServerFailure('Erreur lors de l\'upload du PDF: ${e.toString()}'));
      }
      
      // Créer la demande de validation avec l'URL du PDF
      final request = await remoteDataSource.createValidationRequest(
        organizationId: organizationId,
        employeeId: employeeId,
        managerId: managerId,
        periodStart: periodStart,
        periodEnd: periodEnd,
        pdfPath: fileName,
        pdfHash: pdfHash,
        pdfSizeBytes: pdfBytes.length,
      );
      
      // Sauvegarder localement pour l'offline
      await localDataSource.saveValidationRequest(request);
      
      return Right(request);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      // En cas d'absence de connexion, sauvegarder pour sync ultérieure
      try {
        await localDataSource.addToSyncQueue(
          action: 'create_validation',
          payload: {
            'employee_id': employeeId,
            'manager_id': managerId,
            'period_start': periodStart.toIso8601String(),
            'period_end': periodEnd.toIso8601String(),
            'pdf_bytes': pdfBytes,
          },
        );
        return Left(NetworkFailure('Demande sauvegardée localement'));
      } catch (e) {
        return Left(CacheFailure('Impossible de sauvegarder localement'));
      }
    } catch (e) {
      debugPrint('Error creating validation request: $e');
      return Left(UnexpectedFailure());
    }
  }
  
  @override
  Future<Either<Failure, ValidationRequest>> getValidationRequest(String id) async {
    try {
      // Essayer d'abord en ligne
      try {
        final request = await remoteDataSource.getValidationRequest(id);
        await localDataSource.saveValidationRequest(request);
        return Right(request);
      } on NetworkException {
        // Fallback sur le cache local
        final cachedRequest = await localDataSource.getValidationRequest(id);
        if (cachedRequest != null) {
          return Right(cachedRequest);
        }
        return Left(NetworkFailure('Pas de connexion et aucune donnée en cache'));
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }
  
  @override
  Future<Either<Failure, List<ValidationRequest>>> getEmployeeValidations(String employeeId) async {
    try {
      try {
        final validations = await remoteDataSource.getEmployeeValidations(employeeId);
        // Sauvegarder en cache
        for (final validation in validations) {
          await localDataSource.saveValidationRequest(validation);
        }
        return Right(validations);
      } on NetworkException {
        // Utiliser le cache
        final cachedValidations = await localDataSource.getEmployeeValidations(employeeId);
        return Right(cachedValidations);
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }
  
  @override
  Future<Either<Failure, List<ValidationRequest>>> getManagerValidations(String managerId) async {
    try {
      try {
        final validations = await remoteDataSource.getManagerValidations(managerId);
        // Sauvegarder en cache
        for (final validation in validations) {
          await localDataSource.saveValidationRequest(validation);
        }
        return Right(validations);
      } on NetworkException {
        // Utiliser le cache
        final cachedValidations = await localDataSource.getManagerValidations(managerId);
        return Right(cachedValidations);
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }
  
  @override
  Future<Either<Failure, ValidationRequest>> approveValidation({
    required String validationId,
    required String managerSignature,
    String? comment,
  }) async {
    try {
      final updatedRequest = await remoteDataSource.approveValidation(
        validationId: validationId,
        managerSignature: managerSignature,
        comment: comment,
      );
      
      // Mettre à jour le cache
      await localDataSource.saveValidationRequest(updatedRequest);
      
      return Right(updatedRequest);
    } on NetworkException {
      // Sauvegarder pour sync ultérieure
      await localDataSource.addToSyncQueue(
        action: 'update_validation',
        payload: {
          'validation_id': validationId,
          'status': 'approved',
          'manager_signature': managerSignature,
          'comment': comment,
        },
      );
      return Left(NetworkFailure('Approbation sauvegardée localement'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }
  
  @override
  Future<Either<Failure, ValidationRequest>> rejectValidation({
    required String validationId,
    required String comment,
  }) async {
    try {
      final updatedRequest = await remoteDataSource.rejectValidation(
        validationId: validationId,
        comment: comment,
      );
      
      // Mettre à jour le cache
      await localDataSource.saveValidationRequest(updatedRequest);
      
      return Right(updatedRequest);
    } on NetworkException {
      // Sauvegarder pour sync ultérieure
      await localDataSource.addToSyncQueue(
        action: 'update_validation',
        payload: {
          'validation_id': validationId,
          'status': 'rejected',
          'comment': comment,
        },
      );
      return Left(NetworkFailure('Rejet sauvegardé localement'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }
  
  @override
  Future<Either<Failure, Uint8List>> downloadValidationPdf(String validationId) async {
    try {
      // Récupérer la validation pour obtenir le chemin du PDF
      final validationResult = await getValidationRequest(validationId);
      
      return validationResult.fold(
        (failure) => Left(failure),
        (validation) async {
          try {
            // Télécharger le PDF depuis Supabase Storage
            final response = await supabaseService.client.storage
                .from('validation-pdfs')
                .download(validation.pdfPath);
            
            return Right(response);
          } catch (e) {
            return Left(ServerFailure('Impossible de télécharger le PDF: $e'));
          }
        },
      );
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }
  
  @override
  Future<Either<Failure, List<NotificationEntity>>> getUserNotifications(String userId) async {
    try {
      try {
        final notifications = await remoteDataSource.getUserNotifications(userId);
        // Sauvegarder en cache
        for (final notification in notifications) {
          await localDataSource.saveNotification(notification);
        }
        return Right(notifications);
      } on NetworkException {
        // Utiliser le cache
        final cachedNotifications = await localDataSource.getUserNotifications(userId);
        return Right(cachedNotifications);
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }
  
  @override
  Future<Either<Failure, NotificationEntity>> markNotificationAsRead(String notificationId) async {
    try {
      final updatedNotification = await remoteDataSource.markNotificationAsRead(notificationId);
      await localDataSource.saveNotification(updatedNotification);
      return Right(updatedNotification);
    } on NetworkException {
      // Marquer localement
      final notification = await localDataSource.markNotificationAsRead(notificationId);
      if (notification != null) {
        return Right(notification);
      }
      return Left(NetworkFailure('Impossible de marquer la notification'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }
  
  @override
  Future<Either<Failure, void>> markAllNotificationsAsRead(String userId) async {
    try {
      await remoteDataSource.markAllNotificationsAsRead(userId);
      await localDataSource.markAllNotificationsAsRead(userId);
      return const Right(null);
    } on NetworkException {
      await localDataSource.markAllNotificationsAsRead(userId);
      return Left(NetworkFailure('Marqué localement seulement'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }
  
  @override
  Future<Either<Failure, int>> getUnreadNotificationCount(String userId) async {
    try {
      try {
        final count = await remoteDataSource.getUnreadNotificationCount(userId);
        return Right(count);
      } on NetworkException {
        final count = await localDataSource.getUnreadNotificationCount(userId);
        return Right(count);
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }
  
  @override
  Future<Either<Failure, void>> syncOfflineData() async {
    try {
      final pendingSync = await localDataSource.getPendingSyncItems();
      
      for (final item in pendingSync) {
        try {
          switch (item['action']) {
            case 'create_validation':
              // Re-créer la validation
              await createValidationRequest(
                employeeId: item['payload']['employee_id'],
                managerId: item['payload']['manager_id'],
                periodStart: DateTime.parse(item['payload']['period_start']),
                periodEnd: DateTime.parse(item['payload']['period_end']),
                pdfBytes: item['payload']['pdf_bytes'],
              );
              break;
            case 'update_validation':
              // Mettre à jour la validation
              final status = item['payload']['status'];
              if (status == 'approved') {
                await approveValidation(
                  validationId: item['payload']['validation_id'],
                  managerSignature: item['payload']['manager_signature'],
                  comment: item['payload']['comment'],
                );
              } else if (status == 'rejected') {
                await rejectValidation(
                  validationId: item['payload']['validation_id'],
                  comment: item['payload']['comment'],
                );
              }
              break;
          }
          
          // Marquer comme synchronisé
          await localDataSource.markAsSynced(item['id']);
        } catch (e) {
          debugPrint('Error syncing item ${item['id']}: $e');
        }
      }
      
      return const Right(null);
    } catch (e) {
      return Left(SyncFailure('Erreur lors de la synchronisation'));
    }
  }
  
  @override
  Future<Either<Failure, List<Manager>>> getAvailableManagers(String employeeId) async {
    try {
      // Extraire la company de l'employeeId (format: firstName_lastName)
      // Pour cela, on doit récupérer la company depuis les préférences
      final getUserPref = di.getIt<GetUserPreferenceUseCase>();
      final company = await getUserPref.execute('company') ?? '';
      
      if (company.isEmpty) {
        return Left(ValidationFailure('Entreprise non configurée'));
      }
      
      // Récupérer les managers de la même entreprise depuis Supabase
      try {
        final response = await supabaseService.client
            .from('managers')
            .select()
            .eq('company', company);
        
        final managers = <Manager>[];
        
        if (response is List) {
          for (final row in response) {
            if (row is Map<String, dynamic>) {
              managers.add(Manager(
                id: row['id'] as String,
                email: row['email'] as String,
                name: '${row['first_name']} ${row['last_name']}',
              ));
            }
          }
        }
        
        if (managers.isEmpty) {
          return Left(ValidationFailure('Aucun manager disponible. Demandez à votre manager d\'activer le mode Manager dans les paramètres.'));
        }
        
        return Right(managers);
      } catch (e) {
        debugPrint('Supabase error getting managers: $e');
        // Si la table n'existe pas, retourner une erreur claire
        if (e.toString().contains('relation "managers" does not exist')) {
          return Left(ValidationFailure('La table des managers n\'est pas configurée. Veuillez contacter l\'administrateur.'));
        }
        return Left(ServerFailure('Erreur de connexion. Vérifiez votre connexion internet.'));
      }
    } catch (e) {
      debugPrint('Error getting available managers: $e');
      return Left(ServerFailure('Erreur lors de la récupération des managers: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, void>> deleteValidationRequest(String validationId) async {
    try {
      await remoteDataSource.deleteValidationRequest(validationId);
      await localDataSource.deleteValidationRequest(validationId);
      return const Right(null);
    } on NetworkException {
      await localDataSource.addToSyncQueue(
        action: 'delete_validation',
        payload: {'validation_id': validationId},
      );
      return Left(NetworkFailure('Suppression sauvegardée localement'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }
  
  @override
  Future<Either<Failure, void>> updateFCMToken(String token) async {
    try {
      // Firebase désactivé - pas de mise à jour du token FCM
      debugPrint('Firebase désactivé - token FCM non mis à jour');
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Impossible de mettre à jour le token FCM'));
    }
  }
  
  @override
  Stream<Either<Failure, List<ValidationRequest>>> watchEmployeeValidations(String employeeId) {
    return remoteDataSource.watchEmployeeValidations(employeeId).map((validations) {
      return Right<Failure, List<ValidationRequest>>(validations);
    }).handleError((error) {
      return Left<Failure, List<ValidationRequest>>(ServerFailure(error.toString()));
    });
  }
  
  @override
  Stream<Either<Failure, List<NotificationEntity>>> watchUserNotifications(String userId) {
    return remoteDataSource.watchUserNotifications(userId).map((notifications) {
      return Right<Failure, List<NotificationEntity>>(notifications);
    }).handleError((error) {
      return Left<Failure, List<NotificationEntity>>(ServerFailure(error.toString()));
    });
  }
}

/// Failures spécifiques
class AuthenticationFailure extends Failure {
  const AuthenticationFailure(String message) : super(message);
}

class SyncFailure extends Failure {
  const SyncFailure(String message) : super(message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}