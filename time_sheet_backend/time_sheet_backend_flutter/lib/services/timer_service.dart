import 'dart:async';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_sheet/services/weekend_detection_service.dart';
import 'package:time_sheet/services/overtime_configuration_service.dart';
import 'package:time_sheet/services/work_time_calculator_service.dart';
import 'package:time_sheet/services/logger_service.dart';
import 'package:time_sheet/features/pointage/domain/entities/extended_timer_state.dart';
import 'package:time_sheet/features/pointage/domain/entities/work_time_info.dart';
import 'package:time_sheet/features/pointage/domain/entities/work_time_configuration.dart';

// Classe pour encapsuler les données sauvegardées
class _SavedTimerData {
  final int? savedAccumulatedTimeMillis;
  final int? savedElapsedTimeMillis;
  final int? savedLastUpdateTimeMillis;
  final String? savedState;
  final String? savedDate;

  _SavedTimerData({
    this.savedAccumulatedTimeMillis,
    this.savedElapsedTimeMillis,
    this.savedLastUpdateTimeMillis,
    this.savedState,
    this.savedDate,
  });
}

class TimerService {
  static final TimerService _instance = TimerService._internal();

  factory TimerService() {
    return _instance;
  }

  TimerService._internal();

  // Services for weekend detection, overtime configuration, and work time calculations
  final WeekendDetectionService _weekendDetectionService =
      WeekendDetectionService();
  final OvertimeConfigurationService _overtimeConfigService =
      OvertimeConfigurationService();
  final WorkTimeCalculatorService _workTimeCalculatorService =
      WorkTimeCalculatorService();

  // État du timer
  DateTime? _startTime;
  Duration _accumulatedTime = Duration.zero;
  Duration _elapsedTime = Duration.zero;
  String _currentState = 'Non commencé';
  DateTime? _lastUpdateTime;
  Timer? _timer;

  // Weekend and overtime tracking
  bool _isWeekendDay = false;
  bool _weekendOvertimeEnabled = true;

  // Getters
  DateTime? get startTime => _startTime;
  Duration get accumulatedTime => _accumulatedTime;
  // Getter pour le temps écoulé - calcule en temps réel avec synchronisation
  Duration get elapsedTime {
    final now = DateTime.now();

    if (_startTime != null &&
        (_currentState == 'Entrée' || _currentState == 'Reprise')) {
      final currentElapsed = _accumulatedTime + now.difference(_startTime!);
      // Assurer la cohérence : pas de temps négatif
      return currentElapsed.isNegative ? Duration.zero : currentElapsed;
    }

    // En pause ou arrêté, retourner le temps accumulé
    return _accumulatedTime.isNegative ? Duration.zero : _accumulatedTime;
  }

  String get currentState => _currentState;

  // Weekend and overtime getters
  bool get isWeekendDay => _isWeekendDay;
  bool get weekendOvertimeEnabled => _weekendOvertimeEnabled;

  /// Returns true if current work session should be considered overtime
  bool get isOvertimeSession {
    if (_isWeekendDay && _weekendOvertimeEnabled) {
      return true; // All weekend work is overtime when enabled
    }

    // For weekdays, check if we've exceeded the daily threshold
    final dailyThreshold =
        Duration(hours: 8); // Default 8 hours, could be configurable
    return elapsedTime > dailyThreshold;
  }

