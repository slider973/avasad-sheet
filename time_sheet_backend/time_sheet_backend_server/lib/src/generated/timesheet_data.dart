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

abstract class TimesheetData
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  TimesheetData._({
    this.id,
    required this.validationRequestId,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCompany,
    required this.month,
    required this.year,
    required this.entries,
    required this.totalDays,
    required this.totalHours,
    required this.totalOvertimeHours,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory TimesheetData({
    int? id,
    required int validationRequestId,
    required String employeeId,
    required String employeeName,
    required String employeeCompany,
    required int month,
    required int year,
    required String entries,
    required double totalDays,
    required String totalHours,
    required String totalOvertimeHours,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _TimesheetDataImpl;

  factory TimesheetData.fromJson(Map<String, dynamic> jsonSerialization) {
    return TimesheetData(
      id: jsonSerialization['id'] as int?,
      validationRequestId: jsonSerialization['validationRequestId'] as int,
      employeeId: jsonSerialization['employeeId'] as String,
      employeeName: jsonSerialization['employeeName'] as String,
      employeeCompany: jsonSerialization['employeeCompany'] as String,
      month: jsonSerialization['month'] as int,
      year: jsonSerialization['year'] as int,
      entries: jsonSerialization['entries'] as String,
      totalDays: (jsonSerialization['totalDays'] as num).toDouble(),
      totalHours: jsonSerialization['totalHours'] as String,
      totalOvertimeHours: jsonSerialization['totalOvertimeHours'] as String,
      createdAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  static final t = TimesheetDataTable();

  static const db = TimesheetDataRepository._();

  @override
  int? id;

  int validationRequestId;

  String employeeId;

  String employeeName;

  String employeeCompany;

  int month;

  int year;

  String entries;

  double totalDays;

  String totalHours;

  String totalOvertimeHours;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [TimesheetData]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TimesheetData copyWith({
    int? id,
    int? validationRequestId,
    String? employeeId,
    String? employeeName,
    String? employeeCompany,
    int? month,
    int? year,
    String? entries,
    double? totalDays,
    String? totalHours,
    String? totalOvertimeHours,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'validationRequestId': validationRequestId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'employeeCompany': employeeCompany,
      'month': month,
      'year': year,
      'entries': entries,
      'totalDays': totalDays,
      'totalHours': totalHours,
      'totalOvertimeHours': totalOvertimeHours,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      if (id != null) 'id': id,
      'validationRequestId': validationRequestId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'employeeCompany': employeeCompany,
      'month': month,
      'year': year,
      'entries': entries,
      'totalDays': totalDays,
      'totalHours': totalHours,
      'totalOvertimeHours': totalOvertimeHours,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static TimesheetDataInclude include() {
    return TimesheetDataInclude._();
  }

  static TimesheetDataIncludeList includeList({
    _i1.WhereExpressionBuilder<TimesheetDataTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TimesheetDataTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TimesheetDataTable>? orderByList,
    TimesheetDataInclude? include,
  }) {
    return TimesheetDataIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TimesheetData.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(TimesheetData.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TimesheetDataImpl extends TimesheetData {
  _TimesheetDataImpl({
    int? id,
    required int validationRequestId,
    required String employeeId,
    required String employeeName,
    required String employeeCompany,
    required int month,
    required int year,
    required String entries,
    required double totalDays,
    required String totalHours,
    required String totalOvertimeHours,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super._(
          id: id,
          validationRequestId: validationRequestId,
          employeeId: employeeId,
          employeeName: employeeName,
          employeeCompany: employeeCompany,
          month: month,
          year: year,
          entries: entries,
          totalDays: totalDays,
          totalHours: totalHours,
          totalOvertimeHours: totalOvertimeHours,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  /// Returns a shallow copy of this [TimesheetData]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TimesheetData copyWith({
    Object? id = _Undefined,
    int? validationRequestId,
    String? employeeId,
    String? employeeName,
    String? employeeCompany,
    int? month,
    int? year,
    String? entries,
    double? totalDays,
    String? totalHours,
    String? totalOvertimeHours,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimesheetData(
      id: id is int? ? id : this.id,
      validationRequestId: validationRequestId ?? this.validationRequestId,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeCompany: employeeCompany ?? this.employeeCompany,
      month: month ?? this.month,
      year: year ?? this.year,
      entries: entries ?? this.entries,
      totalDays: totalDays ?? this.totalDays,
      totalHours: totalHours ?? this.totalHours,
      totalOvertimeHours: totalOvertimeHours ?? this.totalOvertimeHours,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TimesheetDataTable extends _i1.Table<int?> {
  TimesheetDataTable({super.tableRelation})
      : super(tableName: 'timesheet_data') {
    validationRequestId = _i1.ColumnInt(
      'validationRequestId',
      this,
    );
    employeeId = _i1.ColumnString(
      'employeeId',
      this,
    );
    employeeName = _i1.ColumnString(
      'employeeName',
      this,
    );
    employeeCompany = _i1.ColumnString(
      'employeeCompany',
      this,
    );
    month = _i1.ColumnInt(
      'month',
      this,
    );
    year = _i1.ColumnInt(
      'year',
      this,
    );
    entries = _i1.ColumnString(
      'entries',
      this,
    );
    totalDays = _i1.ColumnDouble(
      'totalDays',
      this,
    );
    totalHours = _i1.ColumnString(
      'totalHours',
      this,
    );
    totalOvertimeHours = _i1.ColumnString(
      'totalOvertimeHours',
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

  late final _i1.ColumnInt validationRequestId;

  late final _i1.ColumnString employeeId;

  late final _i1.ColumnString employeeName;

  late final _i1.ColumnString employeeCompany;

  late final _i1.ColumnInt month;

  late final _i1.ColumnInt year;

  late final _i1.ColumnString entries;

  late final _i1.ColumnDouble totalDays;

  late final _i1.ColumnString totalHours;

  late final _i1.ColumnString totalOvertimeHours;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
        id,
        validationRequestId,
        employeeId,
        employeeName,
        employeeCompany,
        month,
        year,
        entries,
        totalDays,
        totalHours,
        totalOvertimeHours,
        createdAt,
        updatedAt,
      ];
}

class TimesheetDataInclude extends _i1.IncludeObject {
  TimesheetDataInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => TimesheetData.t;
}

class TimesheetDataIncludeList extends _i1.IncludeList {
  TimesheetDataIncludeList._({
    _i1.WhereExpressionBuilder<TimesheetDataTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TimesheetData.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => TimesheetData.t;
}

class TimesheetDataRepository {
  const TimesheetDataRepository._();

  /// Returns a list of [TimesheetData]s matching the given query parameters.
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
  Future<List<TimesheetData>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TimesheetDataTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TimesheetDataTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TimesheetDataTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<TimesheetData>(
      where: where?.call(TimesheetData.t),
      orderBy: orderBy?.call(TimesheetData.t),
      orderByList: orderByList?.call(TimesheetData.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [TimesheetData] matching the given query parameters.
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
  Future<TimesheetData?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TimesheetDataTable>? where,
    int? offset,
    _i1.OrderByBuilder<TimesheetDataTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TimesheetDataTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<TimesheetData>(
      where: where?.call(TimesheetData.t),
      orderBy: orderBy?.call(TimesheetData.t),
      orderByList: orderByList?.call(TimesheetData.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [TimesheetData] by its [id] or null if no such row exists.
  Future<TimesheetData?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<TimesheetData>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [TimesheetData]s in the list and returns the inserted rows.
  ///
  /// The returned [TimesheetData]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<TimesheetData>> insert(
    _i1.Session session,
    List<TimesheetData> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<TimesheetData>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [TimesheetData] and returns the inserted row.
  ///
  /// The returned [TimesheetData] will have its `id` field set.
  Future<TimesheetData> insertRow(
    _i1.Session session,
    TimesheetData row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<TimesheetData>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [TimesheetData]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<TimesheetData>> update(
    _i1.Session session,
    List<TimesheetData> rows, {
    _i1.ColumnSelections<TimesheetDataTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<TimesheetData>(
      rows,
      columns: columns?.call(TimesheetData.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TimesheetData]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TimesheetData> updateRow(
    _i1.Session session,
    TimesheetData row, {
    _i1.ColumnSelections<TimesheetDataTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<TimesheetData>(
      row,
      columns: columns?.call(TimesheetData.t),
      transaction: transaction,
    );
  }

  /// Deletes all [TimesheetData]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<TimesheetData>> delete(
    _i1.Session session,
    List<TimesheetData> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<TimesheetData>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [TimesheetData].
  Future<TimesheetData> deleteRow(
    _i1.Session session,
    TimesheetData row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TimesheetData>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<TimesheetData>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<TimesheetDataTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<TimesheetData>(
      where: where(TimesheetData.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TimesheetDataTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<TimesheetData>(
      where: where?.call(TimesheetData.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
