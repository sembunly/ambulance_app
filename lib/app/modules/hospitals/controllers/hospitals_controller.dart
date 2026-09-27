import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/dashboard_model.dart';
import '../../../data/models/hospital_model.dart';
import '../../../data/services/hospital_service.dart';
import '../../../data/services/location_service.dart';

enum NearbyHospitalsStatus {
  initial,
  locating,
  loading,
  success,
  empty,
  gpsDisabled,
  permissionDenied,
  permissionDeniedForever,
  locationError,
  apiError,
}

class HospitalsController extends GetxController {
  HospitalsController({
    required HospitalService hospitalService,
    required LocationService locationService,
  }) : _hospitalService = hospitalService,
       _locationService = locationService;

  static const int rowsPerPage = 10;

  final HospitalService _hospitalService;
  final LocationService _locationService;

  final Rx<NearbyHospitalsStatus> status = NearbyHospitalsStatus.initial.obs;
  final RxList<HospitalModel> hospitals = <HospitalModel>[].obs;
  final Rxn<DashboardLocation> currentLocation = Rxn<DashboardLocation>();
  final RxString searchText = ''.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = false.obs;
  final RxInt total = 0.obs;
  final RxnString errorMessage = RxnString();
  final RxnString paginationError = RxnString();
  final RxnString actionError = RxnString();

  late final Worker _searchWorker;
  StreamSubscription<DashboardLocation>? _locationSubscription;
  int _page = 1;
  int _operationId = 0;

