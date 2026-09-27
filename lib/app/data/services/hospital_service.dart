import 'package:dio/dio.dart';

import '../../config/app_config.dart';
import '../models/hospital_model.dart';
import '../providers/api_provider.dart';

class HospitalApiException implements Exception {
  const HospitalApiException(this.message, this.statusCode);

  final String message;
  final int? statusCode;
}

class HospitalService {
  HospitalService({required ApiProvider apiProvider})
    : _apiProvider = apiProvider;

  final ApiProvider _apiProvider;

  Future<HospitalPage> getHospitals({
    String searchText = '',
    int page = 1,
    int rowsPerPage = 10,
    String orderBy = '',
    int status = 1,
  }) async {
    final Map<String, dynamic> response;
    try {
      final result = await _apiProvider.get(
        AppConfig.hospitalsList,
        queryParameters: <String, dynamic>{
          'searchText': searchText.trim(),
          'page': page,
          'rowsPerPage': rowsPerPage,
          'orderBy': orderBy,
          'status': status,
        },
      );
      final data = result.data;
      response = data is Map ? _asMap(data) : <String, dynamic>{'data': data};
    } on DioException catch (error) {
      final data = _asMap(error.response?.data);
      final message = _errorMessage(data, fallback: error.message);
      throw HospitalApiException(
        message.isEmpty ? 'Unable to load nearby hospitals.' : message,
        error.response?.statusCode,
      );
    }
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

  void _validateEnvelope(Map<String, dynamic> response) {
    final header = _asMap(response['header']);
    if (response['success'] != false && header['result'] != false) return;
    final message =
        (header['errorText'] ?? response['errorText'] ?? response['message'])
            ?.toString()
            .trim();
    throw HospitalApiException(
      message == null || message.isEmpty
          ? 'Unable to load nearby hospitals.'
          : message,
      null,
    );
  }

  String _errorMessage(Map<String, dynamic> response, {String? fallback}) {
    final header = _asMap(response['header']);
    final body = _asMap(response['body']);
    final validation = _validationMessage(response['errors'] ?? body['errors']);
    final message =
        header['errorText'] ??
        response['errorText'] ??
        response['message'] ??
        body['errorText'] ??
        body['message'] ??
        validation ??
        fallback;
    return message?.toString().trim() ?? '';
  }

  String? _validationMessage(Object? errors) {
    if (errors is Map) {
      final messages = errors.values
          .expand((value) => value is List ? value : <Object?>[value])
          .map((value) => value?.toString().trim() ?? '')
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
      return messages.isEmpty ? null : messages.join('\n');
    }
    if (errors is List) {
      final messages = errors
          .map((value) => value?.toString().trim() ?? '')
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
      return messages.isEmpty ? null : messages.join('\n');
    }
    final message = errors?.toString().trim() ?? '';
    return message.isEmpty ? null : message;
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

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }
}
