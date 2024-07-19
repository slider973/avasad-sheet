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
  final DateTime? lastGenerationDate;
  Uint8List? signature;

   PreferencesLoaded({
    required this.firstName,
    required this.lastName,
    this.signatureBase64,
    this.lastGenerationDate,
    this.signature

  });



  @override
  List<Object?> get props => [firstName, lastName, signature, lastGenerationDate];
}

class PreferencesSaved extends PreferencesState {}

class PreferencesError extends PreferencesState {
  final String message;

  const PreferencesError(this.message);

  @override
  List<Object> get props => [message];
}
