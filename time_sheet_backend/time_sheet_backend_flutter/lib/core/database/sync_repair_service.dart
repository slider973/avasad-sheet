import 'package:powersync/sqlite_async.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/absence/data/models/absence_type_db_mapper.dart';
import '../../features/absence/domain/value_objects/absence_type.dart';
import '../../features/expense/data/models/expense_category_db_mapper.dart';
import '../../features/expense/domain/entities/expense_category.dart';
import '../../features/pointage/data/models/anomalies/anomalies.dart';
import '../../features/pointage/data/models/anomalies/anomaly_type_db_mapper.dart';
import '../../features/preference/data/utils/weekend_days_db_codec.dart';
import '../../services/logger_service.dart';
import 'schema.dart';

/// Passe de réparation au démarrage pour les lignes locales « legacy ».
///
/// Contexte : avant les correctifs des mappers, le connecteur PowerSync
/// uploadait des valeurs d'enum invalides (camelCase, JSON au lieu de littéral
/// tableau) que PostgreSQL rejetait (contrainte CHECK / 22P02). Le connecteur
/// skippe ces erreurs non récupérables : les lignes existent en SQLite local
/// mais n'ont JAMAIS atteint le serveur, et leurs entrées de queue d'upload
/// ont été jetées. Les mappers corrigent les écritures futures ; ce service
/// remonte les lignes historiques.
///
/// Stratégie DELETE + INSERT (et non UPDATE) : un UPDATE local produit une
/// opération `patch` que le connecteur traduit en `update().eq('id', ...)` —
/// sur une ligne absente côté serveur, PostgREST met à jour 0 ligne SANS
/// erreur et la réparation serait perdue. Seul un INSERT local produit un
/// `put` (upsert pleine ligne). On lit donc la ligne complète, on la supprime
/// puis on la réinsère (même id, valeurs normalisées) dans une même
/// transaction locale : le connecteur enverra delete (no-op serveur, la ligne
/// n'y existe pas) puis upsert pleine ligne.
class SyncRepairService {
  /// Flag SharedPreferences évitant de rescanner à chaque démarrage.
  /// Le scan reste idempotent : le flag n'est qu'une optimisation.
  static const String prefsFlagKey = 'sync_repair_v1_done';

  final SqliteConnection db;

  SyncRepairService({required this.db});

  /// Valeurs legacy `anomalies.type` (camelCase) -> valeurs CHECK PostgreSQL.
  /// Dérivé du mapper [AnomalyTypeDb] : source de vérité unique.
  static Map<String, String> get anomalyLegacyValues => {
        for (final type in AnomalyType.values)
          if (type.name != type.dbValue) type.name: type.dbValue,
      };

  /// Valeurs legacy `absences.type` ('sickLeave' -> 'sick',
  /// 'publicHoliday' -> 'holiday'). Dérivé du mapper [AbsenceTypeDb].
  static Map<String, String> get absenceLegacyValues => {
        for (final type in AbsenceType.values)
          if (type.name != type.dbValue) type.name: type.dbValue,
      };

  /// Valeurs legacy `expenses.category` ('meal' -> 'meals').
  /// Dérivé du mapper [ExpenseCategoryDb].
  static Map<String, String> get expenseLegacyValues => {
        for (final category in ExpenseCategory.values)
          if (category.name != category.dbValue) category.name: category.dbValue,
      };

