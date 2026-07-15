import 'package:flutter_test/flutter_test.dart';
import 'package:powersync/sqlite3.dart' as sqlite;
import 'package:powersync/sqlite_async.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_sheet/core/database/schema.dart';
import 'package:time_sheet/core/database/sync_repair_service.dart';

/// Tests de la passe de réparation des lignes locales legacy
/// (valeurs d'enum rejetées par PostgreSQL avant les correctifs des mappers).
///
/// La base est un vrai SQLite en mémoire (via sqlite_async, la même
/// abstraction [SqliteConnection] que PowerSyncDatabase implémente) : les
/// requêtes SQL du service sont exercées telles quelles.
void main() {
  const repairedTables = [
    'anomalies',
    'absences',
    'expenses',
    'overtime_configurations',
  ];

  late SqliteDatabase db;
  late SyncRepairService service;

  Future<void> insert(String table, Map<String, Object?> values) async {
    final columns = values.keys.join(', ');
    final placeholders = List.filled(values.length, '?').join(', ');
    await db.execute(
      'INSERT INTO $table ($columns) VALUES ($placeholders)',
      values.values.toList(),
    );
  }

  Future<Map<String, Object?>> rowById(String table, String id) async {
    final row = await db.get('SELECT * FROM $table WHERE id = ?', [id]);
    return Map<String, Object?>.from(row);
  }

  setUp(() async {
    db = SqliteDatabase.singleConnection(
      SyncSqliteConnection(sqlite.sqlite3.openInMemory(), Mutex()),
    );
    // Tables locales identiques au schéma PowerSync (source de vérité).
    for (final table in schema.tables) {
      if (!repairedTables.contains(table.name)) continue;
      final columns = table.columns.map((c) => c.name).join(', ');
      await db.execute(
        'CREATE TABLE ${table.name} (id TEXT PRIMARY KEY, $columns)',
      );
    }
    service = SyncRepairService(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('SyncRepairService.repair', () {
    test('détecte et normalise les anomalies camelCase legacy', () async {
      await insert('anomalies', {
        'id': 'a1',
        'user_id': 'u1',
        'type': 'insufficientHours',
        'detected_date': '2025-01-06',
        'description': 'Heures insuffisantes',
        'is_resolved': 0,
      });
      await insert('anomalies', {
        'id': 'a2',
        'user_id': 'u1',
        'type': 'missingEntry',
        'detected_date': '2025-01-07',
      });
      await insert('anomalies', {
        'id': 'a3',
        'user_id': 'u1',
        'type': 'invalidTimes',
        'detected_date': '2025-01-08',
      });

      final results = await service.repair();

      expect(results['anomalies'], 3);
      expect((await rowById('anomalies', 'a1'))['type'], 'insufficient_hours');
      expect((await rowById('anomalies', 'a2'))['type'], 'missing_entry');
      expect((await rowById('anomalies', 'a3'))['type'], 'invalid_times');
    });

    test('normalise les absences sickLeave et publicHoliday', () async {
      await insert('absences', {
        'id': 'ab1',
        'user_id': 'u1',
        'start_date': '2025-02-03',
        'end_date': '2025-02-03',
        'type': 'sickLeave',
        'motif': 'Grippe',
      });
      await insert('absences', {
        'id': 'ab2',
        'user_id': 'u1',
        'start_date': '2025-08-01',
        'end_date': '2025-08-01',
        'type': 'publicHoliday',
      });

      final results = await service.repair();

      expect(results['absences'], 2);
      expect((await rowById('absences', 'ab1'))['type'], 'sick');
      expect((await rowById('absences', 'ab2'))['type'], 'holiday');
    });

    test("normalise expenses.category 'meal' en copiant TOUTES les colonnes",
        () async {
      final fullRow = <String, Object?>{
        'id': 'e1',
        'user_id': 'u1',
        'date': '2025-03-10',
        'category': 'meal',
        'description': 'Repas client',
        'currency': 'CHF',
        'amount': 42.5,
        'mileage_rate': 0.7,
        'distance_km': 12,
        'departure_location': 'Lausanne',
        'arrival_location': 'Genève',
        'attachment_url': 'receipts/u1/e1.jpg',
        'is_approved': 1,
        'approved_by': 'm1',
        'manager_comment': 'OK',
        'approved_at': '2025-03-11T08:00:00Z',
        'created_at': '2025-03-10T12:00:00Z',
        'updated_at': '2025-03-11T08:00:00Z',
      };
      await insert('expenses', fullRow);

      final results = await service.repair();

      expect(results['expenses'], 1);
      final repaired = await rowById('expenses', 'e1');
      expect(repaired['category'], 'meals');
      // La ligne complète est préservée (upsert pleine ligne côté serveur).
      for (final entry in fullRow.entries) {
        if (entry.key == 'category') continue;
        expect(repaired[entry.key], entry.value,
            reason: 'colonne ${entry.key} altérée par la réparation');
      }
    });

    test('convertit weekend_days JSON en littéral PostgreSQL', () async {
      await insert('overtime_configurations', {
        'id': 'oc1',
        'user_id': 'u1',
        'weekend_overtime_enabled': 1,
        'weekend_days': '[6,7]',
        'weekend_overtime_rate': 1.5,
      });

      final results = await service.repair();

      expect(results['overtime_configurations'], 1);
      final repaired = await rowById('overtime_configurations', 'oc1');
      expect(repaired['weekend_days'], '{6,7}');
      expect(repaired['weekend_overtime_rate'], 1.5);
    });

    test('laisse intactes les valeurs weekend_days illisibles', () async {
      await insert('overtime_configurations', {
        'id': 'oc2',
        'user_id': 'u1',
        'weekend_days': '[6,broken',
      });

      final results = await service.repair();

      expect(results['overtime_configurations'], 0);
      final untouched = await rowById('overtime_configurations', 'oc2');
      expect(untouched['weekend_days'], '[6,broken');
    });

    test('ne touche pas aux lignes saines', () async {
      await insert('anomalies', {
        'id': 'a1',
        'user_id': 'u1',
        'type': 'insufficient_hours',
        'detected_date': '2025-01-06',
      });
      await insert('absences', {
        'id': 'ab1',
        'user_id': 'u1',
        'start_date': '2025-02-03',
        'type': 'vacation',
      });
      await insert('expenses', {
        'id': 'e1',
        'user_id': 'u1',
        'date': '2025-03-10',
        'category': 'meals',
        'amount': 10.0,
      });
      await insert('overtime_configurations', {
        'id': 'oc1',
        'user_id': 'u1',
        'weekend_days': '{6,7}',
      });

      final before = <String, Map<String, Object?>>{
        'anomalies': await rowById('anomalies', 'a1'),
        'absences': await rowById('absences', 'ab1'),
        'expenses': await rowById('expenses', 'e1'),
        'overtime_configurations': await rowById('overtime_configurations', 'oc1'),
      };

      final results = await service.repair();

      expect(results.values.every((count) => count == 0), isTrue,
          reason: 'aucune ligne saine ne doit être réparée : $results');
      expect(await rowById('anomalies', 'a1'), before['anomalies']);
      expect(await rowById('absences', 'ab1'), before['absences']);
      expect(await rowById('expenses', 'e1'), before['expenses']);
      expect(await rowById('overtime_configurations', 'oc1'),
          before['overtime_configurations']);
    });

    test('est idempotent : un deuxième passage ne répare rien', () async {
      await insert('anomalies', {
        'id': 'a1',
        'user_id': 'u1',
        'type': 'missingEntry',
        'detected_date': '2025-01-07',
      });
      await insert('expenses', {
        'id': 'e1',
        'user_id': 'u1',
        'date': '2025-03-10',
        'category': 'meal',
      });
      await insert('overtime_configurations', {
        'id': 'oc1',
        'user_id': 'u1',
        'weekend_days': '[6,7]',
      });

      final firstRun = await service.repair();
      expect(firstRun['anomalies'], 1);
      expect(firstRun['expenses'], 1);
      expect(firstRun['overtime_configurations'], 1);

      final secondRun = await service.repair();
      expect(secondRun.values.every((count) => count == 0), isTrue,
          reason: 'deuxième passage : $secondRun');
      // Les lignes restent normalisées.
      expect((await rowById('anomalies', 'a1'))['type'], 'missing_entry');
      expect((await rowById('expenses', 'e1'))['category'], 'meals');
      expect((await rowById('overtime_configurations', 'oc1'))['weekend_days'],
          '{6,7}');
    });
  });

  group('SyncRepairService.repairIfNeeded', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('répare puis pose le flag sync_repair_v1_done', () async {
      await insert('absences', {
        'id': 'ab1',
        'user_id': 'u1',
        'start_date': '2025-02-03',
        'type': 'sickLeave',
      });

      await service.repairIfNeeded();

      expect((await rowById('absences', 'ab1'))['type'], 'sick');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(SyncRepairService.prefsFlagKey), isTrue);
    });

    test('ne rescanne pas quand le flag est déjà posé', () async {
      await service.repairIfNeeded();

      // Nouvelle ligne legacy insérée après la première passe : elle ne doit
      // pas être touchée par repairIfNeeded (flag posé)...
      await insert('anomalies', {
        'id': 'a1',
        'user_id': 'u1',
        'type': 'invalidTimes',
        'detected_date': '2025-01-08',
      });
      await service.repairIfNeeded();
      expect((await rowById('anomalies', 'a1'))['type'], 'invalidTimes');

      // ...mais un scan explicite reste sans danger et la répare.
      final results = await service.repair();
      expect(results['anomalies'], 1);
      expect((await rowById('anomalies', 'a1'))['type'], 'invalid_times');
    });
  });

  group('Valeurs legacy dérivées des mappers', () {
    test('anomalies : les trois valeurs camelCase sont couvertes', () {
      expect(SyncRepairService.anomalyLegacyValues, {
        'insufficientHours': 'insufficient_hours',
        'missingEntry': 'missing_entry',
        'invalidTimes': 'invalid_times',
      });
    });

    test('absences : sickLeave -> sick, publicHoliday -> holiday', () {
      expect(SyncRepairService.absenceLegacyValues, {
        'publicHoliday': 'holiday',
        'sickLeave': 'sick',
      });
    });

    test('expenses : meal -> meals', () {
      expect(SyncRepairService.expenseLegacyValues, {'meal': 'meals'});
    });
  });
}
