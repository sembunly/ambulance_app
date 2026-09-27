import 'package:ambulance_app/app/data/models/dashboard_model.dart';
import 'package:ambulance_app/app/data/providers/api_provider.dart';
import 'package:ambulance_app/app/data/services/hospital_service.dart';
import 'package:ambulance_app/app/data/services/location_service.dart';
import 'package:ambulance_app/app/data/services/storage_service.dart';
import 'package:ambulance_app/app/modules/hospitals/controllers/hospitals_controller.dart';
import 'package:ambulance_app/app/routes/app_pages.dart';
import 'package:ambulance_app/main.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;

void main() {
  late Dio dio;
  late ApiProvider apiProvider;
  late _FixedLocationService locationService;

  setUp(() {
    Get.reset();
    dio = Dio(BaseOptions(baseUrl: 'https://example.test/ems-api'));
    final storage = _TokenStorage();
    apiProvider = ApiProvider(client: dio, storageService: storage);
    locationService = _FixedLocationService();
  });

  tearDown(Get.reset);

  test('loads the old hospital endpoint, query, and response model', () async {
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
                'body': {
                  'totalRecords': 1,
                  'data': [
                    {
                      'hospitalId': 7,
                      'hospitalName': 'Central Hospital',
                      'hospitalNameKhmer': 'មន្ទីរពេទ្យកណ្ដាល',
                      'latitude': 11.5564,
                      'longitude': 104.9282,
                      'status': 1,
                    },
                  ],
                },
              },
            ),
          );
        },
      ),
    );

    final page = await HospitalService(
      apiProvider: apiProvider,
    ).getHospitals(searchText: ' Central ');

    expect(request?.method, 'GET');
    expect(request?.uri.path, '/ems-api/api/v1/hospitals/list');
    expect(request?.headers['Authorization'], 'Bearer access-123');
    expect(request?.queryParameters, {
      'searchText': 'Central',
      'page': 1,
      'rowsPerPage': 10,
      'orderBy': '',
      'status': 1,
    });
    expect(page.total, 1);
    expect(page.hasMore, isFalse);
    expect(page.hospitals.single.id, '7');
    expect(page.hospitals.single.khmerName, 'មន្ទីរពេទ្យកណ្ដាល');
  });

  test('backend failure envelope keeps its error message', () async {
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
                  'errorText': 'Hospitals unavailable',
                },
              },
            ),
          );
        },
      ),
    );

    expect(
      () => HospitalService(apiProvider: apiProvider).getHospitals(),
      throwsA(
        isA<HospitalApiException>().having(
          (error) => error.message,
          'message',
          'Hospitals unavailable',
        ),
      ),
    );
  });

  test('Dio validation errors remain useful', () async {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response(
                requestOptions: options,
                statusCode: 422,
                data: {
                  'errors': {
                    'searchText': ['Search is invalid'],
                  },
                },
              ),
            ),
          );
        },
      ),
    );

    expect(
      () => HospitalService(apiProvider: apiProvider).getHospitals(),
      throwsA(
        isA<HospitalApiException>()
            .having((error) => error.message, 'message', 'Search is invalid')
            .having((error) => error.statusCode, 'status', 422),
      ),
    );
  });

  test('sorts nearby hospitals and appends the next page', () async {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final page = options.queryParameters['page'];
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'body': {
                  'total': 11,
                  'data': page == 1
                      ? [
                          {
                            'id': 2,
                            'hospitalName': 'Far Hospital',
                            'latitude': 12.0,
                            'longitude': 105.0,
                          },
                          {
                            'id': 1,
                            'hospitalName': 'Near Hospital',
                            'latitude': 11.5601,
                            'longitude': 104.9201,
                          },
                        ]
                      : [
                          {
                            'id': 3,
                            'hospitalName': 'Third Hospital',
                            'latitude': 11.7,
                            'longitude': 104.9,
                          },
                        ],
                },
              },
            ),
          );
        },
      ),
    );
    final controller = HospitalsController(
      hospitalService: HospitalService(apiProvider: apiProvider),
      locationService: locationService,
    );

    await controller.refreshHospitals();
    expect(controller.status.value, NearbyHospitalsStatus.success);
    expect(controller.hospitals.first.name, 'Near Hospital');
    expect(controller.hasMore.value, isTrue);

    await controller.loadMore();
    expect(controller.hospitals, hasLength(3));
    expect(controller.hospitals.first.name, 'Near Hospital');
    expect(controller.hasMore.value, isFalse);
  });

  testWidgets('shows hospital cards and debounced empty search', (
    tester,
  ) async {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final search = options.queryParameters['searchText'];
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'body': {
                  'total': search == '' ? 1 : 0,
                  'data': search == ''
                      ? [
                          {
                            'id': 7,
                            'hospitalName': 'Central Hospital',
                            'latitude': 11.5601,
                            'longitude': 104.9201,
                            'phone': '012345678',
                          },
                        ]
                      : <Object>[],
                },
              },
            ),
          );
        },
      ),
    );
    Get.put<StorageService>(_TokenStorage(), permanent: true);
    Get.put<ApiProvider>(apiProvider, permanent: true);
    Get.put<LocationService>(locationService, permanent: true);

    await tester.pumpWidget(const AmbulanceApp(initialRoute: Routes.hospitals));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('nearbyHospitalsScreen')), findsOneWidget);
    expect(find.text('Central Hospital'), findsOneWidget);
    expect(find.text('Call Hospital'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('hospitalSearchField')),
      'Other',
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('No matching hospitals'), findsOneWidget);
  });
}

class _TokenStorage extends StorageService {
  @override
  Future<String?> getAccessToken() async => 'access-123';
}

class _FixedLocationService extends LocationService {
  @override
  Future<bool> isServiceEnabled() async => true;

  @override
  Future<LocationPermissionStatus> checkPermission() async =>
      LocationPermissionStatus.allowed;

  @override
  Future<DashboardLocation?> getCurrentLocation() async =>
      const DashboardLocation(latitude: 11.56, longitude: 104.92);

  @override
  Stream<DashboardLocation> watchLocation({double distanceFilter = 1}) =>
      const Stream<DashboardLocation>.empty();
}
