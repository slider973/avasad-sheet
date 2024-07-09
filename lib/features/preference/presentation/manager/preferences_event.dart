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