import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/pointage/domain/rules/anomaly_rule_registry.dart';
import 'package:time_sheet/features/pointage/domain/rules/impl/insufficient_hours_rule.dart';
import 'package:time_sheet/features/pointage/domain/rules/impl/excessive_hours_rule.dart';
import 'package:time_sheet/features/pointage/domain/rules/impl/invalid_times_rule.dart';
import 'package:time_sheet/features/pointage/domain/services/anomaly_detection_service.dart';
import 'package:time_sheet/features/pointage/domain/value_objects/anomaly_type.dart';
import 'package:time_sheet/features/pointage/domain/value_objects/anomaly_severity.dart';

void main() {
  group('New Anomaly Rule System Tests', () {
    
    group('Anomaly Rule Registry', () {
      setUp(() {
        AnomalyRuleRegistry.reset();
        AnomalyRuleRegistry.initialize();
      });
      
      test('should register all default rules', () {
        final availableRules = AnomalyRuleRegistry.getAvailableRuleIds();
        
        expect(availableRules, contains('insufficient_hours'));
        expect(availableRules, contains('excessive_hours'));
        expect(availableRules, contains('invalid_times'));
        expect(availableRules, contains('missing_break'));
        expect(availableRules, contains('schedule_consistency'));
      });
      
      test('should create rule instances', () {
        final insufficientRule = AnomalyRuleRegistry.createRule('insufficient_hours');
        final excessiveRule = AnomalyRuleRegistry.createRule('excessive_hours');
        
        expect(insufficientRule, isA<InsufficientHoursRule>());
        expect(excessiveRule, isA<ExcessiveHoursRule>());
      });
      
      test('should return null for unknown rule', () {
        final unknownRule = AnomalyRuleRegistry.createRule('unknown_rule');
        expect(unknownRule, isNull);
      });
      
      test('should provide rule information', () {
        final rulesInfo = AnomalyRuleRegistry.getAvailableRulesInfo();
        
        expect(rulesInfo.length, greaterThan(0));
        
        final insufficientInfo = rulesInfo.firstWhere(
          (info) => info.id == 'insufficient_hours'
        );
        
        expect(insufficientInfo.name, equals('Heures insuffisantes'));
        expect(insufficientInfo.defaultConfig, containsPair('minHours', 8));
      });
    });
    
    group('Insufficient Hours Rule', () {
      late InsufficientHoursRule rule;
      
      setUp(() {
        rule = InsufficientHoursRule();
      });
      
      test('should detect insufficient hours', () async {
        final entry = TimesheetEntry(
          dayDate: '06-Nov-24',
          dayOfWeekDate: 'Mercredi',
          startMorning: '09:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '16:00', // 6 heures seulement
        );
        
        final result = await rule.validateWithDefaults(entry);
        
        expect(result, isNotNull);
        expect(result!.type, equals(AnomalyType.insufficientHours));
        expect(result.severity, isA<AnomalySeverity>());
        expect(result.description, contains('il manque'));
      });
      
      test('should not detect anomaly for sufficient hours', () async {
        final entry = TimesheetEntry(
          dayDate: '06-Nov-24',
          dayOfWeekDate: 'Mercredi',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:30', // 8.5 heures
        );
        
        final result = await rule.validateWithDefaults(entry);
        
        expect(result, isNull);
      });
      
      test('should validate configuration correctly', () {
        final validConfig = {
          'minHours': 8,
          'minMinutes': 0,
          'toleranceMinutes': 5,
        };
        
        final invalidConfig = {
          'minHours': 'invalid',
          'minMinutes': 0,
        };
        
        expect(rule.isConfigurationValid(validConfig), isTrue);
        expect(rule.isConfigurationValid(invalidConfig), isFalse);
      });
    });
    
    group('Excessive Hours Rule', () {
      late ExcessiveHoursRule rule;
      
      setUp(() {
        rule = ExcessiveHoursRule();
      });
      
      test('should detect excessive hours', () async {
        final entry = TimesheetEntry(
          dayDate: '06-Nov-24',
          dayOfWeekDate: 'Mercredi',
          startMorning: '06:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '21:00', // 14 heures
        );
        
        final result = await rule.validateWithDefaults(entry);
        
        expect(result, isNotNull);
        expect(result!.type, equals(AnomalyType.excessiveHours));
        expect(result.description, contains('excessif'));
      });
      
      test('should not detect anomaly for normal hours', () async {
        final entry = TimesheetEntry(
          dayDate: '06-Nov-24',
          dayOfWeekDate: 'Mercredi',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00', // 8 heures
        );
        
        final result = await rule.validateWithDefaults(entry);
        
        expect(result, isNull);
      });
    });
    
    group('Invalid Times Rule', () {
      late InvalidTimesRule rule;
      
      setUp(() {
        rule = InvalidTimesRule();
      });
      
      test('should detect invalid time order', () async {
        final entry = TimesheetEntry(
          dayDate: '06-Nov-24',
          dayOfWeekDate: 'Mercredi',
          startMorning: '10:00',
          endMorning: '09:00', // Fin avant début
          startAfternoon: '13:00',
          endAfternoon: '17:00',
        );
        
        final result = await rule.validateWithDefaults(entry);
        
        expect(result, isNotNull);
        expect(result!.type, equals(AnomalyType.invalidTimes));
        expect(result.description, contains('avant ou égale'));
      });
      
      test('should detect too short break', () async {
        final entry = TimesheetEntry(
          dayDate: '06-Nov-24',
          dayOfWeekDate: 'Mercredi',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '12:05', // Pause de 5 minutes seulement
          endAfternoon: '17:00',
        );
        
        final result = await rule.validateWithDefaults(entry);
        
        expect(result, isNotNull);
        expect(result!.description, contains('Pause trop courte'));
      });
    });
    
    group('Anomaly Detection Service', () {
      late AnomalyDetectionService service;
      
      setUp(() {
        service = AnomalyDetectionService();
      });
      
      test('should detect multiple anomalies', () async {
        final entry = TimesheetEntry(
          dayDate: '06-Nov-24',
          dayOfWeekDate: 'Mercredi',
          startMorning: '10:00',
          endMorning: '11:00', // Très peu d'heures + fin avant midi
          startAfternoon: '11:05', // Pause très courte
          endAfternoon: '13:00',
        );
        
        final anomalies = await service.detectAnomalies(entry);
        
        expect(anomalies.length, greaterThan(1));
        expect(anomalies.any((a) => a.type == AnomalyType.insufficientHours), isTrue);
      });
      
      test('should allow rule configuration', () {
        service.configureRule('insufficient_hours', {
          'minHours': 6,
          'minMinutes': 0,
          'toleranceMinutes': 10,
        });
        
        final config = service.getRuleConfiguration('insufficient_hours');
        expect(config!['minHours'], equals(6));
      });
      
      test('should allow enabling/disabling rules', () {
        service.setRuleEnabled('schedule_consistency', false);
        expect(service.isRuleEnabled('schedule_consistency'), isFalse);
        
        service.setRuleEnabled('schedule_consistency', true);
        expect(service.isRuleEnabled('schedule_consistency'), isTrue);
      });
      
      test('should export and import configuration', () {
        service.configureRule('insufficient_hours', {
          'minHours': 7,
          'minMinutes': 18,
          'toleranceMinutes': 5,
        });
        service.setRuleEnabled('invalid_times', false);
        
        final exported = service.exportConfiguration();
        
        service.resetToDefaults();
        expect(service.getRuleConfiguration('insufficient_hours')!['minHours'], equals(8));
        
        service.importConfiguration(exported);
        expect(service.getRuleConfiguration('insufficient_hours')!['minHours'], equals(7));
        expect(service.isRuleEnabled('invalid_times'), isFalse);
      });
    });
    
    group('Statistics and Analysis', () {
      late AnomalyDetectionService service;
      
      setUp(() {
        service = AnomalyDetectionService();
      });
      
      test('should calculate statistics correctly', () async {
        final entries = [
          TimesheetEntry(
            dayDate: '04-Nov-24', dayOfWeekDate: 'Lundi',
            startMorning: '08:00', endMorning: '12:00',
            startAfternoon: '13:00', endAfternoon: '15:00', // Heures insuffisantes
          ),
          TimesheetEntry(
            dayDate: '05-Nov-24', dayOfWeekDate: 'Mardi',
            startMorning: '06:00', endMorning: '12:00',
            startAfternoon: '13:00', endAfternoon: '21:00', // Heures excessives
          ),
        ];
        
        final stats = await service.getAnomalyStatistics(entries);
        
        expect(stats.totalAnomalies, greaterThan(0));
        expect(stats.byType.keys, contains('insufficient_hours'));
        expect(stats.bySeverity.keys, isNotEmpty);
      });
    });
  });
}