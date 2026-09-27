import 'package:get/get.dart';

import '../../../data/providers/api_provider.dart';
import '../../../data/services/storage_service.dart';
import '../controllers/settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsController>(
      () => SettingsController(
        apiProvider: Get.find<ApiProvider>(),
        storageService: Get.find<StorageService>(),
      ),
    );
  }
}
