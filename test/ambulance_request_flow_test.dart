import 'package:ambulance_app/app/data/models/dashboard_model.dart';
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
  late bool cancelled;

  setUp(() {
    Get.reset();
    cancelled = false;
    final storage = _SessionStorage();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/ems-api'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final path = options.uri.path;
          final Object data;
          if (path.endsWith('/hospitals/list')) {
            data = {
              'body': {
                'data': [
                  {'id': 12, 'hospitalName': 'Central Hospital'},
                ],
                'total': 1,
              },
            };
          } else if (path.endsWith('/ambulance-bookings/add')) {
            data = {
              'body': {
                'data': {
                  'bookingId': 42,
                  'bookingCode': 'EMS-42',
                  'bookingStatus': 'PENDING',
                },
              },
            };
          } else if (path.endsWith('/dispatches')) {
            data = {
              'data': [
                {
                  'dispatchId': 42,
                  'dispatchCode': 'EMS-42',
                  'dispatchStatus': cancelled ? 'CANCELLED' : 'PENDING',
                },
              ],
            };
          } else if (path.endsWith('/ambulance-bookings/cancel')) {
            cancelled = true;
            data = {'success': true};
          } else {
            handler.reject(
              DioException(
                requestOptions: options,
                error: 'Unexpected request: $path',
              ),
            );
            return;
          }
          handler.resolve(
            Response(requestOptions: options, statusCode: 200, data: data),
          );
        },
      ),
    );
    Get.put<StorageService>(storage, permanent: true);
    Get.put<ApiProvider>(
      ApiProvider(client: dio, storageService: storage),
      permanent: true,
    );
    Get.put<LocationService>(_LocationService(), permanent: true);
  });

  tearDown(Get.reset);

  testWidgets('request moves through review and submits once', (tester) async {
    await tester.pumpWidget(const AmbulanceApp(initialRoute: Routes.ambulance));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('requestAmbulanceScreen')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('phoneNumberField')),
      '012345678',
    );
    await tester.tap(find.byKey(const Key('ambulanceRequestContinueButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('selectHospital_12')));
    await tester.tap(find.byKey(const Key('ambulanceRequestContinueButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pickupCoordinates')), findsOneWidget);

    await tester.tap(find.byKey(const Key('ambulanceRequestContinueButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('emergencyTypeCodeField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Medical emergency').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ambulanceRequestContinueButton')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('confirmAmbulanceBookingScreen')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('confirmAmbulanceBookingButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('submitAmbulanceBookingButton')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('bookingStatusScreen')), findsOneWidget);
    expect(find.text('EMS-42'), findsOneWidget);
  });

  testWidgets(
    'active booking opens status and cancellation refreshes dashboard',
    (tester) async {
      await tester.pumpWidget(
        const AmbulanceApp(initialRoute: Routes.dashboard),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('activeBookingCard')), findsOneWidget);
      await tester.tap(find.byKey(const Key('viewActiveBookingButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const Key('bookingStatusScreen')), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const Key('cancelAmbulanceBookingButton')),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const Key('cancelAmbulanceBookingButton')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Cancel Booking').last);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(cancelled, isTrue);
      expect(find.byKey(const Key('dashboardScreen')), findsOneWidget);
      expect(find.byKey(const Key('activeBookingEmpty')), findsOneWidget);
    },
  );
}

class _SessionStorage extends StorageService {
  @override
  Future<String?> getAccessToken() async => 'access-123';

  @override
  Future<LoginResponse?> getUserSession() async => const LoginResponse(
    token: 'access-123',
    userId: '',
    displayName: 'Responder',
  );
}

class _LocationService extends LocationService {
  @override
  Future<bool> isServiceEnabled() async => true;

  @override
  Future<LocationPermissionStatus> checkPermission() async =>
      LocationPermissionStatus.allowed;

  @override
  Future<DashboardLocation?> getCurrentLocation() async =>
      const DashboardLocation(latitude: 11.56, longitude: 104.92, accuracy: 8);

  @override
  Stream<DashboardLocation> watchLocation({double distanceFilter = 1}) =>
      const Stream<DashboardLocation>.empty();
}
