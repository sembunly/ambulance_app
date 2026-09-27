import 'package:get/get.dart';

import '../../../data/providers/api_provider.dart';
import '../../../data/services/storage_service.dart';
import '../controllers/profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileController>(
      () => ProfileController(
        apiProvider: Get.find<ApiProvider>(),
        storageService: Get.find<StorageService>(),
      ),
    );
  }
}
