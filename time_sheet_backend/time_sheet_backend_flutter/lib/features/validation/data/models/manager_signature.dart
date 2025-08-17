import 'package:isar/isar.dart';

part 'manager_signature.g.dart';

@collection
class ManagerSignature {
  Id id = Isar.autoIncrement;
  
  late String managerId;
  late String signatureBase64;
  late DateTime createdAt;
  
  ManagerSignature() {
    createdAt = DateTime.now();
  }
}