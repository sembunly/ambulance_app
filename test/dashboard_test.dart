import 'package:ambulance_app/app/data/models/login_response.dart';
import 'package:ambulance_app/app/data/providers/api_provider.dart';
import 'package:ambulance_app/app/data/services/location_service.dart';
import 'package:ambulance_app/app/data/services/storage_service.dart';
import 'package:ambulance_app/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Dio dio;
  late _SessionStorage storage;
  late DashboardController controller;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    storage = _SessionStorage();
    controller = DashboardController(
      apiProvider: ApiProvider(client: dio, storageService: storage),
      storageService: storage,
      locationService: _NoLocationService(),
    );
  });

  test('loads dispatches with stored user ID and bearer token', () async {
    RequestOptions? request;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          request = options;
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'emergencyHotline': '012345678',
                'data': [
                  {
                    'dispatchId': '21',
                    'dispatchCode': 'EMS-21',
                    'dispatchStatus': 'COMPLETED',
                    'createdAt': '2026-08-03T08:00:00Z',
                  },
                  {
                    'dispatchId': '22',
                    'dispatchCode': 'EMS-22',
                    'dispatchStatus': 'EN_ROUTE',
                    'etaMinutes': 8,
                    'createdAt': '2026-08-04T08:00:00Z',
                  },
                ],
              },
            ),
          );
        },
      ),
    );

    await controller.loadBookings();

    expect(
      request?.uri.toString(),
      'https://example.test/dispatches?userId=user%2F4',
    );
    expect(request?.headers['Authorization'], 'Bearer access-123');
    expect(controller.userName.value, 'Responder');
    expect(controller.bookingStatus.value, DashboardLoadStatus.success);
    expect(controller.emergencyHotline.value, '012345678');
    expect(controller.activeBooking?.code, 'EMS-22');
    expect(controller.activeBooking?.etaLabel, '8 min');
    expect(controller.activeBooking?.canTrackAmbulance, isTrue);
    expect(controller.recentBookings.single.code, 'EMS-21');
  });

  test('empty dispatch list shows empty state', () async {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {'success': true, 'data': <Object>[]},
            ),
          );
        },
      ),
    );

    await controller.loadBookings();

    expect(controller.bookingStatus.value, DashboardLoadStatus.empty);
    expect(controller.bookings, isEmpty);
  });

  test('accepts a root list as the old API client did', () async {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: [
                {'dispatchId': '23', 'dispatchStatus': 'PENDING'},
              ],
            ),
          );
        },
      ),
    );

    await controller.loadBookings();

    expect(controller.bookingStatus.value, DashboardLoadStatus.success);
    expect(controller.activeBooking?.id, '23');
  });

  test('backend failure shows its message', () async {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'header': {'result': false, 'errorText': 'Session expired'},
              },
            ),
          );
        },
      ),
    );

    await controller.loadBookings();

    expect(controller.bookingStatus.value, DashboardLoadStatus.error);
    expect(controller.bookingError.value, 'Session expired');
  });
}

class _SessionStorage extends StorageService {
  @override
  Future<String?> getAccessToken() async => 'access-123';

  @override
  Future<LoginResponse?> getUserSession() async => const LoginResponse(
    token: 'access-123',
    userId: 'user/4',
    displayName: 'Responder',
  );
}

class _NoLocationService extends LocationService {
  @override
  Future<bool> isServiceEnabled() async => false;
}
