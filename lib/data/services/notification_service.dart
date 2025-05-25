// lib/data/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  /// Call this during app startup (main.dart) to initialize notifications.
  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _notifications.initialize(settings);
  }

  /// Show a local notification with given title & body.
  static Future<void> showNotification(String title, String body) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'channelId', // Any unique id
        'App Notifications',
        channelDescription: 'General app notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
    await _notifications.show(0, title, body, details);
  }
}
