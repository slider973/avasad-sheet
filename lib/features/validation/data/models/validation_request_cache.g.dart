// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'validation_request_cache.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetValidationRequestCacheCollection on Isar {
  IsarCollection<ValidationRequestCache> get validationRequestCaches =>
      this.collection();
}

const ValidationRequestCacheSchema = CollectionSchema(
  name: r'ValidationRequestCache',
  id: 8240837174703299484,
  properties: {
    r'employeeId': PropertySchema(
      id: 0,
      name: r'employeeId',
      type: IsarType.string,
    ),
    r'jsonData': PropertySchema(
      id: 1,
      name: r'jsonData',
      type: IsarType.string,
    ),
    r'lastUpdated': PropertySchema(
      id: 2,
      name: r'lastUpdated',
      type: IsarType.dateTime,
    ),
    r'managerId': PropertySchema(
      id: 3,
      name: r'managerId',
      type: IsarType.string,
    ),
    r'validationId': PropertySchema(
      id: 4,
      name: r'validationId',
      type: IsarType.string,
    )
  },
  estimateSize: _validationRequestCacheEstimateSize,
  serialize: _validationRequestCacheSerialize,
  deserialize: _validationRequestCacheDeserialize,
  deserializeProp: _validationRequestCacheDeserializeProp,
  idName: r'id',
  indexes: {
    r'validationId': IndexSchema(
      id: -9178713511297922509,
      name: r'validationId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'validationId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'employeeId': IndexSchema(
      id: 1283453093523034672,
      name: r'employeeId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'employeeId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'managerId': IndexSchema(
      id: 8332109317052964205,
      name: r'managerId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'managerId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _validationRequestCacheGetId,
  getLinks: _validationRequestCacheGetLinks,
  attach: _validationRequestCacheAttach,
  version: '3.1.0+1',
);

int _validationRequestCacheEstimateSize(
  ValidationRequestCache object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.employeeId.length * 3;
  bytesCount += 3 + object.jsonData.length * 3;
  bytesCount += 3 + object.managerId.length * 3;
  bytesCount += 3 + object.validationId.length * 3;
  return bytesCount;
}

void _validationRequestCacheSerialize(
  ValidationRequestCache object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.employeeId);
  writer.writeString(offsets[1], object.jsonData);
  writer.writeDateTime(offsets[2], object.lastUpdated);
  writer.writeString(offsets[3], object.managerId);
  writer.writeString(offsets[4], object.validationId);
}

ValidationRequestCache _validationRequestCacheDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ValidationRequestCache();
  object.employeeId = reader.readString(offsets[0]);
  object.id = id;
  object.jsonData = reader.readString(offsets[1]);
  object.lastUpdated = reader.readDateTime(offsets[2]);
  object.managerId = reader.readString(offsets[3]);
  object.validationId = reader.readString(offsets[4]);
  return object;
}

P _validationRequestCacheDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _validationRequestCacheGetId(ValidationRequestCache object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _validationRequestCacheGetLinks(
    ValidationRequestCache object) {
  return [];
}

void _validationRequestCacheAttach(
    IsarCollection<dynamic> col, Id id, ValidationRequestCache object) {
  object.id = id;
}

extension ValidationRequestCacheByIndex
    on IsarCollection<ValidationRequestCache> {
  Future<ValidationRequestCache?> getByValidationId(String validationId) {
    return getByIndex(r'validationId', [validationId]);
  }

  ValidationRequestCache? getByValidationIdSync(String validationId) {
    return getByIndexSync(r'validationId', [validationId]);
  }

  Future<bool> deleteByValidationId(String validationId) {
    return deleteByIndex(r'validationId', [validationId]);
  }

  bool deleteByValidationIdSync(String validationId) {
    return deleteByIndexSync(r'validationId', [validationId]);
  }

  Future<List<ValidationRequestCache?>> getAllByValidationId(
      List<String> validationIdValues) {
    final values = validationIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'validationId', values);
  }

  List<ValidationRequestCache?> getAllByValidationIdSync(
      List<String> validationIdValues) {
    final values = validationIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'validationId', values);
  }

  Future<int> deleteAllByValidationId(List<String> validationIdValues) {
    final values = validationIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'validationId', values);
  }

  int deleteAllByValidationIdSync(List<String> validationIdValues) {
    final values = validationIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'validationId', values);
  }

  Future<Id> putByValidationId(ValidationRequestCache object) {
    return putByIndex(r'validationId', object);
  }

  Id putByValidationIdSync(ValidationRequestCache object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'validationId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByValidationId(List<ValidationRequestCache> objects) {
    return putAllByIndex(r'validationId', objects);
  }

  List<Id> putAllByValidationIdSync(List<ValidationRequestCache> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'validationId', objects, saveLinks: saveLinks);
  }
}

