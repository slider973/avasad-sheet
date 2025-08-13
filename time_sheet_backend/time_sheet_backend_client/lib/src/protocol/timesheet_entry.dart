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

abstract class TimesheetEntry implements _i1.SerializableModel {
  TimesheetEntry._({
    required this.dayDate,
    required this.startMorning,
    required this.endMorning,
    required this.startAfternoon,
    required this.endAfternoon,
    required this.isAbsence,
    required this.hasOvertimeHours,
  });

  factory TimesheetEntry({
    required String dayDate,
    required String startMorning,
    required String endMorning,
    required String startAfternoon,
    required String endAfternoon,
    required bool isAbsence,
    required bool hasOvertimeHours,
  }) = _TimesheetEntryImpl;

  factory TimesheetEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return TimesheetEntry(
      dayDate: jsonSerialization['dayDate'] as String,
      startMorning: jsonSerialization['startMorning'] as String,
      endMorning: jsonSerialization['endMorning'] as String,
      startAfternoon: jsonSerialization['startAfternoon'] as String,
      endAfternoon: jsonSerialization['endAfternoon'] as String,
      isAbsence: jsonSerialization['isAbsence'] as bool,
      hasOvertimeHours: jsonSerialization['hasOvertimeHours'] as bool,
    );
  }

  String dayDate;

  String startMorning;

  String endMorning;

  String startAfternoon;

  String endAfternoon;

  bool isAbsence;

  bool hasOvertimeHours;

  /// Returns a shallow copy of this [TimesheetEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TimesheetEntry copyWith({
    String? dayDate,
    String? startMorning,
    String? endMorning,
    String? startAfternoon,
    String? endAfternoon,
    bool? isAbsence,
    bool? hasOvertimeHours,
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
      'hasOvertimeHours': hasOvertimeHours,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _TimesheetEntryImpl extends TimesheetEntry {
  _TimesheetEntryImpl({
    required String dayDate,
    required String startMorning,
    required String endMorning,
    required String startAfternoon,
    required String endAfternoon,
    required bool isAbsence,
    required bool hasOvertimeHours,
  }) : super._(
          dayDate: dayDate,
          startMorning: startMorning,
          endMorning: endMorning,
          startAfternoon: startAfternoon,
          endAfternoon: endAfternoon,
          isAbsence: isAbsence,
          hasOvertimeHours: hasOvertimeHours,
        );

  /// Returns a shallow copy of this [TimesheetEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TimesheetEntry copyWith({
    String? dayDate,
    String? startMorning,
    String? endMorning,
    String? startAfternoon,
    String? endAfternoon,
    bool? isAbsence,
    bool? hasOvertimeHours,
  }) {
    return TimesheetEntry(
      dayDate: dayDate ?? this.dayDate,
      startMorning: startMorning ?? this.startMorning,
      endMorning: endMorning ?? this.endMorning,
      startAfternoon: startAfternoon ?? this.startAfternoon,
      endAfternoon: endAfternoon ?? this.endAfternoon,
      isAbsence: isAbsence ?? this.isAbsence,
      hasOvertimeHours: hasOvertimeHours ?? this.hasOvertimeHours,
    );
  }
}
