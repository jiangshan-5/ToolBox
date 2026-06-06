import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/provider/tools_provider.dart';
import '../../dashboard/provider/analytics_provider.dart';
import '../../auth/provider/auth_provider.dart';

/// State model wrapping clinical biometric outputs and custom diet/weight planning sandboxes
class BmiState {
  final double? bmi;
  final double? bmr;
  final double? idealWeight;
  final double? bsa;
  final String message;

  final bool isMetric;
  final String gender;
  final int age;
  final String activity;
  final double? dailyCalories;

  // 1. WEIGHT GOAL SANDBOX PARAMETERS
  final double targetWeight; // Target weight in kg/lbs
  final double
  weeklyChange; // target loss/gain per week, e.g. -0.5kg or +0.25kg
  final double? weeksToTarget; // calculated weeks
  final double caloricOffset; // calculated daily calorie addition/subtraction
  final double? finalCalorieGoal; // dailyCalories + caloricOffset

  // 2. MACRONUTRIENT RATIO SANDBOX (Percentages must sum to 100)
  final int proteinPercent;
  final int carbPercent;
  final int fatPercent;

  final double? proteinGrams;
  final double? carbGrams;
  final double? fatGrams;

  final String activeGoal;
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

    // Weight Goal Defaults
    required this.targetWeight,
    required this.weeklyChange,
    this.weeksToTarget,
    required this.caloricOffset,
    this.finalCalorieGoal,

    // Nutrition Splits Defaults (30% Protein, 40% Carb, 30% Fat)
    required this.proteinPercent,
    required this.carbPercent,
    required this.fatPercent,
    this.proteinGrams,
    this.carbGrams,
    this.fatGrams,

    required this.activeGoal,
    required this.isCalculating,
  });

  double? get tdee => dailyCalories;
  double? get suggestedCalories => finalCalorieGoal;

  Color get messageColor {
    final double? b = bmi;
    if (b == null) return Colors.white70;
    if (b < 18.5) {
      return Colors.orangeAccent;
    } else if (b < 24.0) {
      return Colors.greenAccent;
    } else if (b < 28.0) {
      return Colors.orangeAccent;
    } else {
      return Colors.redAccent;
    }
  }

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

    double? targetWeight,
    double? weeklyChange,
    double? weeksToTarget,
    double? caloricOffset,
    double? finalCalorieGoal,

    int? proteinPercent,
    int? carbPercent,
    int? fatPercent,
    double? proteinGrams,
    double? carbGrams,
    double? fatGrams,

    String? activeGoal,
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

      targetWeight: targetWeight ?? this.targetWeight,
      weeklyChange: weeklyChange ?? this.weeklyChange,
      weeksToTarget: weeksToTarget ?? this.weeksToTarget,
      caloricOffset: caloricOffset ?? this.caloricOffset,
      finalCalorieGoal: finalCalorieGoal ?? this.finalCalorieGoal,

      proteinPercent: proteinPercent ?? this.proteinPercent,
      carbPercent: carbPercent ?? this.carbPercent,
      fatPercent: fatPercent ?? this.fatPercent,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbGrams: carbGrams ?? this.carbGrams,
      fatGrams: fatGrams ?? this.fatGrams,

      activeGoal: activeGoal ?? this.activeGoal,
      isCalculating: isCalculating ?? this.isCalculating,
    );
  }
}

/// Dynamic Health and Nutrition Sandbox notifier
class BmiNotifier extends StateNotifier<BmiState> {
  final Ref _ref;

  BmiNotifier(this._ref)
    : super(
        const BmiState(
          message: '',
          isMetric: true,
          gender: 'male',
          age: 25,
          activity: '久坐不动',

          targetWeight: 70.0,
          weeklyChange: -0.5,
          caloricOffset: 0.0,

          proteinPercent: 30,
          carbPercent: 40,
          fatPercent: 30,

          activeGoal: 'cut',
          isCalculating: false,
        ),
      );

  void toggleSystem(bool isMetric) {
    // Sensible defaults switch
    final double target = isMetric ? 70.0 : 154.0;
    final double change = isMetric ? -0.5 : -1.1;

    state = state.copyWith(
      isMetric: isMetric,
      targetWeight: target,
      weeklyChange: change,
      bmi: null, // Reset outcomes to force recalculation
    );
  }

