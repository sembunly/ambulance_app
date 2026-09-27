class DashboardData {
  const DashboardData({required this.bookings, required this.emergencyHotline});

  final List<DashboardBooking> bookings;
  final String emergencyHotline;

  static const _configuredHotline = String.fromEnvironment('EMERGENCY_HOTLINE');

  factory DashboardData.fromJson(Map<String, dynamic> response) {
    final bookings =
        _findRecords(response)
            .map(DashboardBooking.fromJson)
            .where(
              (booking) => booking.id.isNotEmpty || booking.code.isNotEmpty,
            )
            .toList(growable: false)
          ..sort((a, b) {
            final aDate =
                a.requestedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate =
                b.requestedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });

    return DashboardData(
      bookings: List<DashboardBooking>.unmodifiable(bookings),
      emergencyHotline: _readHotline(response),
    );
  }

  static String _readHotline(Map<String, dynamic> response) {
    final maps = <Map<String, dynamic>>[
      response,
      _asMap(response['body']),
      _asMap(response['data']),
      _asMap(response['configuration']),
      _asMap(response['config']),
    ];
    for (final map in maps) {
      for (final key in const [
        'emergencyHotline',
        'emergency_hotline',
        'hotline',
        'supportPhone',
      ]) {
        final value = map[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }
    }
    return _configuredHotline.trim();
  }

  static List<Map<String, dynamic>> _findRecords(Object? value) {
    if (value is List) {
      return value.map(_asMap).where((item) => item.isNotEmpty).toList();
    }
    final map = _asMap(value);
    if (map.isEmpty) return const [];
    for (final key in const [
      'body',
      'data',
      'content',
      'items',
      'results',
      'dispatches',
      'bookings',
    ]) {
      if (!map.containsKey(key)) continue;
      final result = _findRecords(map[key]);
      if (result.isNotEmpty || map[key] is List) return result;
    }
    final looksLikeBooking = const [
      'bookingCode',
      'dispatchCode',
      'bookingStatus',
      'dispatchStatus',
    ].any(map.containsKey);
    return looksLikeBooking ? <Map<String, dynamic>>[map] : const [];
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }
}

class DashboardLocation {
  const DashboardLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
  });

  final double latitude;
  final double longitude;
  final double? accuracy;
}

class DashboardBooking {
  const DashboardBooking({
    required this.id,
    required this.code,
    required this.status,
    required this.requestedAt,
    this.etaMinutes,
    this.estimatedArrivalAt,
    this.pickupAddress = '',
    this.hasAssignedResource = false,
  });

  final String id;
  final String code;
  final String status;
  final DateTime? requestedAt;
  final int? etaMinutes;
  final DateTime? estimatedArrivalAt;
  final String pickupAddress;
  final bool hasAssignedResource;

  bool get isActive => !const <String>{
    'completed',
    'cancelled',
    'canceled',
    'rejected',
    'closed',
    'failed',
  }.contains(status.trim().toLowerCase());

  bool get canTrackAmbulance =>
      hasAssignedResource ||
      const <String>{
        'assigned',
        'accepted',
        'dispatched',
        'en_route',
        'arriving',
        'arrived',
        'picked_up',
        'in_progress',
      }.contains(
        status.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_'),
      );

  String get displayStatus {
    final normalized = status.trim().replaceAll(RegExp(r'[_-]+'), ' ');
    if (normalized.isEmpty) return 'Pending';
    return normalized
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String get etaLabel {
    if (etaMinutes != null && etaMinutes! >= 0) {
      return etaMinutes == 0 ? 'Arriving now' : '$etaMinutes min';
    }
    if (estimatedArrivalAt == null) return 'Calculating';
    final minutes = estimatedArrivalAt!.difference(DateTime.now()).inMinutes;
    return minutes <= 0 ? 'Arriving now' : '$minutes min';
  }

  factory DashboardBooking.fromJson(Map<String, dynamic> json) {
    final location = _map(json['pickupLocation'] ?? json['location']);
    return DashboardBooking(
      id: _string(json, const ['id', 'bookingId', 'dispatchId']),
      code: _string(json, const [
        'bookingCode',
        'booking_code',
        'dispatchCode',
        'dispatch_code',
        'referenceCode',
        'code',
        'id',
      ]),
      status: _string(json, const [
        'status',
        'bookingStatus',
        'booking_status',
        'dispatchStatus',
      ]),
      requestedAt: _date(json, const [
        'requestedAt',
        'requested_at',
        'bookingTime',
        'createdAt',
        'created_at',
      ]),
      etaMinutes: _integer(json, const [
        'etaMinutes',
        'eta_minutes',
        'estimatedArrivalMinutes',
      ]),
      estimatedArrivalAt: _date(json, const [
        'estimatedArrivalAt',
        'estimated_arrival_at',
        'eta',
      ]),
      pickupAddress: _string(json, const [
        'pickupAddress',
        'pickup_address',
        'address',
      ], fallback: location),
      hasAssignedResource: _hasAssignment(json),
    );
  }

  static bool _hasAssignment(Map<String, dynamic> json) {
    for (final key in const <String>[
      'driverId',
      'driver_id',
      'ambulanceId',
      'ambulance_id',
      'assignedDriverId',
      'assignedAmbulanceId',
    ]) {
      if (json[key]?.toString().trim().isNotEmpty == true) return true;
    }
    return _map(json['driver']).isNotEmpty ||
        _map(json['ambulance']).isNotEmpty ||
        _map(json['assignedDriver']).isNotEmpty ||
        _map(json['assignedAmbulance']).isNotEmpty;
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  static String _string(
    Map<String, dynamic> json,
    List<String> keys, {
    Map<String, dynamic> fallback = const {},
  }) {
    for (final source in [json, fallback]) {
      for (final key in keys) {
        final value = source[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }
    }
    return '';
  }

  static int? _integer(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.round();
      final parsed = int.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return null;
  }

  static DateTime? _date(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final parsed = DateTime.tryParse(json[key]?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return null;
  }
}
