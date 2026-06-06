import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/provider/tools_provider.dart';
import 'dart:async';

/// Supported standard physical categories, adding Sandbox for custom user converters
enum ConverterCategory { length, mass, temperature, area, sandbox }

/// User-defined conversion formula template
class CustomConverter {
  final String id;
  final String name;
  final String fromUnit;
  final String toUnit;
  final double factor; // multiplier
  final double offset; // offset, e.g. x * factor + offset

  const CustomConverter({
    required this.id,
    required this.name,
    required this.fromUnit,
    required this.toUnit,
    required this.factor,
    required this.offset,
  });

  CustomConverter copyWith({
    String? name,
    String? fromUnit,
    String? toUnit,
    double? factor,
    double? offset,
  }) {
    return CustomConverter(
      id: id,
      name: name ?? this.name,
      fromUnit: fromUnit ?? this.fromUnit,
      toUnit: toUnit ?? this.toUnit,
      factor: factor ?? this.factor,
      offset: offset ?? this.offset,
    );
  }
}

/// Dynamic container for all active conversions outputs
class MatrixUnitItem {
  final String unit;
  final double value;
  const MatrixUnitItem(this.unit, this.value);
}

/// Comprehensive State Model supporting custom rules and visual matrix comparisons
class ConverterState {
  final ConverterCategory category;
  final double inputValue;
  final String fromUnit;
  final String toUnit;
  final double result;
  final bool isConverting;

  // Sandbox Custom Rules
  final List<CustomConverter> customConverters;
  final String? activeCustomId;

  // Simultaneous Outputs
  final List<MatrixUnitItem> allConversionsMatrix;

  const ConverterState({
    required this.category,
    required this.inputValue,
    required this.fromUnit,
    required this.toUnit,
    required this.result,
    required this.isConverting,
    required this.customConverters,
    this.activeCustomId,
    required this.allConversionsMatrix,
  });

  ConverterState copyWith({
    ConverterCategory? category,
    double? inputValue,
    String? fromUnit,
    String? toUnit,
    double? result,
    bool? isConverting,
    List<CustomConverter>? customConverters,
    String? activeCustomId,
    List<MatrixUnitItem>? allConversionsMatrix,
  }) {
    return ConverterState(
      category: category ?? this.category,
      inputValue: inputValue ?? this.inputValue,
      fromUnit: fromUnit ?? this.fromUnit,
      toUnit: toUnit ?? this.toUnit,
      result: result ?? this.result,
      isConverting: isConverting ?? this.isConverting,
      customConverters: customConverters ?? this.customConverters,
      activeCustomId: activeCustomId ?? this.activeCustomId,
      allConversionsMatrix: allConversionsMatrix ?? this.allConversionsMatrix,
    );
  }
}

/// Sandboxed Converter StateNotifier
class ConverterNotifier extends StateNotifier<ConverterState> {
  final Ref _ref;

  // Standard conversion metrics relative to base units
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

  final Map<String, double> massFactors = {
    'g': 0.001,
    'kg': 1.0,
    'ton': 1000.0,
    'lb': 0.45359237,
    'oz': 0.028349523,
    'jin': 0.5,
  };

  final Map<String, double> areaFactors = {
    '㎡': 1.0,
    '㎢': 1000000.0,
    'ft²': 0.09290304,
    'ha': 10000.0,
    'mu': 666.66667,
  };

  ConverterNotifier(this._ref)
    : super(
        ConverterState(
          category: ConverterCategory.length,
          inputValue: 0.0,
          fromUnit: 'cm',
          toUnit: 'm',
          result: 0.0,
          isConverting: false,
          customConverters: [
            const CustomConverter(
              id: '1',
              name: '游戏金币换算器',
              fromUnit: '金币',
              toUnit: '钻石',
              factor: 0.01,
              offset: 5.0, // e.g. y = x * 0.01 + 5.0
            ),
            const CustomConverter(
              id: '2',
              name: '幻想光速转换',
              fromUnit: '光年',
              toUnit: '万公里',
              factor: 946073047.25,
              offset: 0.0,
            ),
          ],
          activeCustomId: '1',
          allConversionsMatrix: [],
        ),
      ) {
    _calculateMatrixComparisons(); // Init matrix
  }

  /// Add dynamic user-defined conversion formula card
  void addCustomConverter({
    required String name,
    required String fromUnit,
    required String toUnit,
    required double factor,
    required double offset,
  }) {
    final list = [...state.customConverters];
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    list.add(
      CustomConverter(
        id: id,
        name: name,
        fromUnit: fromUnit,
        toUnit: toUnit,
        factor: factor,
        offset: offset,
      ),
    );
    state = state.copyWith(customConverters: list, activeCustomId: id);
    _performConversionInstant();
  }

  void removeCustomConverter(String id) {
    final list = state.customConverters
        .where((element) => element.id != id)
        .toList();
    String? nextActive = list.isNotEmpty ? list.first.id : null;
    state = state.copyWith(customConverters: list, activeCustomId: nextActive);
    _performConversionInstant();
  }

  void setActiveCustomId(String id) {
    state = state.copyWith(activeCustomId: id);
    _performConversionInstant();
  }

