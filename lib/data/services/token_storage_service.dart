import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorageService {
  const TokenStorageService(this._storage);
  final FlutterSecureStorage _storage;

  static const _tokenKey = 'coleggo_auth_token';

  Future<String?> readToken() => _storage.read(key: _tokenKey);
  Future<void> writeToken(String token) => _storage.write(key: _tokenKey, value: token);
  Future<void> deleteToken() => _storage.delete(key: _tokenKey);
}
