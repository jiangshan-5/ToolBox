import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/provider/tools_provider.dart';

/// Supported physical categories
enum ConverterCategory { length, mass, temperature, area }

/// Comprehensive state model wrapping conversion parameters
class ConverterState {
  final ConverterCategory category;
  final double inputValue;
  final String fromUnit;
  final String toUnit;
  final double result;
  final bool isConverting;

  const ConverterState({
    required this.category,
    required this.inputValue,
    required this.fromUnit,
    required this.toUnit,
    required this.result,
    required this.isConverting,
  });

  ConverterState copyWith({
    ConverterCategory? category,
    double? inputValue,
    String? fromUnit,
    String? toUnit,
    double? result,
    bool? isConverting,
  }) {
    return ConverterState(
      category: category ?? this.category,
      inputValue: inputValue ?? this.inputValue,
      fromUnit: fromUnit ?? this.fromUnit,
      toUnit: toUnit ?? this.toUnit,
      result: result ?? this.result,
      isConverting: isConverting ?? this.isConverting,
    );
  }
}

/// Supercharged StateNotifier handling multi-dimensional conversions, physical constants, and PostgreSQL telemetry logging
class ConverterNotifier extends StateNotifier<ConverterState> {
  final Ref _ref;

  // Conversion Factors relative to base units
  // Length (Base: Meter)
  final Map<String, double> lengthFactors = {
    'mm': 0.001,
    'cm': 0.01,
    'm': 1.0,
    'km': 1000.0,
    'inch': 0.0254,
    'feet': 0.3048,
    'yard': 0.9144,
    'mile': 1609.344,
  };

  // Mass (Base: Kilogram)
  final Map<String, double> massFactors = {
    'g': 0.001,
    'kg': 1.0,
    'ton': 1000.0,
    'lb': 0.45359237,
    'oz': 0.028349523,
    'jin': 0.5,
  };

  // Area (Base: Square Meter)
  final Map<String, double> areaFactors = {
    '㎡': 1.0,
    '㎢': 1000000.0,
    'ft²': 0.09290304,
    'ha': 10000.0,
    'mu': 666.66667,
  };

  ConverterNotifier(this._ref)
      : super(const ConverterState(
          category: ConverterCategory.length,
          inputValue: 0.0,
          fromUnit: 'cm',
          toUnit: 'm',
          result: 0.0,
          isConverting: false,
        ));

  /// Get unit key list based on selected category
  List<String> getUnitsForCategory(ConverterCategory cat) {
    switch (cat) {
      case ConverterCategory.length:
        return lengthFactors.keys.toList();
      case ConverterCategory.mass:
        return massFactors.keys.toList();
      case ConverterCategory.temperature:
        return ['°c', '°f', 'k'];
      case ConverterCategory.area:
        return areaFactors.keys.toList();
    }
  }

  /// Change Category and set corresponding sensible defaults
  void setCategory(ConverterCategory cat) {
    String defFrom = 'cm';
    String defTo = 'm';

    if (cat == ConverterCategory.mass) {
      defFrom = 'g';
      defTo = 'kg';
    } else if (cat == ConverterCategory.temperature) {
      defFrom = '°c';
      defTo = '°f';
    } else if (cat == ConverterCategory.area) {
      defFrom = '㎡';
      defTo = 'mu';
    }

    state = state.copyWith(
      category: cat,
      fromUnit: defFrom,
      toUnit: defTo,
      result: 0.0,
    );
  }

  void updateInputValue(double val) {
    state = state.copyWith(inputValue: val);
    _performConversionInstant(); // Instant dynamic update as typing
  }

  void updateFromUnit(String unit) {
    state = state.copyWith(fromUnit: unit);
    _performConversionInstant();
  }

  void updateToUnit(String unit) {
    state = state.copyWith(toUnit: unit);
    _performConversionInstant();
  }

  /// Double reverse the physical unit from <=> to
  void reverseUnits() {
    state = state.copyWith(
      fromUnit: state.toUnit,
      toUnit: state.fromUnit,
      inputValue: state.result,
      result: state.inputValue,
    );
  }

  /// Internal instant calculation triggered on input parameters modification
  void _performConversionInstant() {
    if (state.inputValue == 0.0) {
      state = state.copyWith(result: 0.0);
      return;
    }

    double finalResult = 0.0;
    final cat = state.category;
    final from = state.fromUnit;
    final to = state.toUnit;
    final input = state.inputValue;

    if (cat == ConverterCategory.temperature) {
      finalResult = _convertTemperature(input, from, to);
    } else {
      final factors = cat == ConverterCategory.length
          ? lengthFactors
          : (cat == ConverterCategory.mass ? massFactors : areaFactors);

      double baseVal = input * factors[from]!;
      finalResult = baseVal / factors[to]!;
    }

    state = state.copyWith(result: finalResult);
  }

  /// Custom linear temperature algorithms
  double _convertTemperature(double value, String from, String to) {
    if (from == to) return value;
    
    double tempInCelsius = 0;
    
    // 1. Standardize to Celsius
    if (from == '°c') {
      tempInCelsius = value;
    } else if (from == '°f') {
      tempInCelsius = (value - 32) * 5 / 9;
    } else if (from == 'k') {
      tempInCelsius = value - 273.15;
    }

    // 2. Convert to Target
    if (to == '°c') {
      return tempInCelsius;
    } else if (to == '°f') {
      return tempInCelsius * 9 / 5 + 32;
    } else if (to == 'k') {
      return tempInCelsius + 273.15;
    }

    return value;
  }

  /// Trigger heavy formal processing, telemetry logger
  Future<void> runFormalConversion() async {
    if (state.isConverting) return;

    state = state.copyWith(isConverting: true);
    final stopwatch = Stopwatch()..start();

    // Smooth transition simulation
    await Future.delayed(const Duration(milliseconds: 150));
    _performConversionInstant();
    
    stopwatch.stop();
    state = state.copyWith(isConverting: false);

    // Save to PostgreSQL backend
    _ref.read(toolsAnalyticsProvider).logUsage(
      toolKey: 'converter',
      parameters: {
        'category': state.category.name,
        'input_value': state.inputValue,
        'from_unit': state.fromUnit,
        'to_unit': state.toUnit,
        'result': double.parse(state.result.toStringAsFixed(4)),
      },
      status: 'success',
      durationMs: stopwatch.elapsedMilliseconds,
    );
  }
}

/// Riverpod provider for the supercharged converter
final converterProvider = StateNotifierProvider.autoDispose<ConverterNotifier, ConverterState>((ref) {
  return ConverterNotifier(ref);
});
