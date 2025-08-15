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
import 'greeting.dart' as _i2;
import 'timesheet_data.dart' as _i3;
import 'timesheet_entry.dart' as _i4;
import 'timesheet_entry_data.dart' as _i5;
import 'manager.dart' as _i6;
import 'notification.dart' as _i7;
import 'notification_type.dart' as _i8;
import 'pdf_regeneration_queue.dart' as _i9;
import 'queue_status.dart' as _i10;
import 'timesheet_data_response.dart' as _i11;
import 'validation_request.dart' as _i12;
import 'validation_status.dart' as _i13;
import 'package:time_sheet_backend_client/src/protocol/manager.dart' as _i14;
import 'package:time_sheet_backend_client/src/protocol/notification.dart'
    as _i15;
import 'package:time_sheet_backend_client/src/protocol/notification_type.dart'
    as _i16;
import 'package:time_sheet_backend_client/src/protocol/timesheet_entry.dart'
    as _i17;
import 'package:time_sheet_backend_client/src/protocol/validation_request.dart'
    as _i18;
export 'greeting.dart';
export 'timesheet_data.dart';
export 'timesheet_entry.dart';
export 'timesheet_entry_data.dart';
export 'manager.dart';
export 'notification.dart';
export 'notification_type.dart';
export 'pdf_regeneration_queue.dart';
export 'queue_status.dart';
export 'timesheet_data_response.dart';
export 'validation_request.dart';
export 'validation_status.dart';
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;
    if (t == _i2.Greeting) {
      return _i2.Greeting.fromJson(data) as T;
    }
    if (t == _i3.TimesheetData) {
      return _i3.TimesheetData.fromJson(data) as T;
    }
    if (t == _i4.TimesheetEntry) {
      return _i4.TimesheetEntry.fromJson(data) as T;
    }
    if (t == _i5.TimesheetEntryData) {
      return _i5.TimesheetEntryData.fromJson(data) as T;
    }
    if (t == _i6.Manager) {
      return _i6.Manager.fromJson(data) as T;
    }
    if (t == _i7.Notification) {
      return _i7.Notification.fromJson(data) as T;
    }
    if (t == _i8.NotificationType) {
      return _i8.NotificationType.fromJson(data) as T;
    }
    if (t == _i9.PdfRegenerationQueue) {
      return _i9.PdfRegenerationQueue.fromJson(data) as T;
    }
    if (t == _i10.QueueStatus) {
      return _i10.QueueStatus.fromJson(data) as T;
    }
    if (t == _i11.TimesheetDataResponse) {
      return _i11.TimesheetDataResponse.fromJson(data) as T;
    }
    if (t == _i12.ValidationRequest) {
      return _i12.ValidationRequest.fromJson(data) as T;
    }
    if (t == _i13.ValidationStatus) {
      return _i13.ValidationStatus.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.Greeting?>()) {
      return (data != null ? _i2.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.TimesheetData?>()) {
      return (data != null ? _i3.TimesheetData.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.TimesheetEntry?>()) {
      return (data != null ? _i4.TimesheetEntry.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.TimesheetEntryData?>()) {
      return (data != null ? _i5.TimesheetEntryData.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.Manager?>()) {
      return (data != null ? _i6.Manager.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.Notification?>()) {
      return (data != null ? _i7.Notification.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.NotificationType?>()) {
      return (data != null ? _i8.NotificationType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.PdfRegenerationQueue?>()) {
      return (data != null ? _i9.PdfRegenerationQueue.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i10.QueueStatus?>()) {
      return (data != null ? _i10.QueueStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.TimesheetDataResponse?>()) {
      return (data != null ? _i11.TimesheetDataResponse.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i12.ValidationRequest?>()) {
      return (data != null ? _i12.ValidationRequest.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.ValidationStatus?>()) {
      return (data != null ? _i13.ValidationStatus.fromJson(data) : null) as T;
    }
    if (t == List<_i14.Manager>) {
      return (data as List).map((e) => deserialize<_i14.Manager>(e)).toList()
          as T;
    }
    if (t == Map<String, dynamic>) {
      return (data as Map).map((k, v) =>
          MapEntry(deserialize<String>(k), deserialize<dynamic>(v))) as T;
    }
    if (t == List<Map<String, dynamic>>) {
      return (data as List)
          .map((e) => deserialize<Map<String, dynamic>>(e))
          .toList() as T;
    }
    if (t == List<_i15.Notification>) {
      return (data as List)
          .map((e) => deserialize<_i15.Notification>(e))
          .toList() as T;
    }
    if (t == _i1.getType<Map<String, dynamic>?>()) {
      return (data != null
          ? (data as Map).map((k, v) =>
              MapEntry(deserialize<String>(k), deserialize<dynamic>(v)))
          : null) as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == Map<_i16.NotificationType, List<_i15.Notification>>) {
      return Map.fromEntries((data as List).map((e) => MapEntry(
          deserialize<_i16.NotificationType>(e['k']),
          deserialize<List<_i15.Notification>>(e['v'])))) as T;
    }
    if (t == List<_i17.TimesheetEntry>) {
      return (data as List)
          .map((e) => deserialize<_i17.TimesheetEntry>(e))
          .toList() as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == _i1.getType<List<int>?>()) {
      return (data != null
          ? (data as List).map((e) => deserialize<int>(e)).toList()
          : null) as T;
    }
    if (t == List<_i18.ValidationRequest>) {
      return (data as List)
          .map((e) => deserialize<_i18.ValidationRequest>(e))
          .toList() as T;
    }
    return super.deserialize<T>(data, t);
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;
    if (data is _i2.Greeting) {
      return 'Greeting';
    }
    if (data is _i3.TimesheetData) {
      return 'TimesheetData';
    }
    if (data is _i4.TimesheetEntry) {
      return 'TimesheetEntry';
    }
    if (data is _i5.TimesheetEntryData) {
      return 'TimesheetEntryData';
    }
    if (data is _i6.Manager) {
      return 'Manager';
    }
    if (data is _i7.Notification) {
      return 'Notification';
    }
    if (data is _i8.NotificationType) {
      return 'NotificationType';
    }
    if (data is _i9.PdfRegenerationQueue) {
      return 'PdfRegenerationQueue';
    }
    if (data is _i10.QueueStatus) {
      return 'QueueStatus';
    }
    if (data is _i11.TimesheetDataResponse) {
      return 'TimesheetDataResponse';
    }
    if (data is _i12.ValidationRequest) {
      return 'ValidationRequest';
    }
    if (data is _i13.ValidationStatus) {
      return 'ValidationStatus';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i2.Greeting>(data['data']);
    }
    if (dataClassName == 'TimesheetData') {
      return deserialize<_i3.TimesheetData>(data['data']);
    }
    if (dataClassName == 'TimesheetEntry') {
      return deserialize<_i4.TimesheetEntry>(data['data']);
    }
    if (dataClassName == 'TimesheetEntryData') {
      return deserialize<_i5.TimesheetEntryData>(data['data']);
    }
    if (dataClassName == 'Manager') {
      return deserialize<_i6.Manager>(data['data']);
    }
    if (dataClassName == 'Notification') {
      return deserialize<_i7.Notification>(data['data']);
    }
    if (dataClassName == 'NotificationType') {
      return deserialize<_i8.NotificationType>(data['data']);
    }
    if (dataClassName == 'PdfRegenerationQueue') {
      return deserialize<_i9.PdfRegenerationQueue>(data['data']);
    }
    if (dataClassName == 'QueueStatus') {
      return deserialize<_i10.QueueStatus>(data['data']);
    }
    if (dataClassName == 'TimesheetDataResponse') {
      return deserialize<_i11.TimesheetDataResponse>(data['data']);
    }
    if (dataClassName == 'ValidationRequest') {
      return deserialize<_i12.ValidationRequest>(data['data']);
    }
    if (dataClassName == 'ValidationStatus') {
      return deserialize<_i13.ValidationStatus>(data['data']);
    }
    return super.deserializeByClassName(data);
  }
}
