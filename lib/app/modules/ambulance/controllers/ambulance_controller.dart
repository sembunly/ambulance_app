import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../../config/app_config.dart';
import '../../../data/models/ambulance_request_model.dart';
import '../../../data/models/dashboard_model.dart';
import '../../../data/models/hospital_model.dart';
import '../../../data/models/login_response.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/ambulance_request_service.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/storage_service.dart';

enum AmbulanceRequestStatus {
  editing,
  submitting,
  success,
  validationError,
  apiError,
}

enum PickupLocationStatus {
  initial,
  locating,
  ready,
  gpsDisabled,
  permissionDenied,
  permissionDeniedForever,
  error,
}

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

class AmbulanceController extends GetxController {
  AmbulanceController({
    required AmbulanceRequestService service,
    required ApiProvider apiProvider,
    required StorageService storageService,
    required LocationService locationService,
    String priorityCode = backendDefaultPriorityCode,
  }) : _service = service,
       _apiProvider = apiProvider,
       _storageService = storageService,
       _locationService = locationService,
       _priorityCode = priorityCode,
       hospitalController = BookingHospitalPicker(
         service: service,
         locationService: locationService,
       );

  static const String backendDefaultPriorityCode = String.fromEnvironment(
    'AMBULANCE_DEFAULT_PRIORITY_CODE',
  );
  static const Map<String, String> emergencyTypeLabels = <String, String>{
    'MEDICAL_EMERGENCY': 'Medical emergency',
    'TRAFFIC_ACCIDENT': 'Road traffic accident',
    'BREATHING_DIFFICULTY': 'Breathing difficulty',
    'INJURY_FALL': 'Injury or fall',
    'OTHER': 'Other emergency',
  };

  final AmbulanceRequestService _service;
  final ApiProvider _apiProvider;
  final StorageService _storageService;
  final LocationService _locationService;
  final String _priorityCode;
  final BookingHospitalPicker hospitalController;
  LoginResponse? _session;
  UserProfile? _profile;
  String profilePhone = '';

  final Rx<AmbulanceRequestDraft> draft = const AmbulanceRequestDraft().obs;
  final Rx<AmbulanceRequestStatus> status = AmbulanceRequestStatus.editing.obs;
  final Rx<PickupLocationStatus> locationStatus =
      PickupLocationStatus.initial.obs;
  final RxInt currentStep = 0.obs;
  final RxBool isInitializing = true.obs;
  final RxnString errorMessage = RxnString();
  final Rxn<AmbulanceBookingResult> bookingResult =
      Rxn<AmbulanceBookingResult>();
  final Rxn<DashboardBooking> currentBooking = Rxn<DashboardBooking>();
  final RxBool isCancellingBooking = false.obs;
  final RxnString actionError = RxnString();

  final patientFormKey = GlobalKey<FormState>();
  final hospitalFormKey = GlobalKey<FormState>();
  final pickupFormKey = GlobalKey<FormState>();
  final emergencyFormKey = GlobalKey<FormState>();
  final patientNameController = TextEditingController();
  final pickupAddressController = TextEditingController();
  final symptomsController = TextEditingController();

  bool get isSubmitting => status.value == AmbulanceRequestStatus.submitting;
  bool get hasSubmitted => bookingResult.value != null;
  String get emergencyTypeLabel =>
      emergencyTypeLabels[draft.value.typeCode] ?? draft.value.typeCode;

  Future<void> initialize() async {
    isInitializing.value = true;
    try {
      try {
        _session = await _storageService.getUserSession();
        final userId = _session?.userId.trim() ?? '';
        if (userId.isNotEmpty) {
          final response = await _apiProvider.get(
            '${AppConfig.userProfile}${Uri.encodeComponent(userId)}',
          );
          final json = _asMap(response.data);
          if (json['success'] != false &&
              _asMap(json['header'])['result'] != false) {
            _profile = UserProfile.fromJson(json);
            profilePhone = _profile?.phone.trim() ?? '';
          }
        }
      } catch (_) {
        // Session display name still provides a patient default if profile fails.
      }
      if (isClosed) return;
      _applyLoggedInPatient();
      unawaited(hospitalController.refreshHospitals());
    } finally {
      isInitializing.value = false;
    }
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }

