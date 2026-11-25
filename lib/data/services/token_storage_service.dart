import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorageService {
  const TokenStorageService(this._storage);
  final FlutterSecureStorage _storage;

  static const _tokenKey = 'coleggo_auth_token';
  static const _refreshTokenKey = 'coleggo_refresh_token';

  Future<String?> readToken() => _storage.read(key: _tokenKey);
  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);
  Future<void> writeRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
