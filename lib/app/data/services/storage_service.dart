import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  StorageService({FlutterSecureStorage? secureStorage})
    : _storage = secureStorage ?? const FlutterSecureStorage();

  static const accessTokenKey = 'access_token';
  static const refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: accessTokenKey, value: token);

  Future<String?> getAccessToken() => _storage.read(key: accessTokenKey);

  Future<void> saveRefreshToken(String token) => token.isEmpty
      ? _storage.delete(key: refreshTokenKey)
      : _storage.write(key: refreshTokenKey, value: token);

  Future<String?> getRefreshToken() => _storage.read(key: refreshTokenKey);

  Future<void> clearAuth() => Future.wait<void>([
    _storage.delete(key: accessTokenKey),
    _storage.delete(key: refreshTokenKey),
  ]);
}
