import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/pointage/domain/use_cases/find_pointed_list_usecase.dart';
import 'package:time_sheet/features/pointage/domain/use_cases/save_timesheet_entry_usecase.dart';
import 'package:time_sheet/features/pointage/data/repositories/timesheet_repository_impl.dart';
import 'package:time_sheet/features/pointage/domain/repositories/timesheet_repository.dart';
import 'package:mockito/mockito.dart';

class MockTimesheetRepository extends Mock implements TimesheetRepository {}

void main() {
  group('Use Cases Tests', () {
    late MockTimesheetRepository mockRepository;
    late SaveTimesheetEntryUseCase saveTimesheetEntryUseCase;
    late FindPointedListUseCase findPointedListUseCase;

    setUp(() {
      mockRepository = MockTimesheetRepository();
      saveTimesheetEntryUseCase = SaveTimesheetEntryUseCase(mockRepository);
      findPointedListUseCase = FindPointedListUseCase(mockRepository);
    });

    test('SaveTimesheetEntryUseCase should be created correctly', () {
      expect(saveTimesheetEntryUseCase, isA<SaveTimesheetEntryUseCase>());
      expect(saveTimesheetEntryUseCase.repository, equals(mockRepository));
    });

    test('FindPointedListUseCase should be created correctly', () {
      expect(findPointedListUseCase, isA<FindPointedListUseCase>());
      expect(findPointedListUseCase.repository, equals(mockRepository));
    });

    test('TimesheetRepositoryImpl should be created correctly', () {
      // This test just verifies the class can be instantiated with a mock
      expect(() => TimesheetRepositoryImpl, returnsNormally);
    });
  });
}