import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../auth/provider/auth_provider.dart';

class ToolsAnalyticsService {
  final ApiClient _apiClient;

  ToolsAnalyticsService(this._apiClient);

  /// Safe database logger for tool executions
  Future<void> logUsage({
    required String toolKey,
    required Map<String, dynamic> parameters,
    required String status,
    required int durationMs,
  }) async {
    try {
      await _apiClient.instance.post(
        '/tools/usage-logs',
        data: {
          'tool_key': toolKey,
          'parameters': parameters,
          'status': status,
          'duration_ms': durationMs,
        },
      );
    } catch (e) {
      // Telemetry should always be non-blocking. If it fails, log silently to keep UX perfect.
      print("Telemetry logging failed for $toolKey: $e");
    }
  }
}

/// Provider for tools usage analysis and logging
final toolsAnalyticsProvider = Provider<ToolsAnalyticsService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ToolsAnalyticsService(apiClient);
});

/// Asynchronous API provider to retrieve dynamic category catalogue
final categoriesProvider = FutureProvider<List<dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.instance.get('/tools/categories');
  return response.data as List<dynamic>;
});
