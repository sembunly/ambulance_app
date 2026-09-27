import 'package:get/get.dart';

import '../../../data/providers/realtime_provider.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/route_service.dart';
import '../controllers/tracking_controller.dart';

class TrackingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TrackingController>(
      () => TrackingController(
        locationService: Get.find<LocationService>(),
        realtimeProvider: Get.find<RealtimeProvider>(),
        routeService: RouteService.fromEnvironment(),
      ),
    );
  }
}
