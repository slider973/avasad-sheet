

import 'package:permission_handler/permission_handler.dart';
import 'package:time_sheet/services/logger_service.dart';

Future<void> handlePermission()  async {
    List<Permission> permissionsToRequest = [
      Permission.storage,
      Permission.manageExternalStorage,
      Permission.notification,
      Permission.audio,
    ];

    Map<Permission, bool> statuses = await requestPermissions(permissionsToRequest);

    statuses.forEach((permission, isGranted) {
      if (isGranted) {
        logger.i('${permission.toString()} est accordée');
      } else {
        logger.e('${permission.toString()} est refusée');

      }
    });

    // Vérifiez si toutes les permissions sont accordées
    bool allGranted = statuses.values.every((status) => status);

    if (allGranted) {
      logger.i('Toutes les permissions sont accordées');
      // Procédez avec les opérations nécessitant ces permissions
    } else {
      logger.e('Certaines permissions ont été refusées');
      // Gérez le cas où certaines permissions sont refusées
    }
}

Future<Map<Permission, bool>> requestPermissions(List<Permission> permissions) async {
  Map<Permission, bool> statuses = {};

  for (var permission in permissions) {
    if (await permission.isDenied) {
      final status = await permission.request();
      statuses[permission] = status.isGranted;
    } else {
      statuses[permission] = true;
    }
  }

  return statuses;
}