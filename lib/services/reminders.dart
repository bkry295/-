import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/habit.dart';

abstract interface class ReminderService {
  bool get supported;
  Future<String?> configure(Habit habit, {bool requestPermission = false});
  Future<String> test(Habit habit);
}

class LocalReminderService implements ReminderService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  @override
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  Future<bool> _permission(bool request) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()!;
      return (request
              ? await android.requestNotificationsPermission()
              : await android.areNotificationsEnabled()) ??
          false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()!;
    if (request) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return (await ios.checkPermissions())?.isEnabled ?? false;
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_habit',
      '毎日のリマインダー',
      channelDescription: '毎日続けることを思い出すための通知',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
  );

  @override
  Future<String?> configure(
    Habit habit, {
    bool requestPermission = false,
  }) async {
    if (!supported) {
      return habit.notificationsEnabled ? '通知はAndroid・iPhoneアプリで利用できます。' : null;
    }
    await _initialize();
    await _plugin.cancel(1);
    if (!habit.notificationsEnabled) return null;
    if (!await _permission(requestPermission)) {
      return '通知が許可されていません。端末の設定から通知を許可してください。';
    }
    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone.identifier));
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      habit.hour,
      habit.minute,
    );
    if (!next.isAfter(now)) {
      next = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + 1,
        habit.hour,
        habit.minute,
      );
    }
    await _plugin.zonedSchedule(
      1,
      '今日も、小さな一歩を。',
      habit.action,
      next,
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    return null;
  }

  @override
  Future<String> test(Habit habit) async {
    if (!supported) return '通知のテストはAndroid・iPhoneアプリで利用できます。';
    if (!habit.notificationsEnabled) return '「通知を受け取る」をオンにしてください。';
    await _initialize();
    if (!await _permission(true)) return '端末の設定から通知を許可してください。';
    await _plugin.show(2, 'まいにち｜通知のテスト', habit.action, _details);
    return 'テスト通知を送信しました。';
  }
}
