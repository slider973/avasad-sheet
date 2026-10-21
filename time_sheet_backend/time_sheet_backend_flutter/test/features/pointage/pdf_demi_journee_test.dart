import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/enum/absence_period.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/pointage/domain/entities/work_day.dart';

/// Régression PDF : le seuil quotidien appliqué EN PLEIN sur une demi-journée.
///
/// Le correctif précédent portait sur `CalculateOvertimeHoursUseCase`, mais
/// `generate_pdf_usecase.dart` **recalcule le seuil lui-même** (lignes ~727 et
/// ~852) à partir de `user.normalHoursThreshold`, sans passer par le use-case.
/// Corriger le use-case seul ne changeait donc RIEN au PDF — constaté après
/// déploiement du build 32.
///
/// Ce test couvre l'arithmétique dupliquée, celle qui produit réellement la
/// colonne « Dont heures supplémentaires ».
void main() {
  const normalHoursThreshold = 8.3; // 8h18 exprimé en heures décimales

  /// Reproduit à l'identique le calcul de `_buildDayRow`.
  String dayCell({
    required Duration worked,
    required bool isHalfDayAbsence,
    bool isWeekday = true,
  }) {
    final thresholdMinutes = (normalHoursThreshold * 60).round();
    final threshold = isHalfDayAbsence
        ? Duration(minutes: thresholdMinutes ~/ 2)
        : Duration(minutes: thresholdMinutes);

    if (isWeekday && worked > threshold) {
      return '+${(worked - threshold).inMinutes}min';
    } else if (isWeekday && worked < threshold && worked > Duration.zero) {
      return '-${(threshold - worked).inMinutes}min';
    }
    return '';
  }

  group('colonne « Dont heures supplémentaires » du PDF', () {
    test('LE CAS DU 24/09 : demi-journée de 5h00 => +51 min', () {
      final cell = dayCell(
        worked: const Duration(hours: 5),
        isHalfDayAbsence: true,
      );

      expect(cell, '+51min');
    });

    test('sans le prorata, la même ligne affichait −198 min (−3h18)', () {
      final avant = dayCell(
        worked: const Duration(hours: 5),
        isHalfDayAbsence: false, // comportement d'origine
      );

      expect(avant, '-198min',
          reason: 'trace du bug : 5h00 comparées à 8h18 au lieu de 4h09');
    });

    test('une demi-journée sous son seuil reste en déficit', () {
      final cell = dayCell(
        worked: const Duration(hours: 3),
        isHalfDayAbsence: true,
      );

      // 4h09 - 3h00 = 69 min
      expect(cell, '-69min');
    });

    test('une journée pleine à 8h18 n\'affiche ni surplus ni déficit', () {
      final cell = dayCell(
        worked: const Duration(hours: 8, minutes: 18),
        isHalfDayAbsence: false,
      );

      expect(cell, '');
    });

    test('une journée pleine au-dessus du seuil reste en surplus', () {
      final cell = dayCell(
        worked: const Duration(hours: 9),
        isHalfDayAbsence: false,
      );

      expect(cell, '+42min');
    });
  });

  group('Workday : heures travaillées une demi-journée', () {
    test('l\'après-midi travaillé est bien compté', () {
      final day = Workday(TimesheetEntry(
        id: 1,
        dayDate: '24-Sep-26',
        dayOfWeekDate: 'Thursday',
        startMorning: '',
        endMorning: '',
        startAfternoon: '13:30',
        endAfternoon: '18:30',
        absenceReason: 'Congés',
        period: AbsencePeriod.halfDay.value,
      ));

      expect(day.calculateTotalHours(), const Duration(hours: 5));
      expect(day.isAbsence(), isTrue,
          reason: 'une demi-journée reste une absence : c\'est pour ça '
              'qu\'elle était exclue à tort du total hebdomadaire');
    });

    test('une journée complète d\'absence ne compte aucune heure', () {
      final day = Workday(TimesheetEntry(
        id: 2,
        dayDate: '21-Sep-26',
        dayOfWeekDate: 'Monday',
        startMorning: '',
        endMorning: '',
        startAfternoon: '',
        endAfternoon: '',
        absenceReason: 'Jour férié',
        period: AbsencePeriod.fullDay.value,
      ));

      expect(day.calculateTotalHours(), Duration.zero);
    });
  });
}