  bool get hasHospitals => hospitals.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _searchWorker = debounce<String>(
      searchText,
      (_) => unawaited(_reloadForSearch()),
      time: const Duration(milliseconds: 450),
    );
    unawaited(refreshHospitals());
  }

  void updateSearch(String value) {
    searchText.value = value;
  }

  Future<void> refreshHospitals() {
    return _loadFirstPage(refreshLocation: true);
  }

  Future<void> retry() {
    final needsLocation = currentLocation.value == null;
    return _loadFirstPage(refreshLocation: needsLocation);
  }

  Future<void> handleLocationAction() async {
    actionError.value = null;
    try {
      switch (status.value) {
        case NearbyHospitalsStatus.gpsDisabled:
          await _locationService.openLocationSettings();
        case NearbyHospitalsStatus.permissionDeniedForever:
          await _locationService.openAppSettings();
        case NearbyHospitalsStatus.initial ||
            NearbyHospitalsStatus.locating ||
            NearbyHospitalsStatus.loading ||
            NearbyHospitalsStatus.success ||
            NearbyHospitalsStatus.empty ||
            NearbyHospitalsStatus.permissionDenied ||
            NearbyHospitalsStatus.locationError ||
            NearbyHospitalsStatus.apiError:
          break;
      }
      await _loadFirstPage(refreshLocation: true);
    } catch (_) {
      _setLocationError('Unable to open location settings. Please try again.');
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value || hospitals.isEmpty) return;
    final operationId = _operationId;
    final nextPage = _page + 1;
    isLoadingMore.value = true;
    paginationError.value = null;

    try {
      final page = await _hospitalService.getHospitals(
        searchText: searchText.value,
        page: nextPage,
        rowsPerPage: rowsPerPage,
      );
      if (operationId != _operationId) return;
      final location = currentLocation.value;
      if (location == null) return;

      final merged = <HospitalModel>[
        ...hospitals,
        ..._withDistances(page.hospitals, location),
      ];
      hospitals.assignAll(_deduplicateAndSort(merged));
      _page = nextPage;
      hasMore.value = page.hasMore;
      total.value = page.total ?? hospitals.length;
    } on HospitalApiException catch (error) {
      if (operationId == _operationId) paginationError.value = error.message;
    } catch (_) {
      if (operationId == _operationId) {
        paginationError.value =
            'Unable to load more hospitals. Please try again.';
      }
    } finally {
      if (operationId == _operationId) isLoadingMore.value = false;
    }
  }

  Future<bool> callHospital(HospitalModel hospital) async {
    actionError.value = null;
    final phone = hospital.phone.trim();
    if (phone.isEmpty) {
      actionError.value = 'This hospital does not have a phone number.';
      return false;
    }
    try {
      final uri = Uri(scheme: 'tel', path: phone);
      if (!await canLaunchUrl(uri)) {
        actionError.value = 'Phone calls are not available on this device.';
        return false;
      }
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      actionError.value = 'Unable to open the phone dialer.';
      return false;
    }
  }

  Future<bool> openGoogleMaps(HospitalModel hospital) async {
    actionError.value = null;
    if (!hospital.hasCoordinates) {
      actionError.value = 'Map coordinates are unavailable for this hospital.';
      return false;
    }
    try {
      final destination = '${hospital.latitude},${hospital.longitude}';
      final uri = Uri.https('www.google.com', '/maps/dir/', <String, String>{
        'api': '1',
        'destination': destination,
      });
      if (!await canLaunchUrl(uri)) {
        actionError.value = 'Maps is not available on this device.';
        return false;
      }
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      actionError.value = 'Unable to open Maps.';
      return false;
    }
  }

  Future<void> _reloadForSearch() {
    return _loadFirstPage(refreshLocation: currentLocation.value == null);
  }

  Future<void> _loadFirstPage({required bool refreshLocation}) async {
    final operationId = ++_operationId;
    errorMessage.value = null;
    paginationError.value = null;
    isLoadingMore.value = false;
    hasMore.value = false;

    var location = currentLocation.value;
    if (refreshLocation || location == null) {
      status.value = NearbyHospitalsStatus.locating;
      hospitals.clear();
      location = await _readCurrentLocation(operationId);
      if (operationId != _operationId || location == null) return;
    }

    status.value = NearbyHospitalsStatus.loading;
    hospitals.clear();
    try {
      final page = await _hospitalService.getHospitals(
        searchText: searchText.value,
        page: 1,
        rowsPerPage: rowsPerPage,
      );
      if (operationId != _operationId) return;

      final sorted = _deduplicateAndSort(
        _withDistances(page.hospitals, location),
      );
      hospitals.assignAll(sorted);
      _page = 1;
      hasMore.value = page.hasMore;
      total.value = page.total ?? sorted.length;
      status.value = sorted.isEmpty
          ? NearbyHospitalsStatus.empty
          : NearbyHospitalsStatus.success;
    } on HospitalApiException catch (error) {
      if (operationId == _operationId) _setApiError(error.message);
    } catch (_) {
      if (operationId == _operationId) {
        _setApiError('Unable to load nearby hospitals. Please try again.');
      }
    }
  }

  Future<DashboardLocation?> _readCurrentLocation(int operationId) async {
    try {
      await _locationSubscription?.cancel();
      _locationSubscription = null;

      if (!await _locationService.isServiceEnabled()) {
        if (operationId == _operationId) {
          _setLocationState(
            NearbyHospitalsStatus.gpsDisabled,
            'Location Services are turned off.',
          );
        }
        return null;
      }

      var permission = await _locationService.checkPermission();
      if (permission == LocationPermissionStatus.denied) {
        permission = await _locationService.requestPermission();
      }
      if (operationId != _operationId) return null;

      if (permission == LocationPermissionStatus.denied) {
        _setLocationState(
          NearbyHospitalsStatus.permissionDenied,
          'Location permission is required to find nearby hospitals.',
        );
        return null;
      }
      if (permission == LocationPermissionStatus.deniedForever) {
        _setLocationState(
          NearbyHospitalsStatus.permissionDeniedForever,
          'Location permission is blocked. Allow it from App Settings.',
        );
        return null;
      }

      final location = await _locationService.getCurrentLocation();
      if (operationId != _operationId) return null;
      if (location == null) {
        _setLocationError('Your current location is unavailable.');
        return null;
      }
      currentLocation.value = location;
      _startWatchingLocation();
      return location;
    } catch (_) {
      if (operationId == _operationId) {
        _setLocationError(
          'Unable to read your current location. Please try again.',
        );
      }
      return null;
    }
  }

  void _startWatchingLocation() {
    _locationSubscription = _locationService
        .watchLocation(distanceFilter: 1.0)
        .listen(
          (location) {
            currentLocation.value = location;
            if (hospitals.isEmpty) return;
            hospitals.assignAll(
              _deduplicateAndSort(_withDistances(hospitals.toList(), location)),
            );
          },
          onError: (_) {
            // Keep the last reliable distance visible. A pull-to-refresh
            // restarts the stream if the platform stops location updates.
          },
        );
  }

  List<HospitalModel> _withDistances(
    List<HospitalModel> source,
    DashboardLocation location,
  ) {
    return source
        .map((hospital) {
          if (!hospital.hasCoordinates) return hospital;
          final distance = Geolocator.distanceBetween(
            location.latitude,
            location.longitude,
            hospital.latitude!,
            hospital.longitude!,
          );
          return hospital.copyWith(distanceMeters: distance);
        })
        .toList(growable: false);
  }

  List<HospitalModel> _deduplicateAndSort(List<HospitalModel> source) {
    final unique = <String, HospitalModel>{};
    for (final hospital in source) {
      final key = hospital.id.isNotEmpty
          ? hospital.id
          : '${hospital.displayName}|${hospital.latitude}|${hospital.longitude}';
      unique[key] = hospital;
    }
    final result = unique.values.toList(growable: false);
    result.sort((a, b) {
      final aDistance = a.distanceMeters ?? double.infinity;
      final bDistance = b.distanceMeters ?? double.infinity;
      final distanceOrder = aDistance.compareTo(bDistance);
      if (distanceOrder != 0) return distanceOrder;
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });
    return result;
  }

  void _setLocationState(NearbyHospitalsStatus nextStatus, String message) {
    currentLocation.value = null;
    hospitals.clear();
    status.value = nextStatus;
    errorMessage.value = message;
  }

  void _setLocationError(String message) {
    _setLocationState(NearbyHospitalsStatus.locationError, message);
  }

  void _setApiError(String message) {
    hospitals.clear();
    status.value = NearbyHospitalsStatus.apiError;
    errorMessage.value = message;
  }

  @override
  void onClose() {
    unawaited(_locationSubscription?.cancel());
    _searchWorker.dispose();
    super.onClose();
  }
}
