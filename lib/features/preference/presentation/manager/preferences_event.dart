part of 'preferences_bloc.dart';

sealed class PreferencesEvent extends Equatable {
  const PreferencesEvent();

  @override
  List<Object?> get props => [];
}

class LoadPreferences extends PreferencesEvent {}

class SavePreferences extends PreferencesEvent {
  final String firstName;
  final String lastName;
  Uint8List? signature;

  SavePreferences({
    required this.firstName,
    required this.lastName,
    this.signature,
  });

  @override
  List<Object?> get props => [firstName, lastName, signature];
}
class SaveSignature extends PreferencesEvent {
  final Uint8List signature;

  const SaveSignature({required this.signature});

  @override
  List<Object> get props => [signature];
}
class SaveLastGenerationDate extends PreferencesEvent {
  final DateTime date;

  const SaveLastGenerationDate(this.date);

  @override
  List<Object> get props => [date];
}
class SaveBadgeCount extends PreferencesEvent {
  final int count;

  const SaveBadgeCount(this.count);

  @override
  List<Object> get props => [count];
}

class ToggleNotifications extends PreferencesEvent {
  final bool enabled;

  const ToggleNotifications(this.enabled);

  @override
  List<Object> get props => [enabled];
}
class ToggleDeliveryManager extends PreferencesEvent {
  final bool enabled;

  const ToggleDeliveryManager(this.enabled);

  @override
  List<Object> get props => [enabled];
}