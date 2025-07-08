import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/absence/domain/entities/absence_entity.dart';
import 'package:time_sheet/features/absence/domain/use_cases/create_absence_usecase.dart';
import 'package:time_sheet/features/absence/domain/use_cases/get_absences_usecase.dart';
import 'package:time_sheet/features/absence/domain/use_cases/delete_absence_usecase.dart';
import 'package:time_sheet/features/absence/domain/use_cases/get_absence_statistics_usecase.dart';
import 'package:time_sheet/features/absence/domain/value_objects/absence_type.dart';
import 'package:time_sheet/features/absence/domain/repositories/absence_repository.dart';

// Simple fake repository for testing
class FakeAbsenceRepository implements AbsenceRepository {
  @override
  Future<int> saveAbsence(AbsenceEntity absence) async => 1;
  
  @override
  Future<List<AbsenceEntity>> getAbsences() async => [];
  
  @override
  Future<void> deleteAbsence(int absenceId) async {}
  
  @override
  Future<AbsenceEntity?> getAbsenceById(int id) async => null;
  
  @override
  Future<List<AbsenceEntity>> getAbsencesForDateRange(DateTime startDate, DateTime endDate) async => [];
  
  @override
  Future<List<AbsenceEntity>> getAbsencesByType(AbsenceType type) async => [];
  
  @override
  Future<int> getAbsenceCountForYear(int year, AbsenceType type) async => 0;
}

void main() {
  group('Absence Feature - Clean Architecture Tests', () {
    late FakeAbsenceRepository fakeRepository;

    setUp(() {
      fakeRepository = FakeAbsenceRepository();
    });

    group('Domain Entities', () {
      test('AbsenceEntity should be created correctly', () {
        // Arrange & Act
        final absence = AbsenceEntity(
          id: 1,
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 5),
          type: AbsenceType.vacation,
          motif: 'Vacances d\'hiver',
        );

        // Assert
        expect(absence.id, equals(1));
        expect(absence.startDate, equals(DateTime(2024, 1, 1)));
        expect(absence.endDate, equals(DateTime(2024, 1, 5)));
        expect(absence.type, equals(AbsenceType.vacation));
        expect(absence.motif, equals('Vacances d\'hiver'));
      });

      test('AbsenceEntity copyWith should work correctly', () {
        // Arrange
        final absence = AbsenceEntity(
          id: 1,
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 5),
          type: AbsenceType.vacation,
          motif: 'Original',
        );

        // Act
        final modifiedAbsence = absence.copyWith(
          motif: 'Modified',
          type: AbsenceType.sickLeave,
        );

        // Assert
        expect(modifiedAbsence.id, equals(1));
        expect(modifiedAbsence.startDate, equals(DateTime(2024, 1, 1)));
        expect(modifiedAbsence.endDate, equals(DateTime(2024, 1, 5)));
        expect(modifiedAbsence.type, equals(AbsenceType.sickLeave));
        expect(modifiedAbsence.motif, equals('Modified'));
      });
    });

    group('Value Objects', () {
      test('AbsenceType enum should have all expected values', () {
        expect(AbsenceType.values.length, equals(4));
        expect(AbsenceType.values, contains(AbsenceType.vacation));
        expect(AbsenceType.values, contains(AbsenceType.publicHoliday));
        expect(AbsenceType.values, contains(AbsenceType.sickLeave));
        expect(AbsenceType.values, contains(AbsenceType.other));
      });
    });

    group('Use Cases Instantiation', () {
      test('CreateAbsenceUseCase should be instantiated correctly', () {
        final useCase = CreateAbsenceUseCase(fakeRepository);
        expect(useCase, isA<CreateAbsenceUseCase>());
      });

      test('GetAbsencesUseCase should be instantiated correctly', () {
        final useCase = GetAbsencesUseCase(fakeRepository);
        expect(useCase, isA<GetAbsencesUseCase>());
      });

      test('DeleteAbsenceUseCase should be instantiated correctly', () {
        final useCase = DeleteAbsenceUseCase(fakeRepository);
        expect(useCase, isA<DeleteAbsenceUseCase>());
      });

      test('GetAbsenceStatisticsUseCase should be instantiated correctly', () {
        final useCase = GetAbsenceStatisticsUseCase(fakeRepository);
        expect(useCase, isA<GetAbsenceStatisticsUseCase>());
      });
    });

    group('Use Cases Business Logic', () {
      test('CreateAbsenceUseCase should validate dates', () async {
        // Arrange
        final useCase = CreateAbsenceUseCase(fakeRepository);
        final invalidAbsence = AbsenceEntity(
          startDate: DateTime(2024, 1, 10), // Start after end
          endDate: DateTime(2024, 1, 5),
          type: AbsenceType.vacation,
          motif: 'Invalid dates',
        );

        // Act & Assert
        expect(
          () => useCase.execute(invalidAbsence),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('DeleteAbsenceUseCase should validate ID', () async {
        // Arrange
        final useCase = DeleteAbsenceUseCase(fakeRepository);

        // Act & Assert
        expect(
          () => useCase.execute(0),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => useCase.execute(-1),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('CreateAbsenceUseCase should work with valid dates', () async {
        // Arrange
        final useCase = CreateAbsenceUseCase(fakeRepository);
        final validAbsence = AbsenceEntity(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 5),
          type: AbsenceType.vacation,
          motif: 'Valid vacation',
        );

        // Act
        final result = await useCase.execute(validAbsence);

        // Assert
        expect(result, equals(1)); // From our fake repository
      });
    });
  });
}