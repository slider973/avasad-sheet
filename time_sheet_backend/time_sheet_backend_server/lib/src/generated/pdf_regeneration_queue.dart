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
import 'queue_status.dart' as _i2;

abstract class PdfRegenerationQueue
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  PdfRegenerationQueue._({
    this.id,
    required this.validationId,
    _i2.QueueStatus? status,
    this.createdAt,
    this.processedAt,
    this.errorMessage,
    int? retryCount,
  })  : status = status ?? _i2.QueueStatus.pending,
        retryCount = retryCount ?? 0;

  factory PdfRegenerationQueue({
    int? id,
    required int validationId,
    _i2.QueueStatus? status,
    DateTime? createdAt,
    DateTime? processedAt,
    String? errorMessage,
    int? retryCount,
  }) = _PdfRegenerationQueueImpl;

  factory PdfRegenerationQueue.fromJson(
      Map<String, dynamic> jsonSerialization) {
    return PdfRegenerationQueue(
      id: jsonSerialization['id'] as int?,
      validationId: jsonSerialization['validationId'] as int,
      status: _i2.QueueStatus.fromJson((jsonSerialization['status'] as int)),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      processedAt: jsonSerialization['processedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['processedAt']),
      errorMessage: jsonSerialization['errorMessage'] as String?,
      retryCount: jsonSerialization['retryCount'] as int,
    );
  }

  static final t = PdfRegenerationQueueTable();

  static const db = PdfRegenerationQueueRepository._();

  @override
  int? id;

  int validationId;

  _i2.QueueStatus status;

  DateTime? createdAt;

  DateTime? processedAt;

  String? errorMessage;

  int retryCount;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [PdfRegenerationQueue]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PdfRegenerationQueue copyWith({
    int? id,
    int? validationId,
    _i2.QueueStatus? status,
    DateTime? createdAt,
    DateTime? processedAt,
    String? errorMessage,
    int? retryCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'validationId': validationId,
      'status': status.toJson(),
      if (createdAt != null) 'createdAt': createdAt?.toJson(),
      if (processedAt != null) 'processedAt': processedAt?.toJson(),
      if (errorMessage != null) 'errorMessage': errorMessage,
      'retryCount': retryCount,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      if (id != null) 'id': id,
      'validationId': validationId,
      'status': status.toJson(),
      if (createdAt != null) 'createdAt': createdAt?.toJson(),
      if (processedAt != null) 'processedAt': processedAt?.toJson(),
      if (errorMessage != null) 'errorMessage': errorMessage,
      'retryCount': retryCount,
    };
  }

  static PdfRegenerationQueueInclude include() {
    return PdfRegenerationQueueInclude._();
  }

  static PdfRegenerationQueueIncludeList includeList({
    _i1.WhereExpressionBuilder<PdfRegenerationQueueTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<PdfRegenerationQueueTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PdfRegenerationQueueTable>? orderByList,
    PdfRegenerationQueueInclude? include,
  }) {
    return PdfRegenerationQueueIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PdfRegenerationQueue.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(PdfRegenerationQueue.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PdfRegenerationQueueImpl extends PdfRegenerationQueue {
  _PdfRegenerationQueueImpl({
    int? id,
    required int validationId,
    _i2.QueueStatus? status,
    DateTime? createdAt,
    DateTime? processedAt,
    String? errorMessage,
    int? retryCount,
  }) : super._(
          id: id,
          validationId: validationId,
          status: status,
          createdAt: createdAt,
          processedAt: processedAt,
          errorMessage: errorMessage,
          retryCount: retryCount,
        );

  /// Returns a shallow copy of this [PdfRegenerationQueue]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PdfRegenerationQueue copyWith({
    Object? id = _Undefined,
    int? validationId,
    _i2.QueueStatus? status,
    Object? createdAt = _Undefined,
    Object? processedAt = _Undefined,
    Object? errorMessage = _Undefined,
    int? retryCount,
  }) {
    return PdfRegenerationQueue(
      id: id is int? ? id : this.id,
      validationId: validationId ?? this.validationId,
      status: status ?? this.status,
      createdAt: createdAt is DateTime? ? createdAt : this.createdAt,
      processedAt: processedAt is DateTime? ? processedAt : this.processedAt,
      errorMessage: errorMessage is String? ? errorMessage : this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

class PdfRegenerationQueueTable extends _i1.Table<int?> {
  PdfRegenerationQueueTable({super.tableRelation})
      : super(tableName: 'pdf_regeneration_queue') {
    validationId = _i1.ColumnInt(
      'validationId',
      this,
    );
    status = _i1.ColumnEnum(
      'status',
      this,
      _i1.EnumSerialization.byIndex,
      hasDefault: true,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
    processedAt = _i1.ColumnDateTime(
      'processedAt',
      this,
    );
    errorMessage = _i1.ColumnString(
      'errorMessage',
      this,
    );
    retryCount = _i1.ColumnInt(
      'retryCount',
      this,
      hasDefault: true,
    );
  }

  late final _i1.ColumnInt validationId;

  late final _i1.ColumnEnum<_i2.QueueStatus> status;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime processedAt;

  late final _i1.ColumnString errorMessage;

  late final _i1.ColumnInt retryCount;

  @override
  List<_i1.Column> get columns => [
        id,
        validationId,
        status,
        createdAt,
        processedAt,
        errorMessage,
        retryCount,
      ];
}

class PdfRegenerationQueueInclude extends _i1.IncludeObject {
  PdfRegenerationQueueInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => PdfRegenerationQueue.t;
}

class PdfRegenerationQueueIncludeList extends _i1.IncludeList {
  PdfRegenerationQueueIncludeList._({
    _i1.WhereExpressionBuilder<PdfRegenerationQueueTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(PdfRegenerationQueue.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => PdfRegenerationQueue.t;
}

class PdfRegenerationQueueRepository {
  const PdfRegenerationQueueRepository._();

  /// Returns a list of [PdfRegenerationQueue]s matching the given query parameters.
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
  Future<List<PdfRegenerationQueue>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<PdfRegenerationQueueTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<PdfRegenerationQueueTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PdfRegenerationQueueTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<PdfRegenerationQueue>(
      where: where?.call(PdfRegenerationQueue.t),
      orderBy: orderBy?.call(PdfRegenerationQueue.t),
      orderByList: orderByList?.call(PdfRegenerationQueue.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [PdfRegenerationQueue] matching the given query parameters.
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
  Future<PdfRegenerationQueue?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<PdfRegenerationQueueTable>? where,
    int? offset,
    _i1.OrderByBuilder<PdfRegenerationQueueTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PdfRegenerationQueueTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<PdfRegenerationQueue>(
      where: where?.call(PdfRegenerationQueue.t),
      orderBy: orderBy?.call(PdfRegenerationQueue.t),
      orderByList: orderByList?.call(PdfRegenerationQueue.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [PdfRegenerationQueue] by its [id] or null if no such row exists.
  Future<PdfRegenerationQueue?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<PdfRegenerationQueue>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [PdfRegenerationQueue]s in the list and returns the inserted rows.
  ///
  /// The returned [PdfRegenerationQueue]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<PdfRegenerationQueue>> insert(
    _i1.Session session,
    List<PdfRegenerationQueue> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<PdfRegenerationQueue>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [PdfRegenerationQueue] and returns the inserted row.
  ///
  /// The returned [PdfRegenerationQueue] will have its `id` field set.
  Future<PdfRegenerationQueue> insertRow(
    _i1.Session session,
    PdfRegenerationQueue row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<PdfRegenerationQueue>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [PdfRegenerationQueue]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<PdfRegenerationQueue>> update(
    _i1.Session session,
    List<PdfRegenerationQueue> rows, {
    _i1.ColumnSelections<PdfRegenerationQueueTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<PdfRegenerationQueue>(
      rows,
      columns: columns?.call(PdfRegenerationQueue.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PdfRegenerationQueue]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<PdfRegenerationQueue> updateRow(
    _i1.Session session,
    PdfRegenerationQueue row, {
    _i1.ColumnSelections<PdfRegenerationQueueTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<PdfRegenerationQueue>(
      row,
      columns: columns?.call(PdfRegenerationQueue.t),
      transaction: transaction,
    );
  }

  /// Deletes all [PdfRegenerationQueue]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<PdfRegenerationQueue>> delete(
    _i1.Session session,
    List<PdfRegenerationQueue> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<PdfRegenerationQueue>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [PdfRegenerationQueue].
  Future<PdfRegenerationQueue> deleteRow(
    _i1.Session session,
    PdfRegenerationQueue row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<PdfRegenerationQueue>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<PdfRegenerationQueue>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<PdfRegenerationQueueTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<PdfRegenerationQueue>(
      where: where(PdfRegenerationQueue.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<PdfRegenerationQueueTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<PdfRegenerationQueue>(
      where: where?.call(PdfRegenerationQueue.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
