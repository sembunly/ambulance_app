import 'package:equatable/equatable.dart';

// ── Tracked location ──────────────────────────────────────────────────────

class TrackedLocation extends Equatable {
  const TrackedLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.heading,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final double heading;

  static TrackedLocation? tryParse(Object? value) {
    if (value is! Map) return null;
    final map = value.map((key, value) => MapEntry(key.toString(), value));

    for (final key in const <String>[
      'ambulanceLocation',
      'driverLocation',
      'location',
      'position',
      'payload',
      'data',
      'body',
    ]) {
      final nested = tryParse(map[key]);
      if (nested != null) return nested;
    }

    final coordinates = map['coordinates'];
    final latitude =
        _number(map, const <String>[
          'latitude',
          'lat',
          'driverLatitude',
          'ambulanceLatitude',
        ]) ??
        (coordinates is List && coordinates.length > 1
            ? _asDouble(coordinates[1])
            : null);
    final longitude =
        _number(map, const <String>[
          'longitude',
          'lng',
          'lon',
          'driverLongitude',
          'ambulanceLongitude',
        ]) ??
        (coordinates is List && coordinates.isNotEmpty
            ? _asDouble(coordinates[0])
            : null);

    if (latitude == null ||
        longitude == null ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }

    return TrackedLocation(
      latitude: latitude,
      longitude: longitude,
      accuracy: _number(map, const <String>['accuracy', 'accuracyMeters']) ?? 0,
      heading: _number(map, const <String>['heading', 'bearing']) ?? 0,
    );
  }

  static double? _number(Map<String, Object?> map, List<String> keys) {
    for (final key in keys) {
      final number = _asDouble(map[key]);
      if (number != null) return number;
    }
    return null;
  }

  static double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  @override
  List<Object> get props => [latitude, longitude, accuracy, heading];
}
