import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        endpoint: const String.fromEnvironment(
          'POWERSYNC_URL',
          defaultValue: 'https://powersync.timesheet.staticflow.ch',
        ),
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
      endpoint: const String.fromEnvironment(
        'POWERSYNC_URL',
        defaultValue: 'https://powersync.timesheet.staticflow.ch',
      ),
      token: currentSession.accessToken,
      userId: currentSession.user.id,
    );
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final transaction = await database.getCrudBatch();
    if (transaction == null) return;

    for (final op in transaction.crud) {
      await _uploadOperation(op);
    }

    await transaction.complete();
  }

  Future<void> _uploadOperation(CrudEntry op) async {
    final table = op.table;
    final data = Map<String, dynamic>.from(op.opData ?? {});

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
  }
}