  void selectRequestFor(AmbulanceRequestFor value) {
    if (value == AmbulanceRequestFor.myself) {
      _applyLoggedInPatient();
    } else {
      patientNameController.clear();
      draft.value = draft.value.copyWith(
        requestFor: value,
        patientId: '',
        patientName: '',
        clearPatientAge: true,
        patientGender: '',
      );
    }
    _setEditing();
  }

  void _applyLoggedInPatient() {
    final profile = _profile;
    final session = _session;
    final profileName = profile == null
        ? ''
        : <String>[
            profile.firstName.trim(),
            profile.lastName.trim(),
          ].where((part) => part.isNotEmpty).join(' ');
    final patientName = profileName.isNotEmpty
        ? profileName
        : profile?.username.trim().isNotEmpty == true
        ? profile!.username.trim()
        : session?.displayName.trim() ?? '';
    final age = _ageFromDateOfBirth(profile?.dateOfBirth);
    patientNameController.text = patientName;
    draft.value = draft.value.copyWith(
      requestFor: AmbulanceRequestFor.myself,
      patientId: session?.userId.trim() ?? '',
      patientName: patientName,
      patientAge: age,
      clearPatientAge: age == null,
      patientGender: profile?.gender.trim() ?? '',
      priorityCode: _priorityCode,
    );
  }

  int? _ageFromDateOfBirth(DateTime? birthDate) {
    if (birthDate == null) return null;
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age >= 0 ? age : null;
  }

  void updatePatientName(String value) {
    draft.value = draft.value.copyWith(patientName: value.trim());
    _setEditing();
  }

  void updatePatientGender(ReportedGender? value) {
    draft.value = draft.value.copyWith(patientGender: value?.apiValue ?? '');
    _setEditing();
  }

  void selectHospital(HospitalModel hospital) {
    draft.value = draft.value.copyWith(hospital: hospital);
    _setEditing();
  }

  void updatePickupAddress(String value) {
    draft.value = draft.value.copyWith(locationAddress: value.trim());
    _setEditing();
  }

  Future<void> useCurrentLocation() async {
    if (locationStatus.value == PickupLocationStatus.locating) return;
    errorMessage.value = null;
    locationStatus.value = PickupLocationStatus.locating;
    try {
      if (!await _locationService.isServiceEnabled()) {
        _setLocationError(
          PickupLocationStatus.gpsDisabled,
          'Location Services are turned off.',
        );
        return;
      }
      var permission = await _locationService.checkPermission();
      if (permission == LocationPermissionStatus.denied) {
        permission = await _locationService.requestPermission();
      }
      if (permission == LocationPermissionStatus.denied) {
        _setLocationError(
          PickupLocationStatus.permissionDenied,
          'Location permission is required for the pickup location.',
        );
        return;
      }
      if (permission == LocationPermissionStatus.deniedForever) {
        _setLocationError(
          PickupLocationStatus.permissionDeniedForever,
          'Location permission is blocked. Allow it in App Settings.',
        );
        return;
      }
      final location = await _locationService.getCurrentLocation();
      if (location == null) {
        _setLocationError(
          PickupLocationStatus.error,
          'Your current GPS location is unavailable.',
        );
        return;
      }
      final latitude = location.latitude;
      final longitude = location.longitude;
      final gpsLocation =
          '${latitude.toStringAsFixed(6)}, '
          '${longitude.toStringAsFixed(6)}';
      if (pickupAddressController.text.trim().isEmpty) {
        pickupAddressController.text = gpsLocation;
      }
      draft.value = draft.value.copyWith(
        latitude: latitude,
        longitude: longitude,
        locationAccuracyMeters: location.accuracy,
        locationAddress: pickupAddressController.text.trim(),
      );
      locationStatus.value = PickupLocationStatus.ready;
      _setEditing();
    } catch (_) {
      _setLocationError(
        PickupLocationStatus.error,
        'Unable to read your current location. Please try again.',
      );
    }
  }

