import 'package:ambulance_app/app/data/models/login_response.dart';
import 'package:ambulance_app/app/data/providers/api_provider.dart';
import 'package:ambulance_app/app/data/services/location_service.dart';
import 'package:ambulance_app/app/data/services/storage_service.dart';
import 'package:ambulance_app/app/routes/app_pages.dart';
import 'package:ambulance_app/main.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;

void main() {
  late Dio dio;
  late _MemoryStorage storage;

  setUp(() {
    Get.reset();
    dio = Dio(BaseOptions(baseUrl: 'https://example.test/ems-api'));
    storage = _MemoryStorage();
    Get.put<StorageService>(storage, permanent: true);
    Get.put<ApiProvider>(
      ApiProvider(client: dio, storageService: storage),
      permanent: true,
    );
    Get.put<LocationService>(_NoLocationService(), permanent: true);
  });

  tearDown(Get.reset);

  testWidgets('signup posts old registration body and saves the session', (
    tester,
  ) async {
    RequestOptions? request;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.method == 'GET') {
            handler.resolve(
              Response(requestOptions: options, data: {'body': []}),
            );
            return;
          }
          request = options;
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'header': {'result': true},
                'body': {
                  'accessToken': 'signup-access',
                  'refreshToken': 'signup-refresh',
                  'userId': 12,
                  'displayName': 'Sok Dara',
                },
              },
            ),
          );
        },
      ),
    );
    await tester.pumpWidget(
      const AmbulanceApp(initialRoute: Routes.authentication),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('loginSignupButton')));
    await tester.tap(find.byKey(const Key('loginSignupButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('signupScreen')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('signupFullNameField')),
      'Sok Dara',
    );
    await tester.enterText(
      find.byKey(const Key('signupPhoneField')),
      '012345678',
    );
    await tester.enterText(
      find.byKey(const Key('signupEmailField')),
      'dara@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('signupPasswordField')),
      'secret123',
    );
    await tester.enterText(
      find.byKey(const Key('signupConfirmPasswordField')),
      'secret123',
    );
    await tester.ensureVisible(find.byKey(const Key('signUpButton')));
    await tester.tap(find.byKey(const Key('signUpButton')));
    await tester.pumpAndSettle();

    expect(request?.method, 'POST');
    expect(request?.path, '/api/v1/auth/register');
    expect(request?.data, {
      'username': 'dara',
      'email': 'dara@example.com',
      'phoneNumber': '012345678',
      'password': 'secret123',
      'firstName': 'Sok',
      'lastName': 'Dara',
      'avatar': '',
      'gender': '',
      'dateOfBirth': '',
    });
    expect(storage.accessToken, 'signup-access');
    expect(storage.refreshToken, 'signup-refresh');
    expect(storage.session?.userId, '12');
    expect(find.byKey(const Key('dashboardScreen')), findsOneWidget);
  });

  testWidgets('login stays fixed normally and scrolls for keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      const AmbulanceApp(initialRoute: Routes.authentication),
    );
    await tester.pumpAndSettle();

    final scrollView = tester.widget<SingleChildScrollView>(
      find.byKey(const Key('loginScrollView')),
    );
    expect(scrollView.physics, isA<NeverScrollableScrollPhysics>());
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('phoneNumberField')));
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final keyboardScrollView = tester.widget<SingleChildScrollView>(
      find.byKey(const Key('loginScrollView')),
    );
    expect(keyboardScrollView.physics, isA<ClampingScrollPhysics>());
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.enterText(
      find.byKey(const Key('phoneNumberField')),
      '012345678',
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(const Key('signInButton')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('login error fits the fixed phone layout', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'header': {
                  'result': false,
                  'errorText': 'Please check your account details.',
                },
              },
            ),
          );
        },
      ),
    );
    await tester.pumpWidget(
      const AmbulanceApp(initialRoute: Routes.authentication),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('phoneNumberField')),
      '012345678',
    );
    await tester.enterText(find.byKey(const Key('passwordField')), 'wrong');
    await tester.tap(find.byKey(const Key('signInButton')));
    await tester.pumpAndSettle();

    expect(find.text('Please check your account details.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('forgot password contact accepts keyboard input', (tester) async {
    await tester.pumpWidget(
      const AmbulanceApp(initialRoute: Routes.authentication),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('forgotPasswordButton')));
    await tester.tap(find.byKey(const Key('forgotPasswordButton')));
    await tester.pumpAndSettle();

    final contact = find.byKey(const Key('forgotPasswordContactField'));
    expect(contact, findsOneWidget);
    await tester.tap(contact);
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.enterText(contact, 'dara@example.com');
    expect(find.text('dara@example.com'), findsOneWidget);
    await tester.tap(find.byKey(const Key('sendRecoveryButton')));
    await tester.pumpAndSettle();
    expect(
      find.text('Password recovery is not available yet.'),
      findsOneWidget,
    );
  });
}

class _MemoryStorage extends StorageService {
  String? accessToken;
  String? refreshToken;
  LoginResponse? session;

  @override
  Future<void> saveAccessToken(String token) async => accessToken = token;

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<void> saveRefreshToken(String token) async => refreshToken = token;

  @override
  Future<void> saveUserSession(LoginResponse value) async => session = value;

  @override
  Future<LoginResponse?> getUserSession() async => session;

  @override
  Future<void> clearAuth() async {
    accessToken = null;
    refreshToken = null;
    session = null;
  }
}

class _NoLocationService extends LocationService {
  @override
  Future<bool> isServiceEnabled() async => false;
}
