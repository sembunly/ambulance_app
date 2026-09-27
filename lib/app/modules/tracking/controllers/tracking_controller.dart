import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../data/models/map_route.dart';
import '../../../data/models/realtime_message.dart';
import '../../../data/models/tracked_location.dart';
import '../../../data/providers/realtime_provider.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/route_service.dart';

// ── Status enums ──────────────────────────────────────────────────────────

enum GpsTrackingStatus { initial, loading, success, empty, error }

enum GpsTrackingAction { retry, locationSettings, appSettings }

enum RealtimeEventsStatus { initial, loading, success, empty, error }

// ── Tracking controller ───────────────────────────────────────────────────
/// Merged controller that covers GPS location tracking, STOMP realtime
/// subscription, and polyline route loading.
///
/// Flow:  TrackingView → TrackingController → LocationService / RealtimeProvider / RouteService

class TrackingController extends GetxController with WidgetsBindingObserver {
  TrackingController({
    required LocationService locationService,
    required RealtimeProvider realtimeProvider,
    required RouteService routeService,
  }) : _locationService = locationService,
       _realtimeProvider = realtimeProvider,
       _routeService = routeService;

  final LocationService _locationService;
  final RealtimeProvider _realtimeProvider;
  final RouteService _routeService;

  // ── GPS state ─────────────────────────────────────────────────────────
  final Rx<GpsTrackingStatus> gpsStatus = GpsTrackingStatus.initial.obs;
  final Rxn<TrackedLocation> patientLocation = Rxn<TrackedLocation>();
  final RxBool hasPermission = false.obs;
  final Rx<GpsTrackingAction> gpsAction = GpsTrackingAction.retry.obs;
  final RxnString gpsError = RxnString();
  StreamSubscription<dynamic>? _positionSubscription;

  bool get isGpsLoading => gpsStatus.value == GpsTrackingStatus.loading;

  // ── Realtime state ────────────────────────────────────────────────────
  final Rx<RealtimeEventsStatus> realtimeStatus =
      RealtimeEventsStatus.initial.obs;
  final RxList<RealtimeMessage> events = <RealtimeMessage>[].obs;
  final Rxn<TrackedLocation> ambulanceLocation = Rxn<TrackedLocation>();
  final RxnString realtimeError = RxnString();
  StreamSubscription<RealtimeMessage>? _realtimeSubscription;

  // ── Route state ───────────────────────────────────────────────────────
  final Rxn<MapRoute> route = Rxn<MapRoute>();
  final RxBool isRouteLoading = false.obs;
  final RxnString routeError = RxnString();
  TrackedLocation? _lastRouteOrigin;
  TrackedLocation? _lastRouteDestination;
  int _routeRequestId = 0;

  // ── Camera state ──────────────────────────────────────────────────────
  GoogleMapController? mapController;
  bool hasPositionedCamera = false;
  bool hasFittedMarkers = false;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    ever<TrackedLocation?>(patientLocation, (location) {
      if (location == null) return;
      _positionCameraIfPossible();
      _loadRouteIfPossible();
    });

    ever<TrackedLocation?>(ambulanceLocation, (location) {
      if (location == null) return;
      _positionCameraIfPossible();
      _loadRouteIfPossible();
    });

