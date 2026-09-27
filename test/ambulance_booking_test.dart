import 'package:ambulance_app/app/data/models/ambulance_request_model.dart';
import 'package:ambulance_app/app/data/models/hospital_model.dart';
import 'package:ambulance_app/app/data/providers/api_provider.dart';
import 'package:ambulance_app/app/data/services/ambulance_request_service.dart';
import 'package:ambulance_app/app/data/services/storage_service.dart';
import 'package:ambulance_app/app/data/services/location_service.dart';
import 'package:ambulance_app/app/modules/ambulance/controllers/ambulance_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Dio dio;
  late AmbulanceRequestService service;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://example.test/ems-api'));
    service = AmbulanceRequestService(
      apiProvider: ApiProvider(client: dio, storageService: _TokenStorage()),
    );
  });

  test(
    'submits the old booking endpoint and request body with access token',
    () async {
      RequestOptions? sent;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            sent = options;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'header': {'result': true},
                  'body': {
                    'data': {
                      'bookingId': 42,
                      'bookingCode': 'EMS-42',
                      'bookingStatus': 'PENDING',
                    },
                  },
                },
              ),
            );
          },
        ),
      );

      final result = await service.submit(
        AmbulanceRequestDraft(
          requestFor: AmbulanceRequestFor.someoneElse,
          hospital: HospitalModel.fromJson({'id': '12', 'name': 'Central'}),
          patientName: 'Patient',
          patientAge: 34,
          patientGender: 'FEMALE',
          latitude: 11.56,
          longitude: 104.92,
          locationAccuracyMeters: 8,
          locationAddress: 'Main Road',
          typeCode: 'MEDICAL_EMERGENCY',
          priorityCode: 'HIGH',
          symptoms: 'Breathing difficulty',
          note: 'Phone: 012345678',
        ),
      );

      expect(sent?.method, 'POST');
      expect(
        sent?.uri.toString(),
        'https://example.test/ems-api/api/v1/mobile/ambulance-bookings/add',
      );
      expect(sent?.headers['Authorization'], 'Bearer access-123');
      expect(sent?.data, {
        'requestFor': 'SOMEONE',
        'hospitalId': 12,
        'patientId': null,
        'latitude': 11.56,
        'longitude': 104.92,
        'locationAccuracyMeters': 8.0,
        'locationName': '',
        'locationAddress': 'Main Road',
        'landmark': '',
        'provinceId': null,
        'districtId': null,
        'communeId': null,
        'villageId': null,
        'typeCode': 'MEDICAL_EMERGENCY',
        'priorityCode': 'HIGH',
        'patientNameReported': 'Patient',
        'patientAgeReported': 34,
        'patientGenderReported': 'FEMALE',
        'numberOfPatients': 1,
        'chiefComplaint': '',
        'symptoms': 'Breathing difficulty',
        'incidentDescription': '',
        'note': 'Phone: 012345678',
      });
      expect(result.id, '42');
      expect(result.code, 'EMS-42');
      expect(result.status, 'PENDING');
    },
  );

  test('cancels with the old endpoint and numeric booking ID', () async {
    RequestOptions? sent;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          sent = options;
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {'success': true},
            ),
          );
        },
      ),
    );

    await service.cancelBooking('42');

    expect(sent?.uri.path, '/ems-api/api/v1/mobile/ambulance-bookings/cancel');
    expect(sent?.data, {'bookingId': 42});
  });

  test('booking failure envelope exposes backend validation message', () async {
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
                  'statusCode': 422,
                  'errorText': 'Invalid pickup location.',
                },
              },
            ),
          );
        },
      ),
    );

    expect(
      () => service.submit(
        AmbulanceRequestDraft(
          hospital: HospitalModel.fromJson({'id': '12', 'name': 'Central'}),
        ),
      ),
      throwsA(
        isA<BookingApiException>()
            .having(
              (error) => error.message,
              'message',
              'Invalid pickup location.',
            )
            .having((error) => error.statusCode, 'status', 422),
      ),
    );
  });

  test('booking hospital picker uses the old list query', () async {
    RequestOptions? sent;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          sent = options;
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'body': {
                  'data': [
                    {'id': 12, 'hospitalName': 'Central Hospital'},
                  ],
                  'total': 1,
                },
              },
            ),
          );
        },
      ),
    );

    final page = await service.fetchHospitals();

    expect(sent?.uri.path, '/ems-api/api/v1/hospitals/list');
    expect(sent?.queryParameters, {
      'searchText': '',
      'page': 1,
      'rowsPerPage': 10,
      'orderBy': '',
      'status': 1,
    });
    expect(page.hospitals.single.id, '12');
    expect(page.hasMore, isFalse);
  });

  test('validation response keeps the request on the form', () async {
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
                data: {'message': 'Pickup address is invalid.'},
              ),
            ),
          );
        },
      ),
    );
    final controller = AmbulanceController(
      service: service,
      apiProvider: ApiProvider(client: dio),
      storageService: _TokenStorage(),
      locationService: LocationService(),
    );
    controller.draft.value = AmbulanceRequestDraft(
      patientName: 'Patient',
      hospital: HospitalModel.fromJson({'id': '12', 'name': 'Central'}),
      latitude: 11.56,
      longitude: 104.92,
      locationAccuracyMeters: 8,
      locationAddress: 'Main Road',
      typeCode: 'MEDICAL_EMERGENCY',
    );

    final result = await controller.submit();

    expect(result, isNull);
    expect(controller.status.value, AmbulanceRequestStatus.validationError);
    expect(controller.errorMessage.value, 'Pickup address is invalid.');
    expect(controller.hasSubmitted, isFalse);
    controller.onClose();
  });
}

class _TokenStorage extends StorageService {
  @override
  Future<String?> getAccessToken() async => 'access-123';
}
