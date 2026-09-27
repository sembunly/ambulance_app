import 'package:get/get.dart';

import '../../../data/providers/api_provider.dart';
import '../../../data/services/hospital_service.dart';
import '../../../data/services/location_service.dart';
import '../controllers/hospitals_controller.dart';

class HospitalsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HospitalsController>(
      () => HospitalsController(
        hospitalService: HospitalService(apiProvider: Get.find<ApiProvider>()),
        locationService: Get.find<LocationService>(),
      ),
    );
  }
}
