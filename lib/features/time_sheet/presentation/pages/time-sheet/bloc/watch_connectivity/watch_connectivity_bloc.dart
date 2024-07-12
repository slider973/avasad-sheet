import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:time_sheet/services/logger_service.dart';

import '../time_sheet/time_sheet_bloc.dart';

part 'watch_connectivity_event.dart';
part 'watch_connectivity_state.dart';

class WatchConnectivityBloc extends Bloc<WatchConnectivityEvent, WatchConnectivityState> {
  static const MethodChannel _channel = MethodChannel('com.example.watchApp');
  final TimeSheetBloc timeSheetBloc; // Référence au TimeSheetBloc

  WatchConnectivityBloc({required this.timeSheetBloc}) : super(WatchConnectivityState()) {
    on<InitializeWatchConnectivity>(_onInitializeWatchConnectivity);
    on<SendMessageToWatch>(_onSendMessageToWatch);
    on<WatchMessageReceived>(_onWatchMessageReceived);
    on<WatchReachabilityChanged>(_onWatchReachabilityChanged);
  }

  Future<void> _onInitializeWatchConnectivity(
      InitializeWatchConnectivity event,
      Emitter<WatchConnectivityState> emit,
      ) async {
    logger.i('InitializeWatchConnectivity');
    _channel.setMethodCallHandler(_handleMethod);
    try {
     // final bool result = await _channel.invokeMethod("flutterToWatch", {"method": "onMessageReceived", "data": "Non commencé"});
     // print('Watch connectivity initialized: $result');
    } on PlatformException catch (e) {
      print("Failed to initialize watch connectivity: '${e.message}'.");
    }
  }

  Future<void> _onSendMessageToWatch(
      SendMessageToWatch event,
      Emitter<WatchConnectivityState> emit,
      ) async {
    if (state.isReachable) {
      try {
        await _channel.invokeMethod('flutterToWatch', {'message': event.message});
      } on PlatformException catch (e) {
        print("Failed to send message to watch: '${e.message}'.");
      }
    } else {
      print('La montre n\'est pas accessible');
    }
  }

  void _onWatchMessageReceived(
      WatchMessageReceived event,
      Emitter<WatchConnectivityState> emit,
      ) {
    final updatedMessages = List<Map<String, dynamic>>.from(state.receivedMessages)..add(event.message);
    emit(state.copyWith(receivedMessages: updatedMessages));

    // Vous pouvez ajouter ici la logique pour dispatcher les événements à votre TimeSheetBloc
    _dispatchTimeSheetEvent(event.message);
  }

  void _onWatchReachabilityChanged(
      WatchReachabilityChanged event,
      Emitter<WatchConnectivityState> emit,
      ) {
    emit(state.copyWith(isReachable: event.isReachable));
  }

  Future<void> _handleMethod(MethodCall call) async {
    print('Received method call: ${call.method}');
    switch (call.method) {
      case 'onMessageReceived':
        add(WatchMessageReceived(Map<String, dynamic>.from(call.arguments)));
        break;
      case 'reachabilityChanged':
        add(WatchReachabilityChanged(call.arguments as bool));
        break;
    }
  }

  void _dispatchTimeSheetEvent(Map<String, dynamic> message) {
    final eventType = message['eventType'] as String?;
    final timestamp = message['timestamp'] as double?;

    if (eventType != null && timestamp != null) {
      final dateTime = DateTime.fromMillisecondsSinceEpoch((timestamp * 1000).round());

      switch (eventType) {
        case 'TimeSheetEnter':
          timeSheetBloc.add(TimeSheetEnterEvent(dateTime));
          break;
        case 'TimeSheetStartBreak':
          timeSheetBloc.add(TimeSheetStartBreakEvent(dateTime));
          break;
        case 'TimeSheetEndBreak':
          timeSheetBloc.add(TimeSheetEndBreakEvent(dateTime));
          break;
        case 'TimeSheetOut':
          timeSheetBloc.add(TimeSheetOutEvent(dateTime));
          break;
        default:
          print('Unknown eventType: $eventType');
      }
    }
  }
}
