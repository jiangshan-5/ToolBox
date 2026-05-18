import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/provider/tools_provider.dart';

/// Immutable model class wrapping BMI parameters and status classifications
class BmiState {
  final double? bmi;
  final String message;
  final bool isCalculating;

  const BmiState({
    this.bmi,
    required this.message,
    required this.isCalculating,
  });

  BmiState copyWith({
    double? bmi,
    String? message,
    bool? isCalculating,
  }) {
    return BmiState(
      bmi: bmi ?? this.bmi,
      message: message ?? this.message,
      isCalculating: isCalculating ?? this.isCalculating,
    );
  }
}

/// StateNotifier encapsulating BMI medical calculations and usage analytics logging
class BmiNotifier extends StateNotifier<BmiState> {
  final Ref _ref;

  BmiNotifier(this._ref) : super(const BmiState(message: '', isCalculating: false));

  /// Perform pure calculation logic and log telemetry to PostgreSQL
  Future<bool> calculate({required double height, required double weight}) async {
    if (height <= 0 || weight <= 0) {
      return false;
    }

    state = state.copyWith(isCalculating: true);

    final stopwatch = Stopwatch()..start();
    
    // Simulate quick calculation load
    await Future.delayed(const Duration(milliseconds: 200));

    final calculatedBmi = weight / ((height / 100) * (height / 100));
    String msg = "";

    if (calculatedBmi < 18.5) {
      msg = "体重偏轻 - 营养摄入有些不足，吃点点心吧！🥗";
    } else if (calculatedBmi < 25) {
      msg = "健康体态 - 指标非常完美，继续保持！✨";
    } else if (calculatedBmi < 30) {
      msg = "超重范围 - 适当运动，少糖少油哦！🏃";
    } else {
      msg = "肥胖范围 - 为了健康，建议咨询专业医生！❤️";
    }
    stopwatch.stop();

    state = state.copyWith(
      bmi: calculatedBmi,
      message: msg,
      isCalculating: false,
    );

    // Save telemetry to DB logs
    _ref.read(toolsAnalyticsProvider).logUsage(
      toolKey: 'bmi_calculator',
      parameters: {
        'height': height,
        'weight': weight,
        'bmi': double.parse(calculatedBmi.toStringAsFixed(2)),
        'outcome': msg,
      },
      status: 'success',
      durationMs: stopwatch.elapsedMilliseconds,
    );

    return true;
  }
}

/// Provider to watch BMI state and logic actions
final bmiProvider = StateNotifierProvider.autoDispose<BmiNotifier, BmiState>((ref) {
  return BmiNotifier(ref);
});
