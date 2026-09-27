import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/app_notification.dart';

/// Wraps [FlutterLocalNotificationsPlugin] and is registered as a permanent
/// GetX service via [DependencyInjection].  All notification plugin setup
/// (initialisation, permission requests, channel config) lives here — nothing
/// is placed inside views or controllers.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? notificationsPlugin})
    : _notificationsPlugin =
          notificationsPlugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _notificationsPlugin;

  bool _isInitialized = false;

  // ──────────────────────────────────────────────────────────────────
  // Initialisation
  // ──────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('ic_notification');

    // flutter_local_notifications v9+ renamed IOSInitializationSettings →
    // DarwinInitializationSettings.
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  // ──────────────────────────────────────────────────────────────────
  // Permission
  // ──────────────────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    await initialize();

    if (defaultTargetPlatform == TargetPlatform.android) {
      final plugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await plugin?.requestNotificationsPermission() ?? false;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final plugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await plugin?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return true;
  }

  // ──────────────────────────────────────────────────────────────────
  // Show / Cancel
  // ──────────────────────────────────────────────────────────────────

  Future<void> showNotification(AppNotification notification) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'ambulance_booking_channel',
      'Ambulance Booking',
      channelDescription: 'Ambulance booking status notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      ticker: 'Ambulance notification',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    // flutter_local_notifications v22 uses named params for show().
    await _notificationsPlugin.show(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
      payload: notification.payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await initialize();
    await _notificationsPlugin.cancel(id: id);
  }

  Future<void> cancelAllNotifications() async {
    await initialize();
    await _notificationsPlugin.cancelAll();
  }

  // ──────────────────────────────────────────────────────────────────
  // Private
  // ──────────────────────────────────────────────────────────────────

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint(
      'Notification tapped — id: ${response.id}, '
      'payload: ${response.payload}',
    );
    // Navigate to booking status when ready:
    // Get.toNamed(Routes.ambulance, arguments: response.payload);
  }
}
