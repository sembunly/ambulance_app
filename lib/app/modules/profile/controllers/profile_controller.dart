import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../config/app_config.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/storage_service.dart';
import '../../../routes/app_pages.dart';

enum ProfileStatus { initial, loading, success, empty, error }

class ProfileController extends GetxController {
  ProfileController({
    required ApiProvider apiProvider,
    required StorageService storageService,
  }) : _apiProvider = apiProvider,
       _storageService = storageService;

  final ApiProvider _apiProvider;
  final StorageService _storageService;

  final status = ProfileStatus.initial.obs;
  final profile = Rxn<UserProfile>();
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    if (status.value == ProfileStatus.loading) return;
    status.value = ProfileStatus.loading;
    profile.value = null;
    errorMessage.value = null;

    try {
      final userId =
          (await _storageService.getUserSession())?.userId.trim() ?? '';
      final path = userId.isEmpty
          ? AppConfig.userProfile
          : '${AppConfig.userProfile}${Uri.encodeComponent(userId)}';
      final response = await _apiProvider.get(path);
      final json = _asMap(response.data);
      final header = _asMap(json['header']);
      if (json['success'] == false || header['result'] == false) {
        throw _ProfileFailure(
          (header['errorText'] ?? json['errorText'] ?? json['message'])
                  ?.toString() ??
              'Unable to load your profile.',
        );
      }
      profile.value = UserProfile.fromJson(json);
      status.value = ProfileStatus.success;
    } on DioException catch (error) {
      final data = _asMap(error.response?.data);
      final header = _asMap(data['header']);
      errorMessage.value =
          (header['errorText'] ?? data['message'])?.toString() ??
          (error.response == null
              ? 'Check your internet connection.'
              : 'Unable to load your profile.');
      status.value = ProfileStatus.error;
    } on _ProfileFailure catch (error) {
      errorMessage.value = error.message;
      status.value = ProfileStatus.error;
    } catch (_) {
      errorMessage.value = 'Unable to load your profile.';
      status.value = ProfileStatus.error;
    }
  }

  Future<void> logout() async {
    try {
      await _storageService.clearAuth();
      Get.offAllNamed(Routes.authentication);
    } catch (_) {
      errorMessage.value = 'Unable to securely sign out.';
      Get.snackbar('Sign out failed', errorMessage.value!);
    }
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return const <String, dynamic>{};
  }
}

class _ProfileFailure implements Exception {
  const _ProfileFailure(this.message);
  final String message;
}
