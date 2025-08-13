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
  final String company;
  final String? signatureBase64;
  final DateTime? lastGenerationDate;
  Uint8List? signature;
  final bool notificationsEnabled;
  final bool isDeliveryManager;
  final int badgeCount;
  final String versionNumber;
  final String buildNumber;

  PreferencesLoaded({
    required this.firstName,
    required this.lastName,
    required this.company,
    this.signatureBase64,
    this.lastGenerationDate,
    this.signature,
    required this.notificationsEnabled,
    required this.isDeliveryManager,
    required this.badgeCount,
    required this.versionNumber,
    required this.buildNumber,
  });

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        company,
        signature,
        lastGenerationDate,
        notificationsEnabled,
        isDeliveryManager,
        badgeCount
      ];
}

class PreferencesSaved extends PreferencesState {}

class PreferencesError extends PreferencesState {
  final String message;

  const PreferencesError(this.message);

  @override
  List<Object> get props => [message];
}
