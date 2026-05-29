import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

/// Provider to track the hardcoded remote API Base URL
final apiBaseUrlProvider = Provider<String>((ref) {
  return ApiClient.liveServerUrl;
});
