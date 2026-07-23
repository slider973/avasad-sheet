// Point d'entrée pour piloter l'app avec flutter_driver (tests manuels
// outillés sur simulateur) : flutter run -t test_driver/app.dart
import 'package:flutter_driver/driver_extension.dart';
import 'package:time_sheet/main.dart' as app;

void main() {
  enableFlutterDriverExtension();
  app.main();
}
