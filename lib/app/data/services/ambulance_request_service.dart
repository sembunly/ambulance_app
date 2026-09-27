import 'package:dio/dio.dart';

import '../../config/app_config.dart';
import '../models/ambulance_request_model.dart';
import '../models/hospital_model.dart';
import '../providers/api_provider.dart';

class BookingApiException implements Exception {
  const BookingApiException(this.message, this.statusCode);

  final String message;
  final int? statusCode;
}

// ── Ambulance Request Service ───────────────────────────────────────────────
class AmbulanceRequestService {
  AmbulanceRequestService({required ApiProvider apiProvider})
    : _apiProvider = apiProvider;

  final ApiProvider _apiProvider;

  Future<AmbulanceBookingResult> submit(AmbulanceRequestDraft draft) async {
    final hospitalId = int.parse(draft.hospital!.id);
    final response = await _send(
      () => _apiProvider.post(
        AppConfig.addAmbulanceBooking,
        data: <String, dynamic>{
          'requestFor': _requestForValue(draft.requestFor),
          'hospitalId': hospitalId,
          'patientId': null,
          'latitude': draft.latitude,
          'longitude': draft.longitude,
          'locationAccuracyMeters': draft.locationAccuracyMeters,
          'locationName': draft.locationName.trim(),
          'locationAddress': draft.locationAddress.trim(),
          'landmark': draft.landmark.trim(),
          'provinceId': null,
          'districtId': null,
          'communeId': null,
          'villageId': null,
          'typeCode': draft.typeCode.trim(),
          'priorityCode': draft.priorityCode.trim().isEmpty
              ? null
              : draft.priorityCode.trim(),
          'patientNameReported': draft.patientName.trim(),
          'patientAgeReported': draft.patientAge,
          'patientGenderReported': draft.patientGender.trim(),
          'numberOfPatients': draft.numberOfPatients,
          'chiefComplaint': draft.chiefComplaint.trim(),
          'symptoms': draft.symptoms.trim(),
          'incidentDescription': draft.incidentDescription.trim(),
          'note': draft.note.trim(),
        },
      ),
    );

    // ── Validation ─────────────────────────────────────────────────────────
    _validateEnvelope(response);
    return AmbulanceBookingResult(
      id: _readResponseValue(response, const <String>[
        'bookingId',
        'ambulanceBookingId',
        'emergencyCallId',
        'id',
      ]),
      code: _readResponseValue(response, const <String>[
        'bookingCode',
        'ambulanceBookingCode',
        'callCode',
        'referenceCode',
        'code',
      ]),
      status: _readResponseValue(response, const <String>[
        'bookingStatus',
        'statusCode',
        'emergencyStatus',
        'status',
      ]),
    );
  }

  Future<void> cancelBooking(String bookingId) async {
    final normalizedId = bookingId.trim();
    if (normalizedId.isEmpty) {
      throw const BookingApiException('Booking ID is required.', 400);
    }
    final numericId = int.tryParse(normalizedId);
    final response = await _send(
      () => _apiProvider.post(
        AppConfig.cancelAmbulanceBooking,
        data: <String, dynamic>{'bookingId': numericId ?? normalizedId},
      ),
      fallback: 'Unable to cancel this booking.',
    );
    _validateEnvelope(response);
  }

  Future<HospitalPage> fetchHospitals({
    int page = 1,
    int rowsPerPage = 10,
  }) async {
    final response = await _send(
      () => _apiProvider.get(
        AppConfig.hospitalsList,
        queryParameters: <String, dynamic>{
          'searchText': '',
          'page': page,
          'rowsPerPage': rowsPerPage,
          'orderBy': '',
          'status': 1,
        },
      ),
      fallback: 'Unable to load nearby hospitals.',
    );
    _validateEnvelope(response);
    final records = _findRecords(response);
    final hospitals = records
        .map(HospitalModel.fromJson)
        .where((hospital) => hospital.displayName.isNotEmpty)
        .toList(growable: false);
    final total = _findTotal(response);
    return HospitalPage(
      hospitals: List<HospitalModel>.unmodifiable(hospitals),
      page: page,
      total: total,
      hasMore: total == null
          ? hospitals.length >= rowsPerPage
          : page * rowsPerPage < total,
    );
  }

  Future<Map<String, dynamic>> fetchDispatches({String userId = ''}) async {
    final response = await _send(
      () => _apiProvider.get(
        AppConfig.dispatches,
        queryParameters: userId.trim().isEmpty
            ? null
            : {'userId': userId.trim()},
      ),
      fallback: 'Unable to load your booking status.',
    );
    _validateEnvelope(response);
    return response;
  }

