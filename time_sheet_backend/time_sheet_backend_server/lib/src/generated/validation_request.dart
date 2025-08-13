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
import 'validation_status.dart' as _i2;

abstract class ValidationRequest
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  ValidationRequest._({
    this.id,
    required this.employeeId,
    required this.employeeName,
    required this.managerId,
    required this.managerEmail,
    required this.periodStart,
    required this.periodEnd,
    required this.status,
    required this.pdfPath,
    required this.pdfHash,
    required this.pdfSizeBytes,
    this.managerSignature,
    this.managerComment,
    this.managerName,
    this.validatedAt,
    this.expiresAt,
    this.createdAt,
    this.updatedAt,
  });

  factory ValidationRequest({
    int? id,
    required String employeeId,
    required String employeeName,
    required String managerId,
    required String managerEmail,
    required DateTime periodStart,
    required DateTime periodEnd,
    required _i2.ValidationStatus status,
    required String pdfPath,
    required String pdfHash,
    required int pdfSizeBytes,
    String? managerSignature,
    String? managerComment,
    String? managerName,
    DateTime? validatedAt,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ValidationRequestImpl;

  factory ValidationRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return ValidationRequest(
      id: jsonSerialization['id'] as int?,
      employeeId: jsonSerialization['employeeId'] as String,
      employeeName: jsonSerialization['employeeName'] as String,
      managerId: jsonSerialization['managerId'] as String,
      managerEmail: jsonSerialization['managerEmail'] as String,
      periodStart:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['periodStart']),
      periodEnd:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['periodEnd']),
      status:
          _i2.ValidationStatus.fromJson((jsonSerialization['status'] as int)),
      pdfPath: jsonSerialization['pdfPath'] as String,
      pdfHash: jsonSerialization['pdfHash'] as String,
      pdfSizeBytes: jsonSerialization['pdfSizeBytes'] as int,
      managerSignature: jsonSerialization['managerSignature'] as String?,
      managerComment: jsonSerialization['managerComment'] as String?,
      managerName: jsonSerialization['managerName'] as String?,
      validatedAt: jsonSerialization['validatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['validatedAt']),
      expiresAt: jsonSerialization['expiresAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['expiresAt']),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  static final t = ValidationRequestTable();

  static const db = ValidationRequestRepository._();

  @override
  int? id;

  String employeeId;

  String employeeName;

  String managerId;

  String managerEmail;

  DateTime periodStart;

  DateTime periodEnd;

  _i2.ValidationStatus status;

  String pdfPath;

  String pdfHash;

  int pdfSizeBytes;

  String? managerSignature;

  String? managerComment;

  String? managerName;

  DateTime? validatedAt;

  DateTime? expiresAt;

  DateTime? createdAt;

  DateTime? updatedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [ValidationRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ValidationRequest copyWith({
    int? id,
    String? employeeId,
    String? employeeName,
    String? managerId,
    String? managerEmail,
    DateTime? periodStart,
    DateTime? periodEnd,
    _i2.ValidationStatus? status,
    String? pdfPath,
    String? pdfHash,
    int? pdfSizeBytes,
    String? managerSignature,
    String? managerComment,
    String? managerName,
    DateTime? validatedAt,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'managerId': managerId,
      'managerEmail': managerEmail,
      'periodStart': periodStart.toJson(),
      'periodEnd': periodEnd.toJson(),
      'status': status.toJson(),
      'pdfPath': pdfPath,
      'pdfHash': pdfHash,
      'pdfSizeBytes': pdfSizeBytes,
      if (managerSignature != null) 'managerSignature': managerSignature,
      if (managerComment != null) 'managerComment': managerComment,
      if (managerName != null) 'managerName': managerName,
      if (validatedAt != null) 'validatedAt': validatedAt?.toJson(),
      if (expiresAt != null) 'expiresAt': expiresAt?.toJson(),
      if (createdAt != null) 'createdAt': createdAt?.toJson(),
      if (updatedAt != null) 'updatedAt': updatedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      if (id != null) 'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'managerId': managerId,
      'managerEmail': managerEmail,
      'periodStart': periodStart.toJson(),
      'periodEnd': periodEnd.toJson(),
      'status': status.toJson(),
      'pdfPath': pdfPath,
      'pdfHash': pdfHash,
      'pdfSizeBytes': pdfSizeBytes,
      if (managerSignature != null) 'managerSignature': managerSignature,
      if (managerComment != null) 'managerComment': managerComment,
      if (managerName != null) 'managerName': managerName,
      if (validatedAt != null) 'validatedAt': validatedAt?.toJson(),
      if (expiresAt != null) 'expiresAt': expiresAt?.toJson(),
      if (createdAt != null) 'createdAt': createdAt?.toJson(),
      if (updatedAt != null) 'updatedAt': updatedAt?.toJson(),
    };
  }

  static ValidationRequestInclude include() {
    return ValidationRequestInclude._();
  }

  static ValidationRequestIncludeList includeList({
    _i1.WhereExpressionBuilder<ValidationRequestTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ValidationRequestTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ValidationRequestTable>? orderByList,
    ValidationRequestInclude? include,
  }) {
    return ValidationRequestIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ValidationRequest.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(ValidationRequest.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ValidationRequestImpl extends ValidationRequest {
  _ValidationRequestImpl({
    int? id,
    required String employeeId,
    required String employeeName,
    required String managerId,
    required String managerEmail,
    required DateTime periodStart,
    required DateTime periodEnd,
    required _i2.ValidationStatus status,
    required String pdfPath,
    required String pdfHash,
    required int pdfSizeBytes,
    String? managerSignature,
    String? managerComment,
    String? managerName,
    DateTime? validatedAt,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super._(
          id: id,
          employeeId: employeeId,
          employeeName: employeeName,
          managerId: managerId,
          managerEmail: managerEmail,
          periodStart: periodStart,
          periodEnd: periodEnd,
          status: status,
          pdfPath: pdfPath,
          pdfHash: pdfHash,
          pdfSizeBytes: pdfSizeBytes,
          managerSignature: managerSignature,
          managerComment: managerComment,
          managerName: managerName,
          validatedAt: validatedAt,
          expiresAt: expiresAt,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  /// Returns a shallow copy of this [ValidationRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ValidationRequest copyWith({
    Object? id = _Undefined,
    String? employeeId,
    String? employeeName,
    String? managerId,
    String? managerEmail,
    DateTime? periodStart,
    DateTime? periodEnd,
    _i2.ValidationStatus? status,
    String? pdfPath,
    String? pdfHash,
    int? pdfSizeBytes,
    Object? managerSignature = _Undefined,
    Object? managerComment = _Undefined,
    Object? managerName = _Undefined,
    Object? validatedAt = _Undefined,
    Object? expiresAt = _Undefined,
    Object? createdAt = _Undefined,
    Object? updatedAt = _Undefined,
  }) {
    return ValidationRequest(
      id: id is int? ? id : this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      managerId: managerId ?? this.managerId,
      managerEmail: managerEmail ?? this.managerEmail,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      status: status ?? this.status,
      pdfPath: pdfPath ?? this.pdfPath,
      pdfHash: pdfHash ?? this.pdfHash,
      pdfSizeBytes: pdfSizeBytes ?? this.pdfSizeBytes,
      managerSignature: managerSignature is String?
          ? managerSignature
          : this.managerSignature,
      managerComment:
          managerComment is String? ? managerComment : this.managerComment,
      managerName: managerName is String? ? managerName : this.managerName,
      validatedAt: validatedAt is DateTime? ? validatedAt : this.validatedAt,
      expiresAt: expiresAt is DateTime? ? expiresAt : this.expiresAt,
      createdAt: createdAt is DateTime? ? createdAt : this.createdAt,
      updatedAt: updatedAt is DateTime? ? updatedAt : this.updatedAt,
    );
  }
}

class ValidationRequestTable extends _i1.Table<int?> {
  ValidationRequestTable({super.tableRelation})
      : super(tableName: 'validation_requests') {
    employeeId = _i1.ColumnString(
      'employeeId',
      this,
    );
    employeeName = _i1.ColumnString(
      'employeeName',
      this,
    );
    managerId = _i1.ColumnString(
      'managerId',
      this,
    );
    managerEmail = _i1.ColumnString(
      'managerEmail',
      this,
    );
    periodStart = _i1.ColumnDateTime(
      'periodStart',
      this,
    );
    periodEnd = _i1.ColumnDateTime(
      'periodEnd',
      this,
    );
    status = _i1.ColumnEnum(
      'status',
      this,
      _i1.EnumSerialization.byIndex,
    );
    pdfPath = _i1.ColumnString(
      'pdfPath',
      this,
    );
    pdfHash = _i1.ColumnString(
      'pdfHash',
      this,
    );
    pdfSizeBytes = _i1.ColumnInt(
      'pdfSizeBytes',
      this,
    );
    managerSignature = _i1.ColumnString(
      'managerSignature',
      this,
    );
    managerComment = _i1.ColumnString(
      'managerComment',
      this,
    );
    managerName = _i1.ColumnString(
      'managerName',
      this,
    );
    validatedAt = _i1.ColumnDateTime(
      'validatedAt',
      this,
    );
    expiresAt = _i1.ColumnDateTime(
      'expiresAt',
      this,
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

  late final _i1.ColumnString employeeId;

  late final _i1.ColumnString employeeName;

  late final _i1.ColumnString managerId;

  late final _i1.ColumnString managerEmail;

  late final _i1.ColumnDateTime periodStart;

  late final _i1.ColumnDateTime periodEnd;

  late final _i1.ColumnEnum<_i2.ValidationStatus> status;

  late final _i1.ColumnString pdfPath;

  late final _i1.ColumnString pdfHash;

  late final _i1.ColumnInt pdfSizeBytes;

  late final _i1.ColumnString managerSignature;

  late final _i1.ColumnString managerComment;

  late final _i1.ColumnString managerName;

  late final _i1.ColumnDateTime validatedAt;

  late final _i1.ColumnDateTime expiresAt;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
        id,
        employeeId,
        employeeName,
        managerId,
        managerEmail,
        periodStart,
        periodEnd,
        status,
        pdfPath,
        pdfHash,
        pdfSizeBytes,
        managerSignature,
        managerComment,
        managerName,
        validatedAt,
        expiresAt,
        createdAt,
        updatedAt,
      ];
}

class ValidationRequestInclude extends _i1.IncludeObject {
  ValidationRequestInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => ValidationRequest.t;
}

class ValidationRequestIncludeList extends _i1.IncludeList {
  ValidationRequestIncludeList._({
    _i1.WhereExpressionBuilder<ValidationRequestTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ValidationRequest.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => ValidationRequest.t;
}

class ValidationRequestRepository {
  const ValidationRequestRepository._();

  /// Returns a list of [ValidationRequest]s matching the given query parameters.
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
  Future<List<ValidationRequest>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ValidationRequestTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ValidationRequestTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ValidationRequestTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<ValidationRequest>(
      where: where?.call(ValidationRequest.t),
      orderBy: orderBy?.call(ValidationRequest.t),
      orderByList: orderByList?.call(ValidationRequest.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [ValidationRequest] matching the given query parameters.
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
  Future<ValidationRequest?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ValidationRequestTable>? where,
    int? offset,
    _i1.OrderByBuilder<ValidationRequestTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ValidationRequestTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<ValidationRequest>(
      where: where?.call(ValidationRequest.t),
      orderBy: orderBy?.call(ValidationRequest.t),
      orderByList: orderByList?.call(ValidationRequest.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [ValidationRequest] by its [id] or null if no such row exists.
  Future<ValidationRequest?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<ValidationRequest>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [ValidationRequest]s in the list and returns the inserted rows.
  ///
  /// The returned [ValidationRequest]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<ValidationRequest>> insert(
    _i1.Session session,
    List<ValidationRequest> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<ValidationRequest>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [ValidationRequest] and returns the inserted row.
  ///
  /// The returned [ValidationRequest] will have its `id` field set.
  Future<ValidationRequest> insertRow(
    _i1.Session session,
    ValidationRequest row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<ValidationRequest>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [ValidationRequest]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<ValidationRequest>> update(
    _i1.Session session,
    List<ValidationRequest> rows, {
    _i1.ColumnSelections<ValidationRequestTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<ValidationRequest>(
      rows,
      columns: columns?.call(ValidationRequest.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ValidationRequest]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ValidationRequest> updateRow(
    _i1.Session session,
    ValidationRequest row, {
    _i1.ColumnSelections<ValidationRequestTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<ValidationRequest>(
      row,
      columns: columns?.call(ValidationRequest.t),
      transaction: transaction,
    );
  }

  /// Deletes all [ValidationRequest]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<ValidationRequest>> delete(
    _i1.Session session,
    List<ValidationRequest> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<ValidationRequest>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [ValidationRequest].
  Future<ValidationRequest> deleteRow(
    _i1.Session session,
    ValidationRequest row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ValidationRequest>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<ValidationRequest>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<ValidationRequestTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<ValidationRequest>(
      where: where(ValidationRequest.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ValidationRequestTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<ValidationRequest>(
      where: where?.call(ValidationRequest.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