    startTracking();
    subscribe();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_positionSubscription?.cancel());
    unawaited(_realtimeSubscription?.cancel());
    mapController?.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (gpsStatus.value == GpsTrackingStatus.error) startTracking();
      if (realtimeStatus.value == RealtimeEventsStatus.error) subscribe();
    }
  }

  // ── GPS location ─────────────────────────────────────────────────────────

  Future<void> startTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    gpsAction.value = GpsTrackingAction.retry;
    gpsError.value = null;
    gpsStatus.value = GpsTrackingStatus.loading;

    try {
      if (!await _locationService.isServiceEnabled()) {
        await _locationService.openLocationSettings();
        if (!await _locationService.isServiceEnabled()) {
          _setGpsError(
            'Turn on Location Services to show your current position.',
            GpsTrackingAction.locationSettings,
          );
          return;
        }
      }

      var permission = await _locationService.checkPermission();
      if (permission == LocationPermissionStatus.denied) {
        permission = await _locationService.requestPermission();
      }
      if (permission == LocationPermissionStatus.denied) {
        _setGpsError(
          'Location permission is required to show your position on the map.',
          GpsTrackingAction.retry,
        );
        return;
      }
      if (permission == LocationPermissionStatus.deniedForever) {
        _setGpsError(
          'Location permission is blocked. Allow it from App Settings.',
          GpsTrackingAction.appSettings,
        );
        return;
      }

      hasPermission.value = true;

      final currentLocation = await _locationService.getCurrentLocation();
      if (currentLocation != null) {
        patientLocation.value = TrackedLocation(
          latitude: currentLocation.latitude,
          longitude: currentLocation.longitude,
          accuracy: currentLocation.accuracy ?? 0,
          heading: 0,
        );
        gpsStatus.value = GpsTrackingStatus.success;
      } else {
        gpsStatus.value = GpsTrackingStatus.empty;
      }

      _positionSubscription = _locationService.watchLocation().listen(
        (dashboardLocation) {
          patientLocation.value = TrackedLocation(
            latitude: dashboardLocation.latitude,
            longitude: dashboardLocation.longitude,
            accuracy: dashboardLocation.accuracy ?? 0,
            heading: 0,
          );
          hasPermission.value = true;
          gpsAction.value = GpsTrackingAction.retry;
          gpsError.value = null;
          gpsStatus.value = GpsTrackingStatus.success;
        },
        onError: (_) {
          _setGpsReadError('Unable to update your location. Please try again.');
        },
      );
    } catch (_) {
      _setGpsReadError(
        'Unable to read your current location. Please try again.',
      );
    }
  }

  Future<void> requestGpsAction() async {
    try {
      switch (gpsAction.value) {
        case GpsTrackingAction.retry:
          break;
        case GpsTrackingAction.locationSettings:
          await _locationService.openLocationSettings();
        case GpsTrackingAction.appSettings:
          await _locationService.openAppSettings();
      }
    } finally {
      await startTracking();
    }
  }

  void _setGpsError(String message, GpsTrackingAction nextAction) {
    patientLocation.value = null;
    hasPermission.value = false;
    gpsAction.value = nextAction;
    gpsStatus.value = GpsTrackingStatus.error;
    gpsError.value = message;
  }

  void _setGpsReadError(String message) {
    gpsAction.value = GpsTrackingAction.retry;
    gpsStatus.value = GpsTrackingStatus.error;
    gpsError.value = message;
  }

  // ── Realtime STOMP ───────────────────────────────────────────────────────

  Future<void> subscribe() async {
    await _realtimeSubscription?.cancel();
    realtimeError.value = null;
    realtimeStatus.value = RealtimeEventsStatus.loading;

    try {
      _realtimeSubscription = _realtimeProvider.watchEvents().listen(
        (message) {
          events.insert(0, message);
          final nextLocation = TrackedLocation.tryParse(message.payload);
          if (nextLocation != null) ambulanceLocation.value = nextLocation;
          realtimeError.value = null;
          realtimeStatus.value = RealtimeEventsStatus.success;
        },
        onError: (_) => _setConnectionError(),
        onDone: _setConnectionError,
      );
    } catch (_) {
      _setConnectionError();
    }
  }

  void _setConnectionError() {
    if (isClosed) return;
    realtimeStatus.value = RealtimeEventsStatus.error;
    realtimeError.value = 'The real-time connection was interrupted.';
  }

  // ── Route polyline ───────────────────────────────────────────────────────

  Future<void> _loadRouteIfPossible() async {
    final ambulance = ambulanceLocation.value;
    final patient = patientLocation.value;

    if (ambulance == null || patient == null) {
      if (route.value != null ||
          routeError.value != null ||
          isRouteLoading.value) {
        route.value = null;
        routeError.value = null;
        isRouteLoading.value = false;
        _lastRouteOrigin = null;
        _lastRouteDestination = null;
      }
      return;
    }

    if (!_hasMovedSignificantly(_lastRouteOrigin, ambulance, 25) &&
        !_hasMovedSignificantly(_lastRouteDestination, patient, 10)) {
      return;
    }

    final requestId = ++_routeRequestId;
    isRouteLoading.value = true;
    routeError.value = null;
    _lastRouteOrigin = ambulance;
    _lastRouteDestination = patient;

    try {
      final mapRoute = await _routeService.getRoute(
        origin: ambulance,
        destination: patient,
      );
      if (isClosed || requestId != _routeRequestId) return;
      route.value = mapRoute;
      isRouteLoading.value = false;
      await _fitRouteBounds(mapRoute);
    } catch (error) {
      if (isClosed || requestId != _routeRequestId) return;
      route.value = null;
      isRouteLoading.value = false;
      routeError.value = error.toString();
    }
  }

  // ── Camera helpers ───────────────────────────────────────────────────────

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _positionCameraIfPossible();
    _loadRouteIfPossible();
  }

  CameraPosition? get initialCameraPosition {
    final location = patientLocation.value ?? ambulanceLocation.value;
    if (location == null) return null;
    return CameraPosition(
      target: LatLng(location.latitude, location.longitude),
      zoom: 16,
    );
  }

  Future<void> fitAllLocations() async {
    final ambulance = ambulanceLocation.value;
    final patient = patientLocation.value;
    final locations = <TrackedLocation>[?ambulance, ?patient];
    await _fitLocations(locations);
  }

  Future<void> _positionCameraIfPossible() async {
    if (mapController == null) return;
    final patient = patientLocation.value;
    final ambulance = ambulanceLocation.value;
    if (patient != null && ambulance != null && !hasFittedMarkers) {
      hasFittedMarkers = true;
      hasPositionedCamera = true;
      await _fitLocations(<TrackedLocation>[ambulance, patient]);
    } else if (patient != null && !hasPositionedCamera) {
      await _centerOnLocation(patient);
    }
  }

  Future<void> _centerOnLocation(TrackedLocation? location) async {
    final controller = mapController;
    if (controller == null || location == null) return;
    hasPositionedCamera = true;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(location.latitude, location.longitude),
          zoom: 17,
        ),
      ),
    );
  }

  Future<void> _fitLocations(List<TrackedLocation> locations) async {
    final controller = mapController;
    if (controller == null || locations.isEmpty) return;
    if (locations.length == 1) {
      await _centerOnLocation(locations.first);
      return;
    }
    final points = locations
        .map((location) => LatLng(location.latitude, location.longitude))
        .toList(growable: false);
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(_boundsFor(points), 72),
    );
  }

  Future<void> _fitRouteBounds(MapRoute mapRoute) async {
    final controller = mapController;
    if (controller == null || mapRoute.points.isEmpty) return;
    final points = mapRoute.points
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList(growable: false);
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(_boundsFor(points), 72),
    );
  }

  // ── Marker and polyline builders ─────────────────────────────────────────

  Set<Marker> get markers {
    final set = <Marker>{};
    final patient = patientLocation.value;
    final ambulance = ambulanceLocation.value;

    if (patient != null) {
      set.add(
        Marker(
          markerId: const MarkerId('patient'),
          position: LatLng(patient.latitude, patient.longitude),
          anchor: const Offset(0.5, 1),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Patient location'),
        ),
      );
    }

    if (ambulance != null) {
      final heading = ambulance.heading.isFinite && ambulance.heading >= 0
          ? ambulance.heading
          : 0.0;
      set.add(
        Marker(
          markerId: const MarkerId('ambulance'),
          position: LatLng(ambulance.latitude, ambulance.longitude),
          rotation: heading,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'Ambulance location'),
        ),
      );
    }

    return set;
  }

  Set<Polyline> polylines(Color color) {
    final currentRoute = route.value;
    if (currentRoute == null || currentRoute.isEmpty) return const {};
    return {
      Polyline(
        polylineId: const PolylineId('ambulancePatientRoute'),
        points: currentRoute.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList(growable: false),
        color: color,
        width: 6,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };
  }

  // ── Geometry helpers ─────────────────────────────────────────────────────

  LatLngBounds _boundsFor(List<LatLng> points) {
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }

    if (minLat == maxLat) {
      minLat -= 0.0005;
      maxLat += 0.0005;
    }
    if (minLng == maxLng) {
      minLng -= 0.0005;
      maxLng += 0.0005;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  static bool _hasMovedSignificantly(
    TrackedLocation? previous,
    TrackedLocation current,
    double thresholdMeters,
  ) {
    if (previous == null) return true;
    const earthRadius = 6371000.0;
    final dLat = _radians(current.latitude - previous.latitude);
    final dLng = _radians(current.longitude - previous.longitude);
    final lat1 = _radians(previous.latitude);
    final lat2 = _radians(current.latitude);
    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = h.clamp(0.0, 1.0);
    return earthRadius * 2 * math.atan2(math.sqrt(c), math.sqrt(1 - c)) >=
        thresholdMeters;
  }

  static double _radians(double degrees) => degrees * math.pi / 180;
}
