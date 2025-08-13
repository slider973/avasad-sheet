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

abstract class TimesheetEntryData
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  TimesheetEntryData._({
    required this.dayDate,
    required this.startMorning,
    required this.endMorning,
    required this.startAfternoon,
    required this.endAfternoon,
    required this.isAbsence,
    this.absenceType,
    this.absenceMotif,
    this.absencePeriod,
    required this.hasOvertimeHours,
    this.overtimeHours,
  });

  factory TimesheetEntryData({
    required String dayDate,
    required String startMorning,
    required String endMorning,
    required String startAfternoon,
    required String endAfternoon,
    required bool isAbsence,
    String? absenceType,
    String? absenceMotif,
    String? absencePeriod,
    required bool hasOvertimeHours,
    String? overtimeHours,
  }) = _TimesheetEntryDataImpl;

  factory TimesheetEntryData.fromJson(Map<String, dynamic> jsonSerialization) {
    return TimesheetEntryData(
      dayDate: jsonSerialization['dayDate'] as String,
      startMorning: jsonSerialization['startMorning'] as String,
      endMorning: jsonSerialization['endMorning'] as String,
      startAfternoon: jsonSerialization['startAfternoon'] as String,
      endAfternoon: jsonSerialization['endAfternoon'] as String,
      isAbsence: jsonSerialization['isAbsence'] as bool,
      absenceType: jsonSerialization['absenceType'] as String?,
      absenceMotif: jsonSerialization['absenceMotif'] as String?,
      absencePeriod: jsonSerialization['absencePeriod'] as String?,
      hasOvertimeHours: jsonSerialization['hasOvertimeHours'] as bool,
      overtimeHours: jsonSerialization['overtimeHours'] as String?,
    );
  }

  String dayDate;

  String startMorning;

  String endMorning;

  String startAfternoon;

  String endAfternoon;

  bool isAbsence;

  String? absenceType;

  String? absenceMotif;

  String? absencePeriod;

  bool hasOvertimeHours;

  String? overtimeHours;

  /// Returns a shallow copy of this [TimesheetEntryData]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TimesheetEntryData copyWith({
    String? dayDate,
    String? startMorning,
    String? endMorning,
    String? startAfternoon,
    String? endAfternoon,
    bool? isAbsence,
    String? absenceType,
    String? absenceMotif,
    String? absencePeriod,
    bool? hasOvertimeHours,
    String? overtimeHours,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      'dayDate': dayDate,
      'startMorning': startMorning,
      'endMorning': endMorning,
      'startAfternoon': startAfternoon,
      'endAfternoon': endAfternoon,
      'isAbsence': isAbsence,
      if (absenceType != null) 'absenceType': absenceType,
      if (absenceMotif != null) 'absenceMotif': absenceMotif,
      if (absencePeriod != null) 'absencePeriod': absencePeriod,
      'hasOvertimeHours': hasOvertimeHours,
      if (overtimeHours != null) 'overtimeHours': overtimeHours,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      'dayDate': dayDate,
      'startMorning': startMorning,
      'endMorning': endMorning,
      'startAfternoon': startAfternoon,
      'endAfternoon': endAfternoon,
      'isAbsence': isAbsence,
      if (absenceType != null) 'absenceType': absenceType,
      if (absenceMotif != null) 'absenceMotif': absenceMotif,
      if (absencePeriod != null) 'absencePeriod': absencePeriod,
      'hasOvertimeHours': hasOvertimeHours,
      if (overtimeHours != null) 'overtimeHours': overtimeHours,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TimesheetEntryDataImpl extends TimesheetEntryData {
  _TimesheetEntryDataImpl({
    required String dayDate,
    required String startMorning,
    required String endMorning,
    required String startAfternoon,
    required String endAfternoon,
    required bool isAbsence,
    String? absenceType,
    String? absenceMotif,
    String? absencePeriod,
    required bool hasOvertimeHours,
    String? overtimeHours,
  }) : super._(
          dayDate: dayDate,
          startMorning: startMorning,
          endMorning: endMorning,
          startAfternoon: startAfternoon,
          endAfternoon: endAfternoon,
          isAbsence: isAbsence,
          absenceType: absenceType,
          absenceMotif: absenceMotif,
          absencePeriod: absencePeriod,
          hasOvertimeHours: hasOvertimeHours,
          overtimeHours: overtimeHours,
        );

  /// Returns a shallow copy of this [TimesheetEntryData]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TimesheetEntryData copyWith({
    String? dayDate,
    String? startMorning,
    String? endMorning,
    String? startAfternoon,
    String? endAfternoon,
    bool? isAbsence,
    Object? absenceType = _Undefined,
    Object? absenceMotif = _Undefined,
    Object? absencePeriod = _Undefined,
    bool? hasOvertimeHours,
    Object? overtimeHours = _Undefined,
  }) {
    return TimesheetEntryData(
      dayDate: dayDate ?? this.dayDate,
      startMorning: startMorning ?? this.startMorning,
      endMorning: endMorning ?? this.endMorning,
      startAfternoon: startAfternoon ?? this.startAfternoon,
      endAfternoon: endAfternoon ?? this.endAfternoon,
      isAbsence: isAbsence ?? this.isAbsence,
      absenceType: absenceType is String? ? absenceType : this.absenceType,
      absenceMotif: absenceMotif is String? ? absenceMotif : this.absenceMotif,
      absencePeriod:
          absencePeriod is String? ? absencePeriod : this.absencePeriod,
      hasOvertimeHours: hasOvertimeHours ?? this.hasOvertimeHours,
      overtimeHours:
          overtimeHours is String? ? overtimeHours : this.overtimeHours,
    );
  }
}
