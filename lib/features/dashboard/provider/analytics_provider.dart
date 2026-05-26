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
      healthBmiTrend:
          (json['health_bmi_trend'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      healthTrendDates:
          (json['health_trend_dates'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      heatmapActivity:
          (json['heatmap_activity'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
    );
  }
}

class AnalyticsNotifier
    extends StateNotifier<AsyncValue<AnalyticsDashboardData>> {
  final Ref _ref;

  AnalyticsNotifier(this._ref) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    final authState = _ref.read(authProvider);
    if (!authState.isAuthenticated || authState.email == null) {
      final data = AnalyticsDashboardData(
        aiWordsGenerated: 0,
        aiTimeSavedHours: 0.0,
        aiModelInvocations: 0,
        healthBmiTrend: [],
        healthTrendDates: [],
        heatmapActivity: List.filled(24, 0.0),
      );
      state = AsyncValue.data(data);
      return;
    }

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

final analyticsProvider =
    StateNotifierProvider<
      AnalyticsNotifier,
      AsyncValue<AnalyticsDashboardData>
    >((ref) {
      ref.watch(authProvider);
      return AnalyticsNotifier(ref);
    });

class WorkflowExecution {
  final String id;
  final List<String> steps;
  final Map<int, String> stepInputs;
  final Map<int, String> stepOutputs;
  final String status;
  final DateTime createdAt;

  WorkflowExecution({
    required this.id,
    required this.steps,
    required this.stepInputs,
    required this.stepOutputs,
    required this.status,
    required this.createdAt,
  });

  factory WorkflowExecution.fromJson(Map<String, dynamic> json) {
    final Map<int, String> inputs = {};
    if (json['step_inputs'] != null) {
      (json['step_inputs'] as Map<dynamic, dynamic>).forEach((k, v) {
        inputs[int.tryParse(k.toString()) ?? 0] = v.toString();
      });
    }
    final Map<int, String> outputs = {};
    if (json['step_outputs'] != null) {
      (json['step_outputs'] as Map<dynamic, dynamic>).forEach((k, v) {
        outputs[int.tryParse(k.toString()) ?? 0] = v.toString();
      });
    }

    return WorkflowExecution(
      id: json['id'] as String,
      steps: List<String>.from(json['steps'] as List),
      stepInputs: inputs,
      stepOutputs: outputs,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

final workflowExecutionsProvider = FutureProvider<List<WorkflowExecution>>((ref) async {
  try {
    final auth = ref.watch(authProvider);
    if (!auth.isAuthenticated || auth.email == null) return const [];
    
    final dio = ref.read(apiClientProvider).instance;
    final response = await dio.get('/tools/workflows/executions');
    final List data = response.data as List;
    return data.map((json) => WorkflowExecution.fromJson(json)).toList();
  } catch (e) {
    return const [];
  }
});

