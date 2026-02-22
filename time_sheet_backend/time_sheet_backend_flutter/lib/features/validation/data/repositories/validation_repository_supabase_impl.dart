import 'dart:convert';
import 'dart:typed_data';
import 'package:fpdart/fpdart.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/database/powersync_database.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/storage/storage_service.dart';
import '../../../../core/services/supabase/supabase_service.dart';
import '../../../../services/logger_service.dart';
import '../../domain/entities/notification.dart';
import '../../domain/entities/validation_request.dart';
import '../../domain/repositories/validation_repository.dart';

/// Supabase + PowerSync based implementation of ValidationRepository.
/// Replaces the Serverpod-based implementation.
class ValidationRepositorySupabaseImpl implements ValidationRepository {
  final PowerSyncDatabase _db;
  final SupabaseClient _supabase;
  final StorageService _storage;

  ValidationRepositorySupabaseImpl({
    PowerSyncDatabase? db,
    SupabaseClient? supabase,
    StorageService? storage,
  })  : _db = db ?? PowerSyncDatabaseManager.database,
        _supabase = supabase ?? SupabaseService.instance.client,
        _storage = storage ?? StorageService();

  String get _userId => SupabaseService.instance.currentUserId ?? '';

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
      // Upload PDF to storage
      final month = periodStart.month;
      final year = periodStart.year;
      final pdfUrl = await _storage.uploadPdf(
        pdfBytes: pdfBytes,
        year: year,
        month: month,
        customFileName: 'validation_${year}_$month.pdf',
      );

      // Upload employee signature if available
      String? signatureUrl;
      try {
        signatureUrl = await _storage.getSignatureUrl();
      } catch (_) {}

      // Insert validation request via PowerSync (syncs to Supabase)
      await _db.execute(
        '''INSERT INTO validation_requests
          (id, employee_id, manager_id, period_start, period_end, status,
           pdf_url, employee_signature_url)
          VALUES (uuid(), ?, ?, ?, ?, 'pending', ?, ?)''',
        [
          employeeId, managerId,
          periodStart.toIso8601String().substring(0, 10),
          periodEnd.toIso8601String().substring(0, 10),
          pdfUrl, signatureUrl ?? '',
        ],
      );

      // Create notification for manager
      await _db.execute(
        '''INSERT INTO notifications
          (id, user_id, type, title, message, data, is_read)
          VALUES (uuid(), ?, 'validation_created', ?,  ?, ?, 0)''',
        [
          managerId,
          'Nouvelle demande de validation',
          '${employeeName ?? 'Un employé'} a soumis une demande de validation pour ${periodStart.month}/$year',
          jsonEncode({'employee_id': employeeId, 'period': '$month/$year'}),
        ],
      );

      // Fetch the created validation
      final row = await _db.getOptional(
        '''SELECT * FROM validation_requests
          WHERE employee_id = ? AND manager_id = ? AND period_start = ?
          ORDER BY created_at DESC LIMIT 1''',
        [employeeId, managerId, periodStart.toIso8601String().substring(0, 10)],
      );

      if (row == null) {
        return const Left(ServerFailure('Impossible de créer la validation'));
      }

