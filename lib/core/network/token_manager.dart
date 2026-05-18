import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  static const _secureStorage = FlutterSecureStorage();
  
  static const _keyAccessToken = 'access_token';
  static const _keyUserEmail = 'user_email';

  /// Securely save JWT access token and user identifier email
  static Future<void> saveSession({required String token, required String email}) async {
    await _secureStorage.write(key: _keyAccessToken, value: token);
    await _secureStorage.write(key: _keyUserEmail, value: email);
  }

  /// Read the stored access token
  static Future<String?> getToken() async {
    return await _secureStorage.read(key: _keyAccessToken);
  }

  /// Read the stored user email
  static Future<String?> getEmail() async {
    return await _secureStorage.read(key: _keyUserEmail);
  }

  /// Clear the session details on logout or token expiration
  static Future<void> clearSession() async {
    await _secureStorage.delete(key: _keyAccessToken);
    await _secureStorage.delete(key: _keyUserEmail);
  }
}
