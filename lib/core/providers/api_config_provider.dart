import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage/local_storage.dart';
import '../network/api_client.dart';

/// Provider to reactively track and manage the custom API Base URL
final apiBaseUrlProvider = StateNotifierProvider<ApiBaseUrlNotifier, String>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ApiBaseUrlNotifier(prefs);
});

class ApiBaseUrlNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;

  static const String _storageKey = 'api_custom_base_url';

  ApiBaseUrlNotifier(this._prefs) : super(_getInitialBaseUrl(_prefs));

  static String _getInitialBaseUrl(SharedPreferences prefs) {
    final stored = prefs.getString(_storageKey);
    if (stored != null && stored.trim().isNotEmpty) {
      return stored.trim();
    }
    return ApiClient.defaultBaseUrl;
  }

  /// Update base URL and persist
  Future<void> updateBaseUrl(String newUrl) async {
    final cleanUrl = newUrl.trim();
    if (cleanUrl.isEmpty) {
      await resetToDefault();
      return;
    }

    // Auto add protocol and api version if missing
    String formattedUrl = cleanUrl;
    if (!formattedUrl.startsWith('http://') &&
        !formattedUrl.startsWith('https://')) {
      formattedUrl = 'http://$formattedUrl';
    }
    if (!formattedUrl.contains('/api/v1')) {
      // Remove trailing slash if any and append path
      if (formattedUrl.endsWith('/')) {
        formattedUrl = formattedUrl.substring(0, formattedUrl.length - 1);
      }
      formattedUrl = '$formattedUrl/api/v1';
    }

    await _prefs.setString(_storageKey, formattedUrl);
    state = formattedUrl;
  }

  /// Reset to standard automatic local detection base URL
  Future<void> resetToDefault() async {
    await _prefs.remove(_storageKey);
    state = ApiClient.defaultBaseUrl;
  }
}
