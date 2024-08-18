import 'dart:ffi';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:time_sheet/services/logger_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import '../features/pointage/presentation/pages/time-sheet/bloc/time_sheet/time_sheet_bloc.dart';
import '../features/preference/presentation/manager/preferences_bloc.dart';

class DynamicMultiplatformNotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final TimeSheetBloc timeSheetBloc;
  final PreferencesBloc preferencesBloc;

  DynamicMultiplatformNotificationService({
    required this.flutterLocalNotificationsPlugin,
    required this.timeSheetBloc,
    required this.preferencesBloc,
  }) {
    timeSheetBloc.stream.listen((_) => _updateNotifications());
  }

  Future<void> initNotifications() async {
    if (Platform.isIOS) {
      await _initIOSNotifications();
    }
    // Pas besoin d'initialisation spécifique pour Windows
    await _updateNotifications();
  }

  Future<void> _initIOSNotifications() async {
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      defaultPresentBadge: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(iOS: initializationSettingsIOS);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation()
        ?.cancelAll();

    await _resetBadge();
  }

  Future<void> _resetBadge() async {
    if (Platform.isIOS) {
      _updateBadgeCount(0);
    }
  }

  Future<void> _updateBadgeCount(int count) async {
    await flutterLocalNotificationsPlugin.show(
      0,
      null,
      null,
      NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: false,
          presentBadge: true,
          presentSound: false,
          badgeNumber: count,
        ),
      ),
    );
    preferencesBloc.add(SaveBadgeCount(count));
  }

  Future<void> testNotification() async {
    const int testId = 0;
    const String testTitle = "Test de notification";
    const String testBody =
        "Si vous voyez ceci, les notifications fonctionnent !";

    if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin.show(
        testId,
        testTitle,
        testBody,
        const NotificationDetails(
          iOS: DarwinNotificationDetails(
            badgeNumber: 0,
            presentAlert: true,
            presentBadge: false,
            presentSound: true,
            sound: 'default',
          ),
        ),
      );
    } else if (Platform.isWindows) {
      _showWindowsNotification(testTitle, testBody);
    }

    print("Notification de test envoyée. Vérifiez votre appareil.");
  }

  Future<void> _onDidReceiveNotificationResponse(
      NotificationResponse response) async {
    final String? payload = response.payload;
    if (payload != null) {
      await _handlePointageAction(payload);
    }
    await _resetBadge();
  }
  // Méthode à appeler lorsque l'application est fermée
  Future<void> onAppClosed() async {
    await _resetBadge();
  }
  // Méthode à appeler lorsque l'application est ouverte
  Future<void> onAppOpened() async {
    final currentState = preferencesBloc.state;
    if (currentState is PreferencesLoaded) {
      await _updateBadgeCount(currentState.badgeCount);
    }
  }


  Future<void> _updateNotifications() async {
    if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin.cancelAll();
    }
    await _scheduleNextNotification();
  }

  Future<void> _scheduleNextNotification() async {
    final state = timeSheetBloc.state;
    if (state is TimeSheetDataState) {
      final entry = state.entry;

      if (entry.startMorning.isEmpty) {
        await _scheduleNotification(
          id: 1,
          hour: 9,
          minute: 30,
          title: "Rappel de pointage",
          body: "N'oubliez pas de pointer votre arrivée",
          payload: 'POINTAGE_ENTREE',
        );
      } else if (entry.endMorning.isEmpty) {
        await _scheduleNotification(
          id: 2,
          hour: 12,
          minute: 0,
          title: "Pause déjeuner",
          body: "N'oubliez pas de pointer votre pause",
          payload: 'POINTAGE_PAUSE',
        );
      } else if (entry.startAfternoon.isEmpty) {
        await _scheduleNotification(
          id: 3,
          hour: 13,
          minute: 30,
          title: "Reprise du travail",
          body: "N'oubliez pas de pointer votre reprise",
          payload: 'POINTAGE_REPRISE',
        );
      } else if (entry.endAfternoon.isEmpty) {
        await _scheduleNotification(
          id: 4,
          hour: 18,
          minute: 0,
          title: "Fin de journée",
          body: "N'oubliez pas de pointer votre départ",
          payload: 'POINTAGE_SORTIE',
        );
      }
    }
  }
  Future<void> _incrementBadge() async {
    if (Platform.isIOS) {
      final currentState = preferencesBloc.state;
      if (currentState is PreferencesLoaded) {
        final newBadgeCount = currentState.badgeCount + 1;
        await _updateBadgeCount(newBadgeCount);
      }
    }
  }


  Future<void> _scheduleNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String payload,
  }) async {
    final scheduledDate = _timeFor(hour, minute);

    if (Platform.isIOS) {
      await _scheduleIOSNotification(id, scheduledDate, title, body, payload);
    } else if (Platform.isWindows) {
      _scheduleWindowsNotification(id, scheduledDate, title, body);
    }
  }

  Future<void> _scheduleIOSNotification(
    int id,
    tz.TZDateTime scheduledDate,
    String title,
    String body,
    String payload,
  ) async {
    final currentState = preferencesBloc.state;
    int currentBadgeCount = 0;
    if (currentState is PreferencesLoaded) {
      currentBadgeCount = currentState.badgeCount;
    }
    logger.i('Scheduling notification with id $id at $scheduledDate with payload $payload and current badge count $currentBadgeCount');
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
          sound: 'default',
          categoryIdentifier: 'pointage',
          badgeNumber: currentBadgeCount,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
    await _incrementBadge();
  }


  void _scheduleWindowsNotification(
    int id,
    tz.TZDateTime scheduledDate,
    String title,
    String body,
  ) {
    final now = tz.TZDateTime.now(tz.local);
    final delay = scheduledDate.difference(now);

    Future.delayed(delay, () {
      _showWindowsNotification(title, body);
    });
  }

  void _showWindowsNotification(String title, String body) {
    final hInstance = GetModuleHandle(nullptr);

    final className = 'Flutter Notification'.toNativeUtf16();
    final windowName = 'Flutter Notification'.toNativeUtf16();

    final wc = calloc<WNDCLASS>();
    wc.ref.lpfnWndProc = Pointer.fromFunction<WNDPROC>(DefWindowProc, 0);
    wc.ref.hInstance = hInstance;
    wc.ref.lpszClassName = className;

    RegisterClass(wc);

    final hwnd = CreateWindowEx(
      0,
      className,
      windowName,
      WINDOW_STYLE.WS_OVERLAPPEDWINDOW,
      CW_USEDEFAULT,
      CW_USEDEFAULT,
      CW_USEDEFAULT,
      CW_USEDEFAULT,
      NULL,
      NULL,
      hInstance,
      nullptr,
    );

    final nid = calloc<NOTIFYICONDATA>();
    nid.ref.cbSize = sizeOf<NOTIFYICONDATA>();
    nid.ref.hWnd = hwnd;
    nid.ref.uID = 100;
    nid.ref.uFlags = NOTIFY_ICON_DATA_FLAGS.NIF_INFO;
    nid.ref.dwInfoFlags = NOTIFY_ICON_INFOTIP_FLAGS.NIIF_INFO;
    nid.ref.szInfoTitle = title.toString();
    nid.ref.szInfo = body.toString();

    Shell_NotifyIcon(NOTIFY_ICON_MESSAGE.NIM_ADD, nid);

    free(className);
    free(windowName);
    free(wc);
    free(nid);
  }

  tz.TZDateTime _timeFor(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> _handlePointageAction(String action) async {
    final now = DateTime.now();
    switch (action) {
      case 'POINTAGE_ENTREE':
        timeSheetBloc.add(TimeSheetEnterEvent(now));
        break;
      case 'POINTAGE_PAUSE':
        timeSheetBloc.add(TimeSheetStartBreakEvent(now));
        break;
      case 'POINTAGE_REPRISE':
        timeSheetBloc.add(TimeSheetEndBreakEvent(now));
        break;
      case 'POINTAGE_SORTIE':
        timeSheetBloc.add(TimeSheetOutEvent(now));
        break;
    }
  }
}
