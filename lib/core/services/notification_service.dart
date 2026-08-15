import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Daily local reminder to record today's spending. No backend involved.
class NotificationService {
  NotificationService();

  static const int _reminderId = 1001;
  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'duitku_reminder',
    'Pengingat Harian',
    channelDescription: 'Pengingat untuk mencatat transaksi harian',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    try {
      await _plugin.initialize(settings: settings);
      _initialized = true;
    } on Object catch (error) {
      debugPrint('Notification init failed: $error');
    }
  }

  Future<bool> requestPermission() async {
    await init();
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(alert: true, badge: true, sound: true) ??
            false;
      }
    } on Object catch (error) {
      debugPrint('Notification permission failed: $error');
    }
    return false;
  }

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await init();
    await cancelReminder();
    try {
      await _plugin.zonedSchedule(
        id: _reminderId,
        title: 'DUITKU',
        body: 'Sudah mencatat pengeluaran hari ini?',
        scheduledDate: _nextInstanceOf(hour, minute),
        notificationDetails: const NotificationDetails(
          android: _androidDetails,
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } on Object catch (error) {
      debugPrint('Schedule reminder failed: $error');
    }
  }

  Future<void> cancelReminder() async {
    await init();
    try {
      await _plugin.cancel(id: _reminderId);
    } on Object catch (error) {
      debugPrint('Cancel reminder failed: $error');
    }
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
