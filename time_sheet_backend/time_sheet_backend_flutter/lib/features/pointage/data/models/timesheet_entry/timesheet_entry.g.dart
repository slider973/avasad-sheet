// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timesheet_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTimeSheetEntryModelCollection on Isar {
  IsarCollection<TimeSheetEntryModel> get timeSheetEntryModels =>
      this.collection();
}

const TimeSheetEntryModelSchema = CollectionSchema(
  name: r'TimeSheetEntryModel',
  id: 1852731348862127509,
  properties: {
    r'absenceReason': PropertySchema(
      id: 0,
      name: r'absenceReason',
      type: IsarType.string,
    ),
    r'dayDate': PropertySchema(
      id: 1,
      name: r'dayDate',
      type: IsarType.dateTime,
    ),
    r'dayOfWeekDate': PropertySchema(
      id: 2,
      name: r'dayOfWeekDate',
      type: IsarType.string,
    ),
    r'endAfternoon': PropertySchema(
      id: 3,
      name: r'endAfternoon',
      type: IsarType.string,
    ),
    r'endMorning': PropertySchema(
      id: 4,
      name: r'endMorning',
      type: IsarType.string,
    ),
    r'hasOvertimeHours': PropertySchema(
      id: 5,
      name: r'hasOvertimeHours',
      type: IsarType.bool,
    ),
    r'isWeekendDay': PropertySchema(
      id: 6,
      name: r'isWeekendDay',
      type: IsarType.bool,
    ),
    r'isWeekendOvertimeEnabled': PropertySchema(
      id: 7,
      name: r'isWeekendOvertimeEnabled',
      type: IsarType.bool,
    ),
    r'overtimeType': PropertySchema(
      id: 8,
      name: r'overtimeType',
      type: IsarType.string,
      enumMap: _TimeSheetEntryModelovertimeTypeEnumValueMap,
    ),
    r'period': PropertySchema(
      id: 9,
      name: r'period',
      type: IsarType.string,
    ),
    r'startAfternoon': PropertySchema(
      id: 10,
      name: r'startAfternoon',
      type: IsarType.string,
    ),
    r'startMorning': PropertySchema(
      id: 11,
      name: r'startMorning',
      type: IsarType.string,
    )
  },
  estimateSize: _timeSheetEntryModelEstimateSize,
  serialize: _timeSheetEntryModelSerialize,
  deserialize: _timeSheetEntryModelDeserialize,
  deserializeProp: _timeSheetEntryModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'hasOvertimeHours': IndexSchema(
      id: -1731479981131342031,
      name: r'hasOvertimeHours',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'hasOvertimeHours',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'isWeekendDay': IndexSchema(
      id: 1412842850436869628,
      name: r'isWeekendDay',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isWeekendDay',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'isWeekendOvertimeEnabled': IndexSchema(
      id: 6990069947100456004,
      name: r'isWeekendOvertimeEnabled',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isWeekendOvertimeEnabled',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {
    r'absence': LinkSchema(
      id: 7426728764344287438,
      name: r'absence',
      target: r'Absence',
      single: true,
      linkName: r'timesheetEntry',
    ),
    r'anomaly': LinkSchema(
      id: -4880604681407737451,
      name: r'anomaly',
      target: r'AnomalyModel',
      single: true,
      linkName: r'timesheetEntry',
    )
  },
  embeddedSchemas: {},
  getId: _timeSheetEntryModelGetId,
  getLinks: _timeSheetEntryModelGetLinks,
  attach: _timeSheetEntryModelAttach,
  version: '3.1.0+1',
);

int _timeSheetEntryModelEstimateSize(
  TimeSheetEntryModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.absenceReason.length * 3;
  bytesCount += 3 + object.dayOfWeekDate.length * 3;
  bytesCount += 3 + object.endAfternoon.length * 3;
  bytesCount += 3 + object.endMorning.length * 3;
  bytesCount += 3 + object.overtimeType.name.length * 3;
  bytesCount += 3 + object.period.length * 3;
  bytesCount += 3 + object.startAfternoon.length * 3;
  bytesCount += 3 + object.startMorning.length * 3;
  return bytesCount;
}

void _timeSheetEntryModelSerialize(
  TimeSheetEntryModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.absenceReason);
  writer.writeDateTime(offsets[1], object.dayDate);
  writer.writeString(offsets[2], object.dayOfWeekDate);
  writer.writeString(offsets[3], object.endAfternoon);
  writer.writeString(offsets[4], object.endMorning);
  writer.writeBool(offsets[5], object.hasOvertimeHours);
  writer.writeBool(offsets[6], object.isWeekendDay);
  writer.writeBool(offsets[7], object.isWeekendOvertimeEnabled);
  writer.writeString(offsets[8], object.overtimeType.name);
  writer.writeString(offsets[9], object.period);
  writer.writeString(offsets[10], object.startAfternoon);
  writer.writeString(offsets[11], object.startMorning);
}

