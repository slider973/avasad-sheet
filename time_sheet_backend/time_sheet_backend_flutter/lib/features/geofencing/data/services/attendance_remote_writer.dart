import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:time_sheet/features/geofencing/domain/entities/attendance_decision.dart';

/// Issue d'une tentative d'écriture directe depuis l'arrière-plan.
enum RemoteWriteStatus {
  /// Le pointage est enregistré côté serveur.
  written,

  /// La colonne visée portait déjà une valeur : rien n'a été touché.
  alreadyFilled,

  /// L'action ne correspond à aucun horaire (confirmation attendue, etc.).
  skipped,

  /// Pas de jeton exploitable : l'appel n'a même pas été tenté.
  noCredentials,

  /// Réseau indisponible, serveur en erreur, ou jeton refusé.
  failed,
}

class RemoteWriteResult {
  const RemoteWriteResult(this.status, {this.detail});

  final RemoteWriteStatus status;
  final String? detail;

  /// Faut-il conserver la décision dans la file pour un rejeu à l'ouverture ?
  ///
  /// Oui dès que l'écriture n'a pas abouti pour une raison transitoire. Non
  /// quand elle a réussi, quand la valeur existait déjà, ou quand l'action
  /// n'avait pas vocation à produire un horaire — rejouer ces cas créerait un
  /// doublon ou écraserait une saisie manuelle.
  bool get shouldKeepInQueue =>
      status == RemoteWriteStatus.failed ||
      status == RemoteWriteStatus.noCredentials;
}

/// Écrit un pointage directement dans PostgREST, depuis l'isolate
/// d'arrière-plan du géorepérage.
///
/// **Pourquoi cette classe existe.** Core Location relance l'application à
/// chaque franchissement de zone, y compris application tuée, et lui accorde
/// « environ 10 secondes » (documentation Apple, *Region Monitoring*), portées
/// à 30 au plus par `beginBackgroundTask`. C'est très court pour du Bluetooth,
/// mais amplement suffisant pour un appel HTTPS.
///
/// PowerSync, lui, n'est pas utilisable ici : il réclame GetIt, une base SQLite
/// ouverte et une initialisation complète, dont rien n'existe dans cet isolate.
/// La file d'attente seule ne suffisait pas — tant que l'utilisateur n'ouvrait
/// pas l'application, aucun pointage n'était enregistré, ce qui vide la
/// fonctionnalité de son sens.
///
/// L'appel passe par PostgREST plutôt que par le client Supabase : ce dernier
/// suppose lui aussi une initialisation applicative absente de l'isolate.
class AttendanceRemoteWriter {
  AttendanceRemoteWriter({
    required http.Client httpClient,
    required String baseUrl,
    required String anonKey,
    this.timeout = const Duration(seconds: 6),
  })  : _http = httpClient,
        _baseUrl = baseUrl,
        _anonKey = anonKey;

  final http.Client _http;
  final String _baseUrl;
  final String _anonKey;

  /// Délai maximal d'un appel.
  ///
  /// Volontairement inférieur au budget de 10 s : au-delà, le système peut
  /// suspendre l'application avant que l'écriture n'aboutisse, et l'appel
  /// aurait consommé le temps sans rien produire.
  final Duration timeout;

  /// Colonne de la feuille de temps visée par chaque action.
  ///
  /// Les actions absentes de cette table ne produisent aucun horaire :
  /// `askAmbiguity` attend une réponse de l'utilisateur, `reconcile` recolle un
  /// état incohérent et `none` ne décide rien. Les écrire fabriquerait un
  /// pointage que personne n'a demandé.
  static const Map<AttendanceAction, String> _columnByAction = {
    AttendanceAction.clockIn: 'start_morning',
    AttendanceAction.startBreak: 'end_morning',
    AttendanceAction.endBreak: 'start_afternoon',
    AttendanceAction.clockOut: 'end_afternoon',
  };

