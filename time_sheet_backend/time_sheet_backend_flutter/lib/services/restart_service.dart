import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

class RestartService {
  static Future<void> restartApp() async {
    if (Platform.isIOS) {
      // Pour iOS, utilisez la méthode de canal pour redémarrer l'app
      const platform = MethodChannel('samples.flutter.dev/restart');
      await platform.invokeMethod('restart');
    }
    if (Platform.isWindows) {
      // Pour Windows, lancez un nouveau processus et fermez le courant
      final executablePath = Platform.resolvedExecutable;
      final workingDirectory = path.dirname(executablePath);
      await Process.start(executablePath, [], workingDirectory: workingDirectory);
      exit(0);
    } else {
      // Pour les autres plateformes, essayez de fermer l'app
      // L'utilisateur devra la redémarrer manuellement
      SystemNavigator.pop();
    }
  }
}
