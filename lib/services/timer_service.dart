import 'dart:async';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimerService {
  static final TimerService _instance = TimerService._internal();

  factory TimerService() {
    return _instance;
  }

  TimerService._internal();

  // État du timer
  DateTime? _startTime;
  Duration _accumulatedTime = Duration.zero;
  Duration _elapsedTime = Duration.zero;
  String _currentState = 'Non commencé';
  DateTime? _lastUpdateTime;
  Timer? _timer;

  // Getters
  DateTime? get startTime => _startTime;
  Duration get accumulatedTime => _accumulatedTime;
  Duration get elapsedTime => _elapsedTime;
  String get currentState => _currentState;

  // Initialiser le service
  Future<void> initialize(String etatActuel, DateTime? dernierPointage) async {
    _currentState = etatActuel;

    if (etatActuel == 'Non commencé' || etatActuel == 'Sortie') {
      _startTime = null;
      _accumulatedTime = Duration.zero;
      _elapsedTime = Duration.zero;
      await _saveTimerState();
      return;
    }

    // Charger l'état sauvegardé et calculer le temps écoulé depuis la dernière fermeture
    final bool stateLoaded = await _loadSavedTimerState();

    // Si nous avons un dernier pointage et que nous sommes en mode actif
    if (dernierPointage != null &&
        (etatActuel == 'Entrée' || etatActuel == 'Reprise')) {
      // Si nous n'avons pas pu charger l'état ou si nous sommes un nouveau jour
      if (!stateLoaded) {
        // Utiliser le dernier pointage comme référence
        final now = DateTime.now();
        final today = DateFormat('yyyy-MM-dd').format(now);
        final pointageDay = DateFormat('yyyy-MM-dd').format(dernierPointage);

        // Si le pointage est d'aujourd'hui et que nous sommes en mode actif
        if (today == pointageDay &&
            (etatActuel == 'Entrée' || etatActuel == 'Reprise')) {
          // Calculer le temps écoulé depuis le dernier pointage
          _accumulatedTime = Duration.zero;
          _startTime = dernierPointage;
          _elapsedTime = now.difference(_startTime!);
          await _saveTimerState();
        }
      }
    }

    // Démarrer le timer si nécessaire
    if ((etatActuel == 'Entrée' || etatActuel == 'Reprise') && _timer == null) {
      _startTimer();
    }
  }

  // Charger l'état sauvegardé du timer
  Future<bool> _loadSavedTimerState() async {
    if (_currentState == 'Non commencé' || _currentState == 'Sortie') {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    // Nous n'utilisons plus cette variable, mais la gardons pour référence future
    // final savedStartTimeMillis = prefs.getInt('timer_start_time');
    final savedAccumulatedTimeMillis = prefs.getInt('timer_accumulated_time');
    final savedElapsedTimeMillis = prefs.getInt('timer_elapsed_time');
    final savedLastUpdateTimeMillis = prefs.getInt('timer_last_update_time');
    final savedState = prefs.getString('timer_etat_actuel');
    final savedDate = prefs.getString('timer_date');

    // Vérifier si les données sauvegardées sont pour aujourd'hui
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    // Débug: afficher les valeurs sauvegardées
    print('Saved date: $savedDate, today: $today');
    print('Saved elapsed time: ${savedElapsedTimeMillis != null ? Duration(milliseconds: savedElapsedTimeMillis).inSeconds : "null"} seconds');
    print('Saved accumulated time: ${savedAccumulatedTimeMillis != null ? Duration(milliseconds: savedAccumulatedTimeMillis).inSeconds : "null"} seconds');

    if (savedDate == today) {
      // Toujours utiliser le temps écoulé sauvegardé s'il existe
      if (savedElapsedTimeMillis != null) {
        _elapsedTime = Duration(milliseconds: savedElapsedTimeMillis);
        print('Restored elapsed time: ${_elapsedTime.inSeconds} seconds');
      }

      // Toujours charger le temps accumulé s'il existe
      if (savedAccumulatedTimeMillis != null) {
        _accumulatedTime = Duration(milliseconds: savedAccumulatedTimeMillis);
        print('Restored accumulated time: ${_accumulatedTime.inSeconds} seconds');
      }

      if (_currentState == 'Entrée' || _currentState == 'Reprise') {
        // Si nous avons une heure de dernière mise à jour, calculer le temps écoulé depuis
        if (savedLastUpdateTimeMillis != null) {
          DateTime lastUpdate = DateTime.fromMillisecondsSinceEpoch(savedLastUpdateTimeMillis);
          Duration timeOffline = now.difference(lastUpdate);
          
          // Ajouter le temps hors ligne si nous étions en mode actif
          if (savedState == 'Entrée' || savedState == 'Reprise') {
            if (timeOffline.inHours < 12) { // Limite raisonnable
              _accumulatedTime += timeOffline;
              _elapsedTime = _accumulatedTime;
              print('Added offline time: ${timeOffline.inSeconds} seconds');
              print('New elapsed time: ${_elapsedTime.inSeconds} seconds');
            }
          }
        }
        
        // Toujours démarrer le timer à partir de maintenant
        _startTime = now;
      } else if (_currentState == 'Pause') {
        // En pause, pas de temps de démarrage
        _startTime = null;
        // S'assurer que le temps écoulé est égal au temps accumulé
        _elapsedTime = _accumulatedTime;
      }

      return true;
    }

    return false;
  }

  // Sauvegarder l'état du timer
  Future<void> _saveTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    // Toujours sauvegarder l'heure de la dernière mise à jour
    await prefs.setInt('timer_last_update_time', now.millisecondsSinceEpoch);

    // Débug: afficher ce que nous sauvegardons
    print('Saving timer state: currentState=$_currentState');
    
    if (_currentState == 'Entrée' || _currentState == 'Reprise') {
      // Calculer le temps écoulé actuel
      Duration currentElapsedTime;
      if (_startTime != null) {
        currentElapsedTime = _accumulatedTime + now.difference(_startTime!);
      } else {
        // Si pas de startTime, utiliser directement elapsedTime
        currentElapsedTime = _elapsedTime;
      }
      
      print('Saving elapsed time: ${currentElapsedTime.inSeconds} seconds');
      print('Saving accumulated time: ${_accumulatedTime.inSeconds} seconds');
      
      // Toujours sauvegarder le temps de démarrage actuel
      if (_startTime != null) {
        await prefs.setInt('timer_start_time', _startTime!.millisecondsSinceEpoch);
      }
      
      await prefs.setInt('timer_accumulated_time', _accumulatedTime.inMilliseconds);
      await prefs.setString('timer_etat_actuel', _currentState);
      await prefs.setString('timer_date', today);
      await prefs.setInt('timer_elapsed_time', currentElapsedTime.inMilliseconds);
    } else if (_currentState == 'Pause') {
      // En pause, on sauvegarde le temps accumulé mais pas l'heure de démarrage
      await prefs.remove('timer_start_time');
      
      print('Saving in PAUSE - elapsed time: ${_elapsedTime.inSeconds} seconds');
      print('Saving in PAUSE - accumulated time: ${_accumulatedTime.inSeconds} seconds');
      
      await prefs.setInt('timer_accumulated_time', _accumulatedTime.inMilliseconds);
      await prefs.setString('timer_etat_actuel', _currentState);
      await prefs.setString('timer_date', today);
      await prefs.setInt('timer_elapsed_time', _elapsedTime.inMilliseconds);
    } else if (_currentState == 'Sortie' || _currentState == 'Non commencé') {
      // Effacer les données sauvegardées si la journée est terminée
      print('Clearing timer state');
      await prefs.remove('timer_start_time');
      await prefs.remove('timer_accumulated_time');
      await prefs.remove('timer_etat_actuel');
      await prefs.remove('timer_elapsed_time');
      // Garder la date pour référence
      await prefs.setString('timer_date', today);
    }
  }

  // Démarrer le timer
  void _startTimer() {
    // Annuler le timer existant s'il y en a un
    _timer?.cancel();
    _timer = null;
    
    print('Starting timer in state: $_currentState');
    print('Current elapsed time: ${_elapsedTime.inSeconds} seconds');
    print('Current accumulated time: ${_accumulatedTime.inSeconds} seconds');

    if (_currentState == 'Non commencé' || _currentState == 'Sortie') {
      _startTime = null;
      _accumulatedTime = Duration.zero;
      _elapsedTime = Duration.zero;
      _saveTimerState();
      return;
    }

    // Pour Entrée ou Reprise, on démarre le timer maintenant
    if (_currentState == 'Entrée' || _currentState == 'Reprise') {
      _startTime = DateTime.now();
      // Pour Entrée, on réinitialise le temps accumulé
      if (_currentState == 'Entrée') {
        _accumulatedTime = Duration.zero;
        _elapsedTime = Duration.zero;
      }
    }

    _saveTimerState();

    // Créer un nouveau timer qui s'exécute chaque seconde
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Mise à jour du temps écoulé selon l'état actuel
      switch (_currentState) {
        case 'Entrée':
        case 'Reprise':
          // Si on est en mode actif et qu'on a une heure de démarrage
          if (_startTime != null) {
            // Calculer le temps écoulé = temps accumulé + temps depuis le démarrage
            _elapsedTime = _accumulatedTime + DateTime.now().difference(_startTime!);
          }
          break;

        case 'Pause':
          // Si on vient juste de passer en pause et qu'on a une heure de démarrage
          if (_startTime != null) {
            // Ajouter le temps depuis le démarrage au temps accumulé
            _accumulatedTime += DateTime.now().difference(_startTime!);
            _startTime = null;
            _elapsedTime = _accumulatedTime;
            _saveTimerState();
          }
          break;

        case 'Sortie':
        case 'Non commencé':
          // Arrêter le timer si on est en mode inactif
          _timer?.cancel();
          _timer = null;
          _startTime = null;
          _accumulatedTime = Duration.zero;
          _elapsedTime = Duration.zero;
          _saveTimerState();
          break;
      }
    });
  }

  // Mettre à jour l'état du timer
  void updateState(String newState, DateTime? dernierPointage) {
    // Nous n'utilisons plus cette variable
    // bool stateChanged = _currentState != newState;
    String oldState = _currentState;
    _currentState = newState;

    print('Timer state changing from $oldState to $newState');
    print('Current elapsed time: ${_elapsedTime.inSeconds} seconds');
    print('Current accumulated time: ${_accumulatedTime.inSeconds} seconds');

    if (newState == 'Non commencé' || newState == 'Sortie') {
      // Réinitialiser le timer
      _startTime = null;
      _accumulatedTime = Duration.zero;
      _elapsedTime = Duration.zero;
      _timer?.cancel();
      _timer = null;
    } else if (newState == 'Pause') {
      // Si on passe en pause, on accumule le temps écoulé jusqu'à maintenant
      if (_startTime != null) {
        _accumulatedTime += DateTime.now().difference(_startTime!);
        _elapsedTime = _accumulatedTime;
        _startTime = null;
      }
      // On ne cancel pas le timer, on le laisse tourner pour mettre à jour l'UI
    } else if (newState == 'Entrée' || newState == 'Reprise') {
      // Si on démarre ou reprend, on met à jour le startTime
      _startTime = DateTime.now();
      
      // Si on vient de 'Non commencé' et qu'on passe à 'Entrée', réinitialiser
      if (oldState == 'Non commencé' && newState == 'Entrée') {
        _accumulatedTime = Duration.zero;
        _elapsedTime = Duration.zero;
      }
      
      // Démarrer ou redémarrer le timer si nécessaire
      if (_timer == null) {
        _startTimer();
      }
    }

    _saveTimerState();
  }

  // Gérer l'application qui passe en arrière-plan
  void appPaused() {
    _lastUpdateTime = DateTime.now();
    _saveTimerState();
  }

  // Gérer l'application qui revient au premier plan
  void appResumed() {
    final now = DateTime.now();

    if (_lastUpdateTime != null) {
      final timeInBackground = now.difference(_lastUpdateTime!);

      // Si plus de 30 secondes se sont écoulées en arrière-plan
      if (timeInBackground.inSeconds > 30) {
        _loadSavedTimerState();
      } else if (_startTime != null &&
          (_currentState == 'Entrée' || _currentState == 'Reprise')) {
        // Pour de courtes périodes, ajuster simplement le temps de démarrage
        _startTime = _startTime!.add(timeInBackground);
      }
    } else {
      _loadSavedTimerState();
    }

    // Si nous sommes en mode actif mais sans timer, le démarrer
    if ((_currentState == 'Entrée' || _currentState == 'Reprise') &&
        _timer == null) {
      _startTimer();
    }
  }

  // Arrêter le timer
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
