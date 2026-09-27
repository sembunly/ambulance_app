import 'package:get/get.dart';

import 'data/providers/api_provider.dart';
import 'data/services/location_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/storage_service.dart';

class DependencyInjection {
  static void init() {
    final storageService = Get.put<StorageService>(
      StorageService(),
      permanent: true,
    );
    Get.put<ApiProvider>(
      ApiProvider(storageService: storageService),
      permanent: true,
    );
    Get.put<LocationService>(LocationService(), permanent: true);
    Get.put<NotificationService>(NotificationService(), permanent: true);
  }
}
