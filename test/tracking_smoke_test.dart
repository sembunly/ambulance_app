import 'dart:async';
import 'dart:io';

import 'package:ambulance_app/app/data/models/dashboard_model.dart';
import 'package:ambulance_app/app/data/models/map_route.dart';
import 'package:ambulance_app/app/data/models/realtime_message.dart';
import 'package:ambulance_app/app/data/models/tracked_location.dart';
import 'package:ambulance_app/app/data/providers/realtime_provider.dart';
import 'package:ambulance_app/app/data/services/location_service.dart';
import 'package:ambulance_app/app/data/services/route_service.dart';
import 'package:ambulance_app/app/modules/tracking/controllers/tracking_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  tearDown(Get.reset);

  test('STOMP provider subscribes and parses a live WebSocket message', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      socket.listen((data) {
        final frame = data.toString();
        if (frame.startsWith('CONNECT')) {
          socket.add('CONNECTED\nversion:1.2\nheart-beat:0,0\n\n\u0000');
        } else if (frame.startsWith('SUBSCRIBE')) {
          final id = RegExp(r'(?:^|\n)id:([^\n]+)').firstMatch(frame)?.group(1);
          if (id == null) return;
          socket.add(
            'MESSAGE\nsubscription:$id\ndestination:/topic/ambulance-locations\n'
            'message-id:1\ncontent-type:application/json\n\n'
            '{"id":"event-1","type":"ambulance.location",'
            '"payload":{"latitude":11.56,"longitude":104.92}}\u0000',
          );
        }
      });
    });

    final provider = RealtimeProvider(
      url: 'ws://127.0.0.1:${server.port}',
      useSockJs: false,
    );
    final messages = await provider
        .watchEvents()
        .take(2)
        .toList()
        .timeout(const Duration(seconds: 5));

    expect(messages.first.type, 'realtime.connected');
    expect(messages.last.id, 'event-1');
    expect(messages.last.payload['latitude'], 11.56);
  });

  testWidgets('GPS and STOMP locations build markers and a route polyline', (
    tester,
  ) async {
    final realtime = _FakeRealtimeProvider();
    final routeService = _FakeRouteService();
    final controller = Get.put(
      TrackingController(
        locationService: _FakeLocationService(),
        realtimeProvider: realtime,
        routeService: routeService,
      ),
    );
    await tester.pump();
    expect(controller.gpsStatus.value, GpsTrackingStatus.success);
    expect(controller.patientLocation.value?.latitude, 11.55);

    realtime.send(
      const RealtimeMessage(
        id: 'event-1',
        type: 'ambulance.location',
        payload: {'latitude': 11.56, 'longitude': 104.92, 'heading': 45},
      ),
    );
    await tester.pumpAndSettle();

    expect(controller.realtimeStatus.value, RealtimeEventsStatus.success);
    expect(controller.ambulanceLocation.value?.longitude, 104.92);
    expect(routeService.calls, 1);
    expect(controller.markers.map((marker) => marker.markerId.value).toSet(), {
      'patient',
      'ambulance',
    });
    expect(
      controller.markers
          .singleWhere((marker) => marker.markerId.value == 'ambulance')
          .rotation,
      45,
    );
    final polylines = controller.polylines(Colors.blue);
    expect(polylines.single.polylineId.value, 'ambulancePatientRoute');
    expect(polylines.single.points, [
      const LatLng(11.56, 104.92),
      const LatLng(11.55, 104.91),
    ]);

    Get.delete<TrackingController>();
    await realtime.close();
  });
}

class _FakeLocationService extends LocationService {
  @override
  Future<bool> isServiceEnabled() async => true;

  @override
  Future<LocationPermissionStatus> checkPermission() async =>
      LocationPermissionStatus.allowed;

  @override
  Future<DashboardLocation?> getCurrentLocation() async =>
      const DashboardLocation(latitude: 11.55, longitude: 104.91, accuracy: 5);

  @override
  Stream<DashboardLocation> watchLocation({double distanceFilter = 1}) =>
      const Stream<DashboardLocation>.empty();
}

class _FakeRealtimeProvider extends RealtimeProvider {
  final _events = StreamController<RealtimeMessage>.broadcast();

  @override
  Stream<RealtimeMessage> watchEvents() => _events.stream;

  void send(RealtimeMessage message) => _events.add(message);

  Future<void> close() => _events.close();
}

class _FakeRouteService extends RouteService {
  _FakeRouteService() : super(apiKey: 'test-key');

  int calls = 0;

  @override
  Future<MapRoute> getRoute({
    required TrackedLocation origin,
    required TrackedLocation destination,
  }) async {
    calls++;
    return MapRoute(points: [origin, destination]);
  }
}
