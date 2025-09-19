// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'overtime_configuration.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetOvertimeConfigurationCollection on Isar {
  IsarCollection<OvertimeConfiguration> get overtimeConfigurations =>
      this.collection();
}

const OvertimeConfigurationSchema = CollectionSchema(
  name: r'OvertimeConfiguration',
  id: 2221216975970809619,
  properties: {
    r'configVersion': PropertySchema(
      id: 0,
      name: r'configVersion',
      type: IsarType.long,
    ),
    r'dailyWorkThresholdMinutes': PropertySchema(
      id: 1,
      name: r'dailyWorkThresholdMinutes',
      type: IsarType.long,
    ),
    r'description': PropertySchema(
      id: 2,
      name: r'description',
      type: IsarType.string,
    ),
    r'hashCode': PropertySchema(
      id: 3,
      name: r'hashCode',
      type: IsarType.long,
    ),
    r'lastUpdated': PropertySchema(
      id: 4,
      name: r'lastUpdated',
      type: IsarType.dateTime,
    ),
    r'weekdayOvertimeRate': PropertySchema(
      id: 5,
      name: r'weekdayOvertimeRate',
      type: IsarType.double,
    ),
    r'weekendDays': PropertySchema(
      id: 6,
      name: r'weekendDays',
      type: IsarType.longList,
    ),
    r'weekendOvertimeEnabled': PropertySchema(
      id: 7,
      name: r'weekendOvertimeEnabled',
      type: IsarType.bool,
    ),
    r'weekendOvertimeRate': PropertySchema(
      id: 8,
      name: r'weekendOvertimeRate',
      type: IsarType.double,
    )
  },
  estimateSize: _overtimeConfigurationEstimateSize,
  serialize: _overtimeConfigurationSerialize,
  deserialize: _overtimeConfigurationDeserialize,
  deserializeProp: _overtimeConfigurationDeserializeProp,
  idName: r'id',
  indexes: {
    r'weekendOvertimeEnabled': IndexSchema(
      id: -3865244563847687760,
      name: r'weekendOvertimeEnabled',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'weekendOvertimeEnabled',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'lastUpdated': IndexSchema(
      id: 8989359681631629925,
      name: r'lastUpdated',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'lastUpdated',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _overtimeConfigurationGetId,
  getLinks: _overtimeConfigurationGetLinks,
  attach: _overtimeConfigurationAttach,
  version: '3.1.0+1',
);

int _overtimeConfigurationEstimateSize(
  OvertimeConfiguration object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.weekendDays.length * 8;
  return bytesCount;
}

void _overtimeConfigurationSerialize(
  OvertimeConfiguration object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.configVersion);
  writer.writeLong(offsets[1], object.dailyWorkThresholdMinutes);
  writer.writeString(offsets[2], object.description);
  writer.writeLong(offsets[3], object.hashCode);
  writer.writeDateTime(offsets[4], object.lastUpdated);
  writer.writeDouble(offsets[5], object.weekdayOvertimeRate);
  writer.writeLongList(offsets[6], object.weekendDays);
  writer.writeBool(offsets[7], object.weekendOvertimeEnabled);
  writer.writeDouble(offsets[8], object.weekendOvertimeRate);
}

OvertimeConfiguration _overtimeConfigurationDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = OvertimeConfiguration();
  object.configVersion = reader.readLong(offsets[0]);
  object.dailyWorkThresholdMinutes = reader.readLong(offsets[1]);
  object.description = reader.readStringOrNull(offsets[2]);
  object.id = id;
  object.lastUpdated = reader.readDateTime(offsets[4]);
  object.weekdayOvertimeRate = reader.readDouble(offsets[5]);
  object.weekendDays = reader.readLongList(offsets[6]) ?? [];
  object.weekendOvertimeEnabled = reader.readBool(offsets[7]);
  object.weekendOvertimeRate = reader.readDouble(offsets[8]);
  return object;
}

P _overtimeConfigurationDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (reader.readLongList(offset) ?? []) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _overtimeConfigurationGetId(OvertimeConfiguration object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _overtimeConfigurationGetLinks(
    OvertimeConfiguration object) {
  return [];
}

void _overtimeConfigurationAttach(
    IsarCollection<dynamic> col, Id id, OvertimeConfiguration object) {
  object.id = id;
}

extension OvertimeConfigurationQueryWhereSort
    on QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QWhere> {
  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterWhere>
      anyWeekendOvertimeEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'weekendOvertimeEnabled'),
      );
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterWhere>
      anyLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'lastUpdated'),
      );
    });
  }
}