  Future<void> handleLocationAction() async {
    if (locationStatus.value == PickupLocationStatus.gpsDisabled) {
      await _locationService.openLocationSettings();
    } else if (locationStatus.value ==
        PickupLocationStatus.permissionDeniedForever) {
      await _locationService.openAppSettings();
    }
    await useCurrentLocation();
  }

  void selectTypeCode(String? value) {
    draft.value = draft.value.copyWith(typeCode: value ?? '');
    _setEditing();
  }

  void selectPriorityCode(String? value) {
    draft.value = draft.value.copyWith(priorityCode: value ?? '');
    _setEditing();
  }

  void updateSymptoms(String value) {
    draft.value = draft.value.copyWith(symptoms: value.trim());
    _setEditing();
  }

  void updateNote(String value) {
    draft.value = draft.value.copyWith(note: value.trim());
    _setEditing();
  }

  bool validateCurrentStep() {
    final bool valid;
    switch (currentStep.value) {
      case 0:
        final formValid = patientFormKey.currentState?.validate() ?? true;
        final stateValid = validatePatient();
        valid = formValid && stateValid;
      case 1:
        valid = validateHospital();
      case 2:
        final formValid = pickupFormKey.currentState?.validate() ?? true;
        final stateValid = validatePickup();
        valid = formValid && stateValid;
      case 3:
        final formValid = emergencyFormKey.currentState?.validate() ?? true;
        final stateValid = validateEmergency();
        valid = formValid && stateValid;
      default:
        valid = validateAll();
    }
    if (!valid && errorMessage.value == null) {
      _setValidationError('Please correct the highlighted information.');
    }
    return valid;
  }

  bool validatePatient() {
    final value = draft.value;
    if (value.patientName.trim().isEmpty) {
      _setValidationError('Enter the patient name.');
      return false;
    }
    return true;
  }

  bool validateHospital() {
    final hospitalId = int.tryParse(draft.value.hospital?.id ?? '');
    if (hospitalId == null || hospitalId <= 0) {
      _setValidationError('Select a valid hospital.');
      return false;
    }
    return true;
  }

  bool validatePickup() {
    final value = draft.value;
    final latitude = value.latitude;
    final longitude = value.longitude;
    final accuracy = value.locationAccuracyMeters;
    if (latitude == null ||
        longitude == null ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180 ||
        (latitude == 0 && longitude == 0)) {
      _setValidationError('Capture a valid GPS pickup location.');
      return false;
    }
    if (accuracy == null || !accuracy.isFinite || accuracy <= 0) {
      _setValidationError('GPS accuracy is unavailable. Capture it again.');
      return false;
    }
    if (value.locationAddress.trim().isEmpty) {
      _setValidationError('Enter the pickup address.');
      return false;
    }
    return true;
  }

  bool validateEmergency() {
    final value = draft.value;
    if (value.typeCode.trim().isEmpty) {
      _setValidationError('Select the emergency type.');
      return false;
    }
    return true;
  }

  bool validateAll() {
    if (!validatePatient()) return false;
    if (!validateHospital()) return false;
    if (!validatePickup()) return false;
    if (!validateEmergency()) return false;
    return true;
  }

  bool goNext() {
    FocusManager.instance.primaryFocus?.unfocus();
    errorMessage.value = null;
    if (!validateCurrentStep()) return false;
    if (currentStep.value < 3) currentStep.value++;
    _setEditing();
    return true;
  }

  bool goBack() {
    if (currentStep.value == 0) return false;
    currentStep.value--;
    errorMessage.value = null;
    return true;
  }

  void editStep(int step) {
    currentStep.value = step.clamp(0, 3);
    errorMessage.value = null;
    status.value = AmbulanceRequestStatus.editing;
  }

