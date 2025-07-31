import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:time_sheet/core/error/exceptions.dart';
import 'package:time_sheet/features/validation/data/models/validation_request_model.dart';
import 'package:time_sheet/features/validation/data/models/notification_model.dart';
import 'package:time_sheet/features/validation/domain/repositories/validation_repository.dart';

/// Source de données distante pour les validations
abstract class ValidationRemoteDataSource {
  Future<ValidationRequestModel> createValidationRequest({
    required String organizationId,
    required String employeeId,
    required String managerId,
    required DateTime periodStart,
    required DateTime periodEnd,
    required String pdfPath,
    required String pdfHash,
    required int pdfSizeBytes,
  });
  
  Future<ValidationRequestModel> getValidationRequest(String id);
  Future<List<ValidationRequestModel>> getEmployeeValidations(String employeeId);
  Future<List<ValidationRequestModel>> getManagerValidations(String managerId);
  
  Future<ValidationRequestModel> approveValidation({
    required String validationId,
    required String managerSignature,
    String? comment,
  });
  
  Future<ValidationRequestModel> rejectValidation({
    required String validationId,
    required String comment,
  });
  
  Future<List<NotificationModel>> getUserNotifications(String userId);
  Future<NotificationModel> markNotificationAsRead(String notificationId);
  Future<void> markAllNotificationsAsRead(String userId);
  Future<int> getUnreadNotificationCount(String userId);
  
  Future<List<Manager>> getAvailableManagers(String employeeId);
  Future<void> deleteValidationRequest(String validationId);
  
  Stream<List<ValidationRequestModel>> watchEmployeeValidations(String employeeId);
  Stream<List<NotificationModel>> watchUserNotifications(String userId);
}

/// Implémentation avec Supabase
class ValidationRemoteDataSourceImpl implements ValidationRemoteDataSource {
  final SupabaseClient supabaseClient;
  
  const ValidationRemoteDataSourceImpl({
    required this.supabaseClient,
  });
  
  @override
  Future<ValidationRequestModel> createValidationRequest({
    required String organizationId,
    required String employeeId,
    required String managerId,
    required DateTime periodStart,
    required DateTime periodEnd,
    required String pdfPath,
    required String pdfHash,
    required int pdfSizeBytes,
  }) async {
    try {
      final data = {
        'organization_id': organizationId,
        'employee_id': employeeId,
        'manager_id': managerId,
        'period_start': periodStart.toIso8601String(),
        'period_end': periodEnd.toIso8601String(),
        'pdf_path': pdfPath,
        'pdf_hash': pdfHash,
        'pdf_size_bytes': pdfSizeBytes,
        'status': 'pending',
      };
      
      final response = await supabaseClient
          .from('validation_requests')
          .insert(data)
          .select()
          .single();
      
      return ValidationRequestModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw NetworkException();
    }
  }
  
  @override
  Future<ValidationRequestModel> getValidationRequest(String id) async {
    try {
      final response = await supabaseClient
          .from('validation_requests')
          .select()
          .eq('id', id)
          .single();
      
      return ValidationRequestModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw NetworkException();
    }
  }
  
  @override
  Future<List<ValidationRequestModel>> getEmployeeValidations(String employeeId) async {
    try {
      final response = await supabaseClient
          .from('validation_requests')
          .select()
          .eq('employee_id', employeeId)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => ValidationRequestModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw NetworkException();
    }
  }
  
  @override
  Future<List<ValidationRequestModel>> getManagerValidations(String managerId) async {
    try {
      final response = await supabaseClient
          .from('validation_requests')
          .select()
          .eq('manager_id', managerId)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => ValidationRequestModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw NetworkException();
    }
  }
  
  @override
  Future<ValidationRequestModel> approveValidation({
    required String validationId,
    required String managerSignature,
    String? comment,
  }) async {
    try {
      final data = {
        'status': 'approved',
        'status_changed_at': DateTime.now().toIso8601String(),
        'manager_signature': managerSignature,
        'manager_comment': comment,
        'validated_at': DateTime.now().toIso8601String(),
      };
      
      final response = await supabaseClient
          .from('validation_requests')
          .update(data)
          .eq('id', validationId)
          .select()
          .single();
      
      return ValidationRequestModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw NetworkException();
    }
  }
  
  @override
  Future<ValidationRequestModel> rejectValidation({
    required String validationId,
    required String comment,
  }) async {
    try {
      final data = {
        'status': 'rejected',
        'status_changed_at': DateTime.now().toIso8601String(),
        'manager_comment': comment,
      };
      
      final response = await supabaseClient
          .from('validation_requests')
          .update(data)
          .eq('id', validationId)
          .select()
          .single();
      
      return ValidationRequestModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw NetworkException();
    }
  }
  
  @override
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      final response = await supabaseClient
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw NetworkException();
    }
  }
  
  @override
  Future<NotificationModel> markNotificationAsRead(String notificationId) async {
    try {
      final data = {
        'read': true,
        'read_at': DateTime.now().toIso8601String(),
      };
      
      final response = await supabaseClient
          .from('notifications')
          .update(data)
          .eq('id', notificationId)
          .select()
          .single();
      
      return NotificationModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw NetworkException();
    }
  }
  
  @override
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final data = {
        'read': true,
        'read_at': DateTime.now().toIso8601String(),
      };
      
      await supabaseClient
          .from('notifications')
          .update(data)
          .eq('user_id', userId)
          .eq('read', false);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw NetworkException();
    }
  }
  
  @override
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final response = await supabaseClient
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('read', false)
          .count();
      
      return response.count;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw NetworkException();
    }
  }
  
  @override
  Future<List<Manager>> getAvailableManagers(String employeeId) async {
    try {
      final response = await supabaseClient
          .rpc('get_managers_for_employee', params: {'employee_uuid': employeeId});
      
      return (response as List).map((json) => Manager(
        id: json['id'] as String,
        email: json['email'] as String,
      )).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw NetworkException();
    }
  }
  
  @override
  Future<void> deleteValidationRequest(String validationId) async {
    try {
      await supabaseClient
          .from('validation_requests')
          .delete()
          .eq('id', validationId)
          .eq('status', 'pending');
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw NetworkException();
    }
  }
  
  @override
  Stream<List<ValidationRequestModel>> watchEmployeeValidations(String employeeId) {
    return supabaseClient
        .from('validation_requests')
        .stream(primaryKey: ['id'])
        .eq('employee_id', employeeId)
        .order('created_at')
        .map((data) => data.map((json) => ValidationRequestModel.fromJson(json)).toList());
  }
  
  @override
  Stream<List<NotificationModel>> watchUserNotifications(String userId) {
    return supabaseClient
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at')
        .map((data) => data.map((json) => NotificationModel.fromJson(json)).toList());
  }
}