import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/provider/tools_provider.dart';

/// Immutable model class wrapping all parameters and outputs for physical conversion
class ConverterState {
  final double inputValue;
  final String fromUnit;
  final String toUnit;
  final double result;
  final bool isConverting;

  const ConverterState({
    required this.inputValue,
    required this.fromUnit,
    required this.toUnit,
    required this.result,
    required this.isConverting,
  });

  ConverterState copyWith({
    double? inputValue,
    String? fromUnit,
    String? toUnit,
    double? result,
    bool? isConverting,
  }) {
    return ConverterState(
      inputValue: inputValue ?? this.inputValue,
      fromUnit: fromUnit ?? this.fromUnit,
      toUnit: toUnit ?? this.toUnit,
      result: result ?? this.result,
      isConverting: isConverting ?? this.isConverting,
    );
  }
}

/// StateNotifier encapsulating physical factors, computation, and telemetry logger
class ConverterNotifier extends StateNotifier<ConverterState> {
  final Ref _ref;

  final Map<String, double> unitFactors = {
    'cm': 1.0,
    'm': 100.0,
    'inch': 2.54,
    'feet': 30.48,
  };

  ConverterNotifier(this._ref)
      : super(const ConverterState(
          inputValue: 0.0,
          fromUnit: 'cm',
          toUnit: 'm',
          result: 0.0,
          isConverting: false,
        ));

  void updateInputValue(double value) {
    state = state.copyWith(inputValue: value);
  }

  void updateFromUnit(String unit) {
    state = state.copyWith(fromUnit: unit);
  }

  void updateToUnit(String unit) {
    state = state.copyWith(toUnit: unit);
  }

  /// Trigger conversion calculation and log telemetry to PostgreSQL
  Future<void> convert() async {
    if (state.isConverting) return;

    state = state.copyWith(isConverting: true);

    final stopwatch = Stopwatch()..start();

    // Quick delay simulating unit processing
    await Future.delayed(const Duration(milliseconds: 150));

    double valueInCm = state.inputValue * unitFactors[state.fromUnit]!;
    double finalResult = valueInCm / unitFactors[state.toUnit]!;
    
    stopwatch.stop();

    state = state.copyWith(
      result: finalResult,
      isConverting: false,
    );

    // Fire off non-blocking telemetry logging to database
    _ref.read(toolsAnalyticsProvider).logUsage(
      toolKey: 'converter',
      parameters: {
        'input_value': state.inputValue,
        'from_unit': state.fromUnit,
        'to_unit': state.toUnit,
        'result': double.parse(finalResult.toStringAsFixed(4)),
      },
      status: 'success',
      durationMs: stopwatch.elapsedMilliseconds,
    );
  }
}

/// Provider to listen to converter logic state
final converterProvider = StateNotifierProvider.autoDispose<ConverterNotifier, ConverterState>((ref) {
  return ConverterNotifier(ref);
});
