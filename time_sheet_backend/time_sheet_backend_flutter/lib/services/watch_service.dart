import 'dart:async';
import 'package:watch_connectivity/watch_connectivity.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

class WatchService {
  final Logger logger = GetIt.I<Logger>();
  final _watchConnectivity = WatchConnectivity();
  
  final StreamController<String> _stateController = StreamController<String>.broadcast();
  Stream<String> get stateStream => _stateController.stream;
  
  String _currentState = 'Non commencé';
  String get currentState => _currentState;
  
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  Future<void> initialize() async {
    try {
      // Vérifier si l'appareil est supporté
      final isSupported = await _watchConnectivity.isSupported;
      if (!isSupported) {
        logger.w('Watch connectivity is not supported on this device');
        return;
      }
      
      // Vérifier si une montre est appairée
      final isPaired = await _watchConnectivity.isPaired;
      if (!isPaired) {
        logger.w('No watch is paired with this device');
        return;
      }
      
      // Vérifier si la montre est accessible
      final isReachable = await _watchConnectivity.isReachable;
      _isConnected = isReachable;
      
      logger.i('Watch connectivity initialized - Paired: $isPaired, Reachable: $isReachable');
      
      // Écouter les messages de la montre
      _setupListeners();
      
      // La session est activée automatiquement côté iOS
      
      // Envoyer l'état initial
      if (isReachable) {
        await sendState(_currentState);
      }
    } catch (e) {
      logger.e('Error initializing watch connectivity: $e');
    }
  }
  
  void _setupListeners() {
    // Écouter les changements de connexion
    _watchConnectivity.isReachable.then((reachable) {
      _isConnected = reachable;
      logger.i('Watch reachability changed: $reachable');
    });
    
    // Écouter les messages
    _watchConnectivity.messageStream.listen((message) {
      logger.i('Received message from watch: $message');
      _handleWatchMessage(message);
    });
    
    // Écouter le contexte d'application (pour les données en arrière-plan)
    _watchConnectivity.applicationContext.then((context) {
      if (context.containsKey('state')) {
        _updateState(context['state'] as String);
      }
    });
  }
  
  void _handleWatchMessage(Map<String, dynamic> message) {
    if (message['action'] != null) {
      final action = message['action'] as String;
      logger.i('Watch action received: $action');
      
      // Notifier l'app Flutter de l'action reçue
      switch (action) {
        case 'entry':
          _updateState('Entrée');
          break;
        case 'break':
          _updateState('Pause');
          break;
        case 'resume':
          _updateState('Reprise');
          break;
        case 'exit':
          _updateState('Sortie');
          break;
      }
    }
  }
  
  void _updateState(String newState) {
    _currentState = newState;
    _stateController.add(newState);
  }
  
  Future<void> sendState(String state) async {
    try {
      _currentState = state;
      
      // Envoyer via message si la montre est accessible
      if (_isConnected) {
        await _watchConnectivity.sendMessage({
          'type': 'stateUpdate',
          'state': state,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
      
      // Toujours mettre à jour le contexte d'application (persistant)
      await _watchConnectivity.updateApplicationContext({
        'state': state,
        'lastUpdate': DateTime.now().toIso8601String(),
      });
      
      logger.i('State sent to watch: $state');
    } catch (e) {
      logger.e('Error sending state to watch: $e');
    }
  }
  
  Future<void> sendPointageConfirmation(String action) async {
    try {
      if (_isConnected) {
        await _watchConnectivity.sendMessage({
          'type': 'confirmation',
          'action': action,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      logger.e('Error sending confirmation to watch: $e');
    }
  }
  
  void dispose() {
    _stateController.close();
  }
}