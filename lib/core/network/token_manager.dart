import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  static const _secureStorage = FlutterSecureStorage();

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUserEmail = 'user_email';

  /// Securely save JWT access token, refresh token and user identifier email
  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String email,
  }) async {
    await _secureStorage.write(key: _keyAccessToken, value: accessToken);
    await _secureStorage.write(key: _keyRefreshToken, value: refreshToken);
    await _secureStorage.write(key: _keyUserEmail, value: email);
  }

  /// Read the stored access token
  static Future<String?> getToken() async {
    return await _secureStorage.read(key: _keyAccessToken);
  }

  /// Read the stored refresh token
  static Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _keyRefreshToken);
  }

  /// Read the stored user email
  static Future<String?> getEmail() async {
    return await _secureStorage.read(key: _keyUserEmail);
  }

  /// Clear the session details on logout or token expiration
  static Future<void> clearSession() async {
    await _secureStorage.delete(key: _keyAccessToken);
    await _secureStorage.delete(key: _keyRefreshToken);
    await _secureStorage.delete(key: _keyUserEmail);
  }
}
