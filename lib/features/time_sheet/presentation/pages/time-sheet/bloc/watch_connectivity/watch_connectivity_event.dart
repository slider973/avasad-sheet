part of 'watch_connectivity_bloc.dart';

abstract class WatchConnectivityEvent extends Equatable {
  const WatchConnectivityEvent();

  @override
  List<Object> get props => [];
}

class InitializeWatchConnectivity extends WatchConnectivityEvent {}

class SendMessageToWatch extends WatchConnectivityEvent {
  final Map<String, dynamic> message;

  const SendMessageToWatch(this.message);

  @override
  List<Object> get props => [message];
}

class WatchMessageReceived extends WatchConnectivityEvent {
  final Map<String, dynamic> message;

  const WatchMessageReceived(this.message);

  @override
  List<Object> get props => [message];
}

class WatchReachabilityChanged extends WatchConnectivityEvent {
  final bool isReachable;

  const WatchReachabilityChanged(this.isReachable);

  @override
  List<Object> get props => [isReachable];
}
