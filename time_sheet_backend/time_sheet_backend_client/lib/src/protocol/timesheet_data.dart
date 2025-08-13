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

abstract class TimesheetData implements _i1.SerializableModel {
  TimesheetData._({
    this.id,
    required this.validationRequestId,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCompany,
    required this.month,
    required this.year,
    required this.entries,
    required this.totalDays,
    required this.totalHours,
    required this.totalOvertimeHours,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory TimesheetData({
    int? id,
    required int validationRequestId,
    required String employeeId,
    required String employeeName,
    required String employeeCompany,
    required int month,
    required int year,
    required String entries,
    required double totalDays,
    required String totalHours,
    required String totalOvertimeHours,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _TimesheetDataImpl;

  factory TimesheetData.fromJson(Map<String, dynamic> jsonSerialization) {
    return TimesheetData(
      id: jsonSerialization['id'] as int?,
      validationRequestId: jsonSerialization['validationRequestId'] as int,
      employeeId: jsonSerialization['employeeId'] as String,
      employeeName: jsonSerialization['employeeName'] as String,
      employeeCompany: jsonSerialization['employeeCompany'] as String,
      month: jsonSerialization['month'] as int,
      year: jsonSerialization['year'] as int,
      entries: jsonSerialization['entries'] as String,
      totalDays: (jsonSerialization['totalDays'] as num).toDouble(),
      totalHours: jsonSerialization['totalHours'] as String,
      totalOvertimeHours: jsonSerialization['totalOvertimeHours'] as String,
      createdAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int validationRequestId;

  String employeeId;

  String employeeName;

  String employeeCompany;

  int month;

  int year;

  String entries;

  double totalDays;

  String totalHours;

  String totalOvertimeHours;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [TimesheetData]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TimesheetData copyWith({
    int? id,
    int? validationRequestId,
    String? employeeId,
    String? employeeName,
    String? employeeCompany,
    int? month,
    int? year,
    String? entries,
    double? totalDays,
    String? totalHours,
    String? totalOvertimeHours,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
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
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TimesheetDataImpl extends TimesheetData {
  _TimesheetDataImpl({
    int? id,
    required int validationRequestId,
    required String employeeId,
    required String employeeName,
    required String employeeCompany,
    required int month,
    required int year,
    required String entries,
    required double totalDays,
    required String totalHours,
    required String totalOvertimeHours,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super._(
          id: id,
          validationRequestId: validationRequestId,
          employeeId: employeeId,
          employeeName: employeeName,
          employeeCompany: employeeCompany,
          month: month,
          year: year,
          entries: entries,
          totalDays: totalDays,
          totalHours: totalHours,
          totalOvertimeHours: totalOvertimeHours,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  /// Returns a shallow copy of this [TimesheetData]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TimesheetData copyWith({
    Object? id = _Undefined,
    int? validationRequestId,
    String? employeeId,
    String? employeeName,
    String? employeeCompany,
    int? month,
    int? year,
    String? entries,
    double? totalDays,
    String? totalHours,
    String? totalOvertimeHours,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimesheetData(
      id: id is int? ? id : this.id,
      validationRequestId: validationRequestId ?? this.validationRequestId,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeCompany: employeeCompany ?? this.employeeCompany,
      month: month ?? this.month,
      year: year ?? this.year,
      entries: entries ?? this.entries,
      totalDays: totalDays ?? this.totalDays,
      totalHours: totalHours ?? this.totalHours,
      totalOvertimeHours: totalOvertimeHours ?? this.totalOvertimeHours,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
