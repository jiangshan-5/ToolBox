import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/provider/tools_provider.dart';

/// Interactive modes for the Sandboxed Randomizer
enum RandomizerMode { number, list, dice }

/// Individual option with a custom weight assigned by the user
class WeightedOption {
  final String id;
  final String text;
  final double weight; // Relative weight, e.g. 1.0, 5.0, 10.0

  const WeightedOption({
    required this.id,
    required this.text,
    required this.weight,
  });

  WeightedOption copyWith({
    String? text,
    double? weight,
  }) {
    return WeightedOption(
      id: id,
      text: text ?? this.text,
      weight: weight ?? this.weight,
    );
  }
}

/// Dynamic range parameters for combinatorial generation
class CustomRange {
  final int min;
  final int max;
  final bool active;

  const CustomRange({
    required this.min,
    required this.max,
    required this.active,
  });

  CustomRange copyWith({
    int? min,
    int? max,
    bool? active,
  }) {
    return CustomRange(
      min: min ?? this.min,
      max: max ?? this.max,
      active: active ?? this.active,
    );
  }
}

/// Comprehensive State keeping all custom sandbox attributes
class RandomizerState {
  final RandomizerMode mode;
  
  // 1. COMBINATORIAL NUMBER SANDBOX
  final List<CustomRange> customRanges;
  final int generateCount;
  final bool allowDuplicates;
  final String prefix;
  final String suffix;
  final int padLeft; // Zero padding count, e.g. 3 -> 003
  final List<String> formattedResults;

  // 2. WEIGHTED DECISION SANDBOX
  final List<WeightedOption> weightedOptions;
  final List<String> drawnOptions;
  final int drawCount;

  // 3. CUSTOM SIDES DICE SANDBOX
  final int diceSides; // e.g. 6, 12, 20, 100
  final String customDiceLabels; // comma separated custom text sides
  final List<String> diceRollResults;

  final bool isGenerating;

  const RandomizerState({
    required this.mode,
    required this.customRanges,
    required this.generateCount,
    required this.allowDuplicates,
    required this.prefix,
    required this.suffix,
    required this.padLeft,
    required this.formattedResults,
    required this.weightedOptions,
    required this.drawnOptions,
    required this.drawCount,
    required this.diceSides,
    required this.customDiceLabels,
    required this.diceRollResults,
    required this.isGenerating,
  });

  RandomizerState copyWith({
    RandomizerMode? mode,
    List<CustomRange>? customRanges,
    int? generateCount,
    bool? allowDuplicates,
    String? prefix,
    String? suffix,
    int? padLeft,
    List<String>? formattedResults,
    List<WeightedOption>? weightedOptions,
    List<String>? drawnOptions,
    int? drawCount,
    int? diceSides,
    String? customDiceLabels,
    List<String>? diceRollResults,
    bool? isGenerating,
  }) {
    return RandomizerState(
      mode: mode ?? this.mode,
      customRanges: customRanges ?? this.customRanges,
      generateCount: generateCount ?? this.generateCount,
      allowDuplicates: allowDuplicates ?? this.allowDuplicates,
      prefix: prefix ?? this.prefix,
      suffix: suffix ?? this.suffix,
      padLeft: padLeft ?? this.padLeft,
      formattedResults: formattedResults ?? this.formattedResults,
      weightedOptions: weightedOptions ?? this.weightedOptions,
      drawnOptions: drawnOptions ?? this.drawnOptions,
      drawCount: drawCount ?? this.drawCount,
      diceSides: diceSides ?? this.diceSides,
      customDiceLabels: customDiceLabels ?? this.customDiceLabels,
      diceRollResults: diceRollResults ?? this.diceRollResults,
      isGenerating: isGenerating ?? this.isGenerating,
    );
  }
}

/// Sandbox Randomizer Notifier implementing weighted select, combinatorial intervals, and custom dice
class RandomizerNotifier extends StateNotifier<RandomizerState> {
  final Ref _ref;
  final _random = Random();

