import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/app_config.dart';
import '../../../data/models/dashboard_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/storage_service.dart';

enum DashboardLoadStatus { initial, loading, success, empty, error }

enum DashboardLocationStatus {
  initial,
  loading,
  success,
  empty,
  permissionDenied,
  permissionDeniedForever,
  gpsDisabled,
  error,
}

class DashboardController extends GetxController {
  DashboardController({
    required ApiProvider apiProvider,
    required StorageService storageService,
    required LocationService locationService,
  }) : _apiProvider = apiProvider,
       _storageService = storageService,
       _locationService = locationService;

  final ApiProvider _apiProvider;
  final StorageService _storageService;
  final LocationService _locationService;

  final bookingStatus = DashboardLoadStatus.initial.obs;
  final locationStatus = DashboardLocationStatus.initial.obs;
  final bookings = <DashboardBooking>[].obs;
  final currentLocation = Rxn<DashboardLocation>();
  final userName = ''.obs;
  final emergencyHotline = ''.obs;
  final bookingError = RxnString();
  final locationError = RxnString();
  final actionError = RxnString();

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get locationLabel {
    final location = currentLocation.value;
    if (location == null) return '';
    return '${location.latitude.toStringAsFixed(5)}, '
        '${location.longitude.toStringAsFixed(5)}';
  }

  DashboardBooking? get activeBooking {
    for (final booking in bookings) {
      if (booking.isActive) return booking;
    }
    return null;
  }

  List<DashboardBooking> get recentBookings =>
      bookings.where((booking) => !booking.isActive).take(3).toList();

  List<DashboardBooking> get bookingHistory =>
      bookings.where((booking) => !booking.isActive).toList();

  @override
  void onInit() {
    super.onInit();
    unawaited(refreshDashboard());
  }

  Future<void> refreshDashboard() async {
    await Future.wait<void>([loadBookings(), loadCurrentLocation()]);
  }

  Future<void> loadBookings() async {
    bookingError.value = null;
    bookingStatus.value = DashboardLoadStatus.loading;
    try {
      final session = await _storageService.getUserSession();
      userName.value = session?.displayName.trim().isNotEmpty == true
          ? session!.displayName.trim()
          : session?.username.trim() ?? '';
      final userId = session?.userId.trim() ?? '';
      final response = await _apiProvider.get(
        AppConfig.dispatches,
        queryParameters: userId.isEmpty ? null : {'userId': userId},
      );
      final json = response.data is List
          ? <String, dynamic>{'data': response.data}
          : _asMap(response.data);
      if (json.isEmpty) {
        throw const FormatException('Invalid dashboard response');
      }
      _validateEnvelope(json);

      final data = DashboardData.fromJson(json);
      bookings.assignAll(data.bookings);
      emergencyHotline.value = data.emergencyHotline;
      bookingStatus.value = data.bookings.isEmpty
          ? DashboardLoadStatus.empty
          : DashboardLoadStatus.success;
    } on DioException catch (error) {
      _setBookingError(_dioErrorMessage(error));
    } on FormatException catch (error) {
      _setBookingError(error.message);
    } catch (_) {
      _setBookingError('Unable to load your bookings. Please try again.');
    }
  }

  Future<void> loadCurrentLocation() async {
    locationError.value = null;
    currentLocation.value = null;
    locationStatus.value = DashboardLocationStatus.loading;
    try {
      if (!await _locationService.isServiceEnabled()) {
        _setLocationState(
          DashboardLocationStatus.gpsDisabled,
          'Location Services are turned off.',
        );
        return;
      }

      var permission = await _locationService.checkPermission();
      if (permission == LocationPermissionStatus.denied) {
        permission = await _locationService.requestPermission();
      }
      if (permission == LocationPermissionStatus.denied) {
        _setLocationState(
          DashboardLocationStatus.permissionDenied,
          'Location permission was denied.',
        );
        return;
      }
      if (permission == LocationPermissionStatus.deniedForever) {
        _setLocationState(
          DashboardLocationStatus.permissionDeniedForever,
          'Allow location access from App Settings.',
        );
        return;
      }

      final location = await _locationService.getCurrentLocation();
      currentLocation.value = location;
      locationStatus.value = location == null
          ? DashboardLocationStatus.empty
          : DashboardLocationStatus.success;
      if (location == null) {
        locationError.value = 'Current location is unavailable.';
      }
    } catch (_) {
      _setLocationState(
        DashboardLocationStatus.error,
        'Unable to read your current location.',
      );
    }
  }

  Future<void> handleLocationAction() async {
    if (locationStatus.value == DashboardLocationStatus.gpsDisabled) {
      await _locationService.openLocationSettings();
    } else if (locationStatus.value ==
        DashboardLocationStatus.permissionDeniedForever) {
      await _locationService.openAppSettings();
    }
    await loadCurrentLocation();
  }

  Future<bool> openEmergencyHotline() async {
    actionError.value = null;
    final hotline = emergencyHotline.value.trim();
    if (hotline.isEmpty) {
      actionError.value = 'The emergency hotline is not configured.';
      return false;
    }
    final uri = Uri(scheme: 'tel', path: hotline);
    try {
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

  void _validateEnvelope(Map<String, dynamic> response) {
    final header = _asMap(response['header']);
    if (response['success'] != false && header['result'] != false) return;
    final message =
        (header['errorText'] ?? response['errorText'] ?? response['message'])
            ?.toString()
            .trim();
    throw FormatException(
      message == null || message.isEmpty
          ? 'Unable to load dashboard information.'
          : message,
    );
  }

  String _dioErrorMessage(DioException error) {
    if (error.response == null) return 'Check your internet connection.';
    final data = _asMap(error.response?.data);
    final header = _asMap(data['header']);
    final message =
        (header['errorText'] ?? data['errorText'] ?? data['message'])
            ?.toString()
            .trim();
    return message == null || message.isEmpty
        ? 'Unable to load your bookings. Please try again.'
        : message;
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }

  void _setBookingError(String message) {
    bookings.clear();
    bookingError.value = message;
    bookingStatus.value = DashboardLoadStatus.error;
  }

  void _setLocationState(DashboardLocationStatus status, String message) {
    currentLocation.value = null;
    locationError.value = message;
    locationStatus.value = status;
  }
}
