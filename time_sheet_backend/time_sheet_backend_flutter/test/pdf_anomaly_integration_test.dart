import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/pointage/domain/services/anomaly_detection_service.dart';
import 'package:time_sheet/features/pointage/domain/rules/anomaly_rule_registry.dart';

void main() {
  group('PDF Generation Anomaly Integration Tests', () {
    late AnomalyDetectionService anomalyService;

    setUp(() {
      // Initialiser le registre des règles
      AnomalyRuleRegistry.reset();
      AnomalyRuleRegistry.initialize();
      anomalyService = AnomalyDetectionService();
    });

    test('should detect critical anomalies that would block PDF generation', () async {
      // Arrange - Créer des entrées avec des anomalies critiques
      final problemEntries = [
        TimesheetEntry(
          id: 1,
          dayDate: '06-Nov-24',
          dayOfWeekDate: 'Mercredi',
          startMorning: '10:00',
          endMorning: '11:00', // Seulement 1h le matin
          startAfternoon: '12:00',
          endAfternoon: '13:00', // Seulement 1h l'après-midi = 2h total
        ),
        TimesheetEntry(
          id: 2,
          dayDate: '07-Nov-24',
          dayOfWeekDate: 'Jeudi',
          startMorning: '06:00', // Très tôt
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '23:00', // Très tard = 13h total
        ),
      ];

      // Act
      final results = await anomalyService.detectAnomaliesForEntries(problemEntries);
      
      // Rassembler toutes les anomalies
      final allAnomalies = results.values.expand((list) => list).toList();
      
      // Filtrer les anomalies critiques
      final criticalAnomalies = allAnomalies.where((anomaly) => 
        anomaly.severity.priority >= 3 // high et critical
      ).toList();

      // Assert
      expect(allAnomalies.length, greaterThan(0), 
          reason: 'Should detect anomalies in problematic entries');
      
      expect(criticalAnomalies.length, greaterThan(0), 
          reason: 'Should detect critical anomalies that would block PDF generation');
      
      print('🔍 Anomalies détectées: ${allAnomalies.length}');
      print('🚨 Anomalies critiques: ${criticalAnomalies.length}');
      
      for (final anomaly in criticalAnomalies) {
        print('• ${anomaly.severity.displayName}: ${anomaly.type.displayName} - ${anomaly.description}');
      }
    });

    test('should allow PDF generation when only minor anomalies exist', () async {
      // Arrange - Créer des entrées avec seulement des anomalies mineures
      final goodEntries = [
        TimesheetEntry(
          id: 1,
          dayDate: '06-Nov-24',
          dayOfWeekDate: 'Mercredi',
          startMorning: '07:30', // Légèrement tôt mais pas critique
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:30', // 8h30 total - bon
        ),
      ];

      // Act
      final results = await anomalyService.detectAnomaliesForEntries(goodEntries);
      
      // Rassembler toutes les anomalies
      final allAnomalies = results.values.expand((list) => list).toList();
      
      // Filtrer les anomalies critiques
      final criticalAnomalies = allAnomalies.where((anomaly) => 
        anomaly.severity.priority >= 3 // high et critical
      ).toList();

      // Assert
      expect(criticalAnomalies.length, equals(0), 
          reason: 'Should not have critical anomalies that would block PDF generation');
      
      print('🔍 Anomalies détectées: ${allAnomalies.length}');
      print('✅ Anomalies critiques: ${criticalAnomalies.length} (PDF generation allowed)');
      
      if (allAnomalies.isNotEmpty) {
        print('ℹ️  Anomalies mineures détectées:');
        for (final anomaly in allAnomalies) {
          print('• ${anomaly.severity.displayName}: ${anomaly.type.displayName}');
        }
      }
    });

    test('should allow PDF generation when no anomalies exist', () async {
      // Arrange - Créer des entrées parfaites
      final perfectEntries = [
        TimesheetEntry(
          id: 1,
          dayDate: '06-Nov-24',
          dayOfWeekDate: 'Mercredi',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:18', // Exactement 8h18
        ),
      ];

      // Act
      final results = await anomalyService.detectAnomaliesForEntries(perfectEntries);
      
      // Rassembler toutes les anomalies
      final allAnomalies = results.values.expand((list) => list).toList();

      // Assert
      expect(allAnomalies.length, equals(0), 
          reason: 'Perfect entries should have no anomalies');
      
      print('✅ Aucune anomalie détectée - PDF generation allowed');
    });

    test('demonstrates the error message format that would be shown to user', () async {
      // Arrange - Créer des entrées avec plusieurs types d'anomalies
      final mixedEntries = [
        TimesheetEntry(
          id: 1,
          dayDate: '06-Nov-24',
          dayOfWeekDate: 'Mercredi',
          startMorning: '10:00',
          endMorning: '09:00', // Fin avant début - critique
          startAfternoon: '13:00',
          endAfternoon: '16:00',
        ),
        TimesheetEntry(
          id: 2,
          dayDate: '07-Nov-24',
          dayOfWeekDate: 'Jeudi',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '12:05', // Pause très courte - mineur
          endAfternoon: '15:00', // Heures insuffisantes - élevé
        ),
      ];

      // Act
      final results = await anomalyService.detectAnomaliesForEntries(mixedEntries);
      final allAnomalies = results.values.expand((list) => list).toList();
      
      // Simuler le message qui serait affiché à l'utilisateur
      final criticalAnomalies = allAnomalies.where((a) => a.severity.priority >= 3).toList();
      final minorAnomalies = allAnomalies.where((a) => a.severity.priority < 3).toList();
      
      final messageBuffer = StringBuffer();
      messageBuffer.writeln('⚠️  ANOMALIES DÉTECTÉES DANS LE POINTAGE ⚠️');
      messageBuffer.writeln('');
      messageBuffer.writeln('La génération du PDF a été interrompue car ${allAnomalies.length} anomalie(s) ont été détectées.');
      
      if (criticalAnomalies.isNotEmpty) {
        messageBuffer.writeln('');
        messageBuffer.writeln('🚨 ANOMALIES CRITIQUES ET ÉLEVÉES (${criticalAnomalies.length}):');
        messageBuffer.writeln('Ces anomalies doivent être corrigées avant de générer le PDF.');
        messageBuffer.writeln('');
        
        for (final anomaly in criticalAnomalies) {
          messageBuffer.writeln('• ${anomaly.severity.displayName.toUpperCase()} - ${anomaly.type.displayName}');
          messageBuffer.writeln('  ${anomaly.description}');
          messageBuffer.writeln('');
        }
      }
      
      if (minorAnomalies.isNotEmpty) {
        messageBuffer.writeln('');
        messageBuffer.writeln('ℹ️  ANOMALIES MINEURES (${minorAnomalies.length}):');
        messageBuffer.writeln('Ces anomalies n\'empêchent pas la génération mais sont à vérifier.');
        messageBuffer.writeln('');
        
        for (final anomaly in minorAnomalies) {
          messageBuffer.writeln('• ${anomaly.severity.displayName} - ${anomaly.type.displayName}');
        }
      }
      
      messageBuffer.writeln('');
      messageBuffer.writeln('📋 ACTIONS RECOMMANDÉES:');
      messageBuffer.writeln('1. Corrigez les heures de pointage dans l\'application');
      messageBuffer.writeln('2. Vérifiez les entrées et sorties manquantes');
      messageBuffer.writeln('3. Ajustez les heures incohérentes');
      messageBuffer.writeln('4. Relancez la génération du PDF une fois les corrections effectuées');

      // Assert et affichage du message
      expect(allAnomalies.length, greaterThan(0));
      expect(criticalAnomalies.length, greaterThan(0));
      
      print('\n' + '='*60);
      print('EXEMPLE DE MESSAGE UTILISATEUR:');
      print('='*60);
      print(messageBuffer.toString());
      print('='*60);
    });
  });
}