TimeSheetEntryModel _timeSheetEntryModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TimeSheetEntryModel();
  object.absenceReason = reader.readString(offsets[0]);
  object.dayDate = reader.readDateTime(offsets[1]);
  object.dayOfWeekDate = reader.readString(offsets[2]);
  object.endAfternoon = reader.readString(offsets[3]);
  object.endMorning = reader.readString(offsets[4]);
  object.hasOvertimeHours = reader.readBool(offsets[5]);
  object.id = id;
  object.isWeekendDay = reader.readBool(offsets[6]);
  object.isWeekendOvertimeEnabled = reader.readBool(offsets[7]);
  object.overtimeType = _TimeSheetEntryModelovertimeTypeValueEnumMap[
          reader.readStringOrNull(offsets[8])] ??
      OvertimeType.NONE;
  object.period = reader.readString(offsets[9]);
  object.startAfternoon = reader.readString(offsets[10]);
  object.startMorning = reader.readString(offsets[11]);
  return object;
}

P _timeSheetEntryModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (_TimeSheetEntryModelovertimeTypeValueEnumMap[
              reader.readStringOrNull(offset)] ??
          OvertimeType.NONE) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _TimeSheetEntryModelovertimeTypeEnumValueMap = {
  r'NONE': r'NONE',
  r'WEEKDAY_ONLY': r'WEEKDAY_ONLY',
  r'WEEKEND_ONLY': r'WEEKEND_ONLY',
  r'BOTH': r'BOTH',
};
const _TimeSheetEntryModelovertimeTypeValueEnumMap = {
  r'NONE': OvertimeType.NONE,
  r'WEEKDAY_ONLY': OvertimeType.WEEKDAY_ONLY,
  r'WEEKEND_ONLY': OvertimeType.WEEKEND_ONLY,
  r'BOTH': OvertimeType.BOTH,
};

Id _timeSheetEntryModelGetId(TimeSheetEntryModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _timeSheetEntryModelGetLinks(
    TimeSheetEntryModel object) {
  return [object.absence, object.anomaly];
}

void _timeSheetEntryModelAttach(
    IsarCollection<dynamic> col, Id id, TimeSheetEntryModel object) {
  object.id = id;
  object.absence.attach(col, col.isar.collection<Absence>(), r'absence', id);
  object.anomaly
      .attach(col, col.isar.collection<AnomalyModel>(), r'anomaly', id);
}

extension TimeSheetEntryModelQueryWhereSort
    on QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QWhere> {
  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterWhere>
      anyHasOvertimeHours() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'hasOvertimeHours'),
      );
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterWhere>
      anyIsWeekendDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isWeekendDay'),
      );
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterWhere>
      anyIsWeekendOvertimeEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isWeekendOvertimeEnabled'),
      );
    });
  }
}

