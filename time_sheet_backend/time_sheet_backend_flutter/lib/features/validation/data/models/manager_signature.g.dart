// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manager_signature.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetManagerSignatureCollection on Isar {
  IsarCollection<ManagerSignature> get managerSignatures => this.collection();
}

const ManagerSignatureSchema = CollectionSchema(
  name: r'ManagerSignature',
  id: 3363385231540441419,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'managerId': PropertySchema(
      id: 1,
      name: r'managerId',
      type: IsarType.string,
    ),
    r'signatureBase64': PropertySchema(
      id: 2,
      name: r'signatureBase64',
      type: IsarType.string,
    )
  },
  estimateSize: _managerSignatureEstimateSize,
  serialize: _managerSignatureSerialize,
  deserialize: _managerSignatureDeserialize,
  deserializeProp: _managerSignatureDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _managerSignatureGetId,
  getLinks: _managerSignatureGetLinks,
  attach: _managerSignatureAttach,
  version: '3.1.0+1',
);

int _managerSignatureEstimateSize(
  ManagerSignature object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.managerId.length * 3;
  bytesCount += 3 + object.signatureBase64.length * 3;
  return bytesCount;
}

void _managerSignatureSerialize(
  ManagerSignature object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeString(offsets[1], object.managerId);
  writer.writeString(offsets[2], object.signatureBase64);
}

ManagerSignature _managerSignatureDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ManagerSignature();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.id = id;
  object.managerId = reader.readString(offsets[1]);
  object.signatureBase64 = reader.readString(offsets[2]);
  return object;
}

P _managerSignatureDeserializeProp<P>(
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
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _managerSignatureGetId(ManagerSignature object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _managerSignatureGetLinks(ManagerSignature object) {
  return [];
}

void _managerSignatureAttach(
    IsarCollection<dynamic> col, Id id, ManagerSignature object) {
  object.id = id;
}

extension ManagerSignatureQueryWhereSort
    on QueryBuilder<ManagerSignature, ManagerSignature, QWhere> {
  QueryBuilder<ManagerSignature, ManagerSignature, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ManagerSignatureQueryWhere
    on QueryBuilder<ManagerSignature, ManagerSignature, QWhereClause> {
  QueryBuilder<ManagerSignature, ManagerSignature, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterWhereClause>
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

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterWhereClause> idBetween(
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

extension ManagerSignatureQueryFilter
    on QueryBuilder<ManagerSignature, ManagerSignature, QFilterCondition> {
  QueryBuilder<ManagerSignature, ManagerSignature, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterFilterCondition>
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

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterFilterCondition>
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

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterFilterCondition>
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

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterFilterCondition>
      managerIdEqualTo(
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

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterFilterCondition>
      managerIdGreaterThan(
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

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterFilterCondition>
      managerIdLessThan(
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

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterFilterCondition>
      managerIdBetween(
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

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterFilterCondition>
      managerIdStartsWith(
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

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterFilterCondition>
      managerIdEndsWith(
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

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterFilterCondition>
      managerIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'managerId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterFilterCondition>
      managerIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'managerId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterFilterCondition>
      managerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'managerId',
        value: '',
      ));
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterFilterCondition>
      managerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'managerId',
        value: '',
      ));
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterFilterCondition>
      signatureBase64EqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'signatureBase64',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterFilterCondition>
      signatureBase64GreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'signatureBase64',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterFilterCondition>
      signatureBase64LessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'signatureBase64',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterFilterCondition>
      signatureBase64Between(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'signatureBase64',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterFilterCondition>
      signatureBase64StartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'signatureBase64',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterFilterCondition>
      signatureBase64EndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'signatureBase64',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterFilterCondition>
      signatureBase64Contains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'signatureBase64',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterFilterCondition>
      signatureBase64Matches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'signatureBase64',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterFilterCondition>
      signatureBase64IsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'signatureBase64',
        value: '',
      ));
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterFilterCondition>
      signatureBase64IsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'signatureBase64',
        value: '',
      ));
    });
  }
}

extension ManagerSignatureQueryObject
    on QueryBuilder<ManagerSignature, ManagerSignature, QFilterCondition> {}

extension ManagerSignatureQueryLinks
    on QueryBuilder<ManagerSignature, ManagerSignature, QFilterCondition> {}

extension ManagerSignatureQuerySortBy
    on QueryBuilder<ManagerSignature, ManagerSignature, QSortBy> {
  QueryBuilder<ManagerSignature, ManagerSignature, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterSortBy>
      sortByManagerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'managerId', Sort.asc);
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterSortBy>
      sortByManagerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'managerId', Sort.desc);
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterSortBy>
      sortBySignatureBase64() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signatureBase64', Sort.asc);
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterSortBy>
      sortBySignatureBase64Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signatureBase64', Sort.desc);
    });
  }
}

extension ManagerSignatureQuerySortThenBy
    on QueryBuilder<ManagerSignature, ManagerSignature, QSortThenBy> {
  QueryBuilder<ManagerSignature, ManagerSignature, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterSortBy>
      thenByManagerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'managerId', Sort.asc);
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterSortBy>
      thenByManagerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'managerId', Sort.desc);
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterSortBy>
      thenBySignatureBase64() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signatureBase64', Sort.asc);
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QAfterSortBy>
      thenBySignatureBase64Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signatureBase64', Sort.desc);
    });
  }
}

extension ManagerSignatureQueryWhereDistinct
    on QueryBuilder<ManagerSignature, ManagerSignature, QDistinct> {
  QueryBuilder<ManagerSignature, ManagerSignature, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QDistinct>
      distinctByManagerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'managerId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ManagerSignature, ManagerSignature, QDistinct>
      distinctBySignatureBase64({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'signatureBase64',
          caseSensitive: caseSensitive);
    });
  }
}

extension ManagerSignatureQueryProperty
    on QueryBuilder<ManagerSignature, ManagerSignature, QQueryProperty> {
  QueryBuilder<ManagerSignature, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ManagerSignature, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<ManagerSignature, String, QQueryOperations> managerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'managerId');
    });
  }

  QueryBuilder<ManagerSignature, String, QQueryOperations>
      signatureBase64Property() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'signatureBase64');
    });
  }
}
