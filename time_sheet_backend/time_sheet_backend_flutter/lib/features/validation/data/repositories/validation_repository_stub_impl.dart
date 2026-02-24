import 'dart:typed_data';
import 'package:fpdart/fpdart.dart';
import 'package:time_sheet/core/error/failures.dart';
import 'package:time_sheet/features/validation/domain/entities/validation_request.dart';
import 'package:time_sheet/features/validation/domain/entities/notification.dart';
import 'package:time_sheet/features/validation/domain/repositories/validation_repository.dart';

/// Stub implementation of ValidationRepository.
/// Returns empty results / not-implemented failures.
/// TODO: Replace with PowerSync/Supabase-based implementation.
class ValidationRepositoryStubImpl implements ValidationRepository {
  static const _msg = 'Validation non disponible (migration Supabase en cours)';

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
  }) async => Left(ServerFailure(_msg));

  @override
  Future<Either<Failure, ValidationRequest>> getValidationRequest(String id) async =>
      Left(ServerFailure(_msg));

  @override
  Future<Either<Failure, List<ValidationRequest>>> getEmployeeValidations(String employeeId) async =>
      const Right([]);

  @override
  Future<Either<Failure, List<ValidationRequest>>> getManagerValidations(String managerId) async =>
      const Right([]);

  @override
  Future<Either<Failure, ValidationRequest>> approveValidation({
    required String validationId,
    required String managerSignature,
    String? comment,
  }) async => Left(ServerFailure(_msg));

  @override
  Future<Either<Failure, ValidationRequest>> approveValidationWithSignedPdf({
    required String validationId,
    required Uint8List signedPdfBytes,
    required String managerName,
    String? comment,
  }) async => Left(ServerFailure(_msg));

  @override
  Future<Either<Failure, ValidationRequest>> rejectValidation({
    required String validationId,
    required String comment,
  }) async => Left(ServerFailure(_msg));

  @override
  Future<Either<Failure, Uint8List>> downloadValidationPdf(String validationId, [String? managerSignature]) async =>
      Left(ServerFailure(_msg));

  @override
  Future<Either<Failure, Map<String, dynamic>>> getValidationTimesheetData(String validationId) async =>
      Left(ServerFailure(_msg));

  @override
  Future<Either<Failure, List<NotificationEntity>>> getUserNotifications(String userId) async =>
      const Right([]);

  @override
  Future<Either<Failure, NotificationEntity>> markNotificationAsRead(String notificationId) async =>
      Left(ServerFailure(_msg));

  @override
  Future<Either<Failure, void>> markAllNotificationsAsRead(String userId) async =>
      const Right(null);

  @override
  Future<Either<Failure, int>> getUnreadNotificationCount(String userId) async =>
      const Right(0);

  @override
  Future<Either<Failure, void>> syncOfflineData() async =>
      const Right(null);

  @override
  Future<Either<Failure, List<Manager>>> getAvailableManagers(String employeeId) async =>
      const Right([]);

  @override
  Future<Either<Failure, void>> deleteValidationRequest(String validationId) async =>
      Left(ServerFailure(_msg));

  @override
  Future<Either<Failure, void>> updateFCMToken(String token) async =>
      const Right(null);

  @override
  Future<Either<Failure, String>> getSigningUrl({
    required String validationId,
    required String signerRole,
    required String signerName,
    String? signerEmail,
  }) async => Left(ServerFailure(_msg));

  @override
  Stream<Either<Failure, List<ValidationRequest>>> watchEmployeeValidations(String employeeId) =>
      Stream.value(const Right([]));

  @override
  Stream<Either<Failure, List<NotificationEntity>>> watchUserNotifications(String userId) =>
      Stream.value(const Right([]));

}
