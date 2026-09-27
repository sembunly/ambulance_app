import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/notifications_controller.dart';

/// Migrated from [NotificationTestScreen] — rebuilt as a GetX [GetView].
/// All notification plugin setup lives in [NotificationService]; this view only
/// drives UI state through [NotificationsController].
class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Actions ──────────────────────────────────────────────
            Obx(
              () => FilledButton.icon(
                onPressed: controller.isLoading.value
                    ? null
                    : controller.sendStaticNotification,
                icon: controller.isLoading.value
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.notifications_active),
                label: const Text('Send Test Notification'),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: controller.cancelNotification,
              icon: const Icon(Icons.notifications_off),
              label: const Text('Cancel Notification'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: controller.cancelAllNotifications,
              icon: const Icon(Icons.clear_all),
              label: const Text('Cancel All Notifications'),
            ),
            const SizedBox(height: 24),

            // ── Status / feedback ─────────────────────────────────────
            Obx(() {
              final status = controller.status.value;
              final msg = controller.message.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status: ${status.name}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (msg.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        msg,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: status == NotificationStatus.error
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ),
                ],
              );
            }),
            const SizedBox(height: 16),

            // ── Notification list ─────────────────────────────────────
            Text(
              'Notifications',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Obx(() {
                if (controller.notifications.isEmpty) {
                  return const Center(child: Text('No notifications yet.'));
                }
                return ListView.separated(
                  itemCount: controller.notifications.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final notification = controller.notifications[index];
                    return ListTile(
                      leading: Icon(
                        notification.isRead
                            ? Icons.mark_email_read_outlined
                            : Icons.mark_email_unread_outlined,
                        color: notification.isRead ? Colors.grey : Colors.blue,
                      ),
                      title: Text(notification.title),
                      subtitle: Text(notification.body),
                      trailing: notification.isRead
                          ? null
                          : TextButton(
                              onPressed: () =>
                                  controller.markAsRead(notification.id),
                              child: const Text('Mark read'),
                            ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
