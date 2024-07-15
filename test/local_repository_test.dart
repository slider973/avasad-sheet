// FILEPATH: /Users/jonathanlemaine/Documents/Projet/avasad/avasad-sheet/test/services/injection_container_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:mockito/mockito.dart';
import 'package:time_sheet/services/injection_container.dart';
import 'package:time_sheet/features/pointage/data/data_sources/local.dart';
import 'package:time_sheet/features/pointage/data/repositories/timesheet_repository_impl.dart';
import 'package:time_sheet/features/pointage/domain/use_cases/find_pointed_list_usecase.dart';
import 'package:time_sheet/features/pointage/domain/use_cases/save_timesheet_entry_usecase.dart';

class MockIsar extends Mock implements Isar {}

void main() {
  setUp(() async {
    getIt.reset();
    await setup();
  });

  test('should register Isar', () {
    final isar = getIt<Isar>();
    expect(isar, isNotNull);
    expect(isar, isA<Isar>());
  });

  test('should register LocalDatasourceImpl', () {
    final localDatasource = getIt<LocalDatasourceImpl>();
    expect(localDatasource, isNotNull);
    expect(localDatasource, isA<LocalDatasourceImpl>());
  });

  test('should register TimesheetRepositoryImpl', () {
    final timesheetRepository = getIt<TimesheetRepositoryImpl>();
    expect(timesheetRepository, isNotNull);
    expect(timesheetRepository, isA<TimesheetRepositoryImpl>());
  });

  test('should register SaveTimesheetEntryUseCase', () {
    final saveTimesheetEntryUseCase = getIt<SaveTimesheetEntryUseCase>();
    expect(saveTimesheetEntryUseCase, isNotNull);
    expect(saveTimesheetEntryUseCase, isA<SaveTimesheetEntryUseCase>());
  });

  test('should register FindPointedListUseCase', () {
    final findPointedListUseCase = getIt<FindPointedListUseCase>();
    expect(findPointedListUseCase, isNotNull);
    expect(findPointedListUseCase, isA<FindPointedListUseCase>());
  });
}