  // Initialiser le service
  Future<void> initialize(String etatActuel, DateTime? dernierPointage) async {
    _currentState = etatActuel;

    // Detect weekend status and load overtime configuration
    await _updateWeekendStatus();

    // Initialize work time calculator with current configuration
    await _initializeWorkTimeCalculator();

    // D'abord, toujours essayer de charger l'état sauvegardé pour aujourd'hui
    final bool stateLoaded = await _loadSavedTimerState();

    if (etatActuel == 'Non commencé' || etatActuel == 'Sortie') {
      // Si on a terminé la journée ou on n'a pas encore commencé
      if (!stateLoaded || etatActuel == 'Non commencé') {
        _startTime = null;
        _accumulatedTime = Duration.zero;
        _elapsedTime = Duration.zero;
        await _saveTimerState();
      }
      return;
    }

    // Si nous sommes en mode actif (Entrée ou Reprise)
    if (etatActuel == 'Entrée' || etatActuel == 'Reprise') {
      // Si nous n'avons pas pu charger l'état sauvegardé
      if (!stateLoaded) {
        final now = DateTime.now();

        // Si nous avons un dernier pointage
        if (dernierPointage != null) {
          final today = DateFormat('yyyy-MM-dd').format(now);
          final pointageDay = DateFormat('yyyy-MM-dd').format(dernierPointage);

          // Si le pointage est d'aujourd'hui
          if (today == pointageDay) {
            // Calculer le temps écoulé depuis le dernier pointage
            _accumulatedTime = Duration.zero;
            _startTime = dernierPointage;
            _elapsedTime = now.difference(_startTime!);
          } else {
            // Pointage d'un jour précédent, commencer à zéro
            _accumulatedTime = Duration.zero;
            _startTime = now;
            _elapsedTime = Duration.zero;
          }
        } else {
          // Pas de dernier pointage (premier pointage du jour)
          // Initialiser à zéro et commencer maintenant
          _accumulatedTime = Duration.zero;
          _startTime = now;
          _elapsedTime = Duration.zero;
        }

        await _saveTimerState();
      }
    }

    // Démarrer le timer si nécessaire
    if ((etatActuel == 'Entrée' || etatActuel == 'Reprise') && _timer == null) {
      _startTimer();
    }
  }

  // Charger l'état sauvegardé du timer
  Future<bool> _loadSavedTimerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = _extractSavedData(prefs);

      if (!_isDataForToday(savedData.savedDate)) {
        return false;
      }

      // Load weekend preferences along with timer data
      await _loadWeekendPreferences();

      _restoreTimerData(savedData);
      await _handleOfflineTime(savedData);
      _configureTimerForState();

