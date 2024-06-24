import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../pdf/data/data_sources/local.dart';
import '../pdf/data/data_sources/test_data_inserter.dart';
import '../pdf/data/models/timesheet_entry.dart';
import '../pdf/data/repositories/timesheet_repository_impl.dart';
import '../pdf/domain/use_cases/find_pointed_list_usecase.dart';
import '../pdf/domain/use_cases/save_timesheet_entry_usecase.dart';

final getIt = GetIt.instance;

Future<void> setup() async {
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [TimeSheetEntryModelSchema],
    directory: dir.path,
  );
  // a decommenter pour insérer des données de test
  // TestDataInserter(isar).insertTestData();

  getIt.registerSingleton<Isar>(isar);
  getIt.registerLazySingleton<LocalDatasourceImpl>(() => LocalDatasourceImpl(getIt<Isar>()));
  getIt.registerLazySingleton<TimesheetRepositoryImpl>(() => TimesheetRepositoryImpl(getIt<LocalDatasourceImpl>()));
  getIt.registerLazySingleton<SaveTimesheetEntryUseCase>(() => SaveTimesheetEntryUseCase(getIt<TimesheetRepositoryImpl>()));
  getIt.registerLazySingleton<FindPointedListUseCase>(() => FindPointedListUseCase(getIt<TimesheetRepositoryImpl>()));
}
