import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:time_sheet/core/config/environment.dart';

/// Connector that bridges PowerSync with Supabase for auth and data upload.
class SupabaseConnector extends PowerSyncBackendConnector {
  final SupabaseClient _supabaseClient;

  SupabaseConnector({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    final session = _supabaseClient.auth.currentSession;

    if (session == null) {
      // Try refreshing
      try {
        await _supabaseClient.auth.refreshSession();
      } catch (e) {
        debugPrint('Failed to refresh session: $e');
        return null;
      }
      final refreshedSession = _supabaseClient.auth.currentSession;
      if (refreshedSession == null) return null;

      return PowerSyncCredentials(
        endpoint: AppConfig.powersyncUrl,
        token: refreshedSession.accessToken,
        userId: refreshedSession.user.id,
      );
    }

    // Check if token needs refresh (5 min before expiry)
    if (session.expiresAt != null) {
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
      if (expiresAt.difference(DateTime.now()).inMinutes < 5) {
        try {
          await _supabaseClient.auth.refreshSession();
        } catch (e) {
          debugPrint('Token refresh failed: $e');
        }
      }
    }

    final currentSession = _supabaseClient.auth.currentSession!;

    return PowerSyncCredentials(
      endpoint: AppConfig.powersyncUrl,
      token: currentSession.accessToken,
      userId: currentSession.user.id,
    );
  }

  /// Non-recoverable PostgreSQL error codes that should be skipped
  /// rather than retried indefinitely.
  static const _nonRecoverablePostgresCodes = {
    '22P02', // invalid input syntax (e.g. non-UUID in UUID column)
    '23502', // not-null constraint violation
    '23503', // foreign key constraint violation
    '23505', // unique constraint violation
    '42501', // insufficient privilege / RLS violation
  };

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final transaction = await database.getCrudBatch();
    if (transaction == null) return;

    for (final op in transaction.crud) {
      try {
        await _uploadOperation(op);
      } catch (e) {
        if (_isNonRecoverableError(e)) {
          debugPrint('[SupabaseConnector] Skipping non-recoverable operation: '
              '${op.op.name} on ${op.table} (id: ${op.id}): $e');
          continue;
        }
        // For transient errors (network, timeout, etc.), rethrow to trigger retry
        rethrow;
      }
    }

    await transaction.complete();
  }

  /// Returns true if the error is non-recoverable and should be skipped.
  bool _isNonRecoverableError(Object e) {
    if (e is PostgrestException) {
      final code = e.code;
      if (code != null && _nonRecoverablePostgresCodes.contains(code)) {
        return true;
      }
    }
    final errorStr = e.toString();
    return errorStr.contains('row-level security') ||
        errorStr.contains('invalid input syntax') ||
        errorStr.contains('violates') ||
        (errorStr.contains('403') && errorStr.contains('Unauthorized'));
  }

  Future<void> _uploadOperation(CrudEntry op) async {
    final table = op.table;
    final data = Map<String, dynamic>.from(op.opData ?? {});

    try {
      switch (op.op) {
        case UpdateType.put:
          // Upsert (insert or update)
          data['id'] = op.id;
          await _supabaseClient.from(table).upsert(data);
          break;
        case UpdateType.patch:
          // Update
          await _supabaseClient.from(table).update(data).eq('id', op.id);
          break;
        case UpdateType.delete:
          await _supabaseClient.from(table).delete().eq('id', op.id);
          break;
      }
    } catch (e) {
      debugPrint('[SupabaseConnector] Upload failed for ${op.op.name} on $table (id: ${op.id}): $e');
      rethrow;
    }
  }
}
