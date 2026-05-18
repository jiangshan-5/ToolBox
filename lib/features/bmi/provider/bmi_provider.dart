import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/provider/tools_provider.dart';

/// State model encapsulating a full clinical dashboard for body analytics
class BmiState {
  final double? bmi;
  final double? bmr;
  final double? idealWeight;
  final double? bsa;
  final String message;
  
  final bool isMetric;      // Metric (cm/kg) vs Imperial (feet-inch/lbs)
  final String gender;      // 'male' vs 'female'
  final int age;            // years
  final String activity;    // activity level description
  final double? dailyCalories;
  
  final bool isCalculating;

  const BmiState({
    this.bmi,
    this.bmr,
    this.idealWeight,
    this.bsa,
    required this.message,
    required this.isMetric,
    required this.gender,
    required this.age,
    required this.activity,
    this.dailyCalories,
    required this.isCalculating,
  });

  BmiState copyWith({
    double? bmi,
    double? bmr,
    double? idealWeight,
    double? bsa,
    String? message,
    bool? isMetric,
    String? gender,
    int? age,
    String? activity,
    double? dailyCalories,
    bool? isCalculating,
  }) {
    return BmiState(
      bmi: bmi ?? this.bmi,
      bmr: bmr ?? this.bmr,
      idealWeight: idealWeight ?? this.idealWeight,
      bsa: bsa ?? this.bsa,
      message: message ?? this.message,
      isMetric: isMetric ?? this.isMetric,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      activity: activity ?? this.activity,
      dailyCalories: dailyCalories ?? this.dailyCalories,
      isCalculating: isCalculating ?? this.isCalculating,
    );
  }
}

/// Supercharged StateNotifier implementing clinically-approved biometric calculations
class BmiNotifier extends StateNotifier<BmiState> {
  final Ref _ref;

  BmiNotifier(this._ref)
      : super(const BmiState(
          message: '',
          isMetric: true,
          gender: 'male',
          age: 25,
          activity: '久坐不动',
          isCalculating: false,
        ));

  void toggleSystem(bool isMetric) => state = state.copyWith(isMetric: isMetric);
  void setGender(String gender) => state = state.copyWith(gender: gender);
  void setAge(int age) => state = state.copyWith(age: age);
  void setActivity(String act) => state = state.copyWith(activity: act);

  /// Run clinical body analytics pipeline with telemetry logging
  Future<bool> runBiometricAnalysis({
    required double heightInput, // cm if metric, inches if imperial
    required double weightInput, // kg if metric, lbs if imperial
  }) async {
    if (heightInput <= 0 || weightInput <= 0) return false;

    state = state.copyWith(isCalculating: true);
    final stopwatch = Stopwatch()..start();

    // 1. Process System Conversion to Standard Metric Units
    double heightInCm = heightInput;
    double weightInKg = weightInput;

    if (!state.isMetric) {
      heightInCm = heightInput * 2.54; // inches to cm
      weightInKg = weightInput * 0.45359237; // lbs to kg
    }

    // Interactive computation delay
    await Future.delayed(const Duration(milliseconds: 300));

    // 2. BMI Calculation
    final double bmi = weightInKg / ((heightInCm / 100) * (heightInCm / 100));

    // 3. BMI Category Diagnoses
    String msg = "";
    if (bmi < 18.5) {
      msg = "体重偏轻 - 指标显示营养摄入较少，建议适当增加高蛋白膳食与力量训练。🥗";
    } else if (bmi < 24.0) {
      msg = "健康体态 - 恭喜！各项指标均处于医学推荐黄金区间，请继续保持！✨";
    } else if (bmi < 28.0) {
      msg = "超重范围 - 略微超出健康范围，建议合理改善饮食结构并配合有氧运动。🏃";
    } else {
      msg = "肥胖警告 - 显著超出安全红线，建议遵照医嘱，定制科学控糖减重管理计划。❤️";
    }

    // 4. Clinical BMR Calculation (Harris-Benedict Formula Revised)
    double bmr = 0;
    if (state.gender == 'male') {
      bmr = 88.362 + (13.397 * weightInKg) + (4.799 * heightInCm) - (5.677 * state.age);
    } else {
      bmr = 447.593 + (9.247 * weightInKg) + (3.098 * heightInCm) - (4.330 * state.age);
    }

    // 5. BSA Body Surface Area (Mosteller Formula)
    final double bsa = sqrt((heightInCm * weightInKg) / 3600);

    // 6. Ideal Body Weight (Devine Formula)
    double ideal = 0;
    double heightInInches = heightInCm / 2.54;
    double inchesOver5Feet = max(0.0, heightInInches - 60.0);
    if (state.gender == 'male') {
      ideal = 50.0 + (2.3 * inchesOver5Feet);
    } else {
      ideal = 45.5 + (2.3 * inchesOver5Feet);
    }

    // 7. Daily Calorie Goal target calculations based on activity multipliers
    double activityMultiplier = 1.2; // default sedentary
    if (state.activity == '轻度活动') activityMultiplier = 1.375;
    if (state.activity == '中度运动') activityMultiplier = 1.55;
    if (state.activity == '高强度训练') activityMultiplier = 1.725;
    if (state.activity == '专业运动员') activityMultiplier = 1.9;
    
    final double dailyCalories = bmr * activityMultiplier;

    stopwatch.stop();

    state = state.copyWith(
      bmi: bmi,
      bmr: bmr,
      idealWeight: ideal,
      bsa: bsa,
      message: msg,
      dailyCalories: dailyCalories,
      isCalculating: false,
    );

    // Log to backend DB
    _ref.read(toolsAnalyticsProvider).logUsage(
      toolKey: 'bmi_calculator',
      parameters: {
        'system': state.isMetric ? 'metric' : 'imperial',
        'gender': state.gender,
        'age': state.age,
        'activity': state.activity,
        'input_height': heightInput,
        'input_weight': weightInput,
        'bmi': double.parse(bmi.toStringAsFixed(2)),
        'bmr': double.parse(bmr.toStringAsFixed(1)),
        'bsa': double.parse(bsa.toStringAsFixed(2)),
        'ideal_weight': double.parse(ideal.toStringAsFixed(1)),
        'target_calories': double.parse(dailyCalories.toStringAsFixed(0)),
      },
      status: 'success',
      durationMs: stopwatch.elapsedMilliseconds,
    );

    return true;
  }
}

/// Riverpod provider for Bmi
final bmiProvider = StateNotifierProvider.autoDispose<BmiNotifier, BmiState>((ref) {
  return BmiNotifier(ref);
});
