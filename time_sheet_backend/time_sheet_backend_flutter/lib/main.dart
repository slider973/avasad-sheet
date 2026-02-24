import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:time_sheet/services/logger_service.dart';
import 'package:time_sheet/services/service_factory.dart';
import 'package:time_sheet/core/config/environment.dart';
import 'package:time_sheet/core/services/supabase/supabase_service.dart';
import 'package:time_sheet/core/database/powersync_database.dart';
import 'dart:io';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'features/bottom_nav_tab/presentation/pages/bottom_navigation_bar.dart';
import 'features/preference/presentation/pages/initial_check_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import './services/injection_container.dart' as di;
import 'package:window_manager/window_manager.dart';

void main() async {
  logger.i('main');
  WidgetsFlutterBinding.ensureInitialized();

  // Select environment: pass --dart-define=ENV=dev to use dev backend
  const envName = String.fromEnvironment('ENV', defaultValue: 'prod');
  AppConfig.current = envName == 'dev' ? Environment.dev : Environment.prod;
  logger.i('Environment: ${AppConfig.current.name}');

  await _configureLocalTimeZone();
  await initializeDateFormatting('fr_CH', null);
  // Must add this line.
  if (Platform.isWindows) {
    await configWindows();
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://881fc425e6497d1454c99fe537d80968@o4507600245817344.ingest.de.sentry.io/4507600249159760';
      options.tracesSampleRate = 1.0;
      options.profilesSampleRate = 1.0;
    },
  );

  // Initialize Supabase first (auth needs to be ready before DI)
  await SupabaseService.instance.initialize();

  // Initialize PowerSync local database (SQLite)
  await PowerSyncDatabaseManager.initialize();

  await di.setup();

  initializeDateFormatting().then((_) => runApp(const MyApp()));
}

Future<void> configWindows() async {
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(500, 1000),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    maximumSize: Size(500, 1000),
    minimumSize: Size(500, 1000),
    titleBarStyle: TitleBarStyle.normal,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ServiceFactory(
      child: MaterialApp(
        title: 'Planet Time Sheet ',
        locale: const Locale('fr', 'CH'),
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          primaryColor: Colors.teal,
          useMaterial3: false,
        ),
        home: const InitialCheckPage(),
        routes: {
          '/main': (context) => const BottomNavigationBarPage(),
          '/login': (context) => const LoginPage(),
        },
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          SfGlobalLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fr', 'CH'),
          Locale('fr', 'FR'),
          Locale('en', 'US'),
        ],
      ),
    );
  }
}

Future<void> _configureLocalTimeZone() async {
  if (kIsWeb || Platform.isLinux) {
    return;
  }
  tz.initializeTimeZones();
  final String timeZoneName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName));
}
