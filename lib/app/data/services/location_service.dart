import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:location/location.dart';

import '../models/dashboard_model.dart';

enum LocationPermissionStatus { denied, deniedForever, allowed }

class LocationService {
  LocationService({Location? location}) : _location = location ?? Location();

  final Location _location;

  Future<bool> isServiceEnabled() => _location.serviceEnabled();

  Future<LocationPermissionStatus> checkPermission() async =>
      _mapPermission(await _location.hasPermission());

  Future<LocationPermissionStatus> requestPermission() async =>
      _mapPermission(await _location.requestPermission());

  Future<DashboardLocation?> getCurrentLocation() async {
    await _location.changeSettings(accuracy: LocationAccuracy.high);
    final data = await _location.getLocation();
    return DashboardLocation(
      latitude: data.latitude,
      longitude: data.longitude,
    );
  }

  Future<void> openLocationSettings() async {
    await _location.requestService();
  }

  Future<void> openAppSettings() async {
    await geolocator.Geolocator.openAppSettings();
  }

  LocationPermissionStatus _mapPermission(PermissionStatus permission) {
    return switch (permission) {
      PermissionStatus.granted ||
      PermissionStatus.grantedLimited => LocationPermissionStatus.allowed,
      PermissionStatus.denied => LocationPermissionStatus.denied,
      PermissionStatus.deniedForever => LocationPermissionStatus.deniedForever,
    };
  }
}
