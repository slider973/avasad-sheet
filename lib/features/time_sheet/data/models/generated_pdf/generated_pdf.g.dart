// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generated_pdf.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetGeneratedPdfModelCollection on Isar {
  IsarCollection<GeneratedPdfModel> get generatedPdfModels => this.collection();
}

const GeneratedPdfModelSchema = CollectionSchema(
  name: r'GeneratedPdfModel',
  id: -1889847071290927776,
  properties: {
    r'fileName': PropertySchema(
      id: 0,
      name: r'fileName',
      type: IsarType.string,
    ),
    r'filePath': PropertySchema(
      id: 1,
      name: r'filePath',
      type: IsarType.string,
    ),
    r'generatedDate': PropertySchema(
      id: 2,
      name: r'generatedDate',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _generatedPdfModelEstimateSize,
  serialize: _generatedPdfModelSerialize,
  deserialize: _generatedPdfModelDeserialize,
  deserializeProp: _generatedPdfModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'fileName': IndexSchema(
      id: -6213672517780651480,
      name: r'fileName',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'fileName',
          type: IndexType.value,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _generatedPdfModelGetId,
  getLinks: _generatedPdfModelGetLinks,
  attach: _generatedPdfModelAttach,
  version: '3.1.0+1',
);

int _generatedPdfModelEstimateSize(
  GeneratedPdfModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.fileName.length * 3;
  bytesCount += 3 + object.filePath.length * 3;
  return bytesCount;
}

void _generatedPdfModelSerialize(
  GeneratedPdfModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.fileName);
  writer.writeString(offsets[1], object.filePath);
  writer.writeDateTime(offsets[2], object.generatedDate);
}

GeneratedPdfModel _generatedPdfModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = GeneratedPdfModel(
    fileName: reader.readString(offsets[0]),
    filePath: reader.readString(offsets[1]),
    generatedDate: reader.readDateTime(offsets[2]),
  );
  object.id = id;
  return object;
}

P _generatedPdfModelDeserializeProp<P>(
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
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _generatedPdfModelGetId(GeneratedPdfModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _generatedPdfModelGetLinks(
    GeneratedPdfModel object) {
  return [];
}

void _generatedPdfModelAttach(
    IsarCollection<dynamic> col, Id id, GeneratedPdfModel object) {
  object.id = id;
}

extension GeneratedPdfModelQueryWhereSort
    on QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QWhere> {
  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterWhere>
      anyFileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'fileName'),
      );
    });
  }
}

extension GeneratedPdfModelQueryWhere
    on QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QWhereClause> {
  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterWhereClause>
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

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterWhereClause>
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

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterWhereClause>
      fileNameEqualTo(String fileName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'fileName',
        value: [fileName],
      ));
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterWhereClause>
      fileNameNotEqualTo(String fileName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fileName',
              lower: [],
              upper: [fileName],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fileName',
              lower: [fileName],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fileName',
              lower: [fileName],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fileName',
              lower: [],
              upper: [fileName],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterWhereClause>
      fileNameGreaterThan(
    String fileName, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'fileName',
        lower: [fileName],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterWhereClause>
      fileNameLessThan(
    String fileName, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'fileName',
        lower: [],
        upper: [fileName],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterWhereClause>
      fileNameBetween(
    String lowerFileName,
    String upperFileName, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'fileName',
        lower: [lowerFileName],
        includeLower: includeLower,
        upper: [upperFileName],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterWhereClause>
      fileNameStartsWith(String FileNamePrefix) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'fileName',
        lower: [FileNamePrefix],
        upper: ['$FileNamePrefix\u{FFFFF}'],
      ));
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterWhereClause>
      fileNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'fileName',
        value: [''],
      ));
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterWhereClause>
      fileNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.lessThan(
              indexName: r'fileName',
              upper: [''],
            ))
            .addWhereClause(IndexWhereClause.greaterThan(
              indexName: r'fileName',
              lower: [''],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.greaterThan(
              indexName: r'fileName',
              lower: [''],
            ))
            .addWhereClause(IndexWhereClause.lessThan(
              indexName: r'fileName',
              upper: [''],
            ));
      }
    });
  }
}

extension GeneratedPdfModelQueryFilter
    on QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QFilterCondition> {
  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterFilterCondition>
      fileNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterFilterCondition>
      fileNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterFilterCondition>
      fileNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterFilterCondition>
      fileNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fileName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterFilterCondition>
      fileNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterFilterCondition>
      fileNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterFilterCondition>
      fileNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterFilterCondition>
      fileNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fileName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterFilterCondition>
      fileNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fileName',
        value: '',
      ));
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterFilterCondition>
      fileNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fileName',
        value: '',
      ));
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterFilterCondition>
      filePathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterFilterCondition>
      filePathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterFilterCondition>
      filePathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterFilterCondition>
      filePathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'filePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterFilterCondition>
      filePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterFilterCondition>
      filePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterFilterCondition>
      filePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterFilterCondition>
      filePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'filePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterFilterCondition>
      filePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'filePath',
        value: '',
      ));
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterFilterCondition>
      filePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'filePath',
        value: '',
      ));
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterFilterCondition>
      generatedDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'generatedDate',
        value: value,
      ));
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterFilterCondition>
      generatedDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'generatedDate',
        value: value,
      ));
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterFilterCondition>
      generatedDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'generatedDate',
        value: value,
      ));
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterFilterCondition>
      generatedDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'generatedDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterFilterCondition>
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

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterFilterCondition>
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

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterFilterCondition>
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
}

extension GeneratedPdfModelQueryObject
    on QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QFilterCondition> {}

extension GeneratedPdfModelQueryLinks
    on QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QFilterCondition> {}

extension GeneratedPdfModelQuerySortBy
    on QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QSortBy> {
  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterSortBy>
      sortByFileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.asc);
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterSortBy>
      sortByFileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.desc);
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterSortBy>
      sortByFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.asc);
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterSortBy>
      sortByFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.desc);
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterSortBy>
      sortByGeneratedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generatedDate', Sort.asc);
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterSortBy>
      sortByGeneratedDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generatedDate', Sort.desc);
    });
  }
}

extension GeneratedPdfModelQuerySortThenBy
    on QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QSortThenBy> {
  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterSortBy>
      thenByFileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.asc);
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterSortBy>
      thenByFileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.desc);
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterSortBy>
      thenByFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.asc);
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterSortBy>
      thenByFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.desc);
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterSortBy>
      thenByGeneratedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generatedDate', Sort.asc);
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterSortBy>
      thenByGeneratedDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generatedDate', Sort.desc);
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }
}

extension GeneratedPdfModelQueryWhereDistinct
    on QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QDistinct> {
  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QDistinct>
      distinctByFileName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QDistinct>
      distinctByFilePath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'filePath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QDistinct>
      distinctByGeneratedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'generatedDate');
    });
  }
}

extension GeneratedPdfModelQueryProperty
    on QueryBuilder<GeneratedPdfModel, GeneratedPdfModel, QQueryProperty> {
  QueryBuilder<GeneratedPdfModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<GeneratedPdfModel, String, QQueryOperations> fileNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileName');
    });
  }

  QueryBuilder<GeneratedPdfModel, String, QQueryOperations> filePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'filePath');
    });
  }

  QueryBuilder<GeneratedPdfModel, DateTime, QQueryOperations>
      generatedDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'generatedDate');
    });
  }
}