  RandomizerNotifier(this._ref)
      : super(RandomizerState(
          mode: RandomizerMode.number,
          customRanges: [
            const CustomRange(min: 1, max: 10, active: true),
            const CustomRange(min: 50, max: 60, active: false),
            const CustomRange(min: 100, max: 120, active: false),
          ],
          generateCount: 3,
          allowDuplicates: false,
          prefix: 'ID-',
          suffix: '',
          padLeft: 3,
          formattedResults: [],
          weightedOptions: [
            const WeightedOption(id: '1', text: '吃披萨', weight: 5.0),
            const WeightedOption(id: '2', text: '吃火锅', weight: 3.0),
            const WeightedOption(id: '3', text: '吃沙拉', weight: 1.0),
            const WeightedOption(id: '4', text: '自己做饭', weight: 1.0),
          ],
          drawnOptions: [],
          drawCount: 1,
          diceSides: 6,
          customDiceLabels: '大吉, 中吉, 小吉, 平, 凶, 大凶',
          diceRollResults: [],
          isGenerating: false,
        ));

  void setMode(RandomizerMode mode) => state = state.copyWith(mode: mode);

  // 1. COMBINATORIAL SETTERS
  void updateRangeMin(int index, int val) {
    final ranges = [...state.customRanges];
    ranges[index] = ranges[index].copyWith(min: val);
    state = state.copyWith(customRanges: ranges);
  }

  void updateRangeMax(int index, int val) {
    final ranges = [...state.customRanges];
    ranges[index] = ranges[index].copyWith(max: val);
    state = state.copyWith(customRanges: ranges);
  }

  void toggleRangeActive(int index, bool active) {
    final ranges = [...state.customRanges];
    ranges[index] = ranges[index].copyWith(active: active);
    state = state.copyWith(customRanges: ranges);
  }

  void setGenerateCount(int val) => state = state.copyWith(generateCount: val);
  void setAllowDuplicates(bool val) => state = state.copyWith(allowDuplicates: val);
  void setPrefix(String val) => state = state.copyWith(prefix: val);
  void setSuffix(String val) => state = state.copyWith(suffix: val);
  void setPadLeft(int val) => state = state.copyWith(padLeft: val);

  // 2. WEIGHTED SETTERS
  void addWeightedOption(String text) {
    final options = [...state.weightedOptions];
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    options.add(WeightedOption(id: id, text: text, weight: 1.0));
    state = state.copyWith(weightedOptions: options);
  }

  void removeWeightedOption(String id) {
    final options = state.weightedOptions.where((element) => element.id != id).toList();
    state = state.copyWith(weightedOptions: options);
  }

  void updateOptionText(String id, String newText) {
    final options = state.weightedOptions.map((e) {
      return e.id == id ? e.copyWith(text: newText) : e;
    }).toList();
    state = state.copyWith(weightedOptions: options);
  }

  void updateOptionWeight(String id, double newWeight) {
    final options = state.weightedOptions.map((e) {
      return e.id == id ? e.copyWith(weight: newWeight) : e;
    }).toList();
    state = state.copyWith(weightedOptions: options);
  }

  void setDrawCount(int val) => state = state.copyWith(drawCount: val);

  // 3. DICE SETTERS
  void setDiceSides(int val) => state = state.copyWith(diceSides: val);
  void setCustomDiceLabels(String val) => state = state.copyWith(customDiceLabels: val);

  /// --- ALGORITHMS ---

  /// Dynamic mathematical calculation of current probabilities
  double getProbabilityOfOption(String id) {
    final total = state.weightedOptions.fold<double>(0.0, (sum, item) => sum + item.weight);
    if (total == 0.0) return 0.0;
    final target = state.weightedOptions.firstWhere((element) => element.id == id);
    return (target.weight / total) * 100.0;
  }

