import 'package:ambulance_app/app/data/providers/api_provider.dart';
import 'package:ambulance_app/app/data/models/login_response.dart';
import 'package:ambulance_app/app/data/services/location_service.dart';
import 'package:ambulance_app/app/data/services/storage_service.dart';
import 'package:ambulance_app/main.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;

void main() {
  late Dio dio;
  late _MemoryStorageService storage;

  setUp(() {
    Get.reset();
    dio = Dio(BaseOptions(baseUrl: 'http://example.test/ems-api'));
    storage = _MemoryStorageService();
    Get.put<StorageService>(storage, permanent: true);
    Get.put<ApiProvider>(
      ApiProvider(client: dio, storageService: storage),
      permanent: true,
    );
    Get.put<LocationService>(_NoLocationService(), permanent: true);
  });

  tearDown(Get.reset);

  Future<void> enterCredentials(WidgetTester tester) async {
    await tester.pumpWidget(const AmbulanceApp());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('phoneNumberField')),
      ' 012345678 ',
    );
    await tester.enterText(find.byKey(const Key('passwordField')), 'secret');
    await tester.ensureVisible(find.byKey(const Key('signInButton')));
    await tester.tap(find.byKey(const Key('signInButton')));
    await tester.pumpAndSettle();
  }

  testWidgets('login posts the old request and saves both tokens', (
    tester,
  ) async {
    RequestOptions? request;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.method == 'GET') {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {'body': <Object>[]},
              ),
            );
            return;
          }
          request = options;
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'header': {'result': true},
                'body': {
                  'accessToken': 'access-123',
                  'refreshToken': 'refresh-456',
                  'userId': 7,
                  'displayName': 'Responder',
                },
              },
            ),
          );
        },
      ),
    );

    await enterCredentials(tester);

    expect(request?.method, 'POST');
    expect(
      request?.uri.toString(),
      'http://example.test/ems-api/api/v1/auth/login',
    );
    expect(request?.data, {'phoneNumber': '012345678', 'password': 'secret'});
    expect(storage.accessToken, 'access-123');
    expect(storage.refreshToken, 'refresh-456');
    expect(storage.session?.userId, '7');
    expect(find.byKey(const Key('dashboardScreen')), findsOneWidget);
  });

  testWidgets('401 shows a useful error and stays on login', (tester) async {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response(
                requestOptions: options,
                statusCode: 401,
                data: {'message': 'Unauthorized'},
              ),
            ),
          );
        },
      ),
    );

    await enterCredentials(tester);

    expect(find.byKey(const Key('loginScreen')), findsOneWidget);
    expect(find.text('Incorrect phone number or password.'), findsOneWidget);
    expect(find.byKey(const Key('loginProgress')), findsNothing);
    expect(storage.accessToken, isNull);
    expect(storage.refreshToken, isNull);
  });

  testWidgets('failure envelope does not save tokens or navigate', (
    tester,
  ) async {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'header': {
                  'result': false,
                  'errorText': 'Account is inactive.',
                },
                'body': {'accessToken': 'must-not-save'},
              },
            ),
          );
        },
      ),
    );

    await enterCredentials(tester);

    expect(find.byKey(const Key('loginScreen')), findsOneWidget);
    expect(find.text('Account is inactive.'), findsOneWidget);
    expect(storage.accessToken, isNull);
  });

  testWidgets('network failure stops loading without navigating', (
    tester,
  ) async {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            ),
          );
        },
      ),
    );

    await enterCredentials(tester);

    expect(find.byKey(const Key('loginScreen')), findsOneWidget);
    expect(find.text('Check your internet connection.'), findsOneWidget);
    expect(find.byKey(const Key('loginProgress')), findsNothing);
  });

  testWidgets('failed token write clears the partial session', (tester) async {
    storage.failRefreshWrite = true;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'body': {
                  'accessToken': 'access-123',
                  'refreshToken': 'refresh-456',
                },
              },
            ),
          );
        },
      ),
    );

    await enterCredentials(tester);

    expect(find.byKey(const Key('loginScreen')), findsOneWidget);
    expect(
      find.text('Unable to save your session. Please try again.'),
      findsOneWidget,
    );
    expect(storage.accessToken, isNull);
    expect(storage.refreshToken, isNull);
  });
}

class _MemoryStorageService extends StorageService {
  String? accessToken;
  String? refreshToken;
  LoginResponse? session;
  bool failRefreshWrite = false;

  @override
  Future<void> saveAccessToken(String token) async {
    accessToken = token;
  }

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<void> saveRefreshToken(String token) async {
    if (failRefreshWrite) throw StateError('secure storage unavailable');
    refreshToken = token.isEmpty ? null : token;
  }

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> saveUserSession(LoginResponse value) async {
    session = value;
  }

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
