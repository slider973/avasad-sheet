// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anomalies.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAnomalyModelCollection on Isar {
  IsarCollection<AnomalyModel> get anomalyModels => this.collection();
}

const AnomalyModelSchema = CollectionSchema(
  name: r'AnomalyModel',
  id: 3559570158274515192,
  properties: {
    r'description': PropertySchema(
      id: 0,
      name: r'description',
      type: IsarType.string,
    ),
    r'detectedDate': PropertySchema(
      id: 1,
      name: r'detectedDate',
      type: IsarType.dateTime,
    ),
    r'isResolved': PropertySchema(
      id: 2,
      name: r'isResolved',
      type: IsarType.bool,
    ),
    r'type': PropertySchema(
      id: 3,
      name: r'type',
      type: IsarType.byte,
      enumMap: _AnomalyModeltypeEnumValueMap,
    )
  },
  estimateSize: _anomalyModelEstimateSize,
  serialize: _anomalyModelSerialize,
  deserialize: _anomalyModelDeserialize,
  deserializeProp: _anomalyModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'detectedDate': IndexSchema(
      id: 3790884950733590742,
      name: r'detectedDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'detectedDate',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {
    r'timesheetEntry': LinkSchema(
      id: 6750034674537119580,
      name: r'timesheetEntry',
      target: r'TimeSheetEntryModel',
      single: true,
    )
  },
  embeddedSchemas: {},
  getId: _anomalyModelGetId,
  getLinks: _anomalyModelGetLinks,
  attach: _anomalyModelAttach,
  version: '3.1.0+1',
);

int _anomalyModelEstimateSize(
  AnomalyModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.description.length * 3;
  return bytesCount;
}

void _anomalyModelSerialize(
  AnomalyModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.description);
  writer.writeDateTime(offsets[1], object.detectedDate);
  writer.writeBool(offsets[2], object.isResolved);
  writer.writeByte(offsets[3], object.type.index);
}

AnomalyModel _anomalyModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AnomalyModel();
  object.description = reader.readString(offsets[0]);
  object.detectedDate = reader.readDateTime(offsets[1]);
  object.id = id;
  object.isResolved = reader.readBool(offsets[2]);
  object.type =
      _AnomalyModeltypeValueEnumMap[reader.readByteOrNull(offsets[3])] ??
          AnomalyType.insufficientHours;
  return object;
}

P _anomalyModelDeserializeProp<P>(
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
      return (reader.readBool(offset)) as P;
    case 3:
      return (_AnomalyModeltypeValueEnumMap[reader.readByteOrNull(offset)] ??
          AnomalyType.insufficientHours) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _AnomalyModeltypeEnumValueMap = {
  'insufficientHours': 0,
  'missingEntry': 1,
  'invalidTimes': 2,
};
const _AnomalyModeltypeValueEnumMap = {
  0: AnomalyType.insufficientHours,
  1: AnomalyType.missingEntry,
  2: AnomalyType.invalidTimes,
};

Id _anomalyModelGetId(AnomalyModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _anomalyModelGetLinks(AnomalyModel object) {
  return [object.timesheetEntry];
}

void _anomalyModelAttach(
    IsarCollection<dynamic> col, Id id, AnomalyModel object) {
  object.id = id;
  object.timesheetEntry.attach(
      col, col.isar.collection<TimeSheetEntryModel>(), r'timesheetEntry', id);
}

extension AnomalyModelQueryWhereSort
    on QueryBuilder<AnomalyModel, AnomalyModel, QWhere> {
  QueryBuilder<AnomalyModel, AnomalyModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterWhere> anyDetectedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'detectedDate'),
      );
    });
  }
}

