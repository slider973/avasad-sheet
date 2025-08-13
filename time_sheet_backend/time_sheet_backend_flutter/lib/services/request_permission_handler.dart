

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:time_sheet/services/logger_service.dart';

Future<void> handlePermission(BuildContext context)  async {
    Future<Map<Permission, PermissionStatus>> permissionsToRequest = [
      Permission.storage,
      Permission.manageExternalStorage,
      Permission.notification,
      Permission.audio,
    ].request();


    permissionsToRequest.then((value) {
      value.forEach((key, value) {
        if (value.isGranted) {
          logger.i('${key.toString()} est accordée');
        } else {
          logger.e('${key.toString()} est refusée');
        }
      });
    });


    // Vérifiez si toutes les permissions sont accordées
    bool allGranted = await permissionsToRequest.then((value) {
      return value.values.every((element) => element.isGranted);
    });

    if (allGranted) {
      logger.i('Toutes les permissions sont accordées');
      // Procédez avec les opérations nécessitant ces permissions
    } else {
      logger.e('Certaines permissions ont été refusées');
      // Gérez le cas où certaines permissions sont refusées
    }
}