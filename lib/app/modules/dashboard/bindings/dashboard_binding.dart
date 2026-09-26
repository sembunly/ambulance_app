import 'package:get/get.dart';

import '../../../data/providers/api_provider.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/storage_service.dart';
import '../controllers/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(
      () => DashboardController(
        apiProvider: Get.find<ApiProvider>(),
        storageService: Get.find<StorageService>(),
        locationService: Get.find<LocationService>(),
      ),
    );
  }
}
