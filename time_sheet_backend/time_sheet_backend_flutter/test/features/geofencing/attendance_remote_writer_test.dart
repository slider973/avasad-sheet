import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:time_sheet/features/geofencing/data/services/attendance_remote_writer.dart';
import 'package:time_sheet/features/geofencing/domain/entities/attendance_decision.dart';

/// Écriture directe du pointage depuis l'isolate d'arrière-plan.
///
/// Apple relance l'application pour un franchissement de zone et lui accorde
/// environ 10 secondes (jusqu'à 30 avec `beginBackgroundTask`) : c'est
/// largement suffisant pour un appel HTTPS, et c'est la raison d'être de cette
/// classe. PowerSync, lui, n'est pas utilisable depuis cet isolate — ni GetIt,
/// ni base SQLite ouverte.
///
/// Ces tests portent sur la valeur probante du pointage : si l'heure envoyée
/// n'est pas celle du franchissement, la feuille de temps est fausse ; si
/// l'écriture écrase une saisie manuelle, l'utilisateur perd une correction.
void main() {
  const userId = 'd69e428a-9733-4f07-93bc-8df57d8bee63';
  const baseUrl = 'https://supabase.example.test';

  /// Faux client HTTP : enregistre les requêtes et rend la réponse programmée.
  _FakeClient client({int status = 201, String body = '[]'}) =>
      _FakeClient(status: status, body: body);

  group('horodatage', () {
    test('envoie l heure du franchissement, pas celle de l envoi', () async {
      // Le piège documenté du géorepérage : horodater à la détection décale
      // tous les pointages du délai de réveil.
      final c = client();
      final writer = AttendanceRemoteWriter(
        httpClient: c,
        baseUrl: baseUrl,
        anonKey: 'anon',
      );

      await writer.write(
        decision: AttendanceDecision(
          action: AttendanceAction.clockIn,
          at: DateTime(2026, 11, 4, 8, 3),
          reason: 'Entrée zone travail',
        ),
        userId: userId,
        accessToken: 'jwt',
        now: DateTime(2026, 11, 4, 8, 11),
      );

      // Deux requêtes : la lecture du jour puis l'écriture. C'est la seconde
      // qui porte l'horaire.
      final ecriture = c.requests.last;
      expect(ecriture.method, 'POST');
      final envoye = jsonDecode(ecriture.body) as Map<String, dynamic>;
      expect(envoye['start_morning'], '08:03');
      expect(envoye['day_date'], '2026-11-04');
    });

    test('place une reprise d apres-midi dans la bonne colonne', () async {
      final c = client();
      final writer = AttendanceRemoteWriter(
        httpClient: c,
        baseUrl: baseUrl,
        anonKey: 'anon',
      );

      await writer.write(
        decision: AttendanceDecision(
          action: AttendanceAction.endBreak,
          at: DateTime(2026, 11, 4, 13, 12),
          reason: 'Retour de pause',
        ),
        userId: userId,
        accessToken: 'jwt',
        now: DateTime(2026, 11, 4, 13, 12),
      );

      final envoye =
          jsonDecode(c.requests.last.body) as Map<String, dynamic>;
      expect(envoye['start_afternoon'], '13:12');
      expect(envoye.containsKey('start_morning'), isFalse);
    });

    test('mappe chaque action sur sa colonne', () async {
      final attendu = {
        AttendanceAction.clockIn: 'start_morning',
        AttendanceAction.startBreak: 'end_morning',
        AttendanceAction.endBreak: 'start_afternoon',
        AttendanceAction.clockOut: 'end_afternoon',
      };

      for (final entry in attendu.entries) {
        final c = client();
        final writer = AttendanceRemoteWriter(
          httpClient: c,
          baseUrl: baseUrl,
          anonKey: 'anon',
        );
        await writer.write(
          decision: AttendanceDecision(
            action: entry.key,
            at: DateTime(2026, 11, 4, 9),
            reason: 'test',
          ),
          userId: userId,
          accessToken: 'jwt',
          now: DateTime(2026, 11, 4, 9),
        );
        final envoye =
            jsonDecode(c.requests.last.body) as Map<String, dynamic>;
        expect(envoye[entry.value], '09:00',
            reason: '${entry.key.name} doit viser ${entry.value}');
      }
    });
  });

  group('actions non écrivables', () {
    test('n envoie rien pour une action qui n est pas un pointage', () async {
      // `askAmbiguity` attend une réponse de l'utilisateur, `reconcile` et
      // `none` ne produisent pas d'horaire : écrire ici fabriquerait un
      // pointage que personne n'a demandé.
      for (final action in [
        AttendanceAction.none,
        AttendanceAction.askAmbiguity,
        AttendanceAction.reconcile,
      ]) {
        final c = client();
        final writer = AttendanceRemoteWriter(
          httpClient: c,
          baseUrl: baseUrl,
          anonKey: 'anon',
        );
        final resultat = await writer.write(
          decision: AttendanceDecision(
            action: action,
            at: DateTime(2026, 11, 4, 9),
            reason: 'test',
          ),
          userId: userId,
          accessToken: 'jwt',
          now: DateTime(2026, 11, 4, 9),
        );

        expect(c.requests, isEmpty);
        expect(resultat.status, RemoteWriteStatus.skipped);
      }
    });

    test('n envoie rien sans jeton', () async {
      // Jeton expiré après plusieurs jours sans ouvrir l'app : on ne tente pas
      // un appel qui sera refusé, on laisse la file d'attente faire son office.
      final c = client();
      final writer = AttendanceRemoteWriter(
        httpClient: c,
        baseUrl: baseUrl,
        anonKey: 'anon',
      );
      final resultat = await writer.write(
        decision: AttendanceDecision(
          action: AttendanceAction.clockIn,
          at: DateTime(2026, 11, 4, 8),
          reason: 'test',
        ),
        userId: userId,
        accessToken: null,
        now: DateTime(2026, 11, 4, 8),
      );

      expect(c.requests, isEmpty);
      expect(resultat.status, RemoteWriteStatus.noCredentials);
      expect(resultat.shouldKeepInQueue, isTrue);
    });
  });

  group('ne jamais écraser une saisie existante', () {
    test('laisse intacte une colonne déjà renseignée', () async {
      // Cas réel : l'utilisateur a corrigé son heure d'arrivée à la main.
      // L'arrière-plan ne doit pas la remplacer par l'heure de la zone.
      final c = client(
        body: jsonEncode([
          {
            'id': 'ligne-1',
            'start_morning': '07:45',
            'end_morning': null,
            'start_afternoon': null,
            'end_afternoon': null,
          }
        ]),
      );
      final writer = AttendanceRemoteWriter(
        httpClient: c,
        baseUrl: baseUrl,
        anonKey: 'anon',
      );

      final resultat = await writer.write(
        decision: AttendanceDecision(
          action: AttendanceAction.clockIn,
          at: DateTime(2026, 11, 4, 8, 3),
          reason: 'test',
        ),
        userId: userId,
        accessToken: 'jwt',
        now: DateTime(2026, 11, 4, 8, 3),
      );

      expect(resultat.status, RemoteWriteStatus.alreadyFilled);
      // Une seule requête : la lecture. Aucune écriture.
      expect(c.requests.length, 1);
      expect(c.requests.single.method, 'GET');
    });

    test('complete une colonne vide sur une ligne existante', () async {
      final c = client(
        body: jsonEncode([
          {
            'id': 'ligne-1',
            'start_morning': '08:03',
            'end_morning': null,
            'start_afternoon': null,
            'end_afternoon': null,
          }
        ]),
      );
      final writer = AttendanceRemoteWriter(
        httpClient: c,
        baseUrl: baseUrl,
        anonKey: 'anon',
      );

      final resultat = await writer.write(
        decision: AttendanceDecision(
          action: AttendanceAction.clockOut,
          at: DateTime(2026, 11, 4, 17, 20),
          reason: 'test',
        ),
        userId: userId,
        accessToken: 'jwt',
        now: DateTime(2026, 11, 4, 17, 20),
      );

      expect(resultat.status, RemoteWriteStatus.written);
      final ecriture = c.requests.last;
      expect(ecriture.method, 'PATCH');
      final corps = jsonDecode(ecriture.body) as Map<String, dynamic>;
      expect(corps['end_afternoon'], '17:20');
      // L'heure d'arrivée existante ne doit pas figurer dans le PATCH.
      expect(corps.containsKey('start_morning'), isFalse);
    });
  });

  group('robustesse réseau', () {
    test('garde la décision en file si le réseau échoue', () async {
      final c = _FailingClient();
      final writer = AttendanceRemoteWriter(
        httpClient: c,
        baseUrl: baseUrl,
        anonKey: 'anon',
      );

      final resultat = await writer.write(
        decision: AttendanceDecision(
          action: AttendanceAction.clockIn,
          at: DateTime(2026, 11, 4, 8),
          reason: 'test',
        ),
        userId: userId,
        accessToken: 'jwt',
        now: DateTime(2026, 11, 4, 8),
      );

      expect(resultat.status, RemoteWriteStatus.failed);
      expect(resultat.shouldKeepInQueue, isTrue);
    });

    test('garde la décision en file si le jeton est refusé', () async {
      final c = client(status: 401, body: '{"message":"JWT expired"}');
      final writer = AttendanceRemoteWriter(
        httpClient: c,
        baseUrl: baseUrl,
        anonKey: 'anon',
      );

      final resultat = await writer.write(
        decision: AttendanceDecision(
          action: AttendanceAction.clockIn,
          at: DateTime(2026, 11, 4, 8),
          reason: 'test',
        ),
        userId: userId,
        accessToken: 'jwt-expire',
        now: DateTime(2026, 11, 4, 8),
      );

      expect(resultat.status, RemoteWriteStatus.failed);
      expect(resultat.shouldKeepInQueue, isTrue);
    });

    test('borne l appel pour tenir dans le budget iOS', () async {
      // Apple accorde ~10 s (30 s au plus avec beginBackgroundTask) : un appel
      // sans délai maximal peut consommer tout le budget et se faire tuer
      // avant d'avoir écrit.
      final writer = AttendanceRemoteWriter(
        httpClient: client(),
        baseUrl: baseUrl,
        anonKey: 'anon',
      );
      expect(writer.timeout.inSeconds, lessThanOrEqualTo(8));
      expect(writer.timeout.inSeconds, greaterThanOrEqualTo(3));
    });

    test('envoie le jeton et la cle anon sur chaque appel', () async {
      final c = client();
      final writer = AttendanceRemoteWriter(
        httpClient: c,
        baseUrl: baseUrl,
        anonKey: 'anon-abc',
      );
      await writer.write(
        decision: AttendanceDecision(
          action: AttendanceAction.clockIn,
          at: DateTime(2026, 11, 4, 8),
          reason: 'test',
        ),
        userId: userId,
        accessToken: 'jwt-xyz',
        now: DateTime(2026, 11, 4, 8),
      );

      for (final r in c.requests) {
        expect(r.headers['Authorization'], 'Bearer jwt-xyz');
        expect(r.headers['apikey'], 'anon-abc');
      }
    });
  });
}

class _RecordedRequest {
  _RecordedRequest(this.method, this.url, this.headers, this.body);
  final String method;
  final String url;
  final Map<String, String> headers;
  final String body;
}

class _FakeClient extends http.BaseClient {
  _FakeClient({required this.status, required this.body});
  final int status;
  final String body;
  final List<_RecordedRequest> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final corps =
        request is http.Request ? request.body : '';
    requests.add(_RecordedRequest(
      request.method,
      request.url.toString(),
      request.headers,
      corps,
    ));
    // La lecture rend le corps programmé ; l'écriture rend un succès nu.
    final estLecture = request.method == 'GET';
    return http.StreamedResponse(
      Stream.value(utf8.encode(estLecture ? body : '[]')),
      estLecture ? (status == 401 ? 401 : 200) : status,
    );
  }
}

class _FailingClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw http.ClientException('réseau indisponible');
  }
}
