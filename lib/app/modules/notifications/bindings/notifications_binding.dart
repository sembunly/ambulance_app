import 'package:get/get.dart';

import '../../../data/services/notification_service.dart';
import '../controllers/notifications_controller.dart';

class NotificationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationsController>(
      () => NotificationsController(service: Get.find<NotificationService>()),
    );
  }
}