  /// Run combinatorial range multi-interval generation with zero-padding
  Future<void> runCombinatorialGenerate() async {
    if (state.isGenerating) return;

    state = state.copyWith(isGenerating: true);
    final stopwatch = Stopwatch()..start();

    // 1. Gather all active range sets
    final List<int> combinedPool = [];
    for (final range in state.customRanges) {
      if (range.active) {
        int minVal = range.min;
        int maxVal = range.max;
        if (minVal > maxVal) {
          final temp = minVal;
          minVal = maxVal;
          maxVal = temp;
        }
        for (int i = minVal; i <= maxVal; i++) {
          combinedPool.add(i);
        }
      }
    }

    if (combinedPool.isEmpty) {
      state = state.copyWith(formattedResults: [], isGenerating: false);
      return;
    }

    // Delay visual simulation
    await Future.delayed(const Duration(milliseconds: 400));

    final List<int> drawnNumbers = [];
    int needCount = state.generateCount.clamp(1, 100);

    if (!state.allowDuplicates && needCount > combinedPool.length) {
      needCount = combinedPool.length;
    }

    if (!state.allowDuplicates) {
      final poolCopy = [...combinedPool];
      for (int i = 0; i < needCount; i++) {
        final idx = _random.nextInt(poolCopy.length);
        drawnNumbers.add(poolCopy[idx]);
        poolCopy.removeAt(idx); // prevent duplicates
      }
    } else {
      for (int i = 0; i < needCount; i++) {
        final idx = _random.nextInt(combinedPool.length);
        drawnNumbers.add(combinedPool[idx]);
      }
    }

    // Sort to look professional
    drawnNumbers.sort();

    // Formatter applying zero padding, prefix, and suffix
    final List<String> formatted = drawnNumbers.map((num) {
      final padded = num.toString().padLeft(state.padLeft, '0');
      return '${state.prefix}$padded${state.suffix}';
    }).toList();

    stopwatch.stop();
    state = state.copyWith(formattedResults: formatted, isGenerating: false);

    // DB logs
    _ref.read(toolsAnalyticsProvider).logUsage(
      toolKey: 'randomizer',
      parameters: {
        'mode': 'combinatorial',
        'active_ranges': state.customRanges.where((e) => e.active).map((e) => '[${e.min},${e.max}]').toList(),
        'allow_duplicates': state.allowDuplicates,
        'pad_left': state.padLeft,
        'results': formatted,
      },
      status: 'success',
      durationMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// Run weighted decision extraction using probability proportional to size (PPS)
  Future<void> runWeightedDecision() async {
    if (state.isGenerating || state.weightedOptions.isEmpty) return;

    state = state.copyWith(isGenerating: true);
    final stopwatch = Stopwatch()..start();

    // Decent simulation delay
    await Future.delayed(const Duration(milliseconds: 500));

    final List<WeightedOption> drawn = [];
    final pool = [...state.weightedOptions];
    int needCount = state.drawCount.clamp(1, pool.length);

    for (int i = 0; i < needCount; i++) {
      if (pool.isEmpty) break;
      
      final double totalWeight = pool.fold(0.0, (sum, element) => sum + element.weight);
      if (totalWeight <= 0) {
        // Fallback: simple uniform draw
        final idx = _random.nextInt(pool.length);
        drawn.add(pool[idx]);
        pool.removeAt(idx);
        continue;
      }

      double randPoint = _random.nextDouble() * totalWeight;
      double accumulated = 0.0;
      WeightedOption? chosen;

      for (final option in pool) {
        accumulated += option.weight;
        if (randPoint <= accumulated) {
          chosen = option;
          break;
        }
      }

      chosen ??= pool.last;
      drawn.add(chosen);
      pool.remove((chosen)); // Avoid duplicate picks in same draw
    }

    stopwatch.stop();
    state = state.copyWith(
      drawnOptions: drawn.map((e) => e.text).toList(),
      isGenerating: false,
    );

    _ref.read(toolsAnalyticsProvider).logUsage(
      toolKey: 'randomizer',
      parameters: {
        'mode': 'weighted',
        'options_count': state.weightedOptions.length,
        'draw_count': needCount,
        'drawn': state.drawnOptions,
      },
      status: 'success',
      durationMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// Roll custom dice (either multi-sided standard dice, or custom text label dice!)
  Future<void> rollCustomDice() async {
    if (state.isGenerating) return;

    state = state.copyWith(isGenerating: true);
    final stopwatch = Stopwatch()..start();

    // Wheel visual spin simulation delay
    await Future.delayed(const Duration(milliseconds: 500));

    final List<String> results = [];
    final labels = state.customDiceLabels
        .split(RegExp(r'[,，\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // If custom labels are provided, we treat it as custom text dice rolling
    // Otherwise, we do numeric sides roll [1, diceSides]
    if (labels.isNotEmpty) {
      results.add(labels[_random.nextInt(labels.length)]);
    } else {
      results.add((_random.nextInt(state.diceSides) + 1).toString());
    }

    stopwatch.stop();
    state = state.copyWith(
      diceRollResults: results,
      isGenerating: false,
    );

    _ref.read(toolsAnalyticsProvider).logUsage(
      toolKey: 'randomizer',
      parameters: {
        'mode': 'custom_dice',
        'is_text_dice': labels.isNotEmpty,
        'roll_outcome': results,
      },
      status: 'success',
      durationMs: stopwatch.elapsedMilliseconds,
    );
  }
}

/// Riverpod provider for the Sandboxed Randomizer
final randomizerProvider = StateNotifierProvider.autoDispose<RandomizerNotifier, RandomizerState>((ref) {
  return RandomizerNotifier(ref);
});
