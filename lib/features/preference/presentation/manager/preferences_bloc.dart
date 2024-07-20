import 'dart:convert';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:time_sheet/features/preference/domain/use_cases/get_signature_usecase.dart';

import '../../domain/use_cases/get_user_preference_use_case.dart';
import '../../domain/use_cases/set_user_preference_use_case.dart';

part 'preferences_event.dart';
part 'preferences_state.dart';
class PreferencesBloc extends Bloc<PreferencesEvent, PreferencesState> {
  final GetUserPreferenceUseCase getUserPreferenceUseCase;
  final SetUserPreferenceUseCase setUserPreferenceUseCase;

  PreferencesBloc({
    required this.getUserPreferenceUseCase,
    required this.setUserPreferenceUseCase,
  }) : super(PreferencesInitial()) {
    on<LoadPreferences>(_onLoadPreferences);
    on<SavePreferences>(_onSavePreferences);
    on<SaveSignature>(_onSaveSignature);
    on<SaveLastGenerationDate>(_onSaveLastGenerationDate);
  }

  Future<void> _onLoadPreferences(
      LoadPreferences event,
      Emitter<PreferencesState> emit,
      ) async {
    emit(PreferencesLoading());
    try {
      final firstName = await getUserPreferenceUseCase.execute('firstName') ?? '';
      final lastName = await getUserPreferenceUseCase.execute('lastName') ?? '';
      final signatureBase64 = await getUserPreferenceUseCase.execute('signature');
      final lastGenerationDateString = await getUserPreferenceUseCase.execute('lastGenerationDate');
      final lastGenerationDate = lastGenerationDateString != null
          ? DateTime.parse(lastGenerationDateString)
          : null;

      Uint8List? signature;
      if (signatureBase64 != null) {
        try {
          signature = base64Decode(signatureBase64);
        } catch (e) {
          print('Erreur lors du décodage de la signature: $e');
        }
      }
      emit(PreferencesLoaded(
        firstName: firstName,
        lastName: lastName,
          signature: signature,
        lastGenerationDate: lastGenerationDate
      ));
    } catch (e) {
      emit(PreferencesError(e.toString()));
    }
  }

  Future<void> _onSavePreferences(
      SavePreferences event,
      Emitter<PreferencesState> emit,
      ) async {
    emit(PreferencesLoading());
    try {
      await setUserPreferenceUseCase.execute('firstName', event.firstName);
      await setUserPreferenceUseCase.execute('lastName', event.lastName);
      // Récupérer la signature existante
      final currentState = state;
      Uint8List? signature;
      if (currentState is PreferencesLoaded) {
        signature = currentState.signature;
      }


      // Charger les préférences mises à jour
      final signatureBase64 = await getUserPreferenceUseCase.execute('signature');
      final lastGenerationDateString = await getUserPreferenceUseCase.execute('lastGenerationDate');
      final lastGenerationDate = lastGenerationDateString != null
          ? DateTime.parse(lastGenerationDateString)
          : null;
      emit(PreferencesSaved());
      emit(PreferencesLoaded(
        firstName: event.firstName,
        lastName: event.lastName,
        signatureBase64: signatureBase64,
        lastGenerationDate: lastGenerationDate,

      ));
    } catch (e) {
      print(e);
      emit(PreferencesError(e.toString()));
    }
  }
  Future<void> _onSaveSignature(SaveSignature event, Emitter<PreferencesState> emit) async {
    emit(PreferencesLoading());
    try {
      // Encodez la signature en base64 pour le stockage
      final signatureBase64 = base64Encode(event.signature);

      // Sauvegardez la signature encodée
      await setUserPreferenceUseCase.execute('signature', signatureBase64);

      // Récupérez les autres préférences actuelles
      final firstName = await getUserPreferenceUseCase.execute('firstName') ?? '';
      final lastName = await getUserPreferenceUseCase.execute('lastName') ?? '';
      final lastGenerationDateString = await getUserPreferenceUseCase.execute('lastGenerationDate');
      final lastGenerationDate = lastGenerationDateString != null
          ? DateTime.parse(lastGenerationDateString)
          : null;
      // Émettez un état indiquant que la sauvegarde a réussi
      emit(PreferencesSaved());
      // Émettez le nouvel état avec toutes les données à jour
      emit(PreferencesLoaded(
        firstName: firstName,
        lastName: lastName,
        signature: event.signature, // Utilisez la signature non encodée pour l'état
        lastGenerationDate: lastGenerationDate,
      ));
    } catch (e) {
      print('Erreur lors de la sauvegarde de la signature: $e');
      emit(PreferencesError(e.toString()));
    }
  }
  Future<Uint8List?> getCurrentSignature() async {
    final currentState = state;
    if (currentState is PreferencesLoaded) {
      return currentState.signature;
    }
    // Si l'état n'est pas chargé, chargez les préférences
    add(LoadPreferences());
    // Attendez que l'état soit chargé
    await stream.firstWhere((state) => state is PreferencesLoaded);
    final updatedState = state;
    if (updatedState is PreferencesLoaded) {
      return updatedState.signature;
    }
    return null;
  }


  Future<void> _onSaveLastGenerationDate(
      SaveLastGenerationDate event,
      Emitter<PreferencesState> emit,
      ) async {
    if (state is PreferencesLoaded) {
      final currentState = state as PreferencesLoaded;
      try {
        await setUserPreferenceUseCase.execute(
            'lastGenerationDate',
            event.date.toIso8601String()
        );
        emit(PreferencesLoaded(
          firstName: currentState.firstName,
          lastName: currentState.lastName,
          signature: currentState.signature,
          lastGenerationDate: event.date,
        ));
      } catch (e) {
        print(e);
        emit(PreferencesError('Erreur lors de la sauvegarde de la date de dernière génération: $e'));
      }
    }
  }
}