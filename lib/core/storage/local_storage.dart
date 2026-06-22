import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  /// Get list of string values
  List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }

  /// Save list of string values
  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs.setStringList(key, value);
  }

  /// Get String value
  String? getString(String key) {
    return _prefs.getString(key);
  }

  /// Save String value
  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  /// Clear all keys
  Future<bool> clear() async {
    return await _prefs.clear();
  }

  /// Remove a key
  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }
}

/// Provider for SharedPreferences instance (to be overridden in main.dart)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'SharedPreferences has not been initialized. Make sure to override sharedPreferencesProvider inside main.dart',
  );
});

/// Provider for LocalStorageService
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorageService(prefs);
});
