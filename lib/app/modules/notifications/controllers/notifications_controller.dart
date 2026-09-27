import 'package:get/get.dart';

import '../../../data/models/app_notification.dart';
import '../../../data/services/notification_service.dart';

enum NotificationStatus { initial, loading, success, empty, error }

class NotificationsController extends GetxController {
  NotificationsController({required NotificationService service})
    : _service = service;

  final NotificationService _service;

  final Rx<NotificationStatus> status = NotificationStatus.initial.obs;
  final RxList<AppNotification> notifications = <AppNotification>[].obs;
  final RxnString errorMessage = RxnString();
  final RxBool isLoading = false.obs;
  final RxString message = ''.obs;

  // ──────────────────────────────────────────────────────────────────
  // Lifecycle
  // ──────────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  // ──────────────────────────────────────────────────────────────────
  // Public actions
  // ──────────────────────────────────────────────────────────────────

  Future<void> loadNotifications() async {
    if (status.value == NotificationStatus.loading) return;

    try {
      status.value = NotificationStatus.loading;
      errorMessage.value = null;

      await _service.initialize();

      status.value = notifications.isEmpty
          ? NotificationStatus.empty
          : NotificationStatus.success;
    } catch (error) {
      status.value = NotificationStatus.error;
      errorMessage.value = error.toString();
    }
  }

  Future<void> sendStaticNotification() async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      message.value = '';

      final granted = await _service.requestPermission();
      if (!granted) {
        message.value = 'Notification permission was denied.';
        return;
      }

      final notification = AppNotification(
        id: 1001,
        title: 'Ambulance Booking',
        body: 'Your ambulance request has been submitted.',
        payload: 'ambulance_booking_1001',
        createdAt: DateTime.now(),
      );

      await _service.showNotification(notification);

      notifications
        ..removeWhere((n) => n.id == notification.id)
        ..add(notification);

      status.value = NotificationStatus.success;
      message.value = 'Notification sent successfully.';
    } catch (error) {
      status.value = NotificationStatus.error;
      message.value = 'Failed to send notification: $error';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cancelNotification() async {
    try {
      await _service.cancelNotification(1001);
      notifications.removeWhere((n) => n.id == 1001);
      message.value = 'Notification cancelled.';
      status.value = notifications.isEmpty
          ? NotificationStatus.empty
          : NotificationStatus.success;
    } catch (error) {
      message.value = 'Unable to cancel notification: $error';
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _service.cancelAllNotifications();
      notifications.clear();
      status.value = NotificationStatus.empty;
      message.value = 'All notifications cancelled.';
    } catch (error) {
      message.value = 'Unable to cancel notifications: $error';
    }
  }

  void markAsRead(int id) {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index < 0) return;
    notifications[index] = notifications[index].copyWith(isRead: true);
  }
}
