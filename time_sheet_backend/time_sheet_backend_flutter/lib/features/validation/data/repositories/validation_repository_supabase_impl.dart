import 'dart:convert';
import 'dart:typed_data';
import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';
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
    String? employeeSignature,
    String? clientSignerName,
    String? clientSignerEmail,
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

      // Insert validation request via PowerSync (syncs to Supabase)
      // employee_signature_url stocke la signature base64 directement (pas un URL Storage)
      await _db.execute(
        '''INSERT INTO validation_requests
          (id, employee_id, manager_id, period_start, period_end, status,
           pdf_url, employee_signature_url, signing_step, client_signer_name, client_signer_email)
          VALUES (uuid(), ?, ?, ?, ?, 'pending', ?, ?, 'employee', ?, ?)''',
        [
          employeeId, managerId,
          periodStart.toIso8601String().substring(0, 10),
          periodEnd.toIso8601String().substring(0, 10),
          pdfUrl, employeeSignature ?? '',
          clientSignerName ?? '', clientSignerEmail ?? '',
        ],
      );

      // Ensure manager_employees relationship exists (needed for PowerSync sync)
      try {
        await _supabase.from('manager_employees').upsert(
          {'manager_id': managerId, 'employee_id': employeeId},
          onConflict: 'manager_id,employee_id',
        );
      } catch (e) {
        // Non-critical: fallback to local insert if Supabase fails
        logger.w('Could not upsert manager_employees via Supabase: $e');
        try {
          final existing = await _db.getOptional(
            'SELECT id FROM manager_employees WHERE manager_id = ? AND employee_id = ?',
            [managerId, employeeId],
          );
          if (existing == null) {
            await _db.execute(
              'INSERT INTO manager_employees (id, manager_id, employee_id) VALUES (uuid(), ?, ?)',
              [managerId, employeeId],
            );
          }
        } catch (_) {}
      }

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
      // Préférer Supabase pour avoir les données fraîches (signing_step, status, manager_signature_url)
      // mises à jour par les Edge Functions
      Map<String, dynamic>? row;
      try {
        row = await _supabase
            .from('validation_requests')
            .select()
            .eq('id', id)
            .maybeSingle();
      } catch (e) {
        logger.w('Supabase query for validation_request failed, falling back to local: $e');
      }
      if (row == null) {
        final localRow = await _db.getOptional(
          'SELECT * FROM validation_requests WHERE id = ?',
          [id],
        );
        if (localRow != null) {
          row = Map<String, dynamic>.from(localRow);
        }
      }
      if (row == null) {
        return const Left(ServerFailure('Validation non trouvée'));
      }
      var validation = _rowToValidation(row);

      // Enrichir avec le nom du manager depuis les profils
      final managerId = row['manager_id'] as String?;
      if (managerId != null && managerId.isNotEmpty) {
        final managerProfile = await _db.getOptional(
          'SELECT first_name, last_name FROM profiles WHERE id = ?',
          [managerId],
        );
        if (managerProfile != null) {
          final name = '${managerProfile['first_name'] ?? ''} ${managerProfile['last_name'] ?? ''}'.trim();
          if (name.isNotEmpty) {
            validation = validation.copyWith(managerName: name);
          }
        }
      }

      return Right(validation);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ValidationRequest>>> getEmployeeValidations(String employeeId) async {
    try {
      // 1. Essayer via Supabase directement (données toujours à jour)
      try {
        final response = await _supabase
            .from('validation_requests')
            .select()
            .eq('employee_id', employeeId)
            .order('created_at', ascending: false);
        final supabaseRows = List<Map<String, dynamic>>.from(response);
        if (supabaseRows.isNotEmpty) {
          return Right(supabaseRows.map((row) => _rowToValidation(row)).toList());
        }
      } catch (e) {
        logger.w('Supabase direct query for employee validations failed, falling back to local: $e');
      }

      // 2. Fallback: requête locale PowerSync
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
      // 1. Essayer via Supabase directement (données toujours à jour)
      try {
        final response = await _supabase
            .from('validation_requests')
            .select()
            .eq('manager_id', managerId)
            .order('created_at', ascending: false);
        final supabaseRows = List<Map<String, dynamic>>.from(response);
        if (supabaseRows.isNotEmpty) {
          return Right(supabaseRows.map((row) => _rowToValidation(row)).toList());
        }
      } catch (e) {
        logger.w('Supabase direct query for manager validations failed, falling back to local: $e');
      }

      // 2. Fallback: requête locale PowerSync
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
      // Appeler l'Edge Function approve-validation qui gère :
      // - L'avancement du signing_step (manager → client ou completed)
      // - La création du token de signature client si nécessaire
      // - La mise à jour du statut
      final response = await _supabase.functions.invoke(
        'approve-validation',
        body: {
          'validation_id': validationId,
          'manager_signature': managerSignature,
          'comment': comment ?? '',
        },
      );

      if (response.status != 200) {
        final errorData = response.data;
        final errorMsg = errorData is Map ? errorData['error'] as String? : null;
        return Left(ServerFailure(errorMsg ?? 'Erreur lors de l\'approbation (${response.status})'));
      }

      // Rafraîchir les données locales depuis Supabase pour refléter les changements
      // faits par l'Edge Function (signing_step, status, etc.)
      try {
        final row = await _supabase
            .from('validation_requests')
            .select()
            .eq('id', validationId)
            .maybeSingle();
        if (row != null) {
          return Right(_rowToValidation(row));
        }
      } catch (e) {
        logger.w('Fallback to local after approve: $e');
      }

      return getValidationRequest(validationId);
    } catch (e) {
      logger.e('Error approving validation via Edge Function', error: e);
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
      // Try local PowerSync first
      String? pdfUrl;
      final validation = await _db.getOptional(
        'SELECT pdf_url FROM validation_requests WHERE id = ?',
        [validationId],
      );
      if (validation != null && validation['pdf_url'] != null) {
        pdfUrl = validation['pdf_url'] as String;
      }

      // Fallback to Supabase direct query if not found locally
      if (pdfUrl == null || pdfUrl.isEmpty) {
        logger.i('pdf_url not found locally, falling back to Supabase');
        try {
          final row = await _supabase
              .from('validation_requests')
              .select('pdf_url')
              .eq('id', validationId)
              .maybeSingle();
          if (row != null && row['pdf_url'] != null) {
            pdfUrl = row['pdf_url'] as String;
          }
        } catch (e) {
          logger.w('Supabase fallback for pdf_url failed: $e');
        }
      }

      if (pdfUrl == null || pdfUrl.isEmpty) {
        return const Left(ServerFailure('PDF non trouvé'));
      }

      // Extract relative path from full URL if needed
      // e.g. "https://.../storage/v1/object/public/pdfs/userId/file.pdf" -> "userId/file.pdf"
      String storagePath = pdfUrl;
      final pdfsBucketMarker = '/pdfs/';
      final markerIndex = pdfUrl.indexOf(pdfsBucketMarker);
      if (markerIndex != -1) {
        storagePath = pdfUrl.substring(markerIndex + pdfsBucketMarker.length);
      }

      // Download from Storage
      logger.i('Downloading PDF from Storage path: $storagePath');
      final response = await _supabase.storage.from('pdfs').download(storagePath);
      return Right(response);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getValidationTimesheetData(String validationId) async {
    try {
      // 1. Get validation request (Supabase first for fresh signing_step/manager_signature_url,
      //    then fallback to local PowerSync)
      Map<String, dynamic>? rowData;
      try {
        rowData = await _supabase
            .from('validation_requests')
            .select()
            .eq('id', validationId)
            .maybeSingle();
      } catch (e) {
        logger.w('Supabase query for validation_requests failed, falling back to local: $e');
      }
      if (rowData == null) {
        final localRow = await _db.getOptional(
          'SELECT * FROM validation_requests WHERE id = ?',
          [validationId],
        );
        if (localRow != null) {
          rowData = Map<String, dynamic>.from(localRow);
        }
      }
      if (rowData == null) {
        return const Left(ServerFailure('Validation non trouvée'));
      }

      final employeeId = rowData['employee_id'] as String;
      final periodStart = rowData['period_start'] as String;
      final periodEnd = rowData['period_end'] as String;

      // Parse period to extract month/year (period_end is the 20th of the target month)
      final endDate = DateTime.parse(periodEnd);
      final month = endDate.month;
      final year = endDate.year;

      // 2. Get employee profile (local first, then Supabase)
      Map<String, dynamic>? profileData;
      final localProfile = await _db.getOptional(
        'SELECT first_name, last_name, email, signature_url, organization_id FROM profiles WHERE id = ?',
        [employeeId],
      );
      if (localProfile != null) {
        profileData = Map<String, dynamic>.from(localProfile);
      } else {
        try {
          profileData = await _supabase
              .from('profiles')
              .select('first_name, last_name, email, signature_url, organization_id')
              .eq('id', employeeId)
              .maybeSingle();
        } catch (e) {
          logger.w('Supabase fallback for employee profile failed: $e');
        }
      }

      final employeeName = profileData != null
          ? '${profileData['first_name'] ?? ''} ${profileData['last_name'] ?? ''}'.trim()
          : '';
      // Get organization name for company
      String employeeCompany = '';
      if (profileData != null && profileData['organization_id'] != null) {
        Map<String, dynamic>? orgData;
        final localOrg = await _db.getOptional(
          'SELECT name FROM organizations WHERE id = ?',
          [profileData['organization_id']],
        );
        if (localOrg != null) {
          orgData = Map<String, dynamic>.from(localOrg);
        } else {
          try {
            orgData = await _supabase
                .from('organizations')
                .select('name')
                .eq('id', profileData['organization_id'])
                .maybeSingle();
          } catch (e) {
            logger.w('Supabase fallback for organization failed: $e');
          }
        }
        employeeCompany = (orgData?['name'] as String?) ?? '';
      }

      // Les signatures ne sont pas stockées dans Storage (sécurité).
      // La signature de l'employé est intégrée dans le PDF stocké.
      // La signature du manager est stockée en base64 dans validation_requests.manager_signature_url.

      // 3. Get manager info
      String? managerName;
      String? managerSignatureBase64;
      final managerId = rowData['manager_id'] as String?;
      if (managerId != null) {
        Map<String, dynamic>? managerProfileData;
        final localMgrProfile = await _db.getOptional(
          'SELECT first_name, last_name FROM profiles WHERE id = ?',
          [managerId],
        );
        if (localMgrProfile != null) {
          managerProfileData = Map<String, dynamic>.from(localMgrProfile);
        } else {
          try {
            managerProfileData = await _supabase
                .from('profiles')
                .select('first_name, last_name')
                .eq('id', managerId)
                .maybeSingle();
          } catch (e) {
            logger.w('Supabase fallback for manager profile failed: $e');
          }
        }
        if (managerProfileData != null) {
          managerName = '${managerProfileData['first_name'] ?? ''} ${managerProfileData['last_name'] ?? ''}'.trim();
        }

        // Get manager signature from validation_requests (stored as base64 on approval)
        // La signature manager est disponible dès que signing_step avance à 'client' ou 'completed',
        // même si le status reste 'pending' (en attente de la signature client)
        final status = rowData['status'] as String? ?? 'pending';
        final signingStep = rowData['signing_step'] as String? ?? '';
        if (status == 'approved' || signingStep == 'client' || signingStep == 'completed') {
          managerSignatureBase64 = rowData['manager_signature_url'] as String?;
        }
      }

      // 4. Get timesheet entries for the period (local first, then Supabase)
      final localEntries = await _db.getAll(
        'SELECT * FROM timesheet_entries WHERE user_id = ? AND day_date >= ? AND day_date <= ? ORDER BY day_date',
        [employeeId, periodStart, periodEnd],
      );

      List<Map<String, dynamic>> entriesData;
      if (localEntries.isNotEmpty) {
        entriesData = localEntries.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        // Fallback to Supabase if no local entries (e.g. manager doesn't have employee data synced)
        logger.i('No local timesheet entries found, falling back to Supabase direct query');
        entriesData = [];
        try {
          final response = await _supabase
              .from('timesheet_entries')
              .select()
              .eq('user_id', employeeId)
              .gte('day_date', periodStart)
              .lte('day_date', periodEnd)
              .order('day_date');
          entriesData = List<Map<String, dynamic>>.from(response);
        } catch (e) {
          logger.w('Supabase fallback for timesheet entries failed: $e');
        }
      }

      logger.i('getValidationTimesheetData: ${entriesData.length} entries found for period $periodStart - $periodEnd');

      // Convert entries to the expected format
      // day_date in DB is yyyy-MM-dd, but the PDF use case expects dd-MMM-yy
      final entriesList = entriesData.map((e) {
        final dbDate = (e['day_date'] as String?) ?? '';
        String formattedDate = dbDate;
        try {
          final parsed = DateTime.parse(dbDate);
          formattedDate = DateFormat('dd-MMM-yy', 'en_US').format(parsed);
        } catch (_) {}
        final absenceReason = (e['absence_reason'] as String?) ?? '';
        final hasAbsence = absenceReason.isNotEmpty;
        return <String, dynamic>{
          'dayDate': formattedDate,
          'startMorning': e['start_morning'] ?? '',
          'endMorning': e['end_morning'] ?? '',
          'startAfternoon': e['start_afternoon'] ?? '',
          'endAfternoon': e['end_afternoon'] ?? '',
          'isAbsence': hasAbsence,
          'absenceReason': absenceReason,
          'hasOvertimeHours': e['has_overtime_hours'] == 1 || e['has_overtime_hours'] == true,
          'period': e['period'] ?? '',
        };
      }).toList();

      final data = <String, dynamic>{
        'validationId': rowData['id'],
        'employeeId': employeeId,
        'status': rowData['status'],
        'signingStep': rowData['signing_step'],
        'periodStart': periodStart,
        'periodEnd': periodEnd,
        'managerComment': rowData['manager_comment'],
        'validatedAt': rowData['validated_at'],
        'month': month,
        'year': year,
        'employeeName': employeeName,
        'employeeCompany': employeeCompany,
        'employeeSignature': (rowData['employee_signature_url'] as String?)?.isNotEmpty == true
          ? rowData['employee_signature_url'] as String
          : null,
        'managerName': managerName,
        'managerSignature': managerSignatureBase64,
        'entries': entriesList,
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
      final realUserId = _userId;

      List<Map<String, dynamic>> rows = [];

      // 1. Essayer via RPC Supabase (bypass RLS, données toujours à jour)
      try {
        final response = await _supabase.rpc(
          'get_managers_for_employee',
          params: {'employee_user_id': realUserId},
        );
        rows = List<Map<String, dynamic>>.from(response);
      } catch (rpcError) {
        logger.w('RPC get_managers_for_employee failed, falling back to local query: $rpcError');
      }

      // 2. Fallback: requête locale PowerSync (même org)
      if (rows.isEmpty) {
        final localRows = await _db.getAll(
          '''SELECT p.id, p.email, p.first_name, p.last_name FROM profiles p
            WHERE p.role IN ('manager', 'admin', 'org_admin', 'super_admin') AND p.is_active = 1
            AND p.organization_id IS NOT NULL
            AND p.organization_id = (
              SELECT organization_id FROM profiles WHERE id = ?
            )''',
          [realUserId],
        );
        rows = localRows.map((r) => Map<String, dynamic>.from(r)).toList();
      }

      // 3. Fallback: via manager_employees
      if (rows.isEmpty) {
        final meRows = await _db.getAll(
          '''SELECT p.id, p.email, p.first_name, p.last_name FROM profiles p
            INNER JOIN manager_employees me ON me.manager_id = p.id
            WHERE me.employee_id = ?''',
          [realUserId],
        );
        rows = meRows.map((r) => Map<String, dynamic>.from(r)).toList();
      }

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

  @override
  Future<Either<Failure, String>> getSigningUrl({
    required String validationId,
    required String signerRole,
    required String signerName,
    String? signerEmail,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'generate-signing-token',
        body: {
          'validation_id': validationId,
          'next_signer_role': signerRole,
          'signer_name': signerName,
          if (signerEmail != null) 'signer_email': signerEmail,
        },
      );

      if (response.status != 200) {
        final errorData = response.data;
        final errorMsg = errorData is Map ? errorData['error'] as String? : null;
        return Left(ServerFailure(errorMsg ?? 'Erreur lors de la génération du lien (${response.status})'));
      }

      final data = response.data as Map<String, dynamic>;
      final signingUrl = data['signing_url'] as String?;
      if (signingUrl == null || signingUrl.isEmpty) {
        return const Left(ServerFailure('URL de signature non disponible'));
      }

      return Right(signingUrl);
    } catch (e) {
      logger.e('Error generating signing URL', error: e);
      return Left(ServerFailure(e.toString()));
    }
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
      managerSignature: row['manager_signature_url'] as String?,
      validatedAt: row['validated_at'] != null ? DateTime.tryParse(row['validated_at'] as String) : null,
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? '') ?? DateTime.now(),
      expiresAt: row['expires_at'] != null ? DateTime.tryParse(row['expires_at'] as String) : null,
      pdfPath: row['pdf_url'] as String? ?? '',
      pdfHash: '',
      pdfSizeBytes: 0,
      signingStep: row['signing_step'] as String?,
      clientSignerName: row['client_signer_name'] as String?,
      clientSignerEmail: row['client_signer_email'] as String?,
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
      case 'signing':
        return ValidationStatus.pending;
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
