// lib/data/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  /// Call this during app startup (main.dart) to initialize notifications.
  static Future<void> init() async {
    // Android settings: specify launcher icon and set up the notification channel
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings (add if you want to support iOS later)
    // final iOS = DarwinInitializationSettings(); // Only if you plan for iOS

    // Combine into initialization settings
    const settings = InitializationSettings(
      android: android,
      // iOS: iOS, // Only if supporting iOS
    );

    await _notifications.initialize(settings);
  }

  /// Show a local notification with given title & body.
  static Future<void> showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'booking_channel', // ID (must be unique and stable)
      'Booking Notifications', // Name shown in device settings
      channelDescription: 'Channel for booking confirmations and updates.',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      0,      // Notification ID
      title,  // Notification title
      body,   // Notification body
      details,
    );
  }
}