extension ValidationRequestCacheQueryWhereSort
    on QueryBuilder<ValidationRequestCache, ValidationRequestCache, QWhere> {
  QueryBuilder<ValidationRequestCache, ValidationRequestCache, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ValidationRequestCacheQueryWhere on QueryBuilder<
    ValidationRequestCache, ValidationRequestCache, QWhereClause> {
  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterWhereClause> idBetween(
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

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterWhereClause> validationIdEqualTo(String validationId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'validationId',
        value: [validationId],
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterWhereClause> validationIdNotEqualTo(String validationId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'validationId',
              lower: [],
              upper: [validationId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'validationId',
              lower: [validationId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'validationId',
              lower: [validationId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'validationId',
              lower: [],
              upper: [validationId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterWhereClause> employeeIdEqualTo(String employeeId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'employeeId',
        value: [employeeId],
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterWhereClause> employeeIdNotEqualTo(String employeeId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'employeeId',
              lower: [],
              upper: [employeeId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'employeeId',
              lower: [employeeId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'employeeId',
              lower: [employeeId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'employeeId',
              lower: [],
              upper: [employeeId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterWhereClause> managerIdEqualTo(String managerId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'managerId',
        value: [managerId],
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterWhereClause> managerIdNotEqualTo(String managerId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'managerId',
              lower: [],
              upper: [managerId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'managerId',
              lower: [managerId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'managerId',
              lower: [managerId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'managerId',
              lower: [],
              upper: [managerId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension ValidationRequestCacheQueryFilter on QueryBuilder<
    ValidationRequestCache, ValidationRequestCache, QFilterCondition> {
  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> employeeIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'employeeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> employeeIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'employeeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> employeeIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'employeeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> employeeIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'employeeId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> employeeIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'employeeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> employeeIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'employeeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
          QAfterFilterCondition>
      employeeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'employeeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
          QAfterFilterCondition>
      employeeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'employeeId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> employeeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'employeeId',
        value: '',
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> employeeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'employeeId',
        value: '',
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
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

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
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

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
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

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> jsonDataEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'jsonData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> jsonDataGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'jsonData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> jsonDataLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'jsonData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> jsonDataBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'jsonData',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> jsonDataStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'jsonData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> jsonDataEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'jsonData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
          QAfterFilterCondition>
      jsonDataContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'jsonData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
          QAfterFilterCondition>
      jsonDataMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'jsonData',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> jsonDataIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'jsonData',
        value: '',
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> jsonDataIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'jsonData',
        value: '',
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> lastUpdatedEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastUpdated',
        value: value,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
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

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
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

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
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

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> managerIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'managerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> managerIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'managerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> managerIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'managerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> managerIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'managerId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> managerIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'managerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> managerIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'managerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
          QAfterFilterCondition>
      managerIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'managerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
          QAfterFilterCondition>
      managerIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'managerId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> managerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'managerId',
        value: '',
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> managerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'managerId',
        value: '',
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> validationIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'validationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> validationIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'validationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> validationIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'validationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> validationIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'validationId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> validationIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'validationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> validationIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'validationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
          QAfterFilterCondition>
      validationIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'validationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
          QAfterFilterCondition>
      validationIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'validationId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> validationIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'validationId',
        value: '',
      ));
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache,
      QAfterFilterCondition> validationIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'validationId',
        value: '',
      ));
    });
  }
}

extension ValidationRequestCacheQueryObject on QueryBuilder<
    ValidationRequestCache, ValidationRequestCache, QFilterCondition> {}

extension ValidationRequestCacheQueryLinks on QueryBuilder<
    ValidationRequestCache, ValidationRequestCache, QFilterCondition> {}

extension ValidationRequestCacheQuerySortBy
    on QueryBuilder<ValidationRequestCache, ValidationRequestCache, QSortBy> {
  QueryBuilder<ValidationRequestCache, ValidationRequestCache, QAfterSortBy>
      sortByEmployeeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'employeeId', Sort.asc);
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache, QAfterSortBy>
      sortByEmployeeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'employeeId', Sort.desc);
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache, QAfterSortBy>
      sortByJsonData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jsonData', Sort.asc);
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache, QAfterSortBy>
      sortByJsonDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jsonData', Sort.desc);
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache, QAfterSortBy>
      sortByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache, QAfterSortBy>
      sortByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache, QAfterSortBy>
      sortByManagerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'managerId', Sort.asc);
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache, QAfterSortBy>
      sortByManagerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'managerId', Sort.desc);
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache, QAfterSortBy>
      sortByValidationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'validationId', Sort.asc);
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache, QAfterSortBy>
      sortByValidationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'validationId', Sort.desc);
    });
  }
}

extension ValidationRequestCacheQuerySortThenBy on QueryBuilder<
    ValidationRequestCache, ValidationRequestCache, QSortThenBy> {
  QueryBuilder<ValidationRequestCache, ValidationRequestCache, QAfterSortBy>
      thenByEmployeeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'employeeId', Sort.asc);
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache, QAfterSortBy>
      thenByEmployeeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'employeeId', Sort.desc);
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache, QAfterSortBy>
      thenByJsonData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jsonData', Sort.asc);
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache, QAfterSortBy>
      thenByJsonDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jsonData', Sort.desc);
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache, QAfterSortBy>
      thenByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache, QAfterSortBy>
      thenByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache, QAfterSortBy>
      thenByManagerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'managerId', Sort.asc);
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache, QAfterSortBy>
      thenByManagerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'managerId', Sort.desc);
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache, QAfterSortBy>
      thenByValidationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'validationId', Sort.asc);
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache, QAfterSortBy>
      thenByValidationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'validationId', Sort.desc);
    });
  }
}