extension TimeSheetEntryModelQueryWhere
    on QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QWhereClause> {
  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterWhereClause>
      hasOvertimeHoursEqualTo(bool hasOvertimeHours) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'hasOvertimeHours',
        value: [hasOvertimeHours],
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterWhereClause>
      hasOvertimeHoursNotEqualTo(bool hasOvertimeHours) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'hasOvertimeHours',
              lower: [],
              upper: [hasOvertimeHours],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'hasOvertimeHours',
              lower: [hasOvertimeHours],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'hasOvertimeHours',
              lower: [hasOvertimeHours],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'hasOvertimeHours',
              lower: [],
              upper: [hasOvertimeHours],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterWhereClause>
      isWeekendDayEqualTo(bool isWeekendDay) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'isWeekendDay',
        value: [isWeekendDay],
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterWhereClause>
      isWeekendDayNotEqualTo(bool isWeekendDay) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isWeekendDay',
              lower: [],
              upper: [isWeekendDay],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isWeekendDay',
              lower: [isWeekendDay],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isWeekendDay',
              lower: [isWeekendDay],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isWeekendDay',
              lower: [],
              upper: [isWeekendDay],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterWhereClause>
      isWeekendOvertimeEnabledEqualTo(bool isWeekendOvertimeEnabled) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'isWeekendOvertimeEnabled',
        value: [isWeekendOvertimeEnabled],
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterWhereClause>
      isWeekendOvertimeEnabledNotEqualTo(bool isWeekendOvertimeEnabled) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isWeekendOvertimeEnabled',
              lower: [],
              upper: [isWeekendOvertimeEnabled],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isWeekendOvertimeEnabled',
              lower: [isWeekendOvertimeEnabled],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isWeekendOvertimeEnabled',
              lower: [isWeekendOvertimeEnabled],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isWeekendOvertimeEnabled',
              lower: [],
              upper: [isWeekendOvertimeEnabled],
              includeUpper: false,
            ));
      }
    });
  }
}

extension TimeSheetEntryModelQueryFilter on QueryBuilder<TimeSheetEntryModel,
    TimeSheetEntryModel, QFilterCondition> {
  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      absenceReasonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'absenceReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      absenceReasonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'absenceReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      absenceReasonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'absenceReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      absenceReasonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'absenceReason',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      absenceReasonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'absenceReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      absenceReasonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'absenceReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      absenceReasonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'absenceReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      absenceReasonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'absenceReason',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      absenceReasonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'absenceReason',
        value: '',
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      absenceReasonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'absenceReason',
        value: '',
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      dayDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dayDate',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      dayDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dayDate',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      dayDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dayDate',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      dayDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dayDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      dayOfWeekDateEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dayOfWeekDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      dayOfWeekDateGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dayOfWeekDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      dayOfWeekDateLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dayOfWeekDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      dayOfWeekDateBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dayOfWeekDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      dayOfWeekDateStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dayOfWeekDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      dayOfWeekDateEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dayOfWeekDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      dayOfWeekDateContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dayOfWeekDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      dayOfWeekDateMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dayOfWeekDate',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      dayOfWeekDateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dayOfWeekDate',
        value: '',
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      dayOfWeekDateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dayOfWeekDate',
        value: '',
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      endAfternoonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endAfternoon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      endAfternoonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endAfternoon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      endAfternoonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endAfternoon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      endAfternoonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endAfternoon',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      endAfternoonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'endAfternoon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      endAfternoonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'endAfternoon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      endAfternoonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'endAfternoon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      endAfternoonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'endAfternoon',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      endAfternoonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endAfternoon',
        value: '',
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      endAfternoonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'endAfternoon',
        value: '',
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      endMorningEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endMorning',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      endMorningGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endMorning',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      endMorningLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endMorning',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      endMorningBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endMorning',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      endMorningStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'endMorning',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      endMorningEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'endMorning',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      endMorningContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'endMorning',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      endMorningMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'endMorning',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      endMorningIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endMorning',
        value: '',
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      endMorningIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'endMorning',
        value: '',
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      hasOvertimeHoursEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hasOvertimeHours',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      isWeekendDayEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isWeekendDay',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      isWeekendOvertimeEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isWeekendOvertimeEnabled',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      overtimeTypeEqualTo(
    OvertimeType value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'overtimeType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      overtimeTypeGreaterThan(
    OvertimeType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'overtimeType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      overtimeTypeLessThan(
    OvertimeType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'overtimeType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      overtimeTypeBetween(
    OvertimeType lower,
    OvertimeType upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'overtimeType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      overtimeTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'overtimeType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      overtimeTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'overtimeType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      overtimeTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'overtimeType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      overtimeTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'overtimeType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      overtimeTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'overtimeType',
        value: '',
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      overtimeTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'overtimeType',
        value: '',
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      periodEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'period',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      periodGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'period',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      periodLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'period',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      periodBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'period',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      periodStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'period',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      periodEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'period',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      periodContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'period',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      periodMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'period',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      periodIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'period',
        value: '',
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      periodIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'period',
        value: '',
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      startAfternoonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startAfternoon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      startAfternoonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startAfternoon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      startAfternoonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startAfternoon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      startAfternoonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startAfternoon',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      startAfternoonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'startAfternoon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      startAfternoonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'startAfternoon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      startAfternoonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'startAfternoon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      startAfternoonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'startAfternoon',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      startAfternoonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startAfternoon',
        value: '',
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      startAfternoonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'startAfternoon',
        value: '',
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      startMorningEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startMorning',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      startMorningGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startMorning',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      startMorningLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startMorning',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      startMorningBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startMorning',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      startMorningStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'startMorning',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      startMorningEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'startMorning',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      startMorningContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'startMorning',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      startMorningMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'startMorning',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      startMorningIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startMorning',
        value: '',
      ));
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      startMorningIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'startMorning',
        value: '',
      ));
    });
  }
}