  Future<Map<String, dynamic>> _send(
    Future<Response<dynamic>> Function() request, {
    String fallback = 'Unable to submit the ambulance request.',
  }) async {
    try {
      final response = await request();
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) {
        return data.map((key, value) => MapEntry(key.toString(), value));
      }
      return <String, dynamic>{'data': data};
    } on DioException catch (error) {
      final data = _asMap(error.response?.data);
      final message = _readErrorMessage(data);
      throw BookingApiException(
        message.isNotEmpty ? message : fallback,
        error.response?.statusCode,
      );
    }
  }

  String _requestForValue(AmbulanceRequestFor requestFor) {
    return switch (requestFor) {
      AmbulanceRequestFor.myself => 'SELF',
      AmbulanceRequestFor.someoneElse => 'SOMEONE',
    };
  }

  // ── Validation ─────────────────────────────────────────────────────────
  void _validateEnvelope(Map<String, dynamic> response) {
    final header = _asMap(response['header']);
    if (response['success'] != false && header['result'] != false) return;
    final message = _readErrorMessage(response);
    final statusCode = _asInt(header['statusCode']);
    throw BookingApiException(
      message.isEmpty ? 'Unable to submit the ambulance request.' : message,
      statusCode,
    );
  }

  List<Map<String, dynamic>> _findRecords(Object? value) {
    if (value is List) {
      return value.map(_asMap).where((item) => item.isNotEmpty).toList();
    }
    final map = _asMap(value);
    if (map.isEmpty) return const <Map<String, dynamic>>[];
    for (final key in const <String>[
      'hospitals',
      'rows',
      'records',
      'content',
      'items',
      'results',
      'list',
      'data',
      'body',
    ]) {
      if (!map.containsKey(key)) continue;
      final result = _findRecords(map[key]);
      if (result.isNotEmpty || map[key] is List) return result;
    }
    final looksLikeHospital = const <String>[
      'hospitalName',
      'hospitalNameKhmer',
      'latitude',
      'longitude',
      'logoUrl',
    ].any(map.containsKey);
    return looksLikeHospital ? <Map<String, dynamic>>[map] : const [];
  }

  int? _findTotal(Map<String, dynamic> response) {
    final candidates = <Map<String, dynamic>>[
      response,
      _asMap(response['body']),
      _asMap(response['data']),
      _asMap(response['pagination']),
      _asMap(response['page']),
      _asMap(_asMap(response['body'])['pagination']),
      _asMap(_asMap(response['body'])['page']),
      _asMap(_asMap(response['data'])['pagination']),
      _asMap(_asMap(response['data'])['page']),
    ];
    for (final map in candidates) {
      for (final key in const <String>[
        'total',
        'totalElements',
        'totalRecords',
        'recordsTotal',
        'totalCount',
      ]) {
        final value = map[key];
        if (value is num) return value.round();
        final parsed = int.tryParse(value?.toString() ?? '');
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  // ── Helper Methods ─────────────────────────────────────────────────────────
  String _readErrorMessage(Map<String, dynamic> response) {
    final header = _asMap(response['header']);
    final body = _asMap(response['body']);
    final sources = <Map<String, dynamic>>[header, response, body];
    for (final source in sources) {
      for (final key in const <String>[
        'errorText',
        'error',
        'message',
        'detail',
        'title',
      ]) {
        final message = source[key]?.toString().trim() ?? '';
        if (message.isNotEmpty) return message;
      }
    }
    return _readValidationMessage(response['errors'] ?? body['errors']);
  }

  String _readValidationMessage(Object? errors) {
    if (errors is Map) {
      final messages = errors.values
          .expand((value) => value is List ? value : <Object?>[value])
          .map((value) => value?.toString().trim() ?? '')
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
      return messages.join('\n');
    }
    if (errors is List) {
      final messages = errors
          .map((value) => value?.toString().trim() ?? '')
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
      return messages.join('\n');
    }
    return errors?.toString().trim() ?? '';
  }

  String _readResponseValue(Map<String, dynamic> response, List<String> keys) {
    final sources = <Object?>[
      _asMap(response['body'])['data'],
      response['body'],
      response['data'],
      response,
    ];
    for (final source in sources) {
      final value = _findValue(source, keys);
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  String _findValue(Object? source, List<String> keys) {
    if (source is List) {
      for (final item in source) {
        final found = _findValue(item, keys);
        if (found.isNotEmpty) return found;
      }
      return '';
    }
    final map = _asMap(source);
    if (map.isEmpty) return '';
    for (final key in keys) {
      final value = map[key];
      if (value is Map || value is List) continue;
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    for (final key in const <String>['data', 'booking', 'emergencyCall']) {
      final found = _findValue(map[key], keys);
      if (found.isNotEmpty) return found;
    }
    return '';
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }

  int? _asInt(Object? value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '');
  }
}
