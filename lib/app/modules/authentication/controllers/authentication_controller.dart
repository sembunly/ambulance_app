import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../config/app_config.dart';
import '../../../data/models/login_request.dart';
import '../../../data/models/login_response.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/storage_service.dart';
import '../../../routes/app_pages.dart';

class AuthenticationController extends GetxController {
  AuthenticationController({
    required ApiProvider apiProvider,
    required StorageService storageService,
  }) : _apiProvider = apiProvider,
       _storageService = storageService;

  final ApiProvider _apiProvider;
  final StorageService _storageService;

  final isLoading = false.obs;
  final errorMessage = RxnString();
  final user = Rxn<LoginResponse>();

  Future<void> login(String phoneNumber, String password) async {
    if (isLoading.value) return;

    isLoading.value = true;
    errorMessage.value = null;
    var succeeded = false;

    try {
      final request = LoginRequest(
        phoneNumber: phoneNumber.trim(),
        password: password,
      );
      final response = await _apiProvider.post(
        AppConfig.loginEndpoint,
        data: request.toJson(),
      );
      final json = _responseMap(response.data);
      _validateEnvelope(json);

      final session = LoginResponse.fromJson(json);
      if (session.accessToken.isEmpty) {
        throw const _LoginFailure('Invalid response from server.');
      }

      try {
        await _storageService.saveAccessToken(session.accessToken);
        await _storageService.saveRefreshToken(session.refreshToken);
        await _storageService.saveUserSession(session);
      } catch (_) {
        try {
          await _storageService.clearAuth();
        } catch (_) {
          // Keep the original storage error visible to the user.
        }
        throw const _LoginFailure(
          'Unable to save your session. Please try again.',
        );
      }

      user.value = session;
      succeeded = true;
    } on DioException catch (error) {
      errorMessage.value = _dioErrorMessage(error);
    } on _LoginFailure catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value = 'Unable to sign in. Please try again.';
    } finally {
      isLoading.value = false;
    }

    if (succeeded) Get.offAllNamed(Routes.DASHBOARD);
  }

  Map<String, dynamic> _responseMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    throw const _LoginFailure('Invalid response from server.');
  }

  void _validateEnvelope(Map<String, dynamic> json) {
    final header = _asMap(json['header']);
    if (json['success'] != false && header['result'] != false) return;

    if (_asInt(header['statusCode']) == 401) {
      throw const _LoginFailure('Incorrect phone number or password.');
    }
    throw _LoginFailure(_serverMessage(json) ?? 'Authentication failed.');
  }

  String _dioErrorMessage(DioException error) {
    if (error.response?.statusCode == 401) {
      return 'Incorrect phone number or password.';
    }
    if (error.response == null) {
      return 'Check your internet connection.';
    }
    final data = error.response?.data;
    if (data is Map) {
      return _serverMessage(_asMap(data)) ??
          'Unable to sign in. Please try again.';
    }
    return 'Unable to sign in. Please try again.';
  }

  String? _serverMessage(Map<String, dynamic> json) {
    final header = _asMap(json['header']);
    final body = _asMap(json['body']);
    final value =
        header['errorText'] ??
        json['errorText'] ??
        json['message'] ??
        body['errorText'] ??
        body['message'] ??
        _validationMessage(json['errors'] ?? body['errors']);
    final message = value?.toString().trim();
    return message == null || message.isEmpty ? null : message;
  }

  String? _validationMessage(Object? errors) {
    if (errors is Map) {
      final messages = errors.values
          .expand((value) => value is List ? value : <Object?>[value])
          .whereType<Object>()
          .map((value) => value.toString().trim())
          .where((value) => value.isNotEmpty);
      return messages.isEmpty ? null : messages.join('\n');
    }
    if (errors is List) {
      final messages = errors
          .whereType<Object>()
          .map((value) => value.toString().trim())
          .where((value) => value.isNotEmpty);
      return messages.isEmpty ? null : messages.join('\n');
    }
    final message = errors?.toString().trim();
    return message == null || message.isEmpty ? null : message;
  }

  Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }

  int? _asInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}

class _LoginFailure implements Exception {
  const _LoginFailure(this.message);

  final String message;
}