  void setUnitSystem(bool val) => toggleSystem(val);

  void setGoal(String goal) {
    double change = state.weeklyChange;
    if (goal == 'cut') {
      if (change >= 0) {
        change = state.isMetric ? -0.5 : -1.1;
      }
    } else if (goal == 'maintain') {
      change = 0.0;
    } else if (goal == 'bulk') {
      if (change <= 0) {
        change = state.isMetric ? 0.5 : 1.1;
      }
    }
    state = state.copyWith(activeGoal: goal, weeklyChange: change);
  }

  void setGender(String gender) => state = state.copyWith(gender: gender);
  void setAge(int age) => state = state.copyWith(age: age);
  void setActivity(String act) => state = state.copyWith(activity: act);

  // --- WEIGHT TARGET SANDBOX SETTERS ---
  void setTargetWeight(double val) => state = state.copyWith(targetWeight: val);
  void setWeeklyChange(double val) {
    // Determine active goal based on weekly change value
    String goal = state.activeGoal;
    if (val < 0) {
      goal = 'cut';
    } else if (val > 0) {
      goal = 'bulk';
    } else {
      goal = 'maintain';
    }
    state = state.copyWith(weeklyChange: val, activeGoal: goal);
  }

  // --- MACRO SPLITS SANDBOX SETTERS ---
  void setMacrosRatios(int protein, int carb, int fat) {
    state = state.copyWith(
      proteinPercent: protein,
      carbPercent: carb,
      fatPercent: fat,
    );
    _calculateMacrosOnly();
  }

  /// Internal quick translator converting calorie goals to protein/carbs/fat grams
  void _calculateMacrosOnly() {
    final double? baseGoal = state.finalCalorieGoal ?? state.dailyCalories;
    if (baseGoal == null) return;

    // 1g Protein = 4 kcal, 1g Carb = 4 kcal, 1g Fat = 9 kcal
    final double pG = (baseGoal * (state.proteinPercent / 100.0)) / 4.0;
    final double cG = (baseGoal * (state.carbPercent / 100.0)) / 4.0;
    final double fG = (baseGoal * (state.fatPercent / 100.0)) / 9.0;

    state = state.copyWith(proteinGrams: pG, carbGrams: cG, fatGrams: fG);
  }

