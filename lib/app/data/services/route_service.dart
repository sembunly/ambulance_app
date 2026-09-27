import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import '../models/map_route.dart';
import '../models/tracked_location.dart';

// ── Route service ─────────────────────────────────────────────────────────

class RouteService {
  RouteService({required String apiKey, PolylinePoints? polylinePoints})
    : _apiKey = apiKey.trim(),
      _polylinePoints =
          polylinePoints ??
          PolylinePoints(apiKey: apiKey.trim(), preferRoutesApi: true);

  static const String dartDefineKey = 'MAPS_API_KEY';

  factory RouteService.fromEnvironment() {
    return RouteService(apiKey: const String.fromEnvironment(dartDefineKey));
  }

  final String _apiKey;
  final PolylinePoints _polylinePoints;

  Future<MapRoute> getRoute({
    required TrackedLocation origin,
    required TrackedLocation destination,
  }) async {
    if (_apiKey.isEmpty || _apiKey == 'GOOGLE_MAPS_API_KEY') {
      throw const RouteException(
        'Google Maps API key is missing. Run with --dart-define=MAPS_API_KEY=.',
      );
    }

    final result = await _polylinePoints.getRouteBetweenCoordinatesV2(
      request: RoutesApiRequest(
        origin: PointLatLng(origin.latitude, origin.longitude),
        destination: PointLatLng(destination.latitude, destination.longitude),
        travelMode: TravelMode.driving,
      ),
    );
    final primaryRoute = result.primaryRoute;
    final points = primaryRoute?.polylinePoints ?? const <PointLatLng>[];

    if (points.isEmpty) {
      throw RouteException(
        result.errorMessage?.isNotEmpty == true
            ? result.errorMessage!
            : 'No route found between ambulance and patient.',
      );
    }

    return MapRoute(
      points: points
          .map(
            (point) => TrackedLocation(
              latitude: point.latitude,
              longitude: point.longitude,
              accuracy: 0,
              heading: 0,
            ),
          )
          .toList(growable: false),
      distanceText: _formatDistance(primaryRoute?.distanceMeters),
      durationText: _formatDuration(primaryRoute?.duration),
    );
  }

  String? _formatDistance(int? meters) {
    if (meters == null) return null;
    if (meters < 1000) return '$meters m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String? _formatDuration(int? seconds) {
    if (seconds == null) return null;
    final minutes = (seconds / 60).ceil();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '$hours hr';
    return '$hours hr $remainingMinutes min';
  }
}

// ── Route exception ───────────────────────────────────────────────────────

class RouteException implements Exception {
  const RouteException(this.message);

  final String message;

  @override
  String toString() => message;
}
