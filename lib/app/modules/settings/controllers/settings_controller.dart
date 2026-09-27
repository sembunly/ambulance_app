import 'package:dio/dio.dart';
import 'package:flutter/material.dart' show Locale;
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/app_config.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/storage_service.dart';
import '../../../routes/app_pages.dart';

enum SettingsStatus { initial, loading, success, error }

class SettingsController extends GetxController {
  SettingsController({
    required ApiProvider apiProvider,
    required StorageService storageService,
    SharedPreferences? preferences,
  }) : _apiProvider = apiProvider,
       _storageService = storageService,
       _preferences = preferences;

  static const languageKey = 'language';
  static const notificationEnabledKey = 'notification_enabled';
  static const firstOpenKey = 'first_open';

  final ApiProvider _apiProvider;
  final StorageService _storageService;
  SharedPreferences? _preferences;

  final status = SettingsStatus.initial.obs;
  final language = 'en'.obs;
  final notificationsEnabled = false.obs;
  final firstOpen = true.obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    initialize();
  }

  Future<SharedPreferences> get _prefs async =>
      _preferences ??= await SharedPreferences.getInstance();

  Future<void> initialize() async {
    if (status.value == SettingsStatus.loading ||
        status.value == SettingsStatus.success) {
      return;
    }
    status.value = SettingsStatus.loading;
    errorMessage.value = null;
    try {
      final prefs = await _prefs;
      language.value = _normalizedLanguage(prefs.getString(languageKey));
      notificationsEnabled.value =
          prefs.getBool(notificationEnabledKey) ?? false;
      firstOpen.value = prefs.getBool(firstOpenKey) ?? true;
      if (!prefs.containsKey(languageKey)) {
        await prefs.setString(languageKey, language.value);
      }
      if (!prefs.containsKey(notificationEnabledKey)) {
        await prefs.setBool(notificationEnabledKey, notificationsEnabled.value);
      }
      if (!prefs.containsKey(firstOpenKey)) {
        await prefs.setBool(firstOpenKey, firstOpen.value);
      }
      status.value = SettingsStatus.success;
    } catch (_) {
      status.value = SettingsStatus.error;
      errorMessage.value = 'Unable to load app preferences.';
    }
  }

  Future<void> setLanguage(String value) async {
    final previous = language.value;
    language.value = _normalizedLanguage(value);
    errorMessage.value = null;
    try {
      await (await _prefs).setString(languageKey, language.value);
      await Get.updateLocale(Locale(language.value));
      status.value = SettingsStatus.success;
    } catch (_) {
      language.value = previous;
      _persistenceError();
    }
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final previous = notificationsEnabled.value;
    notificationsEnabled.value = value;
    errorMessage.value = null;
    try {
      await (await _prefs).setBool(notificationEnabledKey, value);
      status.value = SettingsStatus.success;
    } catch (_) {
      notificationsEnabled.value = previous;
      _persistenceError();
    }
  }

  Future<void> markFirstOpenComplete() async {
    if (!firstOpen.value) return;
    firstOpen.value = false;
    try {
      await (await _prefs).setBool(firstOpenKey, false);
      status.value = SettingsStatus.success;
    } catch (_) {
      firstOpen.value = true;
      _persistenceError();
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final session = await _storageService.getUserSession();
    final userId = int.tryParse(session?.userId ?? '');
    if (userId == null) {
      throw const SettingsFailure(
        'User session is missing. Please sign in again.',
      );
    }
    try {
      final response = await _apiProvider.post(
        AppConfig.changePassword,
        data: <String, dynamic>{
          'userId': userId,
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );
      final json = _asMap(response.data);
      final header = _asMap(json['header']);
      if (json['success'] == false || header['result'] == false) {
        throw SettingsFailure(
          _serverMessage(json) ?? 'Unable to change password.',
        );
      }
    } on DioException catch (error) {
      final message =
          _serverMessage(_asMap(error.response?.data)) ??
          (error.response == null
              ? 'Check your internet connection.'
              : 'Unable to change password.');
      throw SettingsFailure(message);
    }
  }

  Future<void> logout() async {
    try {
      await _storageService.clearAuth();
      Get.offAllNamed(Routes.authentication);
    } catch (_) {
      errorMessage.value = 'Unable to securely sign out.';
    }
  }

  String _normalizedLanguage(String? value) => value == 'km' ? 'km' : 'en';

  void _persistenceError() {
    status.value = SettingsStatus.error;
    errorMessage.value = 'Unable to save app preferences.';
  }

  static String? _serverMessage(Map<String, dynamic> json) {
    final header = _asMap(json['header']);
    final body = _asMap(json['body']);
    final message =
        (header['errorText'] ??
                json['errorText'] ??
                json['message'] ??
                body['message'])
            ?.toString()
            .trim();
    return message == null || message.isEmpty ? null : message;
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return const <String, dynamic>{};
  }
}

class SettingsFailure implements Exception {
  const SettingsFailure(this.message);
  final String message;

  @override
  String toString() => message;
}
