import 'package:isar/isar.dart';

import '../models/anomalies/anomalies.dart';

abstract class AnomalyRepository {
  Future<void> markResolved(int anomalyId);
  Future<List<AnomalyModel>> getAnomalies();
  Future<void> saveAnomaly(AnomalyModel anomaly);
}

class AnomalyRepositoryImpl implements AnomalyRepository {
  final Isar isar;

  AnomalyRepositoryImpl(this.isar);

  @override
  Future<void> markResolved(int anomalyId) async {
    await isar.writeTxn(() async {
      final anomaly = await isar.anomalyModels.get(anomalyId);
      if (anomaly != null) {
        anomaly.isResolved = true;
        await isar.anomalyModels.put(anomaly);
      }
    });
  }

  @override
  Future<List<AnomalyModel>> getAnomalies() async {
    return await isar.anomalyModels.where().findAll();
  }

  @override
  Future<void> saveAnomaly(AnomalyModel anomaly) async {
    await isar.writeTxn(() async {
      await isar.anomalyModels.put(anomaly);
    });
  }
}