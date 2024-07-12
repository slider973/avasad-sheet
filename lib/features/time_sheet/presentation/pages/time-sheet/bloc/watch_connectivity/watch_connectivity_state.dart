part of 'watch_connectivity_bloc.dart';

class WatchConnectivityState extends Equatable {
  final bool isReachable;
  final List<Map<String, dynamic>> receivedMessages;
  final bool isSupported;

  const WatchConnectivityState({
    this.isReachable = false,
    this.receivedMessages = const [],
    this.isSupported = false,
  });

  WatchConnectivityState copyWith({
    bool? isReachable,
    List<Map<String, dynamic>>? receivedMessages,
    bool? isSupported,
  }) {
    return WatchConnectivityState(
      isReachable: isReachable ?? this.isReachable,
      receivedMessages: receivedMessages ?? this.receivedMessages,
      isSupported: isSupported ?? this.isSupported,
    );
  }

  @override
  List<Object> get props => [isReachable, receivedMessages, isSupported];
}
