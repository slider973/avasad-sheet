import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/pointage/domain/mapper/timesheetEntry.mapper.dart';

/// Le commentaire de journée traverse huit couches (UI → bloc → entité →
/// mapper → modèle → SQL → PowerSync → PDF). Ces tests verrouillent les deux
/// endroits où il peut disparaître silencieusement.
void main() {
  TimesheetEntry entryAvecCommentaire({String? comment}) => TimesheetEntry(
        dayDate: '15-Sep-25',
        dayOfWeekDate: 'Lundi',
        startMorning: '08:00',
        endMorning: '12:00',
        startAfternoon: '13:00',
        endAfternoon: '17:00',
        comment: comment,
      );

  group('TimesheetEntry.copyWith', () {
    test('conserve le commentaire quand il n\'est pas redéfini', () {
      final entry = entryAvecCommentaire(comment: 'Déplacement client Lausanne');

      // Ce que fait le bloc à chaque pointage : ne changer qu'un horaire.
      final updated = entry.copyWith(endAfternoon: '18:30');

      expect(updated.comment, 'Déplacement client Lausanne');
      expect(updated.endAfternoon, '18:30');
    });

    test('remplace le commentaire quand un nouveau est fourni', () {
      final entry = entryAvecCommentaire(comment: 'Ancien');

      expect(entry.copyWith(comment: 'Nouveau').comment, 'Nouveau');
    });

    test('permet d\'effacer le commentaire avec une chaîne vide', () {
      final entry = entryAvecCommentaire(comment: 'À supprimer');

      // `?? this.comment` ne doit pas retenir l'ancienne valeur : la chaîne
      // vide est une valeur, pas une absence de valeur.
      expect(entry.copyWith(comment: '').comment, '');
    });
  });

  group('TimesheetEntryMapper', () {
    test('fait circuler le commentaire dans les deux sens', () {
      final entry = entryAvecCommentaire(comment: 'Intervention urgente');

      final model = TimesheetEntryMapper.toModel(entry);
      expect(model.comment, 'Intervention urgente');

      expect(TimesheetEntryMapper.fromModel(model).comment,
          'Intervention urgente');
    });

    test('convertit un commentaire absent en chaîne vide côté modèle', () {
      // Le modèle Isar n'accepte pas null : les entrées écrites avant l'ajout
      // du champ doivent se relire sans planter.
      final model = TimesheetEntryMapper.toModel(entryAvecCommentaire());

      expect(model.comment, '');
    });
  });
}
