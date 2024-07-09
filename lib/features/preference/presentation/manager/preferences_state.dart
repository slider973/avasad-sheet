part of 'preferences_bloc.dart';

sealed class PreferencesState extends Equatable {
  const PreferencesState();

  @override
  List<Object?> get props => [];
}

final class PreferencesInitial extends PreferencesState {}



class PreferencesLoading extends PreferencesState {}

class PreferencesLoaded extends PreferencesState {
  final String firstName;
  final String lastName;
  final String? signatureBase64;

  const PreferencesLoaded({
    required this.firstName,
    required this.lastName,
    this.signatureBase64,
  });


  Uint8List? get signature => signatureBase64 != null
      ? base64Decode(signatureBase64!)
      : null;

  @override
  List<Object?> get props => [firstName, lastName, signatureBase64];
}

class PreferencesSaved extends PreferencesState {}

class PreferencesError extends PreferencesState {
  final String message;

  const PreferencesError(this.message);

  @override
  List<Object> get props => [message];
}
