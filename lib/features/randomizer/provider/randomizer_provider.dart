import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/provider/tools_provider.dart';

/// Explicit model class for the Randomizer state
class RandomizerState {
  final int result;
  final bool isGenerating;

  const RandomizerState({
    required this.result,
    required this.isGenerating,
  });

  RandomizerState copyWith({
    int? result,
    bool? isGenerating,
  }) {
    return RandomizerState(
      result: result ?? this.result,
      isGenerating: isGenerating ?? this.isGenerating,
    );
  }
}

/// StateNotifier handling pure computation, tactile delay, and analytics reporting
class RandomizerNotifier extends StateNotifier<RandomizerState> {
  final Ref _ref;
  final _random = Random();

  RandomizerNotifier(this._ref) : super(const RandomizerState(result: 0, isGenerating: false));

  /// Trigger number generation and log execution metrics to database
  Future<void> generate() async {
    if (state.isGenerating) return;

    state = state.copyWith(isGenerating: true);

    final stopwatch = Stopwatch()..start();

    // Subtle delay to simulate physical wheel spinning / tactile feel
    await Future.delayed(const Duration(milliseconds: 300));
    
    final generatedVal = _random.nextInt(100) + 1;
    stopwatch.stop();

    state = state.copyWith(
      result: generatedVal,
      isGenerating: false,
    );

    // Fire-and-forget telemetry logging to backend database
    _ref.read(toolsAnalyticsProvider).logUsage(
      toolKey: 'randomizer',
      parameters: {
        'min': 1,
        'max': 100,
        'result': generatedVal,
      },
      status: 'success',
      durationMs: stopwatch.elapsedMilliseconds,
    );
  }
}

/// Provider to watch the randomizer state and execute actions
final randomizerProvider = StateNotifierProvider.autoDispose<RandomizerNotifier, RandomizerState>((ref) {
  return RandomizerNotifier(ref);
});
