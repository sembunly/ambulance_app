class AppConfig {
  AppConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.102.24:8085/ems-api',
  );

  // ── Auth ─────────────────────────────────────────────────────────────────
  static const loginEndpoint = '/api/v1/auth/login';
  static const signup = '/api/v1/auth/register';
  static const refreshToken = '/api/v1/auth/refresh';

  // ── Core resources ───────────────────────────────────────────────────────
  static const patients = '/patients';
  static const dispatches = '/dispatches';
  static const hospitals = '/hospitals';
  static const reports = '/reports';

  // ── User account ─────────────────────────────────────────────────────────
  static const userProfile = '/api/v1/users/find/';
  static const changePassword = '/api/v1/users/change-password';

  // ── Hospitals ────────────────────────────────────────────────────────────
  static const hospitalsList = '/api/v1/hospitals/list';
  static const nearbyHospitals = '/api/v1/mobile/hospitals/nearby';

  // ── Ambulance booking ────────────────────────────────────────────────────
  static const addAmbulanceBooking = '/api/v1/mobile/ambulance-bookings/add';

  static const cancelAmbulanceBooking =
      '/api/v1/mobile/ambulance-bookings/cancel';

  static const ambulanceBookingList = '/api/v1/mobile/ambulance-bookings/list';

  static String ambulanceBookingById(dynamic id) =>
      '/api/v1/mobile/ambulance-bookings/find/$id';

  // ── Ambulances ───────────────────────────────────────────────────────────
  static const nearbyAmbulances = '/api/v1/mobile/ambulances/nearby';
}
