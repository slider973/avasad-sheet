import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/pointage/presentation/pages/time-sheet/bloc/time_sheet/time_sheet_bloc.dart';
import 'package:time_sheet/services/watch_service.dart';

/// Le protocole montre ↔ iPhone est un contrat entre deux langages : Swift
/// écrit des chaînes, Dart les interprète. Rien ne les relie à la compilation,
/// donc ces tests fixent le vocabulaire et les garde-fous.
void main() {
  group('WatchPointageAction.fromWire', () {
    test('accepte le vocabulaire émis par l\'app watchOS', () {
      // "toggle" est ce qu'envoie le bouton principal de PointageView.swift.
      expect(
          WatchPointageAction.fromWire('toggle'), WatchPointageAction.toggle);
    });

    test('accepte les actions typées historiques', () {
      expect(WatchPointageAction.fromWire('entry'), WatchPointageAction.enter);
      expect(WatchPointageAction.fromWire('break'),
          WatchPointageAction.startBreak);
      expect(WatchPointageAction.fromWire('resume'),
          WatchPointageAction.endBreak);
      expect(WatchPointageAction.fromWire('exit'), WatchPointageAction.exit);
    });

    test('renvoie null sur une action inconnue plutôt que de deviner', () {
      // Un message mal formé ne doit pas déclencher un pointage arbitraire.
      expect(WatchPointageAction.fromWire('pointe'), isNull);
      expect(WatchPointageAction.fromWire(''), isNull);
      expect(WatchPointageAction.fromWire('ENTRY'), isNull);
    });

    test('couvre toutes les valeurs de l\'énumération', () {
      // Garde-fou : si une action est ajoutée sans son décodage, ce test tombe.
      const wire = ['toggle', 'entry', 'break', 'resume', 'exit'];
      final decoded = wire
          .map(WatchPointageAction.fromWire)
          .whereType<WatchPointageAction>();

      expect(decoded.toSet(), WatchPointageAction.values.toSet());
    });
  });

  group('TimeSheetWatchActionEvent', () {
    final request = WatchPointageRequest(
        WatchPointageAction.toggle, DateTime(2026, 9, 28, 8, 30));

    test('conserve l\'heure du geste au fil des rejeux', () {
      // Une demande livrée en différé doit s'inscrire à l'heure de l'appui,
      // pas à celle du traitement.
      final e = TimeSheetWatchActionEvent(request);

      expect(e.retry.request.occurredAt, DateTime(2026, 9, 28, 8, 30));
      expect(e.retry.retry.request.occurredAt, DateTime(2026, 9, 28, 8, 30));
    });

    test('borne le rejeu à deux tentatives', () {
      final e = TimeSheetWatchActionEvent(request);

      expect(e.canRetry, isTrue);
      expect(e.retry.canRetry, isTrue);
      expect(e.retry.retry.canRetry, isFalse,
          reason: 'sans cette borne, un chargement qui échoue bouclerait');
    });
  });
}
