import 'package:get/get.dart';

import '../../../data/providers/api_provider.dart';
import '../../../data/services/ambulance_request_service.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/storage_service.dart';
import '../controllers/ambulance_controller.dart';

class AmbulanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AmbulanceController>(
      () => AmbulanceController(
        service: AmbulanceRequestService(apiProvider: Get.find<ApiProvider>()),
        apiProvider: Get.find<ApiProvider>(),
        storageService: Get.find<StorageService>(),
        locationService: Get.find<LocationService>(),
      ),
    );
  }
}