  Future<AmbulanceBookingResult?> submit() async {
    if (isSubmitting || hasSubmitted) return bookingResult.value;
    if (!validateAll()) return null;
    errorMessage.value = null;
    status.value = AmbulanceRequestStatus.submitting;
    try {
      final result = await _service.submit(draft.value);
      bookingResult.value = result;
      status.value = AmbulanceRequestStatus.success;
      return result;
    } on BookingApiException catch (error) {
      final message = error.message.trim().isEmpty
          ? 'Unable to submit the ambulance request.'
          : error.message;
      if (error.statusCode == 400 || error.statusCode == 422) {
        _setValidationError(message);
      } else {
        status.value = AmbulanceRequestStatus.apiError;
        errorMessage.value = message;
      }
      return null;
    } catch (_) {
      status.value = AmbulanceRequestStatus.apiError;
      errorMessage.value =
          'Unable to submit the ambulance request. Please try again.';
      return null;
    }
  }

  String? validatePatientName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Patient name is required';
    if (text.length > 200) return 'Use 200 characters or fewer';
    return null;
  }

  String? validatePickupAddress(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Pickup address is required';
    if (text.length > 255) return 'Use 255 characters or fewer';
    return null;
  }

  void _setEditing() {
    if (isSubmitting || hasSubmitted) return;
    errorMessage.value = null;
    status.value = AmbulanceRequestStatus.editing;
  }

  void _setValidationError(String message) {
    status.value = AmbulanceRequestStatus.validationError;
    errorMessage.value = message;
  }

  void _setLocationError(PickupLocationStatus next, String message) {
    locationStatus.value = next;
    _setValidationError(message);
  }

  Future<void> refreshBookingStatus(AmbulanceBookingResult result) async {
    try {
      final userId = (await _storageService.getUserSession())?.userId ?? '';
      final response = await _service.fetchDispatches(userId: userId);
      final bookings = DashboardData.fromJson(response).bookings;
      for (final booking in bookings) {
        if ((result.id.isNotEmpty && booking.id == result.id) ||
            (result.code.isNotEmpty && booking.code == result.code)) {
          currentBooking.value = booking;
          return;
        }
      }
    } catch (_) {
      // The submitted status remains visible until the next refresh.
    }
  }

  Future<bool> cancelBooking(String bookingId) async {
    if (isCancellingBooking.value) return false;
    isCancellingBooking.value = true;
    actionError.value = null;
    try {
      await _service.cancelBooking(bookingId);
      return true;
    } on BookingApiException catch (error) {
      actionError.value = error.message;
      return false;
    } catch (_) {
      actionError.value = 'Unable to cancel this booking. Please try again.';
      return false;
    } finally {
      isCancellingBooking.value = false;
    }
  }

  @override
  void onClose() {
    hospitalController.dispose();
    patientNameController.dispose();
    pickupAddressController.dispose();
    symptomsController.dispose();
    super.onClose();
  }
}

/// Hospital choices used by the booking form. The Hospitals feature remains separate.
class BookingHospitalPicker {
  BookingHospitalPicker({
    required AmbulanceRequestService service,
    required LocationService locationService,
  }) : _service = service,
       _locationService = locationService;

  static const rowsPerPage = 10;
  final AmbulanceRequestService _service;
  final LocationService _locationService;
  final status = NearbyHospitalsStatus.initial.obs;
  final hospitals = <HospitalModel>[].obs;
  final hasMore = false.obs;
  final isLoadingMore = false.obs;
  final errorMessage = RxnString();
  final paginationError = RxnString();
  DashboardLocation? _location;
  StreamSubscription<DashboardLocation>? _locationSubscription;
  int _page = 1;
  int _operationId = 0;