extension TimeSheetEntryModelQueryObject on QueryBuilder<TimeSheetEntryModel,
    TimeSheetEntryModel, QFilterCondition> {}

extension TimeSheetEntryModelQueryLinks on QueryBuilder<TimeSheetEntryModel,
    TimeSheetEntryModel, QFilterCondition> {
  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      absence(FilterQuery<Absence> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'absence');
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      absenceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'absence', 0, true, 0, true);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      anomaly(FilterQuery<AnomalyModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'anomaly');
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterFilterCondition>
      anomalyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'anomaly', 0, true, 0, true);
    });
  }
}

extension TimeSheetEntryModelQuerySortBy
    on QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QSortBy> {
  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      sortByAbsenceReason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'absenceReason', Sort.asc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      sortByAbsenceReasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'absenceReason', Sort.desc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      sortByDayDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayDate', Sort.asc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      sortByDayDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayDate', Sort.desc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      sortByDayOfWeekDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayOfWeekDate', Sort.asc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      sortByDayOfWeekDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayOfWeekDate', Sort.desc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      sortByEndAfternoon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endAfternoon', Sort.asc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      sortByEndAfternoonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endAfternoon', Sort.desc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      sortByEndMorning() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endMorning', Sort.asc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      sortByEndMorningDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endMorning', Sort.desc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      sortByHasOvertimeHours() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasOvertimeHours', Sort.asc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      sortByHasOvertimeHoursDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasOvertimeHours', Sort.desc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      sortByIsWeekendDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isWeekendDay', Sort.asc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      sortByIsWeekendDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isWeekendDay', Sort.desc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      sortByIsWeekendOvertimeEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isWeekendOvertimeEnabled', Sort.asc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      sortByIsWeekendOvertimeEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isWeekendOvertimeEnabled', Sort.desc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      sortByOvertimeType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'overtimeType', Sort.asc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      sortByOvertimeTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'overtimeType', Sort.desc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      sortByPeriod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'period', Sort.asc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      sortByPeriodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'period', Sort.desc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      sortByStartAfternoon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startAfternoon', Sort.asc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      sortByStartAfternoonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startAfternoon', Sort.desc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      sortByStartMorning() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startMorning', Sort.asc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      sortByStartMorningDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startMorning', Sort.desc);
    });
  }
}

