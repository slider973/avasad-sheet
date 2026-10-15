import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_sheet/features/geofencing/data/services/day_mirror_store.dart';
import 'package:time_sheet/features/geofencing/data/services/geofence_sync_coordinator.dart';
import 'package:time_sheet/features/geofencing/domain/entities/attendance_decision.dart';
import 'package:time_sheet/features/pointage/presentation/pages/time-sheet/bloc/time_sheet/time_sheet_bloc.dart';

/// Le chaînon manquant du pointage automatique.
///
/// L'isolate d'arrière-plan détecte bien les entrées et sorties de zone et
/// empile ses décisions dans SharedPreferences. Mais `GeofenceSyncCoordinator`
/// — seul capable de les transformer en vrais pointages — n'était instancié
/// NULLE PART dans l'application : les décisions s'accumulaient sans jamais
/// être rejouées.
///
/// Ces tests vérifient le rejeu lui-même, indépendamment du branchement.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DayMirrorStore mirror;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mirror = const DayMirrorStore();
  });

  /// Bloc espion : on ne veut pas de base, seulement les événements reçus.
  TimeSheetBloc? bloc;

  test('les decisions empilees deviennent des evenements de pointage', () async {
    final at = DateTime(2026, 10, 9, 8, 30);
    await mirror.enqueueDecision(
      AttendanceDecision(
        action: AttendanceAction.clockIn,
        at: at,
        reason: 'entree zone travail',
      ),
    );

    final pending = await mirror.drainPendingDecisions();
    expect(
      pending,
      hasLength(1),
      reason: 'la decision doit survivre a l isolate via SharedPreferences',
    );
    expect(pending.first.action, AttendanceAction.clockIn);
    expect(pending.first.at, at);
  });

  test('drain vide la file : une decision n est jamais rejouee deux fois',
      () async {
    await mirror.enqueueDecision(
      AttendanceDecision(
        action: AttendanceAction.clockOut,
        at: DateTime(2026, 10, 9, 17, 30),
        reason: 'sortie zone travail',
      ),
    );

    final first = await mirror.drainPendingDecisions();
    final second = await mirror.drainPendingDecisions();

    expect(first, hasLength(1));
    expect(
      second,
      isEmpty,
      reason: 'un double rejeu creerait un pointage fantome',
    );
  });

  test('plusieurs decisions ressortent en ordre chronologique', () async {
    // Empilées à l'envers exprès : une reprise ne doit jamais précéder la
    // pause qui l'a provoquée.
    await mirror.enqueueDecision(
      AttendanceDecision(
        action: AttendanceAction.endBreak,
        at: DateTime(2026, 10, 9, 13, 0),
        reason: 'retour de pause',
      ),
    );
    await mirror.enqueueDecision(
      AttendanceDecision(
        action: AttendanceAction.startBreak,
        at: DateTime(2026, 10, 9, 12, 0),
        reason: 'depart en pause',
      ),
    );

    final pending = await mirror.drainPendingDecisions()
      ..sort((a, b) => a.at.compareTo(b.at));

    expect(pending.map((d) => d.action).toList(), <AttendanceAction>[
      AttendanceAction.startBreak,
      AttendanceAction.endBreak,
    ]);
  });

  tearDown(() => bloc?.close());
}
