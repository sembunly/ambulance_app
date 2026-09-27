import 'package:flutter_test/flutter_test.dart';

import 'package:ambulance_app/app/data/models/app_notification.dart';
import 'package:ambulance_app/app/data/services/notification_service.dart';
import 'package:ambulance_app/app/modules/notifications/controllers/notifications_controller.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ---------------------------------------------------------------------------
// Fake plugin — overrides only the methods under test using the real signatures
// as reported by the analyzer (all-named params in this package version).
// ---------------------------------------------------------------------------
class _FakePlugin extends Fake implements FlutterLocalNotificationsPlugin {
  bool initialized = false;
  final List<int> shown = [];
  final List<int> cancelled = [];
  bool cancelledAll = false;

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    void Function(NotificationResponse)? onDidReceiveNotificationResponse,
    void Function(NotificationResponse)?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    initialized = true;
    return true;
  }

  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails,
    String? payload,
  }) async {
    shown.add(id);
  }

  @override
  Future<void> cancel({required int id, String? tag}) async {
    cancelled.add(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelledAll = true;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
AppNotification _notification({
  int id = 1,
  String title = 'T',
  String body = 'B',
}) => AppNotification(
  id: id,
  title: title,
  body: body,
  createdAt: DateTime.utc(2026, 9, 27),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late _FakePlugin fakePlugin;
  late NotificationService service;
  late NotificationsController controller;

  setUp(() {
    fakePlugin = _FakePlugin();
    service = NotificationService(notificationsPlugin: fakePlugin);
    controller = NotificationsController(service: service);
  });

  tearDown(() => controller.onClose());

  // ── AppNotification model ──────────────────────────────────────────────────

  group('AppNotification model', () {
    test('default isRead is false', () {
      expect(_notification().isRead, isFalse);
    });

    test('copyWith overrides only provided fields', () {
      final original = _notification(id: 1, title: 'Title', body: 'Body');
      final copy = original.copyWith(title: 'New', isRead: true);

      expect(copy.id, 1);
      expect(copy.title, 'New');
      expect(copy.body, 'Body');
      expect(copy.isRead, isTrue);
      expect(copy.payload, isNull);
    });

    test('copyWith with no args preserves all fields', () {
      final original = _notification();
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.title, original.title);
      expect(copy.body, original.body);
      expect(copy.isRead, original.isRead);
      expect(copy.payload, original.payload);
    });
  });

  // ── NotificationsController ────────────────────────────────────────────────

  group('NotificationsController', () {
    test('initial status is initial', () {
      expect(controller.status.value, NotificationStatus.initial);
    });

    test('notifications list starts empty', () {
      expect(controller.notifications, isEmpty);
    });

    test('markAsRead updates the isRead flag', () {
      controller.notifications.add(_notification(id: 42));

      controller.markAsRead(42);

      expect(controller.notifications.first.isRead, isTrue);
    });

    test('markAsRead with unknown id does not throw', () {
      expect(() => controller.markAsRead(999), returnsNormally);
    });

    test('cancelNotification removes the item and sets empty status', () async {
      controller.notifications.add(_notification(id: 1001));

      await controller.cancelNotification();

      expect(controller.notifications, isEmpty);
      expect(controller.status.value, NotificationStatus.empty);
      expect(fakePlugin.cancelled, contains(1001));
    });

    test('cancelAllNotifications clears list and sets empty status', () async {
      controller.notifications.addAll([
        _notification(id: 1),
        _notification(id: 2),
      ]);

      await controller.cancelAllNotifications();

      expect(controller.notifications, isEmpty);
      expect(controller.status.value, NotificationStatus.empty);
      expect(fakePlugin.cancelledAll, isTrue);
    });

    test('message is non-empty after cancelNotification', () async {
      await controller.cancelNotification();
      expect(controller.message.value, isNotEmpty);
    });

    test('message is non-empty after cancelAllNotifications', () async {
      await controller.cancelAllNotifications();
      expect(controller.message.value, isNotEmpty);
    });
  });
}
