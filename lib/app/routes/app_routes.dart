part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const home = _Paths.home;
  static const splash = _Paths.splash;
  static const authentication = _Paths.authentication;
  static const signup = _Paths.signup;
  static const forgotPassword = _Paths.forgotPassword;
  static const dashboard = _Paths.dashboard;
  static const ambulance = _Paths.ambulance;
  static const tracking = _Paths.tracking;
  static const hospitals = _Paths.hospitals;
  static const profile = _Paths.profile;
  static const settings = _Paths.settings;
  static const passwordSettings = _Paths.passwordSettings;
  static const notifications = _Paths.notifications;
  // ignore: constant_identifier_names
  static const AUTHENTICATION = _Paths.authentication;
  // ignore: constant_identifier_names
  static const DASHBOARD = _Paths.dashboard;
}

abstract class _Paths {
  _Paths._();
  static const home = '/home';
  static const splash = '/splash';
  static const authentication = '/authentication';
  static const signup = '/authentication/signup';
  static const forgotPassword = '/authentication/forgot-password';
  static const dashboard = '/dashboard';
  static const ambulance = '/ambulance';
  static const tracking = '/tracking';
  static const hospitals = '/hospitals';
  static const profile = '/profile';
  static const settings = '/settings';
  static const passwordSettings = '/settings/password';
  static const notifications = '/notifications';
}
