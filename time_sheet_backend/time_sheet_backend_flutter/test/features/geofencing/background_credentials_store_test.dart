import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_sheet/features/geofencing/data/repositories/background_credentials_store.dart';

/// Jeton d'accès mis à disposition de l'isolate d'arrière-plan.
///
/// L'isolate du géorepérage n'a ni GetIt, ni client Supabase initialisé : il ne
/// peut donc pas demander la session courante. Sans un jeton déposé à l'avance
/// dans SharedPreferences, aucune écriture directe n'est possible et le
/// pointage automatique retombe sur la file d'attente — c'est-à-dire sur
/// « rien tant que l'app n'est pas ouverte ».
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('rend null quand rien n a ete depose', () async {
    const store = BackgroundCredentialsStore();
    expect(await store.readAccessToken(), isNull);
    expect(await store.readUserId(), isNull);
  });

  test('restitue ce qui a ete depose par l application', () async {
    const store = BackgroundCredentialsStore();
    await store.save(
      userId: 'd69e428a-9733-4f07-93bc-8df57d8bee63',
      accessToken: 'jwt-abc',
      expiresAt: DateTime(2026, 11, 5, 12),
    );

    expect(await store.readUserId(), 'd69e428a-9733-4f07-93bc-8df57d8bee63');
    expect(await store.readAccessToken(now: DateTime(2026, 11, 5, 11)),
        'jwt-abc');
  });

  test('refuse un jeton expire plutot que de tenter un appel voue a l echec',
      () async {
    // Cas réel : plusieurs jours sans ouvrir l'app. Un appel avec un jeton mort
    // consommerait le budget d'arrière-plan pour un 401.
    const store = BackgroundCredentialsStore();
    await store.save(
      userId: 'u1',
      accessToken: 'jwt-mort',
      expiresAt: DateTime(2026, 11, 4, 10),
    );

    expect(
      await store.readAccessToken(now: DateTime(2026, 11, 4, 11)),
      isNull,
    );
    // L'identifiant reste lisible : il sert au rejeu par la file.
    expect(await store.readUserId(), 'u1');
  });

  test('applique une marge de securite avant l echeance', () async {
    // Un jeton qui expire dans dix secondes sera refusé par le serveur le temps
    // que l'appel aboutisse.
    const store = BackgroundCredentialsStore();
    await store.save(
      userId: 'u1',
      accessToken: 'jwt-limite',
      expiresAt: DateTime(2026, 11, 4, 10, 0, 10),
    );

    expect(
      await store.readAccessToken(now: DateTime(2026, 11, 4, 10, 0, 0)),
      isNull,
      reason: 'une échéance à 10 s doit être traitée comme expirée',
    );
  });

  test('efface les identifiants a la deconnexion', () async {
    const store = BackgroundCredentialsStore();
    await store.save(
      userId: 'u1',
      accessToken: 'jwt',
      expiresAt: DateTime(2026, 12, 1),
    );
    await store.clear();

    expect(await store.readAccessToken(), isNull);
    expect(await store.readUserId(), isNull);
  });
}