extension OvertimeConfigurationQueryWhere on QueryBuilder<OvertimeConfiguration,
    OvertimeConfiguration, QWhereClause> {
  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterWhereClause>
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

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterWhereClause>
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

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterWhereClause>
      weekendOvertimeEnabledEqualTo(bool weekendOvertimeEnabled) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'weekendOvertimeEnabled',
        value: [weekendOvertimeEnabled],
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterWhereClause>
      weekendOvertimeEnabledNotEqualTo(bool weekendOvertimeEnabled) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'weekendOvertimeEnabled',
              lower: [],
              upper: [weekendOvertimeEnabled],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'weekendOvertimeEnabled',
              lower: [weekendOvertimeEnabled],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'weekendOvertimeEnabled',
              lower: [weekendOvertimeEnabled],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'weekendOvertimeEnabled',
              lower: [],
              upper: [weekendOvertimeEnabled],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterWhereClause>
      lastUpdatedEqualTo(DateTime lastUpdated) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'lastUpdated',
        value: [lastUpdated],
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterWhereClause>
      lastUpdatedNotEqualTo(DateTime lastUpdated) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastUpdated',
              lower: [],
              upper: [lastUpdated],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastUpdated',
              lower: [lastUpdated],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastUpdated',
              lower: [lastUpdated],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastUpdated',
              lower: [],
              upper: [lastUpdated],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterWhereClause>
      lastUpdatedGreaterThan(
    DateTime lastUpdated, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'lastUpdated',
        lower: [lastUpdated],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterWhereClause>
      lastUpdatedLessThan(
    DateTime lastUpdated, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'lastUpdated',
        lower: [],
        upper: [lastUpdated],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterWhereClause>
      lastUpdatedBetween(
    DateTime lowerLastUpdated,
    DateTime upperLastUpdated, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'lastUpdated',
        lower: [lowerLastUpdated],
        includeLower: includeLower,
        upper: [upperLastUpdated],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension OvertimeConfigurationQueryFilter on QueryBuilder<
    OvertimeConfiguration, OvertimeConfiguration, QFilterCondition> {
  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> configVersionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'configVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> configVersionGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'configVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> configVersionLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'configVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> configVersionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'configVersion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> dailyWorkThresholdMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dailyWorkThresholdMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> dailyWorkThresholdMinutesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dailyWorkThresholdMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> dailyWorkThresholdMinutesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dailyWorkThresholdMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> dailyWorkThresholdMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dailyWorkThresholdMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> descriptionEqualTo(
    String? value, {
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

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> descriptionGreaterThan(
    String? value, {
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

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> descriptionLessThan(
    String? value, {
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

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> descriptionBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> descriptionStartsWith(
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

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> descriptionEndsWith(
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

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
          QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
          QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> hashCodeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> hashCodeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> hashCodeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> hashCodeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hashCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> idLessThan(
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

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> idBetween(
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

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> lastUpdatedEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastUpdated',
        value: value,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> lastUpdatedGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastUpdated',
        value: value,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> lastUpdatedLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastUpdated',
        value: value,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> lastUpdatedBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastUpdated',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> weekdayOvertimeRateEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weekdayOvertimeRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> weekdayOvertimeRateGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weekdayOvertimeRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> weekdayOvertimeRateLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weekdayOvertimeRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> weekdayOvertimeRateBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weekdayOvertimeRate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> weekendDaysElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weekendDays',
        value: value,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> weekendDaysElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weekendDays',
        value: value,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> weekendDaysElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weekendDays',
        value: value,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> weekendDaysElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weekendDays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> weekendDaysLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'weekendDays',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> weekendDaysIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'weekendDays',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> weekendDaysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'weekendDays',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> weekendDaysLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'weekendDays',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> weekendDaysLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'weekendDays',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> weekendDaysLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'weekendDays',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> weekendOvertimeEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weekendOvertimeEnabled',
        value: value,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> weekendOvertimeRateEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weekendOvertimeRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> weekendOvertimeRateGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weekendOvertimeRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> weekendOvertimeRateLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weekendOvertimeRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration,
      QAfterFilterCondition> weekendOvertimeRateBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weekendOvertimeRate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension OvertimeConfigurationQueryObject on QueryBuilder<
    OvertimeConfiguration, OvertimeConfiguration, QFilterCondition> {}

extension OvertimeConfigurationQueryLinks on QueryBuilder<OvertimeConfiguration,
    OvertimeConfiguration, QFilterCondition> {}

extension OvertimeConfigurationQuerySortBy
    on QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QSortBy> {
  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      sortByConfigVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'configVersion', Sort.asc);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      sortByConfigVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'configVersion', Sort.desc);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      sortByDailyWorkThresholdMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyWorkThresholdMinutes', Sort.asc);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      sortByDailyWorkThresholdMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyWorkThresholdMinutes', Sort.desc);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      sortByHashCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.asc);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      sortByHashCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.desc);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      sortByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      sortByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      sortByWeekdayOvertimeRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weekdayOvertimeRate', Sort.asc);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      sortByWeekdayOvertimeRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weekdayOvertimeRate', Sort.desc);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      sortByWeekendOvertimeEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weekendOvertimeEnabled', Sort.asc);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      sortByWeekendOvertimeEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weekendOvertimeEnabled', Sort.desc);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      sortByWeekendOvertimeRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weekendOvertimeRate', Sort.asc);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      sortByWeekendOvertimeRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weekendOvertimeRate', Sort.desc);
    });
  }
}

extension OvertimeConfigurationQuerySortThenBy
    on QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QSortThenBy> {
  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      thenByConfigVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'configVersion', Sort.asc);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      thenByConfigVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'configVersion', Sort.desc);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      thenByDailyWorkThresholdMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyWorkThresholdMinutes', Sort.asc);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      thenByDailyWorkThresholdMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyWorkThresholdMinutes', Sort.desc);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      thenByHashCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.asc);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      thenByHashCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.desc);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      thenByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      thenByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      thenByWeekdayOvertimeRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weekdayOvertimeRate', Sort.asc);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      thenByWeekdayOvertimeRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weekdayOvertimeRate', Sort.desc);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      thenByWeekendOvertimeEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weekendOvertimeEnabled', Sort.asc);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      thenByWeekendOvertimeEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weekendOvertimeEnabled', Sort.desc);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      thenByWeekendOvertimeRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weekendOvertimeRate', Sort.asc);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QAfterSortBy>
      thenByWeekendOvertimeRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weekendOvertimeRate', Sort.desc);
    });
  }
}

