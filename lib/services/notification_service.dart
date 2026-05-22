import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'jowi_care_reminders',
    'Jowi Care 提醒',
    description: '零食到期、換水、換乾燥劑等提醒',
    importance: Importance.high,
  );

  Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Taipei'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // 建立 Android notification channel
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  /// 排程零食到期提醒：到期前 7 天 + 當天，早上 8:00
  Future<void> scheduleSnackExpiry({
    required int baseId,       // 用 snack index 區分 id
    required String snackName,
    required DateTime expiresAt,
    required String titleExpiring, // 中英文由呼叫端傳入
    required String titleExpired,
    required String bodyExpiring,
    required String bodyExpired,
  }) async {
    final sevenDaysBefore = expiresAt.subtract(const Duration(days: 7));
    final now = DateTime.now();

    // 到期前 7 天 08:00
    if (sevenDaysBefore.isAfter(now)) {
      await _scheduleAt(
        id: baseId * 10 + 1,
        title: titleExpiring,
        body: bodyExpiring,
        scheduledDate: _at8am(sevenDaysBefore),
      );
    }

    // 到期當天 08:00
    if (expiresAt.isAfter(now)) {
      await _scheduleAt(
        id: baseId * 10 + 2,
        title: titleExpired,
        body: bodyExpired,
        scheduledDate: _at8am(expiresAt),
      );
    }
  }

  /// 取消某筆零食的所有提醒
  Future<void> cancelSnackNotifications(int baseId) async {
    await _plugin.cancel(baseId * 10 + 1);
    await _plugin.cancel(baseId * 10 + 2);
  }

  /// 立即顯示一則通知（測試用）
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> _scheduleAt({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// 將日期設為當天 08:00（台北時間）
  tz.TZDateTime _at8am(DateTime date) {
    final taipei = tz.getLocation('Asia/Taipei');
    return tz.TZDateTime(taipei, date.year, date.month, date.day, 8, 0);
  }
}