      return Right(_rowToValidation(row));
    } catch (e) {
      logger.e('Error creating validation request', error: e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ValidationRequest>> getValidationRequest(String id) async {
    try {
      final row = await _db.getOptional(
        'SELECT * FROM validation_requests WHERE id = ?',
        [id],
      );
      if (row == null) {
        return const Left(ServerFailure('Validation non trouvée'));
      }
      return Right(_rowToValidation(row));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ValidationRequest>>> getEmployeeValidations(String employeeId) async {
    try {
      final rows = await _db.getAll(
        'SELECT * FROM validation_requests WHERE employee_id = ? ORDER BY created_at DESC',
        [employeeId],
      );
      return Right(rows.map((row) => _rowToValidation(row)).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ValidationRequest>>> getManagerValidations(String managerId) async {
    try {
      final rows = await _db.getAll(
        'SELECT * FROM validation_requests WHERE manager_id = ? ORDER BY created_at DESC',
        [managerId],
      );
      return Right(rows.map((row) => _rowToValidation(row)).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ValidationRequest>> approveValidation({
    required String validationId,
    required String managerSignature,
    String? comment,
  }) async {
    try {
      await _db.execute(
        '''UPDATE validation_requests
          SET status = 'approved', manager_comment = ?,
              validated_at = datetime('now'), manager_signature_url = ?
          WHERE id = ?''',
        [comment ?? '', managerSignature, validationId],
      );

      // Notify the employee
      final validation = await _db.getOptional(
        'SELECT * FROM validation_requests WHERE id = ?',
        [validationId],
      );
      if (validation != null) {
        await _db.execute(
          '''INSERT INTO notifications
            (id, user_id, type, title, message, is_read)
            VALUES (uuid(), ?, 'validation_approved', 'Validation approuvée',
                    'Votre demande de validation a été approuvée', 0)''',
          [validation['employee_id']],
        );
      }

      return getValidationRequest(validationId);
    } catch (e) {
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
      // Upload signed PDF
      final validation = await _db.getOptional(
        'SELECT * FROM validation_requests WHERE id = ?',
        [validationId],
      );
      if (validation == null) {
        return const Left(ServerFailure('Validation non trouvée'));
      }

      final pdfUrl = await _storage.uploadPdf(
        pdfBytes: signedPdfBytes,
        year: DateTime.now().year,
        month: DateTime.now().month,
        customFileName: 'validation_signed_$validationId.pdf',
      );

      await _db.execute(
        '''UPDATE validation_requests
          SET status = 'approved', manager_comment = ?, pdf_url = ?,
              validated_at = datetime('now')
          WHERE id = ?''',
        [comment ?? '', pdfUrl, validationId],
      );

      // Notify employee
      await _db.execute(
        '''INSERT INTO notifications
          (id, user_id, type, title, message, is_read)
          VALUES (uuid(), ?, 'validation_approved', 'Validation approuvée',
                  'Votre validation a été approuvée par $managerName', 0)''',
        [validation['employee_id']],
      );

      return getValidationRequest(validationId);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ValidationRequest>> rejectValidation({
    required String validationId,
    required String comment,
  }) async {
    try {
      await _db.execute(
        '''UPDATE validation_requests
          SET status = 'rejected', manager_comment = ?,
              validated_at = datetime('now')
          WHERE id = ?''',
        [comment, validationId],
      );

      final validation = await _db.getOptional(
        'SELECT * FROM validation_requests WHERE id = ?',
        [validationId],
      );
      if (validation != null) {
        await _db.execute(
          '''INSERT INTO notifications
            (id, user_id, type, title, message, is_read)
            VALUES (uuid(), ?, 'validation_rejected', 'Validation rejetée',
                    'Votre validation a été rejetée. Motif: $comment', 0)''',
          [validation['employee_id']],
        );
      }

      return getValidationRequest(validationId);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Uint8List>> downloadValidationPdf(String validationId, [String? managerSignature]) async {
    try {
      final validation = await _db.getOptional(
        'SELECT pdf_url FROM validation_requests WHERE id = ?',
        [validationId],
      );
      if (validation == null || validation['pdf_url'] == null) {
        return const Left(ServerFailure('PDF non trouvé'));
      }

      // Download from Storage URL
      final pdfUrl = validation['pdf_url'] as String;
      final response = await _supabase.storage.from('pdfs').download(pdfUrl);
      return Right(response);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getValidationTimesheetData(String validationId) async {
    try {
      final row = await _db.getOptional(
        'SELECT * FROM validation_requests WHERE id = ?',
        [validationId],
      );
      if (row == null) {
        return const Left(ServerFailure('Validation non trouvée'));
      }

      final data = <String, dynamic>{
        'validationId': row['id'],
        'employeeId': row['employee_id'],
        'status': row['status'],
        'periodStart': row['period_start'],
        'periodEnd': row['period_end'],
        'managerComment': row['manager_comment'],
        'validatedAt': row['validated_at'],
      };

      return Right(data);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<NotificationEntity>>> getUserNotifications(String userId) async {
    try {
      final rows = await _db.getAll(
        'SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC',
        [userId],
      );
      return Right(rows.map((row) => _rowToNotification(row)).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, NotificationEntity>> markNotificationAsRead(String notificationId) async {
    try {
      await _db.execute(
        '''UPDATE notifications SET is_read = 1, read_at = datetime('now')
          WHERE id = ?''',
        [notificationId],
      );
      final row = await _db.getOptional(
        'SELECT * FROM notifications WHERE id = ?',
        [notificationId],
      );
      if (row == null) {
        return const Left(ServerFailure('Notification non trouvée'));
      }
      return Right(_rowToNotification(row));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAllNotificationsAsRead(String userId) async {
    try {
      await _db.execute(
        '''UPDATE notifications SET is_read = 1, read_at = datetime('now')
          WHERE user_id = ? AND is_read = 0''',
        [userId],
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadNotificationCount(String userId) async {
    try {
      final result = await _db.getOptional(
        'SELECT COUNT(*) as count FROM notifications WHERE user_id = ? AND is_read = 0',
        [userId],
      );
      return Right(result?['count'] as int? ?? 0);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncOfflineData() async {
    // PowerSync handles sync automatically
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Manager>>> getAvailableManagers(String employeeId) async {
    try {
      final rows = await _db.getAll(
        '''SELECT p.id, p.email, p.first_name, p.last_name FROM profiles p
          WHERE p.role IN ('manager', 'admin') AND p.is_active = 1
          AND p.organization_id = (
            SELECT organization_id FROM profiles WHERE id = ?
          )''',
        [employeeId],
      );
      return Right(rows.map((row) => Manager(
        id: row['id'] as String,
        email: row['email'] as String? ?? '',
        name: '${row['first_name'] ?? ''} ${row['last_name'] ?? ''}'.trim(),
      )).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteValidationRequest(String validationId) async {
    try {
      await _db.execute(
        "DELETE FROM validation_requests WHERE id = ? AND status = 'pending'",
        [validationId],
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateFCMToken(String token) async {
    // FCM tokens can be stored in profiles or a separate table
    return const Right(null);
  }

  @override
  Stream<Either<Failure, List<ValidationRequest>>> watchEmployeeValidations(String employeeId) {
    return _db.watch(
      'SELECT * FROM validation_requests WHERE employee_id = ? ORDER BY created_at DESC',
      parameters: [employeeId],
    ).map((rows) {
      try {
        return Right<Failure, List<ValidationRequest>>(
          rows.map((row) => _rowToValidation(row)).toList(),
        );
      } catch (e) {
        return Left<Failure, List<ValidationRequest>>(ServerFailure(e.toString()));
      }
    });
  }

  @override
  Stream<Either<Failure, List<NotificationEntity>>> watchUserNotifications(String userId) {
    return _db.watch(
      'SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC',
      parameters: [userId],
    ).map((rows) {
      try {
        return Right<Failure, List<NotificationEntity>>(
          rows.map((row) => _rowToNotification(row)).toList(),
        );
      } catch (e) {
        return Left<Failure, List<NotificationEntity>>(ServerFailure(e.toString()));
      }
    });
  }

  ValidationRequest _rowToValidation(Map<String, dynamic> row) {
    return ValidationRequest(
      id: row['id'] as String? ?? '',
      organizationId: '',
      employeeId: row['employee_id'] as String? ?? '',
      employeeName: '',
      managerId: row['manager_id'] as String? ?? '',
      periodStart: DateTime.tryParse(row['period_start'] as String? ?? '') ?? DateTime.now(),
      periodEnd: DateTime.tryParse(row['period_end'] as String? ?? '') ?? DateTime.now(),
      status: _parseStatus(row['status'] as String? ?? 'pending'),
      managerComment: row['manager_comment'] as String?,
      validatedAt: row['validated_at'] != null ? DateTime.tryParse(row['validated_at'] as String) : null,
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? '') ?? DateTime.now(),
      pdfPath: row['pdf_url'] as String? ?? '',
      pdfHash: '',
      pdfSizeBytes: 0,
    );
  }

  NotificationEntity _rowToNotification(Map<String, dynamic> row) {
    return NotificationEntity(
      id: row['id'] as String? ?? '',
      userId: row['user_id'] as String? ?? '',
      type: _parseNotificationType(row['type'] as String? ?? ''),
      title: row['title'] as String? ?? '',
      body: row['message'] as String? ?? '',
      data: row['data'] != null ? jsonDecode(row['data'] as String) as Map<String, dynamic>? : null,
      read: (row['is_read'] as int? ?? 0) == 1,
      readAt: row['read_at'] != null ? DateTime.tryParse(row['read_at'] as String) : null,
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  ValidationStatus _parseStatus(String status) {
    switch (status) {
      case 'approved':
        return ValidationStatus.approved;
      case 'rejected':
        return ValidationStatus.rejected;
      case 'expired':
        return ValidationStatus.rejected;
      default:
        return ValidationStatus.pending;
    }
  }

  NotificationType _parseNotificationType(String type) {
    switch (type) {
      case 'validation_created':
      case 'validation_reminder':
        return NotificationType.validationRequest;
      case 'validation_approved':
      case 'validation_rejected':
        return NotificationType.validationFeedback;
      default:
        return NotificationType.reminder;
    }
  }
}