extension AnomalyModelQueryWhere
    on QueryBuilder<AnomalyModel, AnomalyModel, QWhereClause> {
  QueryBuilder<AnomalyModel, AnomalyModel, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterWhereClause> idBetween(
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

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterWhereClause>
      detectedDateEqualTo(DateTime detectedDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'detectedDate',
        value: [detectedDate],
      ));
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterWhereClause>
      detectedDateNotEqualTo(DateTime detectedDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'detectedDate',
              lower: [],
              upper: [detectedDate],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'detectedDate',
              lower: [detectedDate],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'detectedDate',
              lower: [detectedDate],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'detectedDate',
              lower: [],
              upper: [detectedDate],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterWhereClause>
      detectedDateGreaterThan(
    DateTime detectedDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'detectedDate',
        lower: [detectedDate],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterWhereClause>
      detectedDateLessThan(
    DateTime detectedDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'detectedDate',
        lower: [],
        upper: [detectedDate],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterWhereClause>
      detectedDateBetween(
    DateTime lowerDetectedDate,
    DateTime upperDetectedDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'detectedDate',
        lower: [lowerDetectedDate],
        includeLower: includeLower,
        upper: [upperDetectedDate],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension AnomalyModelQueryFilter
    on QueryBuilder<AnomalyModel, AnomalyModel, QFilterCondition> {
  QueryBuilder<AnomalyModel, AnomalyModel, QAfterFilterCondition>
      descriptionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterFilterCondition>
      descriptionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterFilterCondition>
      descriptionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterFilterCondition>
      descriptionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterFilterCondition>
      descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterFilterCondition>
      descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterFilterCondition>
      detectedDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'detectedDate',
        value: value,
      ));
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterFilterCondition>
      detectedDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'detectedDate',
        value: value,
      ));
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterFilterCondition>
      detectedDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'detectedDate',
        value: value,
      ));
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterFilterCondition>
      detectedDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'detectedDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterFilterCondition> idBetween(
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

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterFilterCondition>
      isResolvedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isResolved',
        value: value,
      ));
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterFilterCondition> typeEqualTo(
      AnomalyType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterFilterCondition>
      typeGreaterThan(
    AnomalyType value, {
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

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterFilterCondition> typeLessThan(
    AnomalyType value, {
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

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterFilterCondition> typeBetween(
    AnomalyType lower,
    AnomalyType upper, {
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

extension AnomalyModelQueryObject
    on QueryBuilder<AnomalyModel, AnomalyModel, QFilterCondition> {}

extension AnomalyModelQueryLinks
    on QueryBuilder<AnomalyModel, AnomalyModel, QFilterCondition> {
  QueryBuilder<AnomalyModel, AnomalyModel, QAfterFilterCondition>
      timesheetEntry(FilterQuery<TimeSheetEntryModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'timesheetEntry');
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterFilterCondition>
      timesheetEntryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'timesheetEntry', 0, true, 0, true);
    });
  }
}

extension AnomalyModelQuerySortBy
    on QueryBuilder<AnomalyModel, AnomalyModel, QSortBy> {
  QueryBuilder<AnomalyModel, AnomalyModel, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterSortBy>
      sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterSortBy> sortByDetectedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedDate', Sort.asc);
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterSortBy>
      sortByDetectedDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedDate', Sort.desc);
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterSortBy> sortByIsResolved() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isResolved', Sort.asc);
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterSortBy>
      sortByIsResolvedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isResolved', Sort.desc);
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension AnomalyModelQuerySortThenBy
    on QueryBuilder<AnomalyModel, AnomalyModel, QSortThenBy> {
  QueryBuilder<AnomalyModel, AnomalyModel, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterSortBy>
      thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterSortBy> thenByDetectedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedDate', Sort.asc);
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterSortBy>
      thenByDetectedDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedDate', Sort.desc);
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterSortBy> thenByIsResolved() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isResolved', Sort.asc);
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterSortBy>
      thenByIsResolvedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isResolved', Sort.desc);
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension AnomalyModelQueryWhereDistinct
    on QueryBuilder<AnomalyModel, AnomalyModel, QDistinct> {
  QueryBuilder<AnomalyModel, AnomalyModel, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QDistinct> distinctByDetectedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'detectedDate');
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QDistinct> distinctByIsResolved() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isResolved');
    });
  }

  QueryBuilder<AnomalyModel, AnomalyModel, QDistinct> distinctByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type');
    });
  }
}

extension AnomalyModelQueryProperty
    on QueryBuilder<AnomalyModel, AnomalyModel, QQueryProperty> {
  QueryBuilder<AnomalyModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AnomalyModel, String, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<AnomalyModel, DateTime, QQueryOperations>
      detectedDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'detectedDate');
    });
  }

  QueryBuilder<AnomalyModel, bool, QQueryOperations> isResolvedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isResolved');
    });
  }

  QueryBuilder<AnomalyModel, AnomalyType, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }
}