extension TimeSheetEntryModelQuerySortThenBy
    on QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QSortThenBy> {
  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      thenByAbsenceReason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'absenceReason', Sort.asc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      thenByAbsenceReasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'absenceReason', Sort.desc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      thenByDayDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayDate', Sort.asc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      thenByDayDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayDate', Sort.desc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      thenByDayOfWeekDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayOfWeekDate', Sort.asc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      thenByDayOfWeekDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayOfWeekDate', Sort.desc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      thenByEndAfternoon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endAfternoon', Sort.asc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      thenByEndAfternoonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endAfternoon', Sort.desc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      thenByEndMorning() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endMorning', Sort.asc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      thenByEndMorningDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endMorning', Sort.desc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      thenByHasOvertimeHours() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasOvertimeHours', Sort.asc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      thenByHasOvertimeHoursDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasOvertimeHours', Sort.desc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      thenByIsWeekendDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isWeekendDay', Sort.asc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      thenByIsWeekendDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isWeekendDay', Sort.desc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      thenByIsWeekendOvertimeEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isWeekendOvertimeEnabled', Sort.asc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      thenByIsWeekendOvertimeEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isWeekendOvertimeEnabled', Sort.desc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      thenByOvertimeType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'overtimeType', Sort.asc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      thenByOvertimeTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'overtimeType', Sort.desc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      thenByPeriod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'period', Sort.asc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      thenByPeriodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'period', Sort.desc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      thenByStartAfternoon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startAfternoon', Sort.asc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      thenByStartAfternoonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startAfternoon', Sort.desc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      thenByStartMorning() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startMorning', Sort.asc);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterSortBy>
      thenByStartMorningDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startMorning', Sort.desc);
    });
  }
}

extension TimeSheetEntryModelQueryWhereDistinct
    on QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QDistinct> {
  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QDistinct>
      distinctByAbsenceReason({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'absenceReason',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QDistinct>
      distinctByDayDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dayDate');
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QDistinct>
      distinctByDayOfWeekDate({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dayOfWeekDate',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QDistinct>
      distinctByEndAfternoon({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endAfternoon', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QDistinct>
      distinctByEndMorning({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endMorning', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QDistinct>
      distinctByHasOvertimeHours() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasOvertimeHours');
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QDistinct>
      distinctByIsWeekendDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isWeekendDay');
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QDistinct>
      distinctByIsWeekendOvertimeEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isWeekendOvertimeEnabled');
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QDistinct>
      distinctByOvertimeType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'overtimeType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QDistinct>
      distinctByPeriod({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'period', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QDistinct>
      distinctByStartAfternoon({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startAfternoon',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QDistinct>
      distinctByStartMorning({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startMorning', caseSensitive: caseSensitive);
    });
  }
}

extension TimeSheetEntryModelQueryProperty
    on QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QQueryProperty> {
  QueryBuilder<TimeSheetEntryModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TimeSheetEntryModel, String, QQueryOperations>
      absenceReasonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'absenceReason');
    });
  }

  QueryBuilder<TimeSheetEntryModel, DateTime, QQueryOperations>
      dayDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dayDate');
    });
  }

  QueryBuilder<TimeSheetEntryModel, String, QQueryOperations>
      dayOfWeekDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dayOfWeekDate');
    });
  }

  QueryBuilder<TimeSheetEntryModel, String, QQueryOperations>
      endAfternoonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endAfternoon');
    });
  }

  QueryBuilder<TimeSheetEntryModel, String, QQueryOperations>
      endMorningProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endMorning');
    });
  }

  QueryBuilder<TimeSheetEntryModel, bool, QQueryOperations>
      hasOvertimeHoursProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasOvertimeHours');
    });
  }

  QueryBuilder<TimeSheetEntryModel, bool, QQueryOperations>
      isWeekendDayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isWeekendDay');
    });
  }

  QueryBuilder<TimeSheetEntryModel, bool, QQueryOperations>
      isWeekendOvertimeEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isWeekendOvertimeEnabled');
    });
  }

  QueryBuilder<TimeSheetEntryModel, OvertimeType, QQueryOperations>
      overtimeTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'overtimeType');
    });
  }

  QueryBuilder<TimeSheetEntryModel, String, QQueryOperations> periodProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'period');
    });
  }

  QueryBuilder<TimeSheetEntryModel, String, QQueryOperations>
      startAfternoonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startAfternoon');
    });
  }

  QueryBuilder<TimeSheetEntryModel, String, QQueryOperations>
      startMorningProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startMorning');
    });
  }
}