  /// Fetch available units
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
      case ConverterCategory.sandbox:
        if (state.activeCustomId == null || state.customConverters.isEmpty) {
          return ['源单位', '目标单位'];
        }
        final cur = state.customConverters.firstWhere(
          (e) => e.id == state.activeCustomId,
        );
        return [cur.fromUnit, cur.toUnit];
    }
  }

  /// Category navigation
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
    } else if (cat == ConverterCategory.sandbox) {
      if (state.customConverters.isNotEmpty) {
        final cur = state.customConverters.firstWhere(
          (e) => e.id == state.activeCustomId,
        );
        defFrom = cur.fromUnit;
        defTo = cur.toUnit;
      } else {
        defFrom = '输入';
        defTo = '输出';
      }
    }

    state = state.copyWith(
      category: cat,
      fromUnit: defFrom,
      toUnit: defTo,
      result: 0.0,
    );
    _calculateMatrixComparisons();
  }

  void updateInputValue(double val) {
    state = state.copyWith(inputValue: val);
    _performConversionInstant();
    _debounceLogUsage();
  }

  // Debounce timer to avoid spamming logs on every keystroke
  Timer? _debounceTimer;

  void _debounceLogUsage() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      _logConversionUsage();
    });
  }

  void _logConversionUsage() {
    if (state.inputValue == 0.0) return;
    final catName = state.category.name;
    _ref
        .read(toolsAnalyticsProvider)
        .logUsage(
          toolKey: 'converter',
          parameters: {
            'category': catName,
            'from': state.fromUnit,
            'to': state.toUnit,
            'input': state.inputValue,
            'result': state.result,
          },
          status: 'success',
          durationMs: 0,
        );
  }

  void updateFromUnit(String unit) {
    state = state.copyWith(fromUnit: unit);
    _performConversionInstant();
  }

  void updateToUnit(String unit) {
    state = state.copyWith(toUnit: unit);
    _performConversionInstant();
  }

  void reverseUnits() {
    state = state.copyWith(
      fromUnit: state.toUnit,
      toUnit: state.fromUnit,
      inputValue: state.result,
      result: state.inputValue,
    );
    _calculateMatrixComparisons();
  }

  /// Instant calculations
  void _performConversionInstant() {
    double finalResult = 0.0;
    final cat = state.category;
    final from = state.fromUnit;
    final to = state.toUnit;
    final input = state.inputValue;

    if (input == 0.0) {
      state = state.copyWith(result: 0.0);
      _calculateMatrixComparisons();
      return;
    }

    if (cat == ConverterCategory.sandbox) {
      if (state.activeCustomId != null && state.customConverters.isNotEmpty) {
        final cur = state.customConverters.firstWhere(
          (e) => e.id == state.activeCustomId,
        );
        if (from == cur.fromUnit) {
          // Forward calculation: y = x * factor + offset
          finalResult = input * cur.factor + cur.offset;
        } else {
          // Backward calculation: x = (y - offset) / factor
          finalResult = (input - cur.offset) / cur.factor;
        }
      }
    } else if (cat == ConverterCategory.temperature) {
      finalResult = _convertTemperature(input, from, to);
    } else {
      final factors = cat == ConverterCategory.length
          ? lengthFactors
          : (cat == ConverterCategory.mass ? massFactors : areaFactors);

      if (factors.containsKey(from) && factors.containsKey(to)) {
        double baseVal = input * factors[from]!;
        finalResult = baseVal / factors[to]!;
      }
    }

    state = state.copyWith(result: finalResult);
    _calculateMatrixComparisons();
  }

  /// Calculates simultaneous comparison sheet across all other sibling units
  void _calculateMatrixComparisons() {
    final cat = state.category;
    final input = state.inputValue;
    final from = state.fromUnit;

    if (cat == ConverterCategory.sandbox ||
        cat == ConverterCategory.temperature) {
      state = state.copyWith(allConversionsMatrix: []);
      return;
    }

    final factors = cat == ConverterCategory.length
        ? lengthFactors
        : (cat == ConverterCategory.mass ? massFactors : areaFactors);

    if (!factors.containsKey(from)) {
      state = state.copyWith(allConversionsMatrix: []);
      return;
    }

    // Convert input to base standard unit value
    final double baseVal = input * factors[from]!;

    final List<MatrixUnitItem> matrix = [];
    factors.forEach((unitKey, factor) {
      if (unitKey != from) {
        final calculated = baseVal / factor;
        matrix.add(MatrixUnitItem(unitKey, calculated));
      }
    });

    state = state.copyWith(allConversionsMatrix: matrix);
  }

  double _convertTemperature(double value, String from, String to) {
    if (from == to) return value;

    double tempInCelsius = 0;
    if (from == '°c') {
      tempInCelsius = value;
    } else if (from == '°f') {
      tempInCelsius = (value - 32) * 5 / 9;
    } else if (from == 'k') {
      tempInCelsius = value - 273.15;
    }

    if (to == '°c') {
      return tempInCelsius;
    } else if (to == '°f') {
      return tempInCelsius * 9 / 5 + 32;
    } else if (to == 'k') {
      return tempInCelsius + 273.15;
    }

    return value;
  }
}

/// Riverpod provider
final converterProvider =
    StateNotifierProvider.autoDispose<ConverterNotifier, ConverterState>((ref) {
      return ConverterNotifier(ref);
    });
