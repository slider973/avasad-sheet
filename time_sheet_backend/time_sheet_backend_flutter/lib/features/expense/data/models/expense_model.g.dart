// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetExpenseModelCollection on Isar {
  IsarCollection<ExpenseModel> get expenseModels => this.collection();
}

const ExpenseModelSchema = CollectionSchema(
  name: r'ExpenseModel',
  id: 8411865314220037745,
  properties: {
    r'amount': PropertySchema(
      id: 0,
      name: r'amount',
      type: IsarType.double,
    ),
    r'approvedAt': PropertySchema(
      id: 1,
      name: r'approvedAt',
      type: IsarType.dateTime,
    ),
    r'arrivalLocation': PropertySchema(
      id: 2,
      name: r'arrivalLocation',
      type: IsarType.string,
    ),
    r'attachmentPath': PropertySchema(
      id: 3,
      name: r'attachmentPath',
      type: IsarType.string,
    ),
    r'category': PropertySchema(
      id: 4,
      name: r'category',
      type: IsarType.string,
      enumMap: _ExpenseModelcategoryEnumValueMap,
    ),
    r'createdAt': PropertySchema(
      id: 5,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'currency': PropertySchema(
      id: 6,
      name: r'currency',
      type: IsarType.string,
    ),
    r'date': PropertySchema(
      id: 7,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'departureLocation': PropertySchema(
      id: 8,
      name: r'departureLocation',
      type: IsarType.string,
    ),
    r'description': PropertySchema(
      id: 9,
      name: r'description',
      type: IsarType.string,
    ),
    r'distanceKm': PropertySchema(
      id: 10,
      name: r'distanceKm',
      type: IsarType.long,
    ),
    r'isApproved': PropertySchema(
      id: 11,
      name: r'isApproved',
      type: IsarType.bool,
    ),
    r'isSynced': PropertySchema(
      id: 12,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'managerComment': PropertySchema(
      id: 13,
      name: r'managerComment',
      type: IsarType.string,
    ),
    r'mileageRate': PropertySchema(
      id: 14,
      name: r'mileageRate',
      type: IsarType.double,
    ),
    r'updatedAt': PropertySchema(
      id: 15,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _expenseModelEstimateSize,
  serialize: _expenseModelSerialize,
  deserialize: _expenseModelDeserialize,
  deserializeProp: _expenseModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'date': IndexSchema(
      id: -7552997827385218417,
      name: r'date',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'date',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _expenseModelGetId,
  getLinks: _expenseModelGetLinks,
  attach: _expenseModelAttach,
  version: '3.1.0+1',
);

int _expenseModelEstimateSize(
  ExpenseModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.arrivalLocation;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.attachmentPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.category.name.length * 3;
  bytesCount += 3 + object.currency.length * 3;
  {
    final value = object.departureLocation;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.description.length * 3;
  {
    final value = object.managerComment;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _expenseModelSerialize(
  ExpenseModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.amount);
  writer.writeDateTime(offsets[1], object.approvedAt);
  writer.writeString(offsets[2], object.arrivalLocation);
  writer.writeString(offsets[3], object.attachmentPath);
  writer.writeString(offsets[4], object.category.name);
  writer.writeDateTime(offsets[5], object.createdAt);
  writer.writeString(offsets[6], object.currency);
  writer.writeDateTime(offsets[7], object.date);
  writer.writeString(offsets[8], object.departureLocation);
  writer.writeString(offsets[9], object.description);
  writer.writeLong(offsets[10], object.distanceKm);
  writer.writeBool(offsets[11], object.isApproved);
  writer.writeBool(offsets[12], object.isSynced);
  writer.writeString(offsets[13], object.managerComment);
  writer.writeDouble(offsets[14], object.mileageRate);
  writer.writeDateTime(offsets[15], object.updatedAt);
}

ExpenseModel _expenseModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ExpenseModel();
  object.amount = reader.readDouble(offsets[0]);
  object.approvedAt = reader.readDateTimeOrNull(offsets[1]);
  object.arrivalLocation = reader.readStringOrNull(offsets[2]);
  object.attachmentPath = reader.readStringOrNull(offsets[3]);
  object.category =
      _ExpenseModelcategoryValueEnumMap[reader.readStringOrNull(offsets[4])] ??
          ExpenseCategory.mileage;
  object.createdAt = reader.readDateTime(offsets[5]);
  object.currency = reader.readString(offsets[6]);
  object.date = reader.readDateTime(offsets[7]);
  object.departureLocation = reader.readStringOrNull(offsets[8]);
  object.description = reader.readString(offsets[9]);
  object.distanceKm = reader.readLongOrNull(offsets[10]);
  object.id = id;
  object.isApproved = reader.readBool(offsets[11]);
  object.isSynced = reader.readBool(offsets[12]);
  object.managerComment = reader.readStringOrNull(offsets[13]);
  object.mileageRate = reader.readDoubleOrNull(offsets[14]);
  object.updatedAt = reader.readDateTime(offsets[15]);
  return object;
}

P _expenseModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (_ExpenseModelcategoryValueEnumMap[
              reader.readStringOrNull(offset)] ??
          ExpenseCategory.mileage) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readDateTime(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readLongOrNull(offset)) as P;
    case 11:
      return (reader.readBool(offset)) as P;
    case 12:
      return (reader.readBool(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readDoubleOrNull(offset)) as P;
    case 15:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _ExpenseModelcategoryEnumValueMap = {
  r'mileage': r'mileage',
  r'meal': r'meal',
  r'accommodation': r'accommodation',
  r'transport': r'transport',
  r'parking': r'parking',
  r'other': r'other',
};
const _ExpenseModelcategoryValueEnumMap = {
  r'mileage': ExpenseCategory.mileage,
  r'meal': ExpenseCategory.meal,
  r'accommodation': ExpenseCategory.accommodation,
  r'transport': ExpenseCategory.transport,
  r'parking': ExpenseCategory.parking,
  r'other': ExpenseCategory.other,
};

Id _expenseModelGetId(ExpenseModel object) {
  return object.id ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _expenseModelGetLinks(ExpenseModel object) {
  return [];
}

void _expenseModelAttach(
    IsarCollection<dynamic> col, Id id, ExpenseModel object) {
  object.id = id;
}

extension ExpenseModelQueryWhereSort
    on QueryBuilder<ExpenseModel, ExpenseModel, QWhere> {
  QueryBuilder<ExpenseModel, ExpenseModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterWhere> anyDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'date'),
      );
    });
  }
}

extension ExpenseModelQueryWhere
    on QueryBuilder<ExpenseModel, ExpenseModel, QWhereClause> {
  QueryBuilder<ExpenseModel, ExpenseModel, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterWhereClause> idBetween(
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

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterWhereClause> dateEqualTo(
      DateTime date) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'date',
        value: [date],
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterWhereClause> dateNotEqualTo(
      DateTime date) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterWhereClause> dateGreaterThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [date],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterWhereClause> dateLessThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [],
        upper: [date],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterWhereClause> dateBetween(
    DateTime lowerDate,
    DateTime upperDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [lowerDate],
        includeLower: includeLower,
        upper: [upperDate],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ExpenseModelQueryFilter
    on QueryBuilder<ExpenseModel, ExpenseModel, QFilterCondition> {
  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> amountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      amountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      amountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> amountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      approvedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'approvedAt',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      approvedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'approvedAt',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      approvedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'approvedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      approvedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'approvedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      approvedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'approvedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      approvedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'approvedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      arrivalLocationIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'arrivalLocation',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      arrivalLocationIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'arrivalLocation',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      arrivalLocationEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'arrivalLocation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      arrivalLocationGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'arrivalLocation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      arrivalLocationLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'arrivalLocation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      arrivalLocationBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'arrivalLocation',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      arrivalLocationStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'arrivalLocation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      arrivalLocationEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'arrivalLocation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      arrivalLocationContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'arrivalLocation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      arrivalLocationMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'arrivalLocation',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      arrivalLocationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'arrivalLocation',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      arrivalLocationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'arrivalLocation',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      attachmentPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'attachmentPath',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      attachmentPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'attachmentPath',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      attachmentPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'attachmentPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      attachmentPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'attachmentPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      attachmentPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'attachmentPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      attachmentPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'attachmentPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      attachmentPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'attachmentPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      attachmentPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'attachmentPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      attachmentPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'attachmentPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      attachmentPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'attachmentPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      attachmentPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'attachmentPath',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      attachmentPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'attachmentPath',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      categoryEqualTo(
    ExpenseCategory value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      categoryGreaterThan(
    ExpenseCategory value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      categoryLessThan(
    ExpenseCategory value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      categoryBetween(
    ExpenseCategory lower,
    ExpenseCategory upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'category',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      categoryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      categoryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      categoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      categoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'category',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
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

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
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

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
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

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      currencyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      currencyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      currencyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      currencyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currency',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      currencyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      currencyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      currencyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'currency',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      currencyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'currency',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      currencyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currency',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      currencyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'currency',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> dateEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      dateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> dateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      departureLocationIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'departureLocation',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      departureLocationIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'departureLocation',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      departureLocationEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'departureLocation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      departureLocationGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'departureLocation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      departureLocationLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'departureLocation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      departureLocationBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'departureLocation',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      departureLocationStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'departureLocation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      departureLocationEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'departureLocation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      departureLocationContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'departureLocation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      departureLocationMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'departureLocation',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      departureLocationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'departureLocation',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      departureLocationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'departureLocation',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
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

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
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

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
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

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
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

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
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

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
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

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      distanceKmIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'distanceKm',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      distanceKmIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'distanceKm',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      distanceKmEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'distanceKm',
        value: value,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      distanceKmGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'distanceKm',
        value: value,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      distanceKmLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'distanceKm',
        value: value,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      distanceKmBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'distanceKm',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> idEqualTo(
      Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> idGreaterThan(
    Id? value, {
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

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> idLessThan(
    Id? value, {
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

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition> idBetween(
    Id? lower,
    Id? upper, {
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

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      isApprovedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isApproved',
        value: value,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      managerCommentIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'managerComment',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      managerCommentIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'managerComment',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      managerCommentEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'managerComment',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      managerCommentGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'managerComment',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      managerCommentLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'managerComment',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      managerCommentBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'managerComment',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      managerCommentStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'managerComment',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      managerCommentEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'managerComment',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      managerCommentContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'managerComment',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      managerCommentMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'managerComment',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      managerCommentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'managerComment',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      managerCommentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'managerComment',
        value: '',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      mileageRateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mileageRate',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      mileageRateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mileageRate',
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      mileageRateEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mileageRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      mileageRateGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mileageRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      mileageRateLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mileageRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      mileageRateBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mileageRate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterFilterCondition>
      updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ExpenseModelQueryObject
    on QueryBuilder<ExpenseModel, ExpenseModel, QFilterCondition> {}

extension ExpenseModelQueryLinks
    on QueryBuilder<ExpenseModel, ExpenseModel, QFilterCondition> {}

extension ExpenseModelQuerySortBy
    on QueryBuilder<ExpenseModel, ExpenseModel, QSortBy> {
  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByApprovedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'approvedAt', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      sortByApprovedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'approvedAt', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      sortByArrivalLocation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'arrivalLocation', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      sortByArrivalLocationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'arrivalLocation', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      sortByAttachmentPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attachmentPath', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      sortByAttachmentPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attachmentPath', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      sortByDepartureLocation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'departureLocation', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      sortByDepartureLocationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'departureLocation', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByDistanceKm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distanceKm', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      sortByDistanceKmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distanceKm', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByIsApproved() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isApproved', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      sortByIsApprovedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isApproved', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      sortByManagerComment() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'managerComment', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      sortByManagerCommentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'managerComment', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByMileageRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mileageRate', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      sortByMileageRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mileageRate', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension ExpenseModelQuerySortThenBy
    on QueryBuilder<ExpenseModel, ExpenseModel, QSortThenBy> {
  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByApprovedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'approvedAt', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      thenByApprovedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'approvedAt', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      thenByArrivalLocation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'arrivalLocation', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      thenByArrivalLocationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'arrivalLocation', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      thenByAttachmentPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attachmentPath', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      thenByAttachmentPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attachmentPath', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currency', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      thenByDepartureLocation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'departureLocation', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      thenByDepartureLocationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'departureLocation', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByDistanceKm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distanceKm', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      thenByDistanceKmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distanceKm', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByIsApproved() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isApproved', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      thenByIsApprovedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isApproved', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      thenByManagerComment() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'managerComment', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      thenByManagerCommentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'managerComment', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByMileageRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mileageRate', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy>
      thenByMileageRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mileageRate', Sort.desc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension ExpenseModelQueryWhereDistinct
    on QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> {
  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> distinctByApprovedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'approvedAt');
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> distinctByArrivalLocation(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'arrivalLocation',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> distinctByAttachmentPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'attachmentPath',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> distinctByCategory(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> distinctByCurrency(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currency', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct>
      distinctByDepartureLocation({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'departureLocation',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> distinctByDistanceKm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'distanceKm');
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> distinctByIsApproved() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isApproved');
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> distinctByManagerComment(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'managerComment',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> distinctByMileageRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mileageRate');
    });
  }

  QueryBuilder<ExpenseModel, ExpenseModel, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension ExpenseModelQueryProperty
    on QueryBuilder<ExpenseModel, ExpenseModel, QQueryProperty> {
  QueryBuilder<ExpenseModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ExpenseModel, double, QQueryOperations> amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<ExpenseModel, DateTime?, QQueryOperations> approvedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'approvedAt');
    });
  }

  QueryBuilder<ExpenseModel, String?, QQueryOperations>
      arrivalLocationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'arrivalLocation');
    });
  }

  QueryBuilder<ExpenseModel, String?, QQueryOperations>
      attachmentPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'attachmentPath');
    });
  }

  QueryBuilder<ExpenseModel, ExpenseCategory, QQueryOperations>
      categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<ExpenseModel, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<ExpenseModel, String, QQueryOperations> currencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currency');
    });
  }

  QueryBuilder<ExpenseModel, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<ExpenseModel, String?, QQueryOperations>
      departureLocationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'departureLocation');
    });
  }

  QueryBuilder<ExpenseModel, String, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<ExpenseModel, int?, QQueryOperations> distanceKmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'distanceKm');
    });
  }

  QueryBuilder<ExpenseModel, bool, QQueryOperations> isApprovedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isApproved');
    });
  }

  QueryBuilder<ExpenseModel, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<ExpenseModel, String?, QQueryOperations>
      managerCommentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'managerComment');
    });
  }

  QueryBuilder<ExpenseModel, double?, QQueryOperations> mileageRateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mileageRate');
    });
  }

  QueryBuilder<ExpenseModel, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
