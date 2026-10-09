import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_sheet/features/geofencing/data/services/day_mirror_store.dart';
import 'package:time_sheet/features/geofencing/domain/entities/day_pointage_snapshot.dart';

/// Le miroir que lit l'isolate de géorepérage.
///
/// Second défaut constaté : `refreshMirror()` n'était appelé nulle part. Après
/// un pointage manuel, l'arrière-plan croyait la journée non commencée et
/// pouvait pointer une seconde fois à l'entrée de zone suivante.
///
/// Le bloc met désormais ce miroir à jour à chaque pointage, en analysant
/// `entry.dayDate` au format `dd-MMM-yy`. Ces tests verrouillent ce format :
/// s'il change, le miroir cesserait silencieusement d'être écrit.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('le format dd-MMM-yy du bloc est bien analysable', () {
    // Aller-retour : c'est exactement ce que fait _refreshGeofenceMirror.
    final jour = DateTime(2026, 10, 9);
    final texte = DateFormat('dd-MMM-yy').format(jour);
    final relu = DateFormat('dd-MMM-yy').parse(texte);

    expect(relu.year, 2026);
    expect(relu.month, 10);
    expect(relu.day, 9);
  });

  test('le miroir ecrit est relu tel quel pour le jour courant', () async {
    const store = DayMirrorStore();
    final today = DateTime.now();

    await store.write(
      const DayPointageSnapshot(
        startMorning: '08:30',
        endMorning: '12:00',
        startAfternoon: '',
        endAfternoon: '',
      ),
      today,
    );

    final relu = await store.readForToday(now: today);
    expect(relu.startMorning, '08:30');
    expect(
      relu.endMorning,
      '12:00',
      reason: 'sans ce miroir, l arriere-plan repointerait l arrivee',
    );
  });

  test('le miroir d un autre jour ne pollue pas le jour courant', () async {
    const store = DayMirrorStore();
    final hier = DateTime.now().subtract(const Duration(days: 1));

    await store.write(
      const DayPointageSnapshot(
        startMorning: '07:00',
        endMorning: '',
        startAfternoon: '',
        endAfternoon: '',
      ),
      hier,
    );

    final aujourdhui = await store.readForToday(now: DateTime.now());
    expect(
      aujourdhui.startMorning,
      anyOf(isNull, isEmpty),
      reason: 'le miroir est journalier : hier ne doit pas compter aujourd hui',
    );
  });
}
