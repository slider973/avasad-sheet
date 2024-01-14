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
    r'dayDate': PropertySchema(
      id: 0,
      name: r'dayDate',
      type: IsarType.dateTime,
    ),
    r'dayOfWeekDate': PropertySchema(
      id: 1,
      name: r'dayOfWeekDate',
      type: IsarType.string,
    ),
    r'endAfternoon': PropertySchema(
      id: 2,
      name: r'endAfternoon',
      type: IsarType.string,
    ),
    r'endMorning': PropertySchema(
      id: 3,
      name: r'endMorning',
      type: IsarType.string,
    ),
    r'startAfternoon': PropertySchema(
      id: 4,
      name: r'startAfternoon',
      type: IsarType.string,
    ),
    r'startMorning': PropertySchema(
      id: 5,
      name: r'startMorning',
      type: IsarType.string,
    )
  },
  estimateSize: _timeSheetEntryModelEstimateSize,
  serialize: _timeSheetEntryModelSerialize,
  deserialize: _timeSheetEntryModelDeserialize,
  deserializeProp: _timeSheetEntryModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
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
  bytesCount += 3 + object.dayOfWeekDate.length * 3;
  bytesCount += 3 + object.endAfternoon.length * 3;
  bytesCount += 3 + object.endMorning.length * 3;
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
  writer.writeDateTime(offsets[0], object.dayDate);
  writer.writeString(offsets[1], object.dayOfWeekDate);
  writer.writeString(offsets[2], object.endAfternoon);
  writer.writeString(offsets[3], object.endMorning);
  writer.writeString(offsets[4], object.startAfternoon);
  writer.writeString(offsets[5], object.startMorning);
}

TimeSheetEntryModel _timeSheetEntryModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TimeSheetEntryModel();
  object.dayDate = reader.readDateTime(offsets[0]);
  object.dayOfWeekDate = reader.readString(offsets[1]);
  object.endAfternoon = reader.readString(offsets[2]);
  object.endMorning = reader.readString(offsets[3]);
  object.id = id;
  object.startAfternoon = reader.readString(offsets[4]);
  object.startMorning = reader.readString(offsets[5]);
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
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _timeSheetEntryModelGetId(TimeSheetEntryModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _timeSheetEntryModelGetLinks(
    TimeSheetEntryModel object) {
  return [];
}

void _timeSheetEntryModelAttach(
    IsarCollection<dynamic> col, Id id, TimeSheetEntryModel object) {
  object.id = id;
}

extension TimeSheetEntryModelQueryWhereSort
    on QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QWhere> {
  QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
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
}

extension TimeSheetEntryModelQueryFilter on QueryBuilder<TimeSheetEntryModel,
    TimeSheetEntryModel, QFilterCondition> {
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
    TimeSheetEntryModel, QFilterCondition> {}

extension TimeSheetEntryModelQuerySortBy
    on QueryBuilder<TimeSheetEntryModel, TimeSheetEntryModel, QSortBy> {
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
