import 'package:equatable/equatable.dart';

class HospitalPage {
  const HospitalPage({
    required this.hospitals,
    required this.page,
    required this.hasMore,
    this.total,
  });

  final List<HospitalModel> hospitals;
  final int page;
  final bool hasMore;
  final int? total;
}

class HospitalModel extends Equatable {
  const HospitalModel({
    required this.id,
    required this.name,
    required this.khmerName,
    required this.type,
    required this.address,
    required this.logo,
    required this.phone,
    required this.website,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.distanceMeters,
  });

  final String id;
  final String name;
  final String khmerName;
  final String type;
  final String address;
  final String logo;
  final String phone;
  final String website;
  final double? latitude;
  final double? longitude;
  final int? status;
  final double? distanceMeters;

  bool get hasCoordinates {
    final lat = latitude;
    final lng = longitude;
    return lat != null &&
        lng != null &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180;
  }

  String get displayName => name.isNotEmpty ? name : khmerName;

  HospitalModel copyWith({double? distanceMeters}) {
    return HospitalModel(
      id: id,
      name: name,
      khmerName: khmerName,
      type: type,
      address: address,
      logo: logo,
      phone: phone,
      website: website,
      latitude: latitude,
      longitude: longitude,
      status: status,
      distanceMeters: distanceMeters ?? this.distanceMeters,
    );
  }

  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    final location = _map(
      json['location'] ?? json['coordinates'] ?? json['geoLocation'],
    );
    final address = _map(json['address']);
    final hospitalType = _map(json['hospitalType'] ?? json['type']);

    return HospitalModel(
      id: _string(json, const ['id', 'hospitalId', 'hospital_id']),
      name: _string(json, const [
        'name',
        'hospitalName',
        'hospital_name',
        'nameEn',
        'name_en',
      ]),
      khmerName: _string(json, const [
        'khmerName',
        'nameKhmer',
        'hospitalNameKhmer',
        'hospitalNameKh',
        'nameKh',
        'name_kh',
        'name_km',
      ]),
      type: _string(
        json,
        const ['typeName', 'hospitalTypeName', 'type'],
        fallback: hospitalType,
        fallbackKeys: const ['name', 'nameEn', 'label', 'code'],
      ),
      address: _string(
        json,
        const ['address', 'fullAddress', 'hospitalAddress', 'addressLine'],
        fallback: address,
        fallbackKeys: const ['fullAddress', 'addressLine', 'name', 'label'],
      ),
      logo: _string(json, const [
        'logo',
        'logoUrl',
        'logo_url',
        'image',
        'imageUrl',
        'photo',
      ]),
      phone: _string(json, const [
        'phone',
        'phoneNumber',
        'phone_number',
        'telephone',
        'contactNumber',
      ]),
      website: _string(json, const [
        'website',
        'websiteUrl',
        'website_url',
        'webUrl',
        'url',
      ]),
      latitude: _number(json, const ['latitude', 'lat'], fallback: location),
      longitude: _number(json, const [
        'longitude',
        'lng',
        'lon',
      ], fallback: location),
      status: _status(json['status'] ?? json['statusId'] ?? json['active']),
    );
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }

  static String _string(
    Map<String, dynamic> json,
    List<String> keys, {
    Map<String, dynamic> fallback = const <String, dynamic>{},
    List<String>? fallbackKeys,
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value is Map) continue;
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    for (final key in fallbackKeys ?? keys) {
      final text = fallback[key]?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static double? _number(
    Map<String, dynamic> json,
    List<String> keys, {
    Map<String, dynamic> fallback = const <String, dynamic>{},
  }) {
    for (final source in <Map<String, dynamic>>[json, fallback]) {
      for (final key in keys) {
        final value = source[key];
        if (value is num) return value.toDouble();
        final parsed = double.tryParse(value?.toString().trim() ?? '');
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static int? _status(Object? value) {
    if (value is bool) return value ? 1 : 0;
    if (value is num) return value.round();
    final text = value?.toString().trim().toLowerCase() ?? '';
    final number = int.tryParse(text);
    if (number != null) return number;
    if (const {'active', 'enabled', 'open'}.contains(text)) return 1;
    if (const {'inactive', 'disabled', 'closed'}.contains(text)) return 0;
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    name,
    khmerName,
    type,
    address,
    logo,
    phone,
    website,
    latitude,
    longitude,
    status,
    distanceMeters,
  ];
}