  /// Lance la réparation si elle n'a pas déjà été marquée comme faite.
  /// Ne lève jamais : un échec est logué et retenté au prochain démarrage
  /// (le flag n'est posé qu'après un scan complet réussi).
  Future<void> repairIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(prefsFlagKey) ?? false) return;

      final repaired = await repair();
      final total = repaired.values.fold<int>(0, (sum, count) => sum + count);
      logger.i('[SyncRepair] Scan terminé : $total ligne(s) réparée(s).');

      await prefs.setBool(prefsFlagKey, true);
    } catch (e, stackTrace) {
      logger.e('[SyncRepair] Échec de la passe de réparation',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Exécute le scan et la réparation, sans consulter le flag.
  /// Idempotent : les WHERE ne sélectionnent que les valeurs legacy,
  /// un deuxième passage ne trouve donc rien à réparer.
  ///
  /// Retourne le nombre de lignes réparées par table.
  Future<Map<String, int>> repair() async {
    final results = <String, int>{
      'anomalies': await _repairLegacyValues(
        table: 'anomalies',
        column: 'type',
        legacyToDb: anomalyLegacyValues,
      ),
      'absences': await _repairLegacyValues(
        table: 'absences',
        column: 'type',
        legacyToDb: absenceLegacyValues,
      ),
      'expenses': await _repairLegacyValues(
        table: 'expenses',
        column: 'category',
        legacyToDb: expenseLegacyValues,
      ),
      'overtime_configurations': await _repairWeekendDays(),
    };

    for (final entry in results.entries) {
      if (entry.value > 0) {
        logger.i(
            '[SyncRepair] ${entry.key} : ${entry.value} ligne(s) réparée(s).');
      }
    }
    return results;
  }

  /// Colonnes locales d'une table, `id` inclus, telles que déclarées dans
  /// [schema] (source de vérité unique — la pleine ligne doit être copiée
  /// pour que l'upsert serveur soit complet).
  static List<String> _columnsOf(String table) {
    final tableSchema = schema.tables.firstWhere((t) => t.name == table);
    return ['id', ...tableSchema.columns.map((column) => column.name)];
  }

  /// Répare les lignes de [table] dont [column] contient une clé de
  /// [legacyToDb] : DELETE + INSERT pleine ligne avec la valeur normalisée.
  Future<int> _repairLegacyValues({
    required String table,
    required String column,
    required Map<String, String> legacyToDb,
  }) async {
    if (legacyToDb.isEmpty) return 0;

    final columns = _columnsOf(table);
    final columnList = columns.join(', ');
    final inPlaceholders = List.filled(legacyToDb.length, '?').join(', ');
    final insertPlaceholders = List.filled(columns.length, '?').join(', ');

    return db.writeTransaction((tx) async {
      final rows = await tx.getAll(
        'SELECT $columnList FROM $table WHERE $column IN ($inPlaceholders)',
        legacyToDb.keys.toList(),
      );

      for (final row in rows) {
        final values = Map<String, Object?>.from(row);
        values[column] = legacyToDb[values[column]];

        await tx.execute('DELETE FROM $table WHERE id = ?', [values['id']]);
        await tx.execute(
          'INSERT INTO $table ($columnList) VALUES ($insertPlaceholders)',
          columns.map((name) => values[name]).toList(),
        );
      }
      return rows.length;
    });
  }

  /// Répare `overtime_configurations.weekend_days` : les valeurs legacy sont
  /// du JSON (`[6,7]`) alors que PostgREST n'accepte que le littéral tableau
  /// PostgreSQL (`{6,7}`). Réencode via [WeekendDaysDbCodec].
  Future<int> _repairWeekendDays() async {
    const table = 'overtime_configurations';
    final columns = _columnsOf(table);
    final columnList = columns.join(', ');
    final insertPlaceholders = List.filled(columns.length, '?').join(', ');

    return db.writeTransaction((tx) async {
      final rows = await tx.getAll(
        'SELECT $columnList FROM $table '
        "WHERE weekend_days IS NOT NULL AND TRIM(weekend_days) LIKE '[%'",
      );

      var repaired = 0;
      for (final row in rows) {
        final days = WeekendDaysDbCodec.decode(row['weekend_days'] as String?);
        // Valeur illisible : on n'y touche pas (la réécrire à l'identique
        // ne réparerait rien côté serveur).
        if (days == null) continue;

        final values = Map<String, Object?>.from(row);
        values['weekend_days'] = WeekendDaysDbCodec.encode(days);

        await tx.execute('DELETE FROM $table WHERE id = ?', [values['id']]);
        await tx.execute(
          'INSERT INTO $table ($columnList) VALUES ($insertPlaceholders)',
          columns.map((name) => values[name]).toList(),
        );
        repaired++;
      }
      return repaired;
    });
  }
}
