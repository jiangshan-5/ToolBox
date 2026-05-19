import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/provider/auth_provider.dart';

class AnalyticsDashboardData {
  final int aiWordsGenerated;
  final double aiTimeSavedHours;
  final int aiModelInvocations;
  final List<double> healthBmiTrend;
  final List<String> healthTrendDates;
  final List<double> heatmapActivity;

  AnalyticsDashboardData({
    required this.aiWordsGenerated,
    required this.aiTimeSavedHours,
    required this.aiModelInvocations,
    required this.healthBmiTrend,
    required this.healthTrendDates,
    required this.heatmapActivity,
  });

  factory AnalyticsDashboardData.fromJson(Map<String, dynamic> json) {
    return AnalyticsDashboardData(
      aiWordsGenerated: json['ai_words_generated'] ?? 0,
      aiTimeSavedHours: (json['ai_time_saved_hours'] ?? 0.0).toDouble(),
      aiModelInvocations: json['ai_model_invocations'] ?? 0,
      healthBmiTrend: (json['health_bmi_trend'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      healthTrendDates: (json['health_trend_dates'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      heatmapActivity: (json['heatmap_activity'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? [],
    );
  }
}

class AnalyticsNotifier extends StateNotifier<AsyncValue<AnalyticsDashboardData>> {
  final Ref _ref;

  AnalyticsNotifier(this._ref) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.instance.get('/analytics/dashboard');
      final data = AnalyticsDashboardData.fromJson(response.data);
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AsyncValue<AnalyticsDashboardData>>((ref) {
  return AnalyticsNotifier(ref);
});
