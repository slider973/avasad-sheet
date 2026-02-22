import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'schema.dart';
import 'supabase_connector.dart';

/// Manages the PowerSync database instance and connection lifecycle.
class PowerSyncDatabaseManager {
  static PowerSyncDatabase? _database;
  static SupabaseConnector? _connector;

  /// Get the PowerSync database instance.
  /// Must call [initialize] first.
  static PowerSyncDatabase get database {
    if (_database == null) {
      throw StateError('PowerSync database not initialized. Call initialize() first.');
    }
    return _database!;
  }

  /// Initialize the PowerSync database with the local SQLite path
  /// and connect to the sync service.
  static Future<PowerSyncDatabase> initialize() async {
    if (_database != null) return _database!;

    final dbPath = await _getDatabasePath();
    debugPrint('PowerSync DB path: $dbPath');

    _database = PowerSyncDatabase(
      schema: schema,
      path: dbPath,
    );

    await _database!.initialize();

    return _database!;
  }

  /// Connect to PowerSync sync service using Supabase credentials.
  /// Call this after the user is authenticated.
  static Future<void> connect() async {
    if (_database == null) {
      throw StateError('PowerSync database not initialized. Call initialize() first.');
    }

    final supabaseClient = Supabase.instance.client;
    _connector = SupabaseConnector(supabaseClient: supabaseClient);

    await _database!.connect(connector: _connector!);
    debugPrint('PowerSync connected to sync service');
  }

  /// Disconnect from PowerSync sync service.
  /// Call this when the user logs out.
  static Future<void> disconnect() async {
    await _database?.disconnect();
    _connector = null;
    debugPrint('PowerSync disconnected');
  }

  /// Close the database entirely.
  static Future<void> close() async {
    await disconnect();
    await _database?.close();
    _database = null;
    debugPrint('PowerSync database closed');
  }

  /// Get the status stream (connected, uploading, downloading, etc.)
  static Stream<SyncStatus> get statusStream {
    return database.statusStream;
  }

  /// Get the current sync status
  static SyncStatus get currentStatus {
    return database.currentStatus;
  }

  static Future<String> _getDatabasePath() async {
    String dir;

    if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
      dir = path.join(localAppData, 'TimeSheet', 'Database');
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      dir = appDir.path;
    }

    await Directory(dir).create(recursive: true);
    return path.join(dir, 'timesheet_powersync.db');
  }
}