  Future<RemoteWriteResult> write({
    required AttendanceDecision decision,
    required String userId,
    required String? accessToken,
    required DateTime now,
  }) async {
    final column = _columnByAction[decision.action];
    if (column == null) {
      return const RemoteWriteResult(
        RemoteWriteStatus.skipped,
        detail: 'action sans horaire',
      );
    }

    // Un jeton absent ou vide ne sert à rien : ne pas dépenser le budget
    // d'arrière-plan sur un appel qui sera refusé.
    if (accessToken == null || accessToken.isEmpty) {
      return const RemoteWriteResult(
        RemoteWriteStatus.noCredentials,
        detail: 'jeton indisponible',
      );
    }

    // L'heure inscrite est celle du FRANCHISSEMENT (`decision.at`), jamais
    // celle de l'envoi : le réveil peut survenir plusieurs minutes après.
    final dayDate = _formatDate(decision.at);
    final heure = formatTime(decision.at);

    final headers = {
      'Authorization': 'Bearer $accessToken',
      'apikey': _anonKey,
      'Content-Type': 'application/json',
    };

    try {
      final existante = await _findEntry(
        userId: userId,
        dayDate: dayDate,
        headers: headers,
      );

      if (existante == null) {
        return await _insert(
          userId: userId,
          dayDate: dayDate,
          column: column,
          heure: heure,
          decision: decision,
          now: now,
          headers: headers,
        );
      }

      // Ne jamais écraser une valeur déjà présente : l'utilisateur a pu
      // corriger son heure à la main, et l'arrière-plan n'a pas à trancher
      // contre lui.
      final dejaRempli = existante[column];
      if (dejaRempli != null && (dejaRempli as String).isNotEmpty) {
        return RemoteWriteResult(
          RemoteWriteStatus.alreadyFilled,
          detail: '$column déjà renseigné à $dejaRempli',
        );
      }

      return await _patch(
        id: existante['id'] as String,
        column: column,
        heure: heure,
        now: now,
        headers: headers,
      );
    } on http.ClientException catch (e) {
      return RemoteWriteResult(RemoteWriteStatus.failed, detail: e.message);
    } catch (e) {
      // Tout échec non prévu doit laisser la décision en file plutôt que de
      // perdre le pointage.
      return RemoteWriteResult(RemoteWriteStatus.failed, detail: '$e');
    }
  }

  Future<Map<String, dynamic>?> _findEntry({
    required String userId,
    required String dayDate,
    required Map<String, String> headers,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/rest/v1/timesheet_entries'
      '?user_id=eq.$userId&day_date=eq.$dayDate'
      '&select=id,start_morning,end_morning,start_afternoon,end_afternoon'
      '&limit=1',
    );

    final reponse = await _http.get(uri, headers: headers).timeout(timeout);
    if (reponse.statusCode < 200 || reponse.statusCode >= 300) {
      throw http.ClientException(
        'lecture refusée (${reponse.statusCode})',
        uri,
      );
    }

    final corps = jsonDecode(reponse.body);
    if (corps is! List || corps.isEmpty) return null;
    return Map<String, dynamic>.from(corps.first as Map);
  }

  Future<RemoteWriteResult> _insert({
    required String userId,
    required String dayDate,
    required String column,
    required String heure,
    required AttendanceDecision decision,
    required DateTime now,
    required Map<String, String> headers,
  }) async {
    final uri = Uri.parse('$_baseUrl/rest/v1/timesheet_entries');
    final corps = <String, dynamic>{
      'user_id': userId,
      'day_date': dayDate,
      'day_of_week': _dayOfWeek(decision.at),
      column: heure,
      // `period` est posé dès la création : une ligne sans période se lit comme
      // une saisie en masse et déclenche de faux diagnostics.
      'period': 'Journée complète',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    final reponse = await _http
        .post(uri, headers: headers, body: jsonEncode(corps))
        .timeout(timeout);

    if (reponse.statusCode < 200 || reponse.statusCode >= 300) {
      return RemoteWriteResult(
        RemoteWriteStatus.failed,
        detail: 'création refusée (${reponse.statusCode})',
      );
    }
    return const RemoteWriteResult(RemoteWriteStatus.written);
  }

  Future<RemoteWriteResult> _patch({
    required String id,
    required String column,
    required String heure,
    required DateTime now,
    required Map<String, String> headers,
  }) async {
    final uri =
        Uri.parse('$_baseUrl/rest/v1/timesheet_entries?id=eq.$id');

    // Le corps ne porte QUE la colonne visée : envoyer les autres risquerait
    // de réécrire une valeur corrigée entre-temps.
    final corps = <String, dynamic>{
      column: heure,
      'updated_at': now.toIso8601String(),
    };

    final reponse = await _http
        .patch(uri, headers: headers, body: jsonEncode(corps))
        .timeout(timeout);

    if (reponse.statusCode < 200 || reponse.statusCode >= 300) {
      return RemoteWriteResult(
        RemoteWriteStatus.failed,
        detail: 'mise à jour refusée (${reponse.statusCode})',
      );
    }
    return const RemoteWriteResult(RemoteWriteStatus.written);
  }

  /// `HH:mm`, format des colonnes horaires de la table.
  static String formatTime(DateTime at) =>
      '${at.hour.toString().padLeft(2, '0')}:'
      '${at.minute.toString().padLeft(2, '0')}';

  /// `YYYY-MM-DD`, format de `day_date` **en base**.
  ///
  /// À ne pas confondre avec `dd-MMM-yy`, utilisé par l'entité Flutter.
  static String _formatDate(DateTime at) =>
      '${at.year.toString().padLeft(4, '0')}-'
      '${at.month.toString().padLeft(2, '0')}-'
      '${at.day.toString().padLeft(2, '0')}';

  static String _dayOfWeek(DateTime at) {
    const jours = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
    return jours[at.weekday - 1];
  }
}