extension OvertimeConfigurationQueryWhereDistinct
    on QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QDistinct> {
  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QDistinct>
      distinctByConfigVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'configVersion');
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QDistinct>
      distinctByDailyWorkThresholdMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dailyWorkThresholdMinutes');
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QDistinct>
      distinctByDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QDistinct>
      distinctByHashCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hashCode');
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QDistinct>
      distinctByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUpdated');
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QDistinct>
      distinctByWeekdayOvertimeRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weekdayOvertimeRate');
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QDistinct>
      distinctByWeekendDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weekendDays');
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QDistinct>
      distinctByWeekendOvertimeEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weekendOvertimeEnabled');
    });
  }

  QueryBuilder<OvertimeConfiguration, OvertimeConfiguration, QDistinct>
      distinctByWeekendOvertimeRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weekendOvertimeRate');
    });
  }
}

extension OvertimeConfigurationQueryProperty on QueryBuilder<
    OvertimeConfiguration, OvertimeConfiguration, QQueryProperty> {
  QueryBuilder<OvertimeConfiguration, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<OvertimeConfiguration, int, QQueryOperations>
      configVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'configVersion');
    });
  }

  QueryBuilder<OvertimeConfiguration, int, QQueryOperations>
      dailyWorkThresholdMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dailyWorkThresholdMinutes');
    });
  }

  QueryBuilder<OvertimeConfiguration, String?, QQueryOperations>
      descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<OvertimeConfiguration, int, QQueryOperations>
      hashCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hashCode');
    });
  }

  QueryBuilder<OvertimeConfiguration, DateTime, QQueryOperations>
      lastUpdatedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUpdated');
    });
  }

  QueryBuilder<OvertimeConfiguration, double, QQueryOperations>
      weekdayOvertimeRateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weekdayOvertimeRate');
    });
  }

  QueryBuilder<OvertimeConfiguration, List<int>, QQueryOperations>
      weekendDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weekendDays');
    });
  }

  QueryBuilder<OvertimeConfiguration, bool, QQueryOperations>
      weekendOvertimeEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weekendOvertimeEnabled');
    });
  }

  QueryBuilder<OvertimeConfiguration, double, QQueryOperations>
      weekendOvertimeRateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weekendOvertimeRate');
    });
  }
}
