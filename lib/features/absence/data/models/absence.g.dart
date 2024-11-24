// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'absence.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAbsenceCollection on Isar {
  IsarCollection<Absence> get absences => this.collection();
}

const AbsenceSchema = CollectionSchema(
  name: r'Absence',
  id: -7247862397841850355,
  properties: {
    r'endDate': PropertySchema(
      id: 0,
      name: r'endDate',
      type: IsarType.dateTime,
    ),
    r'motif': PropertySchema(
      id: 1,
      name: r'motif',
      type: IsarType.string,
    ),
    r'startDate': PropertySchema(
      id: 2,
      name: r'startDate',
      type: IsarType.dateTime,
    ),
    r'type': PropertySchema(
      id: 3,
      name: r'type',
      type: IsarType.byte,
      enumMap: _AbsencetypeEnumValueMap,
    )
  },
  estimateSize: _absenceEstimateSize,
  serialize: _absenceSerialize,
  deserialize: _absenceDeserialize,
  deserializeProp: _absenceDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'timesheetEntry': LinkSchema(
      id: -7133275466858042903,
      name: r'timesheetEntry',
      target: r'TimeSheetEntryModel',
      single: true,
    )
  },
  embeddedSchemas: {},
  getId: _absenceGetId,
  getLinks: _absenceGetLinks,
  attach: _absenceAttach,
  version: '3.1.0+1',
);

int _absenceEstimateSize(
  Absence object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.motif.length * 3;
  return bytesCount;
}

void _absenceSerialize(
  Absence object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.endDate);
  writer.writeString(offsets[1], object.motif);
  writer.writeDateTime(offsets[2], object.startDate);
  writer.writeByte(offsets[3], object.type.index);
}

Absence _absenceDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Absence();
  object.endDate = reader.readDateTime(offsets[0]);
  object.id = id;
  object.motif = reader.readString(offsets[1]);
  object.startDate = reader.readDateTime(offsets[2]);
  object.type = _AbsencetypeValueEnumMap[reader.readByteOrNull(offsets[3])] ??
      AbsenceType.vacation;
  return object;
}

P _absenceDeserializeProp<P>(
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
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (_AbsencetypeValueEnumMap[reader.readByteOrNull(offset)] ??
          AbsenceType.vacation) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _AbsencetypeEnumValueMap = {
  'vacation': 0,
  'publicHoliday': 1,
  'sickLeave': 2,
  'other': 3,
};
const _AbsencetypeValueEnumMap = {
  0: AbsenceType.vacation,
  1: AbsenceType.publicHoliday,
  2: AbsenceType.sickLeave,
  3: AbsenceType.other,
};

Id _absenceGetId(Absence object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _absenceGetLinks(Absence object) {
  return [object.timesheetEntry];
}

void _absenceAttach(IsarCollection<dynamic> col, Id id, Absence object) {
  object.id = id;
  object.timesheetEntry.attach(
      col, col.isar.collection<TimeSheetEntryModel>(), r'timesheetEntry', id);
}

extension AbsenceQueryWhereSort on QueryBuilder<Absence, Absence, QWhere> {
  QueryBuilder<Absence, Absence, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AbsenceQueryWhere on QueryBuilder<Absence, Absence, QWhereClause> {
  QueryBuilder<Absence, Absence, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Absence, Absence, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Absence, Absence, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Absence, Absence, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Absence, Absence, QAfterWhereClause> idBetween(
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

extension AbsenceQueryFilter
    on QueryBuilder<Absence, Absence, QFilterCondition> {
  QueryBuilder<Absence, Absence, QAfterFilterCondition> endDateEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Absence, Absence, QAfterFilterCondition> endDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Absence, Absence, QAfterFilterCondition> endDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Absence, Absence, QAfterFilterCondition> endDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Absence, Absence, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Absence, Absence, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Absence, Absence, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Absence, Absence, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Absence, Absence, QAfterFilterCondition> motifEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'motif',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Absence, Absence, QAfterFilterCondition> motifGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'motif',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Absence, Absence, QAfterFilterCondition> motifLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'motif',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Absence, Absence, QAfterFilterCondition> motifBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'motif',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Absence, Absence, QAfterFilterCondition> motifStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'motif',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Absence, Absence, QAfterFilterCondition> motifEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'motif',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Absence, Absence, QAfterFilterCondition> motifContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'motif',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Absence, Absence, QAfterFilterCondition> motifMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'motif',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Absence, Absence, QAfterFilterCondition> motifIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'motif',
        value: '',
      ));
    });
  }

  QueryBuilder<Absence, Absence, QAfterFilterCondition> motifIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'motif',
        value: '',
      ));
    });
  }

  QueryBuilder<Absence, Absence, QAfterFilterCondition> startDateEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Absence, Absence, QAfterFilterCondition> startDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Absence, Absence, QAfterFilterCondition> startDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Absence, Absence, QAfterFilterCondition> startDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Absence, Absence, QAfterFilterCondition> typeEqualTo(
      AbsenceType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<Absence, Absence, QAfterFilterCondition> typeGreaterThan(
    AbsenceType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<Absence, Absence, QAfterFilterCondition> typeLessThan(
    AbsenceType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<Absence, Absence, QAfterFilterCondition> typeBetween(
    AbsenceType lower,
    AbsenceType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension AbsenceQueryObject
    on QueryBuilder<Absence, Absence, QFilterCondition> {}

extension AbsenceQueryLinks
    on QueryBuilder<Absence, Absence, QFilterCondition> {
  QueryBuilder<Absence, Absence, QAfterFilterCondition> timesheetEntry(
      FilterQuery<TimeSheetEntryModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'timesheetEntry');
    });
  }

  QueryBuilder<Absence, Absence, QAfterFilterCondition> timesheetEntryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'timesheetEntry', 0, true, 0, true);
    });
  }
}