  /// Run primary biometric pipeline and evaluate sandboxes projections
  Future<bool> runBiometricAnalysis({
    required double heightInput,
    required double weightInput,
  }) async {
    if (heightInput <= 0 || weightInput <= 0) return false;

    state = state.copyWith(isCalculating: true);
    final stopwatch = Stopwatch()..start();

    // 1. Standardize units to metric (cm/kg) for internal logic uniformity
    double heightInCm = heightInput;
    double weightInKg = weightInput;
    double targetInKg = state.targetWeight;
    double changeInKgPerWeek = state.weeklyChange;

    if (!state.isMetric) {
      heightInCm = heightInput * 2.54;
      weightInKg = weightInput * 0.45359237;
      targetInKg = state.targetWeight * 0.45359237;
      changeInKgPerWeek = state.weeklyChange * 0.45359237;
    }

    await Future.delayed(const Duration(milliseconds: 300));

    // 2. BMI Calculation
    final double bmi = weightInKg / ((heightInCm / 100) * (heightInCm / 100));

    // 3. BMI Message diagnosys
    String msg = "";
    if (bmi < 18.5) {
      msg = "体重偏轻 - 基础营养摄入较少，建议开启增肌抗阻力沙盒规划。🥗";
    } else if (bmi < 24.0) {
      msg = "健康体态 - 恭喜！各项指标均处于理想健康区间，请继续保持！✨";
    } else if (bmi < 28.0) {
      msg = "超重范围 - 略微超出健康范围，可合理配合能量赤字进行减脂管理。🏃";
    } else {
      msg = "肥胖警告 - 显著超出安全红线，建议遵循医嘱或严格控制碳水与糖分。❤️";
    }

    // 4. Clinical BMR (Harris-Benedict revised)
    double bmr = 0;
    if (state.gender == 'male') {
      bmr =
          88.362 +
          (13.397 * weightInKg) +
          (4.799 * heightInCm) -
          (5.677 * state.age);
    } else {
      bmr =
          447.593 +
          (9.247 * weightInKg) +
          (3.098 * heightInCm) -
          (4.330 * state.age);
    }

    // 5. BSA Body Surface Area (Mosteller)
    final double bsa = sqrt((heightInCm * weightInKg) / 3600);

    // 6. Ideal Weight (Devine Formula)
    double ideal = 0;
    double heightInInches = heightInCm / 2.54;
    double inchesOver5Feet = max(0.0, heightInInches - 60.0);
    if (state.gender == 'male') {
      ideal = 50.0 + (2.3 * inchesOver5Feet);
    } else {
      ideal = 45.5 + (2.3 * inchesOver5Feet);
    }

    // Convert ideal back to imperial if needed
    if (!state.isMetric) {
      ideal = ideal / 0.45359237;
    }

    // 7. Base Daily Calorie consumption
    double activityMultiplier = 1.2;
    if (state.activity == '轻度活动') activityMultiplier = 1.375;
    if (state.activity == '中度运动') activityMultiplier = 1.55;
    if (state.activity == '高强度训练') activityMultiplier = 1.725;
    if (state.activity == '专业运动员') activityMultiplier = 1.9;

    final double dailyCalories = bmr * activityMultiplier;

    // --- WEIGHT PLANNING SANDBOX MATHS ---
    // 1kg Fat = 7700 kcal, 1kg Muscle ~ 5500 kcal
    // Deficit calculation: weekly change in kg * 7700 / 7 days
    double caloricOffset = 0.0;
    double weeksToTarget = 0.0;

    final double deltaWeightKg = targetInKg - weightInKg;

    if (deltaWeightKg.abs() > 0.1) {
      // If losing weight (delta < 0, change < 0)
      if (deltaWeightKg < 0 && changeInKgPerWeek < 0) {
        caloricOffset = (changeInKgPerWeek * 7700) / 7.0; // Negative offset
        weeksToTarget = deltaWeightKg / changeInKgPerWeek;
      }
      // If gaining weight (delta > 0, change > 0)
      else if (deltaWeightKg > 0 && changeInKgPerWeek > 0) {
        caloricOffset = (changeInKgPerWeek * 5500) / 7.0; // Positive offset
        weeksToTarget = deltaWeightKg / changeInKgPerWeek;
      }
    }

    final double finalGoal = dailyCalories + caloricOffset;

    stopwatch.stop();

    state = state.copyWith(
      bmi: bmi,
      bmr: bmr,
      idealWeight: ideal,
      bsa: bsa,
      message: msg,
      dailyCalories: dailyCalories,

      weeksToTarget: weeksToTarget > 0 ? weeksToTarget : 0.0,
      caloricOffset: caloricOffset,
      finalCalorieGoal: finalGoal > 800
          ? finalGoal
          : 800.0, // Clinical safe floor

      isCalculating: false,
    );

    // Calculate Macros based on final target
    _calculateMacrosOnly();

    // Log to DB telemetry
    _ref
        .read(toolsAnalyticsProvider)
        .logUsage(
          toolKey: 'bmi_calculator',
          parameters: {
            'mode': 'clinical_sandbox',
            'target_weight': state.targetWeight,
            'weekly_change': state.weeklyChange,
            'calculated_weeks': weeksToTarget,
            'protein_percent': state.proteinPercent,
            'carb_percent': state.carbPercent,
            'fat_percent': state.fatPercent,
          },
          status: 'success',
          durationMs: stopwatch.elapsedMilliseconds,
        );

    // Sync physical health metrics to the new analytics Cloud Database
    final authState = _ref.read(authProvider);
    if (authState.isAuthenticated && authState.email != null) {
      try {
        final apiClient = _ref.read(apiClientProvider);
        await apiClient.instance.post(
          '/analytics/health',
          data: {
            'weight_kg': double.parse(weightInKg.toStringAsFixed(2)),
            'height_cm': double.parse(heightInCm.toStringAsFixed(2)),
            'bmi': double.parse(bmi.toStringAsFixed(2)),
          },
        );
        // Invalidate to refresh the chart immediately
        _ref.invalidate(analyticsProvider);
      } catch (e) {
        debugPrint('Failed to sync health telemetry: $e');
      }
    }

    return true;
  }
}

/// Riverpod provider
final bmiProvider = StateNotifierProvider.autoDispose<BmiNotifier, BmiState>((
  ref,
) {
  return BmiNotifier(ref);
});