      return true;
    } catch (e) {
      // En cas d'erreur, utiliser les valeurs par défaut
      _resetTimerState();
      return false;
    }
  }

  // Extraire les données sauvegardées
  _SavedTimerData _extractSavedData(SharedPreferences prefs) {
    return _SavedTimerData(
      savedAccumulatedTimeMillis: prefs.getInt('timer_accumulated_time'),
      savedElapsedTimeMillis: prefs.getInt('timer_elapsed_time'),
      savedLastUpdateTimeMillis: prefs.getInt('timer_last_update_time'),
      savedState: prefs.getString('timer_etat_actuel'),
      savedDate: prefs.getString('timer_date'),
    );
  }

  // Vérifier si les données sont pour aujourd'hui
  bool _isDataForToday(String? savedDate) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return savedDate == today;
  }

  // Restaurer les données du timer
  void _restoreTimerData(_SavedTimerData data) {
    if (data.savedElapsedTimeMillis != null) {
      _elapsedTime = Duration(milliseconds: data.savedElapsedTimeMillis!);
    }

    if (data.savedAccumulatedTimeMillis != null) {
      _accumulatedTime =
          Duration(milliseconds: data.savedAccumulatedTimeMillis!);
    }
  }

  // Gérer le temps hors ligne
  Future<void> _handleOfflineTime(_SavedTimerData data) async {
    if ((_currentState == 'Entrée' || _currentState == 'Reprise') &&
        data.savedLastUpdateTimeMillis != null) {
      final lastUpdate =
          DateTime.fromMillisecondsSinceEpoch(data.savedLastUpdateTimeMillis!);
      final timeOffline = DateTime.now().difference(lastUpdate);

      // Ajouter le temps hors ligne si nous étions en mode actif et dans une limite raisonnable
      if ((data.savedState == 'Entrée' || data.savedState == 'Reprise') &&
          timeOffline.inHours < 12) {
        _accumulatedTime += timeOffline;
        _elapsedTime = _accumulatedTime;
      }
    }
  }

  // Configurer le timer selon l'état actuel
  void _configureTimerForState() {
    final now = DateTime.now();

    if (_currentState == 'Entrée' || _currentState == 'Reprise') {
      _startTime = now;
    } else if (_currentState == 'Pause') {
      _startTime = null;
      _elapsedTime = _accumulatedTime;
    } else if (_currentState == 'Sortie') {
      _startTime = null;
    }
  }

  // Réinitialiser l'état du timer
  void _resetTimerState() {
    _startTime = null;
    _accumulatedTime = Duration.zero;
    _elapsedTime = Duration.zero;
  }

  // Sauvegarder l'état du timer
  Future<void> _saveTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    // Apply weekend overtime rules before saving
    await _applyWeekendOvertimeRules();

    // Toujours sauvegarder l'heure de la dernière mise à jour
    await prefs.setInt('timer_last_update_time', now.millisecondsSinceEpoch);

    // Sauvegarder l'état actuel

    if (_currentState == 'Entrée' || _currentState == 'Reprise') {
      // Calculer le temps écoulé actuel
      Duration currentElapsedTime;
      if (_startTime != null) {
        currentElapsedTime = _accumulatedTime + now.difference(_startTime!);
      } else {
        // Si pas de startTime, utiliser directement elapsedTime
        currentElapsedTime = _elapsedTime;
      }

      // Sauvegarder les temps calculés

      // Toujours sauvegarder le temps de démarrage actuel
      if (_startTime != null) {
        await prefs.setInt(
            'timer_start_time', _startTime!.millisecondsSinceEpoch);
      }

      await prefs.setInt(
          'timer_accumulated_time', _accumulatedTime.inMilliseconds);
      await prefs.setString('timer_etat_actuel', _currentState);
      await prefs.setString('timer_date', today);
      await prefs.setInt(
          'timer_elapsed_time', currentElapsedTime.inMilliseconds);
    } else if (_currentState == 'Pause') {
      // En pause, on sauvegarde le temps accumulé mais pas l'heure de démarrage
      await prefs.remove('timer_start_time');

      // Sauvegarder en mode pause

      await prefs.setInt(
          'timer_accumulated_time', _accumulatedTime.inMilliseconds);
      await prefs.setString('timer_etat_actuel', _currentState);
      await prefs.setString('timer_date', today);
      await prefs.setInt('timer_elapsed_time', _elapsedTime.inMilliseconds);
    } else if (_currentState == 'Sortie' || _currentState == 'Non commencé') {
      // Effacer les données sauvegardées si la journée est terminée
      // Nettoyer l'état du timer
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

    // Démarrage du timer avec état actuel

    if (_currentState == 'Non commencé' || _currentState == 'Sortie') {
      _startTime = null;
      _accumulatedTime = Duration.zero;
      _elapsedTime = Duration.zero;
      _saveTimerState();
      return;
    }

    // Pour Entrée ou Reprise, utiliser le startTime existant ou maintenant
    if (_currentState == 'Entrée' || _currentState == 'Reprise') {
      // Si _startTime est null, utiliser maintenant
      _startTime ??= DateTime.now();
      // Pour Entrée, on réinitialise le temps accumulé seulement si pas déjà fait
      if (_currentState == 'Entrée' &&
          _accumulatedTime == Duration.zero &&
          _elapsedTime == Duration.zero) {
        // Calculer le temps écoulé depuis le startTime
        _elapsedTime = DateTime.now().difference(_startTime!);
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
            _elapsedTime =
                _accumulatedTime + DateTime.now().difference(_startTime!);
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

    // Track break periods for work time calculations
    _trackBreakTransitions(oldState, newState);

    // Changement d'état du timer

    if (newState == 'Non commencé' || newState == 'Sortie') {
      // Réinitialiser le timer
      _startTime = null;
      _accumulatedTime = Duration.zero;
      _elapsedTime = Duration.zero;
      _timer?.cancel();
      _timer = null;

      // Reset work time calculator for new day
      if (newState == 'Non commencé') {
        _workTimeCalculatorService.reset();
      }
    } else if (newState == 'Pause') {
      // Si on passe en pause, on accumule le temps écoulé jusqu'à maintenant
      if (_startTime != null) {
        _accumulatedTime += DateTime.now().difference(_startTime!);
        _elapsedTime = _accumulatedTime;
        _startTime = null;
      }
      // On ne cancel pas le timer, on le laisse tourner pour mettre à jour l'UI
    } else if (newState == 'Entrée' || newState == 'Reprise') {
      // Si on démarre ou reprend, utiliser le temps de pointage fourni ou maintenant
      _startTime = dernierPointage ?? DateTime.now();

      // Si on vient de 'Non commencé' et qu'on passe à 'Entrée', réinitialiser
      if (oldState == 'Non commencé' && newState == 'Entrée') {
        _accumulatedTime = Duration.zero;
        // Si on a un temps de pointage, calculer le temps écoulé depuis ce moment
        if (dernierPointage != null) {
          _elapsedTime = DateTime.now().difference(dernierPointage);
        } else {
          _elapsedTime = Duration.zero;
        }
      }

      // Démarrer ou redémarrer le timer si nécessaire
      if (_timer == null) {
        _startTimer();
      }
    }

    _saveTimerState();
  }

  /// Tracks break transitions for work time calculations
  void _trackBreakTransitions(String oldState, String newState) {
    try {
      // Starting a break
      if ((oldState == 'Entrée' || oldState == 'Reprise') &&
          newState == 'Pause') {
        _workTimeCalculatorService.startBreak();
        logger.d(
            '[TimerService] Break started - transition from $oldState to $newState');
      }

      // Ending a break
      if (oldState == 'Pause' &&
          (newState == 'Reprise' || newState == 'Sortie')) {
        _workTimeCalculatorService.endBreak();
        logger.d(
            '[TimerService] Break ended - transition from $oldState to $newState');
      }

      // Reset breaks for new day
      if (oldState != 'Non commencé' && newState == 'Non commencé') {
        _workTimeCalculatorService.clearBreakPeriods();
        logger.d('[TimerService] Break periods cleared for new day');
      }
    } catch (e, stackTrace) {
      logger.e('[TimerService] Error tracking break transitions: $e',
          error: e, stackTrace: stackTrace);
    }
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

  /// Updates weekend status and overtime configuration for the current day
  Future<void> _updateWeekendStatus() async {
    try {
      final now = DateTime.now();

      // Detect if today is a weekend day
      _isWeekendDay = _weekendDetectionService.isWeekend(now);

      // Load weekend overtime configuration
      _weekendOvertimeEnabled =
          await _weekendDetectionService.isWeekendOvertimeEnabled();

      // Save weekend preferences for persistence
      await _saveWeekendPreferences();

      logger.d(
          '[TimerService] Weekend status updated: isWeekend=$_isWeekendDay, overtimeEnabled=$_weekendOvertimeEnabled');
    } catch (e, stackTrace) {
      logger.e('[TimerService] Error updating weekend status: $e',
          error: e, stackTrace: stackTrace);
      // Use default values on error
      _isWeekendDay = false;
      _weekendOvertimeEnabled = true;
    }
  }

  /// Saves weekend preferences to SharedPreferences
  Future<void> _saveWeekendPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await prefs.setBool('timer_is_weekend_day', _isWeekendDay);
      await prefs.setBool(
          'timer_weekend_overtime_enabled', _weekendOvertimeEnabled);
      await prefs.setString('timer_weekend_date', today);
    } catch (e, stackTrace) {
      logger.e('[TimerService] Error saving weekend preferences: $e',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Loads weekend preferences from SharedPreferences
  Future<void> _loadWeekendPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final savedDate = prefs.getString('timer_weekend_date');

      // Only load if the saved data is for today
      if (savedDate == today) {
        _isWeekendDay = prefs.getBool('timer_is_weekend_day') ?? false;
        _weekendOvertimeEnabled =
            prefs.getBool('timer_weekend_overtime_enabled') ?? true;

        logger.d(
            '[TimerService] Weekend preferences loaded: isWeekend=$_isWeekendDay, overtimeEnabled=$_weekendOvertimeEnabled');
      } else {
        // Data is stale, update weekend status
        await _updateWeekendStatus();
      }
    } catch (e, stackTrace) {
      logger.e('[TimerService] Error loading weekend preferences: $e',
          error: e, stackTrace: stackTrace);
      // Update weekend status on error
      await _updateWeekendStatus();
    }
  }

  /// Applies weekend overtime rules automatically when saving timer state
  Future<void> _applyWeekendOvertimeRules() async {
    try {
      if (_isWeekendDay && _weekendOvertimeEnabled) {
        // On weekends with overtime enabled, all work time is considered overtime
        logger.d(
            '[TimerService] Weekend overtime rules applied - all time is overtime');

        // Save additional weekend-specific preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('timer_weekend_overtime_applied', true);
        await prefs.setInt(
            'timer_weekend_work_time', elapsedTime.inMilliseconds);
      } else {
        // Clear weekend overtime flags for non-weekend days
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('timer_weekend_overtime_applied');
        await prefs.remove('timer_weekend_work_time');
      }
    } catch (e, stackTrace) {
      logger.e('[TimerService] Error applying weekend overtime rules: $e',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Refreshes weekend configuration (useful when settings change)
  Future<void> refreshWeekendConfiguration() async {
    logger.i('[TimerService] Refreshing weekend configuration');
    await _updateWeekendStatus();
    await _initializeWorkTimeCalculator();
    await _saveTimerState();
  }

  /// Initializes the work time calculator with current configuration
  Future<void> _initializeWorkTimeCalculator() async {
    try {
      // Load work time configuration from overtime configuration service
      final overtimeConfig =
          await _overtimeConfigService.getConfigurationObject();

      // Create work time configuration from overtime settings
      final workTimeConfig = WorkTimeConfiguration(
        standardWorkDay: overtimeConfig.dailyWorkThreshold,
        maxBreakTime: const Duration(hours: 1), // Default 1 hour max break
        weekendOvertimeEnabled: _weekendOvertimeEnabled,
        weekdayOvertimeRate: overtimeConfig.weekdayOvertimeRate,
        weekendOvertimeRate: overtimeConfig.weekendOvertimeRate,
      );

      // Update work time calculator configuration
      _workTimeCalculatorService.updateConfiguration(workTimeConfig);

      logger.d(
          '[TimerService] Work time calculator initialized with config: $workTimeConfig');
    } catch (e, stackTrace) {
      logger.e('[TimerService] Error initializing work time calculator: $e',
          error: e, stackTrace: stackTrace);
      // Continue with default configuration on error
      _workTimeCalculatorService
          .updateConfiguration(WorkTimeConfiguration.defaultConfig());
    }
  }

  /// Returns overtime information for the current session
  Map<String, dynamic> getOvertimeInfo() {
    return {
      'isWeekendDay': _isWeekendDay,
      'weekendOvertimeEnabled': _weekendOvertimeEnabled,
      'isOvertimeSession': isOvertimeSession,
      'elapsedTime': elapsedTime.inMilliseconds,
      'overtimeType':
          _isWeekendDay && _weekendOvertimeEnabled ? 'weekend' : 'weekday',
    };
  }

  /// Returns extended timer state with automatic work time calculations
  ///
  /// This method combines the current timer state with calculated work time information
  /// including estimated end time, remaining work time, and overtime detection.
  ExtendedTimerState getExtendedTimerState() {
    try {
      // Generate extended state using WorkTimeCalculatorService
      final extendedState =
          _workTimeCalculatorService.generateExtendedTimerState(
        currentState: _currentState,
        elapsedTime: elapsedTime,
        startTime: _startTime,
        isWeekendDay: _isWeekendDay,
        weekendOvertimeEnabled: _weekendOvertimeEnabled,
      );

      logger.d('[TimerService] Generated extended timer state: $extendedState');
      return extendedState;
    } catch (e, stackTrace) {
      logger.e('[TimerService] Error generating extended timer state: $e',
          error: e, stackTrace: stackTrace);

      // Return a safe fallback state
      return ExtendedTimerState(
        currentState: _currentState,
        elapsedTime: elapsedTime,
        startTime: _startTime,
        isWeekendDay: _isWeekendDay,
        weekendOvertimeEnabled: _weekendOvertimeEnabled,
        workTimeInfo: WorkTimeInfo.empty(),
        configuration: _workTimeCalculatorService.configuration,
      );
    }
  }

  /// Gets calculated work time information
  ///
  /// This provides real-time calculations of work time, breaks, overtime, and estimated end time.
  WorkTimeInfo getWorkTimeInfo() {
    try {
      return _workTimeCalculatorService.calculateWorkTimeInfo(
        currentState: _currentState,
        elapsedTime: elapsedTime,
        startTime: _startTime,
        isWeekend: _isWeekendDay,
        weekendOvertimeEnabled: _weekendOvertimeEnabled,
      );
    } catch (e, stackTrace) {
      logger.e('[TimerService] Error getting work time info: $e',
          error: e, stackTrace: stackTrace);
      return WorkTimeInfo.empty();
    }
  }

  /// Gets estimated end time for completing the standard work day
  DateTime? getEstimatedEndTime() {
    try {
      final workTimeInfo = _workTimeCalculatorService.calculateWorkTimeInfo(
        currentState: _currentState,
        elapsedTime: elapsedTime,
        startTime: _startTime,
        isWeekend: _isWeekendDay,
        weekendOvertimeEnabled: _weekendOvertimeEnabled,
      );
      return workTimeInfo.estimatedEndTime;
    } catch (e, stackTrace) {
      logger.e('[TimerService] Error getting estimated end time: $e',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Gets remaining time to complete the standard work day
  Duration getRemainingWorkTime() {
    try {
      final workTimeInfo = _workTimeCalculatorService.calculateWorkTimeInfo(
        currentState: _currentState,
        elapsedTime: elapsedTime,
        startTime: _startTime,
        isWeekend: _isWeekendDay,
        weekendOvertimeEnabled: _weekendOvertimeEnabled,
      );
      return workTimeInfo.remainingTime;
    } catch (e, stackTrace) {
      logger.e('[TimerService] Error getting remaining work time: $e',
          error: e, stackTrace: stackTrace);
      return Duration.zero;
    }
  }

  /// Returns true if overtime has started based on effective work time
  bool get isOvertimeStartedCalculated {
    try {
      final workTimeInfo = _workTimeCalculatorService.calculateWorkTimeInfo(
        currentState: _currentState,
        elapsedTime: elapsedTime,
        startTime: _startTime,
        isWeekend: _isWeekendDay,
        weekendOvertimeEnabled: _weekendOvertimeEnabled,
      );
      return workTimeInfo.isOvertimeStarted;
    } catch (e, stackTrace) {
      logger.e('[TimerService] Error checking calculated overtime status: $e',
          error: e, stackTrace: stackTrace);
      return isOvertimeSession; // Fallback to existing logic
    }
  }

  /// Gets calculated overtime hours based on effective work time
  Duration getCalculatedOvertimeHours() {
    try {
      final workTimeInfo = _workTimeCalculatorService.calculateWorkTimeInfo(
        currentState: _currentState,
        elapsedTime: elapsedTime,
        startTime: _startTime,
        isWeekend: _isWeekendDay,
        weekendOvertimeEnabled: _weekendOvertimeEnabled,
      );
      return workTimeInfo.overtimeHours;
    } catch (e, stackTrace) {
      logger.e('[TimerService] Error getting calculated overtime hours: $e',
          error: e, stackTrace: stackTrace);
      return Duration.zero;
    }
  }

  /// Gets total break time for the current work session
  Duration getTotalBreakTime() {
    try {
      final workTimeInfo = _workTimeCalculatorService.calculateWorkTimeInfo(
        currentState: _currentState,
        elapsedTime: elapsedTime,
        startTime: _startTime,
        isWeekend: _isWeekendDay,
        weekendOvertimeEnabled: _weekendOvertimeEnabled,
      );
      return workTimeInfo.breakTime;
    } catch (e, stackTrace) {
      logger.e('[TimerService] Error getting total break time: $e',
          error: e, stackTrace: stackTrace);
      return Duration.zero;
    }
  }

  // Arrêter le timer
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
