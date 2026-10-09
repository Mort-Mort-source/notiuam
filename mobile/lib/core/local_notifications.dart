import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotifications {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const init = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(init);

    // Canal de alta importancia para Android 8+
    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notificaciones',
      description: 'Avisos y alertas de NotiUAM',
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> show({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'Notificaciones',
      channelDescription: 'Avisos y alertas de NotiUAM',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}