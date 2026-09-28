import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_sheet/services/watch_request_ledger.dart';

/// Ces tests couvrent le scénario qui, sans ce registre, produit des pointages
/// fantômes : le contexte WatchConnectivity est relu à chaque lancement de
/// l'application iOS, donc la dernière demande de la montre serait rejouée à
/// chaque redémarrage.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  WatchRequestLedger ledger() =>
      WatchRequestLedger(preferences: SharedPreferences.getInstance);

  test('une demande inconnue est acceptée une seule fois', () async {
    final l = ledger();
    await l.load();

    expect(await l.remember('req-1'), isTrue);
    expect(l.alreadyHandled('req-1'), isTrue);
    expect(await l.remember('req-1'), isFalse,
        reason: 'la seconde arrivée du même message ne doit rien rejouer');
  });

  test('la mémoire survit au redémarrage de l\'application', () async {
    final avant = ledger();
    await avant.load();
    await avant.remember('req-persistant');

    // Nouvelle instance = nouveau lancement de l'app, mêmes préférences.
    final apres = ledger();
    await apres.load();

    expect(apres.alreadyHandled('req-persistant'), isTrue,
        reason: "c'est exactement le cas que le registre protège : "
            'le contexte relu au démarrage ne doit pas repointer');
  });

  test('la liste est bornée et conserve les plus récents', () async {
    final l = ledger();
    await l.load();

    for (var i = 0; i < WatchRequestLedger.maxRetained + 10; i++) {
      await l.remember('req-$i');
    }

    expect(l.retained.length, WatchRequestLedger.maxRetained);
    expect(l.retained.last, 'req-${WatchRequestLedger.maxRetained + 9}');
    expect(l.alreadyHandled('req-0'), isFalse,
        reason: 'les plus anciens sortent de la fenêtre');
    expect(l.alreadyHandled('req-${WatchRequestLedger.maxRetained + 9}'),
        isTrue);
  });

  test('revoir un identifiant ne le rajeunit pas', () async {
    final l = ledger();
    await l.load();
    await l.remember('vieux');
    for (var i = 0; i < 5; i++) {
      await l.remember('req-$i');
    }

    await l.remember('vieux'); // déjà connu : sans effet

    expect(l.retained.first, 'vieux',
        reason: 'sa position reflète son traitement, pas sa dernière vue');
    expect(l.retained.length, 6);
  });

  test('un stockage illisible ne bloque pas le pointage', () async {
    final l = WatchRequestLedger(
        preferences: () => Future<SharedPreferences>.error(
            StateError('stockage indisponible')));

    // Ne doit pas lever : mieux vaut risquer un doublon que perdre le pointage.
    await l.load();
    expect(l.retained, isEmpty);
    expect(await l.remember('req-1'), isTrue);
    expect(l.alreadyHandled('req-1'), isTrue,
        reason: 'la mémoire en RAM protège au moins la session courante');
  });
}