extension AbsenceQuerySortBy on QueryBuilder<Absence, Absence, QSortBy> {
  QueryBuilder<Absence, Absence, QAfterSortBy> sortByEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.asc);
    });
  }

  QueryBuilder<Absence, Absence, QAfterSortBy> sortByEndDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.desc);
    });
  }

  QueryBuilder<Absence, Absence, QAfterSortBy> sortByMotif() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'motif', Sort.asc);
    });
  }

  QueryBuilder<Absence, Absence, QAfterSortBy> sortByMotifDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'motif', Sort.desc);
    });
  }

  QueryBuilder<Absence, Absence, QAfterSortBy> sortByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.asc);
    });
  }

  QueryBuilder<Absence, Absence, QAfterSortBy> sortByStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.desc);
    });
  }

  QueryBuilder<Absence, Absence, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<Absence, Absence, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension AbsenceQuerySortThenBy
    on QueryBuilder<Absence, Absence, QSortThenBy> {
  QueryBuilder<Absence, Absence, QAfterSortBy> thenByEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.asc);
    });
  }

  QueryBuilder<Absence, Absence, QAfterSortBy> thenByEndDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.desc);
    });
  }

  QueryBuilder<Absence, Absence, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Absence, Absence, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Absence, Absence, QAfterSortBy> thenByMotif() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'motif', Sort.asc);
    });
  }

  QueryBuilder<Absence, Absence, QAfterSortBy> thenByMotifDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'motif', Sort.desc);
    });
  }

  QueryBuilder<Absence, Absence, QAfterSortBy> thenByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.asc);
    });
  }

  QueryBuilder<Absence, Absence, QAfterSortBy> thenByStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.desc);
    });
  }

  QueryBuilder<Absence, Absence, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<Absence, Absence, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension AbsenceQueryWhereDistinct
    on QueryBuilder<Absence, Absence, QDistinct> {
  QueryBuilder<Absence, Absence, QDistinct> distinctByEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endDate');
    });
  }

  QueryBuilder<Absence, Absence, QDistinct> distinctByMotif(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'motif', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Absence, Absence, QDistinct> distinctByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startDate');
    });
  }

  QueryBuilder<Absence, Absence, QDistinct> distinctByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type');
    });
  }
}

extension AbsenceQueryProperty
    on QueryBuilder<Absence, Absence, QQueryProperty> {
  QueryBuilder<Absence, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Absence, DateTime, QQueryOperations> endDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endDate');
    });
  }

  QueryBuilder<Absence, String, QQueryOperations> motifProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'motif');
    });
  }

  QueryBuilder<Absence, DateTime, QQueryOperations> startDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startDate');
    });
  }

  QueryBuilder<Absence, AbsenceType, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }
}