  Future<void> refreshHospitals() async {
    final operationId = ++_operationId;
    status.value = NearbyHospitalsStatus.locating;
    errorMessage.value = null;
    hospitals.clear();
    hasMore.value = false;
    try {
      if (!await _locationService.isServiceEnabled()) {
        _setLocationError(
          NearbyHospitalsStatus.gpsDisabled,
          'Location Services are turned off.',
        );
        return;
      }
      var permission = await _locationService.checkPermission();
      if (permission == LocationPermissionStatus.denied) {
        permission = await _locationService.requestPermission();
      }
      if (permission == LocationPermissionStatus.denied) {
        _setLocationError(
          NearbyHospitalsStatus.permissionDenied,
          'Location permission is required to find nearby hospitals.',
        );
        return;
      }
      if (permission == LocationPermissionStatus.deniedForever) {
        _setLocationError(
          NearbyHospitalsStatus.permissionDeniedForever,
          'Allow location access from App Settings.',
        );
        return;
      }
      _location = await _locationService.getCurrentLocation();
      if (_location == null) {
        _setLocationError(
          NearbyHospitalsStatus.locationError,
          'Your current location is unavailable.',
        );
        return;
      }
      if (operationId != _operationId) return;
      _startWatchingLocation();
      status.value = NearbyHospitalsStatus.loading;
      final page = await _service.fetchHospitals(rowsPerPage: rowsPerPage);
      if (operationId != _operationId) return;
      hospitals.assignAll(_sorted(page.hospitals, _location!));
      _page = 1;
      hasMore.value = page.hasMore;
      status.value = hospitals.isEmpty
          ? NearbyHospitalsStatus.empty
          : NearbyHospitalsStatus.success;
    } on BookingApiException catch (error) {
      if (operationId == _operationId) {
        status.value = NearbyHospitalsStatus.apiError;
        errorMessage.value = error.message;
      }
    } catch (_) {
      if (operationId == _operationId) {
        status.value = NearbyHospitalsStatus.apiError;
        errorMessage.value =
            'Unable to load nearby hospitals. Please try again.';
      }
    }
  }

  Future<void> loadMore() async {
    final location = _location;
    if (isLoadingMore.value || !hasMore.value || location == null) return;
    final operationId = _operationId;
    isLoadingMore.value = true;
    paginationError.value = null;
    try {
      final page = await _service.fetchHospitals(
        page: _page + 1,
        rowsPerPage: rowsPerPage,
      );
      if (operationId != _operationId) return;
      hospitals.assignAll(_sorted([...hospitals, ...page.hospitals], location));
      _page++;
      hasMore.value = page.hasMore;
    } on BookingApiException catch (error) {
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

  List<HospitalModel> _sorted(
    List<HospitalModel> source,
    DashboardLocation location,
  ) {
    final unique = <String, HospitalModel>{};
    for (final hospital in source) {
      final distance = hospital.hasCoordinates
          ? Geolocator.distanceBetween(
              location.latitude,
              location.longitude,
              hospital.latitude!,
              hospital.longitude!,
            )
          : null;
      final updated = hospital.copyWith(distanceMeters: distance);
      final key = hospital.id.isNotEmpty
          ? hospital.id
          : '${hospital.displayName}|${hospital.latitude}|${hospital.longitude}';
      unique[key] = updated;
    }
    final result = unique.values.toList();
    result.sort((a, b) {
      final distanceOrder = (a.distanceMeters ?? double.infinity).compareTo(
        b.distanceMeters ?? double.infinity,
      );
      return distanceOrder != 0
          ? distanceOrder
          : a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });
    return result;
  }

  void _setLocationError(NearbyHospitalsStatus next, String message) {
    status.value = next;
    errorMessage.value = message;
  }

  void _startWatchingLocation() {
    unawaited(_locationSubscription?.cancel());
    _locationSubscription = _locationService.watchLocation().listen(
      (location) {
        _location = location;
        if (hospitals.isNotEmpty) {
          hospitals.assignAll(_sorted(hospitals.toList(), location));
        }
      },
      onError: (_) {
        // Keep the last reliable distance until the user retries.
      },
    );
  }

  void dispose() {
    unawaited(_locationSubscription?.cancel());
  }
}
