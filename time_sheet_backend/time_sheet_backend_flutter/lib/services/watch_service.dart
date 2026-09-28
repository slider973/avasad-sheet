import 'dart:async';
import 'package:watch_connectivity/watch_connectivity.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

/// Actions de pointage qu'une Apple Watch peut demander.
///
/// La montre demande, l'application décide : c'est `TimeSheetBloc` qui applique
/// la transition réellement valide pour la journée en cours, puis renvoie
/// l'état résultant. Une montre restée sur un écran périmé ne peut donc pas
/// écrire un pointage incohérent.
enum WatchPointageAction {
  /// Pointer l'étape suivante, quelle qu'elle soit. C'est le message envoyé
  /// par le bouton principal de l'app watchOS.
  toggle,
  enter,
  startBreak,
  endBreak,
  exit;

  static WatchPointageAction? fromWire(String raw) => switch (raw) {
        'toggle' => WatchPointageAction.toggle,
        'entry' => WatchPointageAction.enter,
        'break' => WatchPointageAction.startBreak,
        'resume' => WatchPointageAction.endBreak,
        'exit' => WatchPointageAction.exit,
        _ => null,
      };
}

/// Demande de pointage reçue de la montre, horodatée à l'instant du geste.
///
/// L'heure est portée par le message et non relue à l'arrivée : une demande
/// mise en file par `transferUserInfo` (iPhone endormi, hors de portée) peut
/// être livrée plusieurs minutes plus tard. Pointer avec `DateTime.now()`
/// écrirait alors une heure fausse.
class WatchPointageRequest {
  final WatchPointageAction action;
  final DateTime occurredAt;

  const WatchPointageRequest(this.action, this.occurredAt);

  @override
  String toString() => 'WatchPointageRequest($action, $occurredAt)';
}

/// Pont WatchConnectivity entre l'application iOS et l'app watchOS.
///
/// Deux canaux, complémentaires et tous deux nécessaires :
/// * `sendMessage` — instantané, mais exige que la montre soit *reachable*
///   (app watch au premier plan ou en session active). Sert au retour immédiat.
/// * `updateApplicationContext` — persistant : le système livre le dernier
///   contexte au prochain réveil de l'app watch. C'est lui qui garantit qu'une
///   montre rallumée plus tard affiche le bon état.
class WatchService {
  final Logger logger = GetIt.I<Logger>();
  final _watchConnectivity = WatchConnectivity();

  final _stateController = StreamController<String>.broadcast();
  final _actionController =
      StreamController<WatchPointageRequest>.broadcast();

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// État de pointage tel que l'application le connaît, rediffusé à l'UI.
  Stream<String> get stateStream => _stateController.stream;

  /// Demandes de pointage émises par la montre. `TimeSheetBloc` s'y abonne.
  Stream<WatchPointageRequest> get actionStream => _actionController.stream;

  String _currentState = 'Non commencé';
  String get currentState => _currentState;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  bool _isPaired = false;
  bool get isPaired => _isPaired;

  Future<void> initialize() async {
    try {
      final isSupported = await _watchConnectivity.isSupported;
      if (!isSupported) {
        logger.w('[Watch] WatchConnectivity non supporté sur cet appareil');
        return;
      }

      // Les écouteurs sont branchés AVANT tout appel réseau : un message
      // arrivant pendant l'initialisation ne doit pas être perdu.
      _setupListeners();

      _isPaired = await _watchConnectivity.isPaired;
      _isConnected = await _watchConnectivity.isReachable;

      logger.i('[Watch] Initialisé — appairée: $_isPaired, '
          'joignable: $_isConnected');

      // Le contexte est publié même montre absente : il sera livré au premier
      // lancement de l'app watch.
      await sendState(_currentState);
    } catch (e, stack) {
      logger.e('[Watch] Échec de l\'initialisation: $e', stackTrace: stack);
    }
  }

  void _setupListeners() {
    _subscriptions.add(
      _watchConnectivity.messageStream.listen(
        _handleWatchMessage,
        onError: (Object e) => logger.e('[Watch] Erreur messageStream: $e'),
      ),
    );

    // `contextStream` était auparavant lu une seule fois via `.then` : les
    // contextes suivants étaient ignorés.
    _subscriptions.add(
      _watchConnectivity.contextStream.listen(
        _handleWatchMessage,
        onError: (Object e) => logger.e('[Watch] Erreur contextStream: $e'),
      ),
    );
  }

  void _handleWatchMessage(Map<String, dynamic> message) {
    logger.i('[Watch] Message reçu: $message');

    final rawAction = message['action'];
    if (rawAction is! String) return;

    final action = WatchPointageAction.fromWire(rawAction);
    if (action == null) {
      logger.w('[Watch] Action inconnue ignorée: $rawAction');
      return;
    }

    // Un message entrant prouve que la montre est joignable.
    _isConnected = true;

    // L'état local n'est PAS modifié ici : seul le bloc, après écriture
    // effective du pointage, fait autorité. Sans quoi l'UI afficherait une
    // transition qui n'a pas eu lieu.
    _actionController.add(WatchPointageRequest(action, _readTimestamp(message)));
  }

  /// Heure du geste, telle qu'envoyée par la montre.
  ///
  /// Repli sur l'heure courante si le champ est absent ou illisible : mieux
  /// vaut un pointage à l'heure d'arrivée qu'un pointage perdu. Une heure
  /// future est ramenée à maintenant — une montre déréglée ne doit pas écrire
  /// un pointage dans le futur.
  DateTime _readTimestamp(Map<String, dynamic> message) {
    final raw = message['timestamp'];
    final now = DateTime.now();
    if (raw is! String) return now;

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      logger.w('[Watch] Horodatage illisible ($raw), heure courante utilisée');
      return now;
    }

    final local = parsed.toLocal();
    return local.isAfter(now) ? now : local;
  }

  /// Rafraîchit la joignabilité. `isReachable` n'a pas de stream côté plugin ;
  /// il faut donc l'interroger avant un envoi qui doit aboutir.
  Future<bool> refreshConnection() async {
    try {
      _isPaired = await _watchConnectivity.isPaired;
      _isConnected = await _watchConnectivity.isReachable;
    } catch (e) {
      logger.w('[Watch] Impossible de rafraîchir la connexion: $e');
      _isConnected = false;
    }
    return _isConnected;
  }

  /// Publie l'état de pointage vers la montre et vers l'UI de l'app.
  Future<void> sendState(String state) async {
    _currentState = state;
    if (!_stateController.isClosed) _stateController.add(state);

    final payload = {
      'state': state,
      'lastUpdate': DateTime.now().toIso8601String(),
    };

    // Le contexte d'abord : il survit à l'absence de la montre, alors qu'un
    // message échoue si elle n'est pas joignable.
    try {
      await _watchConnectivity.updateApplicationContext(payload);
    } catch (e) {
      logger.w('[Watch] updateApplicationContext a échoué: $e');
    }

    try {
      if (await refreshConnection()) {
        await _watchConnectivity.sendMessage({
          'type': 'stateUpdate',
          ...payload,
        });
      }
    } catch (e) {
      logger.w('[Watch] sendMessage a échoué: $e');
    }

    logger.i('[Watch] État publié: $state');
  }

  Future<void> sendPointageConfirmation(String action) async {
    try {
      if (await refreshConnection()) {
        await _watchConnectivity.sendMessage({
          'type': 'confirmation',
          'action': action,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      logger.w('[Watch] Confirmation non transmise: $e');
    }
  }

  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();
    _stateController.close();
    _actionController.close();
  }
}
