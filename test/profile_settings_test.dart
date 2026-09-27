import 'package:ambulance_app/app/data/models/login_response.dart';
import 'package:ambulance_app/app/data/providers/api_provider.dart';
import 'package:ambulance_app/app/data/services/storage_service.dart';
import 'package:ambulance_app/app/modules/profile/controllers/profile_controller.dart';
import 'package:ambulance_app/app/modules/settings/controllers/settings_controller.dart';
import 'package:ambulance_app/app/routes/app_pages.dart';
import 'package:ambulance_app/main.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Dio dio;
  late _MemorySessionStorage storage;
  late ApiProvider api;

  setUp(() {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    dio = Dio(BaseOptions(baseUrl: 'https://example.test/ems-api'));
    storage = _MemorySessionStorage();
    api = ApiProvider(client: dio, storageService: storage);
  });

  tearDown(Get.reset);

  test(
    'profile fetch uses session ID, bearer token, and old endpoint',
    () async {
      storage.session = const LoginResponse(
        token: 'access-123',
        userId: 'user/123',
        displayName: 'Responder',
      );
      RequestOptions? request;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            request = options;
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'success': true,
                  'data': [
                    {
                      'userId': 4,
                      'firstName': 'bunly',
                      'lastName': 'boy',
                      'phoneNumber': '069800921',
                    },
                  ],
                },
              ),
            );
          },
        ),
      );
      final controller = ProfileController(
        apiProvider: api,
        storageService: storage,
      );

      await controller.loadProfile();

      expect(request?.method, 'GET');
      expect(request?.path, '/api/v1/users/find/user%2F123');
      expect(request?.headers['Authorization'], 'Bearer access-123');
      expect(controller.status.value, ProfileStatus.success);
      expect(controller.profile.value?.fullName, 'bunly boy');
      expect(controller.profile.value?.phone, '069800921');
    },
  );

  test('password change sends old body and reports backend failures', () async {
    storage.session = const LoginResponse(
      token: 'access-123',
      userId: '4',
      displayName: 'Responder',
    );
    RequestOptions? request;
    var succeed = true;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          request = options;
          handler.resolve(
            Response(
              requestOptions: options,
              data: succeed
                  ? {
                      'header': {'result': true},
                    }
                  : {
                      'header': {
                        'result': false,
                        'errorText': 'Wrong password.',
                      },
                    },
            ),
          );
        },
      ),
    );
    final controller = SettingsController(
      apiProvider: api,
      storageService: storage,
    );

    Future<void> submit() => controller.changePassword(
      currentPassword: 'old-secret',
      newPassword: 'new-secret1',
      confirmPassword: 'new-secret1',
    );
    await submit();

    expect(request?.method, 'POST');
    expect(request?.path, '/api/v1/users/change-password');
    expect(request?.headers['Authorization'], 'Bearer access-123');
    expect(request?.data, {
      'userId': 4,
      'currentPassword': 'old-secret',
      'newPassword': 'new-secret1',
      'confirmPassword': 'new-secret1',
    });
    succeed = false;
    await expectLater(
      submit(),
      throwsA(
        isA<SettingsFailure>().having(
          (error) => error.message,
          'message',
          'Wrong password.',
        ),
      ),
    );
  });

  testWidgets('profile route displays the fetched user and supports retry', (
    tester,
  ) async {
    storage.session = const LoginResponse(
      token: 'access-123',
      userId: '4',
      displayName: 'Responder',
    );
    var fail = true;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: fail
                  ? {
                      'header': {
                        'result': false,
                        'errorText': 'Try again later.',
                      },
                    }
                  : {
                      'success': true,
                      'data': [
                        {
                          'userId': 4,
                          'firstName': 'Test',
                          'lastName': 'Responder',
                          'email': 'test@example.com',
                        },
                      ],
                    },
            ),
          );
        },
      ),
    );
    Get.put<StorageService>(storage, permanent: true);
    Get.put<ApiProvider>(api, permanent: true);
    await tester.pumpWidget(const AmbulanceApp(initialRoute: Routes.profile));
    await tester.pumpAndSettle();

    expect(find.text('Try again later.'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Test Responder'), findsWidgets);
    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.byKey(const Key('profileSignOutButton')), findsOneWidget);
  });

  testWidgets('password form reaches the settings controller', (tester) async {
    storage.session = const LoginResponse(
      token: 'access-123',
      userId: '4',
      displayName: 'Responder',
    );
    RequestOptions? request;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          request = options;
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'header': {'result': true},
              },
            ),
          );
        },
      ),
    );
    Get.put<StorageService>(storage, permanent: true);
    Get.put<ApiProvider>(api, permanent: true);
    await tester.pumpWidget(
      const AmbulanceApp(initialRoute: Routes.passwordSettings),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('currentPasswordField')),
      'old-secret',
    );
    await tester.enterText(
      find.byKey(const Key('newPasswordField')),
      'new-secret1',
    );
    await tester.enterText(
      find.byKey(const Key('confirmNewPasswordField')),
      'new-secret1',
    );
    await tester.ensureVisible(find.byKey(const Key('savePasswordButton')));
    await tester.tap(find.byKey(const Key('savePasswordButton')));
    await tester.pumpAndSettle();

    expect(request?.path, '/api/v1/users/change-password');
    expect(request?.data['userId'], 4);
    expect(request?.data['newPassword'], 'new-secret1');
  });

  testWidgets('settings save normal preferences and logout clears session', (
    tester,
  ) async {
    storage.session = const LoginResponse(
      token: 'access-123',
      userId: '4',
      displayName: 'Responder',
    );
    Get.put<StorageService>(storage, permanent: true);
    Get.put<ApiProvider>(api, permanent: true);
    await tester.pumpWidget(const AmbulanceApp(initialRoute: Routes.settings));
    await tester.pumpAndSettle();

    final controller = Get.find<SettingsController>();
    await controller.setLanguage('km');
    await controller.setNotificationsEnabled(true);
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('language'), 'km');
    expect(prefs.getBool('notification_enabled'), isTrue);
    expect(Get.locale?.languageCode, 'km');

    await tester.ensureVisible(find.byKey(const Key('moreSignOutButton')));
    await tester.tap(find.byKey(const Key('moreSignOutButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ចាកចេញ').last);
    await tester.pumpAndSettle();

    expect(storage.clearCount, 1);
    expect(find.byKey(const Key('loginScreen')), findsOneWidget);
    expect(prefs.getString('language'), 'km');
    expect(prefs.getBool('notification_enabled'), isTrue);
  });
}

class _MemorySessionStorage extends StorageService {
  LoginResponse? session;
  int clearCount = 0;

  @override
  Future<LoginResponse?> getUserSession() async => session;

  @override
  Future<String?> getAccessToken() async => session?.accessToken;

  @override
  Future<void> clearAuth() async {
    session = null;
    clearCount++;
  }
}
