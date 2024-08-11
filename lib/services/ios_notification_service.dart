import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:time_sheet/services/logger_service.dart';
import 'package:win32/win32.dart';

import '../features/pointage/presentation/pages/time-sheet/bloc/time_sheet/time_sheet_bloc.dart';

class MultiplatformNotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  final TimeSheetBloc timeSheetBloc;

  MultiplatformNotificationService({required this.timeSheetBloc});

  Future<void> initNotifications() async {
    if (Platform.isIOS) {
      await _initIOSNotifications();
    } else if (Platform.isWindows) {
      // Pas besoin d'initialisation spécifique pour Windows
    }
  }

  Future<void> _initIOSNotifications() async {
    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
    InitializationSettings(iOS: initializationSettingsIOS);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    logger.i('Notifications initialisées');
  }
  Future<void> _onDidReceiveNotificationResponse(NotificationResponse response) async {
    final String? payload = response.payload;
    if (payload != null) {
      await _handlePointageAction(payload);
    }
  }

  Future<bool?> requestPermissions() async {
    final bool? result = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return result;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    logger.i('Tentative d\'affichage de notification: $title');
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
    DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      threadIdentifier: 'thread_id',
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(iOS: iOSPlatformChannelSpecifics);

    try {
      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
      logger.i('Notification affichée avec succès: $title');
    } catch (e) {
      logger.e('Erreur lors de l\'affichage de la notification: $e');
    }
  }

  Future<void> _handlePointageAction(String action) async {
    switch (action) {
      case 'POINTAGE_ENTREE':
        timeSheetBloc.add(TimeSheetEnterEvent(DateTime.now()));
        break;
      case 'POINTAGE_PAUSE':
        timeSheetBloc.add(TimeSheetStartBreakEvent(DateTime.now()));
        break;
      case 'POINTAGE_REPRISE':
        timeSheetBloc.add(TimeSheetEndBreakEvent(DateTime.now()));
        break;
      case 'POINTAGE_SORTIE':
        timeSheetBloc.add(TimeSheetOutEvent(DateTime.now()));
        break;
    }
  }

  Future<void> schedulePointageNotifications() async {
    await _scheduleNotification(
      id: 1,
      hour: 9,
      minute: 30,
      title: "Rappel de pointage",
      body: "N'oubliez pas de pointer votre arrivée",
      payload: 'POINTAGE_ENTREE',
    );

    await _scheduleNotification(
      id: 2,
      hour: 12,
      minute: 0,
      title: "Pause déjeuner",
      body: "N'oubliez pas de pointer votre pause",
      payload: 'POINTAGE_PAUSE',
    );

    await _scheduleNotification(
      id: 3,
      hour: 13,
      minute: 30,
      title: "Reprise du travail",
      body: "N'oubliez pas de pointer votre reprise",
      payload: 'POINTAGE_REPRISE',
    );

    await _scheduleNotification(
      id: 4,
      hour: 18,
      minute: 0,
      title: "Fin de journée",
      body: "N'oubliez pas de pointer votre départ",
      payload: 'POINTAGE_SORTIE',
    );
  }

  Future<void> _scheduleNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String payload,
  }) async {
    if (Platform.isIOS) {
      await _scheduleIOSNotification(id, hour, minute, title, body, payload);
    } else if (Platform.isWindows) {
      _scheduleWindowsNotification(id, hour, minute, title, body);
    }
  }

  Future<void> _scheduleIOSNotification(   int id,
      int hour,
      int minute,
      String title,
      String body,
      String payload,) async {
    final tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
    DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      badgeNumber: 1,
      categoryIdentifier: 'pointage',
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(iOS: iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      platformChannelSpecifics,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );

    logger.i('Notification planifiée pour $scheduledDate');
  }

  void _scheduleWindowsNotification(
      int id,
      int hour,
      int minute,
      String title,
      String body,
      ) {
    final now = DateTime.now();
    final scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
    final delay = scheduledTime.difference(now);

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

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}