/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;

abstract class Manager
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Manager._({
    this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.company,
    this.signature,
    bool? isActive,
    this.createdAt,
    this.updatedAt,
  }) : isActive = isActive ?? true;

  factory Manager({
    int? id,
    required String email,
    required String firstName,
    required String lastName,
    required String company,
    String? signature,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ManagerImpl;

  factory Manager.fromJson(Map<String, dynamic> jsonSerialization) {
    return Manager(
      id: jsonSerialization['id'] as int?,
      email: jsonSerialization['email'] as String,
      firstName: jsonSerialization['firstName'] as String,
      lastName: jsonSerialization['lastName'] as String,
      company: jsonSerialization['company'] as String,
      signature: jsonSerialization['signature'] as String?,
      isActive: jsonSerialization['isActive'] as bool,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  static final t = ManagerTable();

  static const db = ManagerRepository._();

  @override
  int? id;

  String email;

  String firstName;

  String lastName;

  String company;

  String? signature;

  bool isActive;

  DateTime? createdAt;

  DateTime? updatedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Manager]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Manager copyWith({
    int? id,
    String? email,
    String? firstName,
    String? lastName,
    String? company,
    String? signature,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'company': company,
      if (signature != null) 'signature': signature,
      'isActive': isActive,
      if (createdAt != null) 'createdAt': createdAt?.toJson(),
      if (updatedAt != null) 'updatedAt': updatedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      if (id != null) 'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'company': company,
      if (signature != null) 'signature': signature,
      'isActive': isActive,
      if (createdAt != null) 'createdAt': createdAt?.toJson(),
      if (updatedAt != null) 'updatedAt': updatedAt?.toJson(),
    };
  }

  static ManagerInclude include() {
    return ManagerInclude._();
  }

  static ManagerIncludeList includeList({
    _i1.WhereExpressionBuilder<ManagerTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ManagerTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ManagerTable>? orderByList,
    ManagerInclude? include,
  }) {
    return ManagerIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Manager.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Manager.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ManagerImpl extends Manager {
  _ManagerImpl({
    int? id,
    required String email,
    required String firstName,
    required String lastName,
    required String company,
    String? signature,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super._(
          id: id,
          email: email,
          firstName: firstName,
          lastName: lastName,
          company: company,
          signature: signature,
          isActive: isActive,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  /// Returns a shallow copy of this [Manager]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Manager copyWith({
    Object? id = _Undefined,
    String? email,
    String? firstName,
    String? lastName,
    String? company,
    Object? signature = _Undefined,
    bool? isActive,
    Object? createdAt = _Undefined,
    Object? updatedAt = _Undefined,
  }) {
    return Manager(
      id: id is int? ? id : this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      company: company ?? this.company,
      signature: signature is String? ? signature : this.signature,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt is DateTime? ? createdAt : this.createdAt,
      updatedAt: updatedAt is DateTime? ? updatedAt : this.updatedAt,
    );
  }
}

class ManagerTable extends _i1.Table<int?> {
  ManagerTable({super.tableRelation}) : super(tableName: 'managers') {
    email = _i1.ColumnString(
      'email',
      this,
    );
    firstName = _i1.ColumnString(
      'firstName',
      this,
    );
    lastName = _i1.ColumnString(
      'lastName',
      this,
    );
    company = _i1.ColumnString(
      'company',
      this,
    );
    signature = _i1.ColumnString(
      'signature',
      this,
    );
    isActive = _i1.ColumnBool(
      'isActive',
      this,
      hasDefault: true,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
    updatedAt = _i1.ColumnDateTime(
      'updatedAt',
      this,
      hasDefault: true,
    );
  }

  late final _i1.ColumnString email;

  late final _i1.ColumnString firstName;

  late final _i1.ColumnString lastName;

  late final _i1.ColumnString company;

  late final _i1.ColumnString signature;

  late final _i1.ColumnBool isActive;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
        id,
        email,
        firstName,
        lastName,
        company,
        signature,
        isActive,
        createdAt,
        updatedAt,
      ];
}

class ManagerInclude extends _i1.IncludeObject {
  ManagerInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Manager.t;
}

class ManagerIncludeList extends _i1.IncludeList {
  ManagerIncludeList._({
    _i1.WhereExpressionBuilder<ManagerTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Manager.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Manager.t;
}

class ManagerRepository {
  const ManagerRepository._();

  /// Returns a list of [Manager]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<Manager>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ManagerTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ManagerTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ManagerTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<Manager>(
      where: where?.call(Manager.t),
      orderBy: orderBy?.call(Manager.t),
      orderByList: orderByList?.call(Manager.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [Manager] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<Manager?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ManagerTable>? where,
    int? offset,
    _i1.OrderByBuilder<ManagerTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ManagerTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<Manager>(
      where: where?.call(Manager.t),
      orderBy: orderBy?.call(Manager.t),
      orderByList: orderByList?.call(Manager.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [Manager] by its [id] or null if no such row exists.
  Future<Manager?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<Manager>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [Manager]s in the list and returns the inserted rows.
  ///
  /// The returned [Manager]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<Manager>> insert(
    _i1.Session session,
    List<Manager> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<Manager>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [Manager] and returns the inserted row.
  ///
  /// The returned [Manager] will have its `id` field set.
  Future<Manager> insertRow(
    _i1.Session session,
    Manager row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Manager>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Manager]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Manager>> update(
    _i1.Session session,
    List<Manager> rows, {
    _i1.ColumnSelections<ManagerTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Manager>(
      rows,
      columns: columns?.call(Manager.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Manager]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Manager> updateRow(
    _i1.Session session,
    Manager row, {
    _i1.ColumnSelections<ManagerTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Manager>(
      row,
      columns: columns?.call(Manager.t),
      transaction: transaction,
    );
  }

  /// Deletes all [Manager]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Manager>> delete(
    _i1.Session session,
    List<Manager> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Manager>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Manager].
  Future<Manager> deleteRow(
    _i1.Session session,
    Manager row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Manager>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Manager>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<ManagerTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Manager>(
      where: where(Manager.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ManagerTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Manager>(
      where: where?.call(Manager.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
