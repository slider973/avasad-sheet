/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;

abstract class TimesheetDataResponse
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  TimesheetDataResponse._({
    required this.validationId,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCompany,
    required this.month,
    required this.year,
    required this.entries,
    required this.totalDays,
    required this.totalHours,
    required this.totalOvertimeHours,
    required this.periodStart,
    required this.periodEnd,
    required this.status,
    this.managerName,
    this.managerComment,
    this.validatedAt,
  });

  factory TimesheetDataResponse({
    required int validationId,
    required String employeeId,
    required String employeeName,
    required String employeeCompany,
    required int month,
    required int year,
    required String entries,
    required double totalDays,
    required String totalHours,
    required String totalOvertimeHours,
    required DateTime periodStart,
    required DateTime periodEnd,
    required String status,
    String? managerName,
    String? managerComment,
    DateTime? validatedAt,
  }) = _TimesheetDataResponseImpl;

  factory TimesheetDataResponse.fromJson(
      Map<String, dynamic> jsonSerialization) {
    return TimesheetDataResponse(
      validationId: jsonSerialization['validationId'] as int,
      employeeId: jsonSerialization['employeeId'] as String,
      employeeName: jsonSerialization['employeeName'] as String,
      employeeCompany: jsonSerialization['employeeCompany'] as String,
      month: jsonSerialization['month'] as int,
      year: jsonSerialization['year'] as int,
      entries: jsonSerialization['entries'] as String,
      totalDays: (jsonSerialization['totalDays'] as num).toDouble(),
      totalHours: jsonSerialization['totalHours'] as String,
      totalOvertimeHours: jsonSerialization['totalOvertimeHours'] as String,
      periodStart:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['periodStart']),
      periodEnd:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['periodEnd']),
      status: jsonSerialization['status'] as String,
      managerName: jsonSerialization['managerName'] as String?,
      managerComment: jsonSerialization['managerComment'] as String?,
      validatedAt: jsonSerialization['validatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['validatedAt']),
    );
  }

  int validationId;

  String employeeId;

  String employeeName;

  String employeeCompany;

  int month;

  int year;

  String entries;

  double totalDays;

  String totalHours;

  String totalOvertimeHours;

  DateTime periodStart;

  DateTime periodEnd;

  String status;

  String? managerName;

  String? managerComment;

  DateTime? validatedAt;

  /// Returns a shallow copy of this [TimesheetDataResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TimesheetDataResponse copyWith({
    int? validationId,
    String? employeeId,
    String? employeeName,
    String? employeeCompany,
    int? month,
    int? year,
    String? entries,
    double? totalDays,
    String? totalHours,
    String? totalOvertimeHours,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? status,
    String? managerName,
    String? managerComment,
    DateTime? validatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      'validationId': validationId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'employeeCompany': employeeCompany,
      'month': month,
      'year': year,
      'entries': entries,
      'totalDays': totalDays,
      'totalHours': totalHours,
      'totalOvertimeHours': totalOvertimeHours,
      'periodStart': periodStart.toJson(),
      'periodEnd': periodEnd.toJson(),
      'status': status,
      if (managerName != null) 'managerName': managerName,
      if (managerComment != null) 'managerComment': managerComment,
      if (validatedAt != null) 'validatedAt': validatedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      'validationId': validationId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'employeeCompany': employeeCompany,
      'month': month,
      'year': year,
      'entries': entries,
      'totalDays': totalDays,
      'totalHours': totalHours,
      'totalOvertimeHours': totalOvertimeHours,
      'periodStart': periodStart.toJson(),
      'periodEnd': periodEnd.toJson(),
      'status': status,
      if (managerName != null) 'managerName': managerName,
      if (managerComment != null) 'managerComment': managerComment,
      if (validatedAt != null) 'validatedAt': validatedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TimesheetDataResponseImpl extends TimesheetDataResponse {
  _TimesheetDataResponseImpl({
    required int validationId,
    required String employeeId,
    required String employeeName,
    required String employeeCompany,
    required int month,
    required int year,
    required String entries,
    required double totalDays,
    required String totalHours,
    required String totalOvertimeHours,
    required DateTime periodStart,
    required DateTime periodEnd,
    required String status,
    String? managerName,
    String? managerComment,
    DateTime? validatedAt,
  }) : super._(
          validationId: validationId,
          employeeId: employeeId,
          employeeName: employeeName,
          employeeCompany: employeeCompany,
          month: month,
          year: year,
          entries: entries,
          totalDays: totalDays,
          totalHours: totalHours,
          totalOvertimeHours: totalOvertimeHours,
          periodStart: periodStart,
          periodEnd: periodEnd,
          status: status,
          managerName: managerName,
          managerComment: managerComment,
          validatedAt: validatedAt,
        );

  /// Returns a shallow copy of this [TimesheetDataResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TimesheetDataResponse copyWith({
    int? validationId,
    String? employeeId,
    String? employeeName,
    String? employeeCompany,
    int? month,
    int? year,
    String? entries,
    double? totalDays,
    String? totalHours,
    String? totalOvertimeHours,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? status,
    Object? managerName = _Undefined,
    Object? managerComment = _Undefined,
    Object? validatedAt = _Undefined,
  }) {
    return TimesheetDataResponse(
      validationId: validationId ?? this.validationId,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeCompany: employeeCompany ?? this.employeeCompany,
      month: month ?? this.month,
      year: year ?? this.year,
      entries: entries ?? this.entries,
      totalDays: totalDays ?? this.totalDays,
      totalHours: totalHours ?? this.totalHours,
      totalOvertimeHours: totalOvertimeHours ?? this.totalOvertimeHours,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      status: status ?? this.status,
      managerName: managerName is String? ? managerName : this.managerName,
      managerComment:
          managerComment is String? ? managerComment : this.managerComment,
      validatedAt: validatedAt is DateTime? ? validatedAt : this.validatedAt,
    );
  }
}
