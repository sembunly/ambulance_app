import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/login_response.dart';

class StorageService {
  StorageService({FlutterSecureStorage? secureStorage})
    : _storage = secureStorage ?? const FlutterSecureStorage();

  static const accessTokenKey = 'access_token';
  static const refreshTokenKey = 'refresh_token';
  static const userSessionKey = 'user_session';

  final FlutterSecureStorage _storage;

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: accessTokenKey, value: token);

  Future<String?> getAccessToken() => _storage.read(key: accessTokenKey);

  Future<void> saveRefreshToken(String token) => token.isEmpty
      ? _storage.delete(key: refreshTokenKey)
      : _storage.write(key: refreshTokenKey, value: token);

  Future<String?> getRefreshToken() => _storage.read(key: refreshTokenKey);

  Future<void> saveUserSession(LoginResponse session) => _storage.write(
    key: userSessionKey,
    value: jsonEncode(session.toStoredSessionJson()),
  );

  Future<LoginResponse?> getUserSession() async {
    final values = await Future.wait<String?>([
      getAccessToken(),
      getRefreshToken(),
      _storage.read(key: userSessionKey),
    ]);
    final accessToken = values[0] ?? '';
    final encodedSession = values[2];
    if (accessToken.isEmpty || encodedSession == null) return null;

    try {
      final decoded = jsonDecode(encodedSession);
      if (decoded is! Map) return null;
      return LoginResponse.fromStoredSession(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
        accessToken: accessToken,
        refreshToken: values[1] ?? '',
      );
    } on FormatException {
      return null;
    }
  }

  Future<void> clearAuth() => Future.wait<void>([
    _storage.delete(key: accessTokenKey),
    _storage.delete(key: refreshTokenKey),
    _storage.delete(key: userSessionKey),
  ]);
}
