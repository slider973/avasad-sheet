import 'package:isar/isar.dart';

part 'validation_request_cache.g.dart';

/// Modèle Isar pour la persistance locale des validations
@Collection()
class ValidationRequestCache {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true, replace: true)
  late String validationId;
  
  late String jsonData;
  
  @Index()
  late String employeeId;
  
  @Index()
  late String managerId;
  
  late DateTime lastUpdated;
}