extension ValidationRequestCacheQueryWhereDistinct
    on QueryBuilder<ValidationRequestCache, ValidationRequestCache, QDistinct> {
  QueryBuilder<ValidationRequestCache, ValidationRequestCache, QDistinct>
      distinctByEmployeeId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'employeeId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache, QDistinct>
      distinctByJsonData({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'jsonData', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache, QDistinct>
      distinctByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUpdated');
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache, QDistinct>
      distinctByManagerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'managerId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ValidationRequestCache, ValidationRequestCache, QDistinct>
      distinctByValidationId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'validationId', caseSensitive: caseSensitive);
    });
  }
}

extension ValidationRequestCacheQueryProperty on QueryBuilder<
    ValidationRequestCache, ValidationRequestCache, QQueryProperty> {
  QueryBuilder<ValidationRequestCache, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ValidationRequestCache, String, QQueryOperations>
      employeeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'employeeId');
    });
  }

  QueryBuilder<ValidationRequestCache, String, QQueryOperations>
      jsonDataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'jsonData');
    });
  }

  QueryBuilder<ValidationRequestCache, DateTime, QQueryOperations>
      lastUpdatedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUpdated');
    });
  }

  QueryBuilder<ValidationRequestCache, String, QQueryOperations>
      managerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'managerId');
    });
  }

  QueryBuilder<ValidationRequestCache, String, QQueryOperations>
      validationIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'validationId');
    });
  }
}
