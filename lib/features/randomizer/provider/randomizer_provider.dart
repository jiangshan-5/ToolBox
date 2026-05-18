import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/provider/tools_provider.dart';

/// Available interactive modes for the Supercharged Randomizer
enum RandomizerMode { number, list, dice }

/// Comprehensive state model supporting multiple options and outputs
class RandomizerState {
  final RandomizerMode mode;
  
  // Number Mode Configuration & Results
  final int min;
  final int max;
  final int count;
  final bool allowDuplicates;
  final List<int> numberResults;
  
  // List Mode Configuration & Results
  final String listInput;
  final List<String> listResults;
  final int listDrawCount;
  
  // Dice Mode Configuration & Results
  final int diceCount;
  final List<int> diceResults;
  
  final bool isGenerating;

  const RandomizerState({
    required this.mode,
    required this.min,
    required this.max,
    required this.count,
    required this.allowDuplicates,
    required this.numberResults,
    required this.listInput,
    required this.listResults,
    required this.listDrawCount,
    required this.diceCount,
    required this.diceResults,
    required this.isGenerating,
  });

  RandomizerState copyWith({
    RandomizerMode? mode,
    int? min,
    int? max,
    int? count,
    bool? allowDuplicates,
    List<int>? numberResults,
    String? listInput,
    List<String>? listResults,
    int? listDrawCount,
    int? diceCount,
    List<int>? diceResults,
    bool? isGenerating,
  }) {
    return RandomizerState(
      mode: mode ?? this.mode,
      min: min ?? this.min,
      max: max ?? this.max,
      count: count ?? this.count,
      allowDuplicates: allowDuplicates ?? this.allowDuplicates,
      numberResults: numberResults ?? this.numberResults,
      listInput: listInput ?? this.listInput,
      listResults: listResults ?? this.listResults,
      listDrawCount: listDrawCount ?? this.listDrawCount,
      diceCount: diceCount ?? this.diceCount,
      diceResults: diceResults ?? this.diceResults,
      isGenerating: isGenerating ?? this.isGenerating,
    );
  }
}

/// Supercharged StateNotifier handling multi-mode algorithms, statistical checks, and analytical tracking
class RandomizerNotifier extends StateNotifier<RandomizerState> {
  final Ref _ref;
  final _random = Random();

  RandomizerNotifier(this._ref)
      : super(const RandomizerState(
          mode: RandomizerMode.number,
          min: 1,
          max: 100,
          count: 1,
          allowDuplicates: false,
          numberResults: [],
          listInput: '选项A, 选项B, 选项C, 选项D',
          listResults: [],
          listDrawCount: 1,
          diceCount: 1,
          diceResults: [],
          isGenerating: false,
        ));

  void setMode(RandomizerMode mode) => state = state.copyWith(mode: mode);

  // Number Mode Setters
  void setMin(int val) => state = state.copyWith(min: val);
  void setMax(int val) => state = state.copyWith(max: val);
  void setCount(int val) => state = state.copyWith(count: val);
  void setAllowDuplicates(bool val) => state = state.copyWith(allowDuplicates: val);

  // List Mode Setters
  void setListInput(String val) => state = state.copyWith(listInput: val);
  void setListDrawCount(int val) => state = state.copyWith(listDrawCount: val);

  // Dice Mode Setters
  void setDiceCount(int val) => state = state.copyWith(diceCount: val);

  /// Run high-end Number Generation algorithm with duplicity protection and telemetry
  Future<void> generateNumbers() async {
    if (state.isGenerating) return;
    
    // Bounds check
    int adjustedMin = state.min;
    int adjustedMax = state.max;
    if (adjustedMin > adjustedMax) {
      final temp = adjustedMin;
      adjustedMin = adjustedMax;
      adjustedMax = temp;
    }
    
    int range = adjustedMax - adjustedMin + 1;
    int neededCount = state.count.clamp(1, 100);

    // If duplicates are not allowed, count cannot exceed the range size
    if (!state.allowDuplicates && neededCount > range) {
      neededCount = range;
    }

    state = state.copyWith(isGenerating: true);
    final stopwatch = Stopwatch()..start();

    // Visual feel delay
    await Future.delayed(const Duration(milliseconds: 400));

    final List<int> results = [];
    if (!state.allowDuplicates) {
      final Set<int> uniqueResults = {};
      while (uniqueResults.length < neededCount) {
        uniqueResults.add(_random.nextInt(range) + adjustedMin);
      }
      results.addAll(uniqueResults);
      results.sort(); // Sort for neat presentation
    } else {
      for (int i = 0; i < neededCount; i++) {
        results.add(_random.nextInt(range) + adjustedMin);
      }
    }

    stopwatch.stop();
    state = state.copyWith(
      numberResults: results,
      isGenerating: false,
    );

    // Save logs to telemetry
    _ref.read(toolsAnalyticsProvider).logUsage(
      toolKey: 'randomizer',
      parameters: {
        'mode': 'number',
        'min': adjustedMin,
        'max': adjustedMax,
        'count': neededCount,
        'allow_duplicates': state.allowDuplicates,
        'results': results,
      },
      status: 'success',
      durationMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// Run custom list draw picking items out of comma/newline split values
  Future<void> drawFromList() async {
    if (state.isGenerating) return;

    final items = state.listInput
        .split(RegExp(r'[,，\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (items.isEmpty) return;

    state = state.copyWith(isGenerating: true);
    final stopwatch = Stopwatch()..start();

    // Wheel visual spin simulation delay
    await Future.delayed(const Duration(milliseconds: 600));

    final List<String> results = [];
    int drawNum = state.listDrawCount.clamp(1, items.length);

    // Draw unique items
    final Set<String> drawn = {};
    while (drawn.length < drawNum) {
      final idx = _random.nextInt(items.length);
      drawn.add(items[idx]);
    }
    results.addAll(drawn);
    stopwatch.stop();

    state = state.copyWith(
      listResults: results,
      isGenerating: false,
    );

    _ref.read(toolsAnalyticsProvider).logUsage(
      toolKey: 'randomizer',
      parameters: {
        'mode': 'list',
        'pool_size': items.length,
        'draw_count': drawNum,
        'results': results,
      },
      status: 'success',
      durationMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// Run physics simulated visual dice rolling
  Future<void> rollDice() async {
    if (state.isGenerating) return;

    state = state.copyWith(isGenerating: true);
    final stopwatch = Stopwatch()..start();

    // Tactical friction rolling delay
    await Future.delayed(const Duration(milliseconds: 500));

    final List<int> results = [];
    final rollingCount = state.diceCount.clamp(1, 6);
    for (int i = 0; i < rollingCount; i++) {
      results.add(_random.nextInt(6) + 1);
    }
    stopwatch.stop();

    state = state.copyWith(
      diceResults: results,
      isGenerating: false,
    );

    _ref.read(toolsAnalyticsProvider).logUsage(
      toolKey: 'randomizer',
      parameters: {
        'mode': 'dice',
        'dice_count': rollingCount,
        'results': results,
        'sum': results.reduce((a, b) => a + b),
      },
      status: 'success',
      durationMs: stopwatch.elapsedMilliseconds,
    );
  }
}

/// Riverpod provider for the supercharged Randomizer
final randomizerProvider = StateNotifierProvider.autoDispose<RandomizerNotifier, RandomizerState>((ref) {
  return RandomizerNotifier(ref);
});
