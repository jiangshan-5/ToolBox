import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dashboard/view/widgets/dashboard_utils.dart';
import '../../features/auth/provider/auth_provider.dart';
import '../widgets/pipeline_summary_screen.dart';

class PipelineSession {
  final List<String> steps;
  final int currentStepIndex;
  final Map<int, String> stepInputs;
  final Map<int, String> stepOutputs;
  final bool isActive;

  const PipelineSession({
    this.steps = const [],
    this.currentStepIndex = 0,
    this.stepInputs = const {},
    this.stepOutputs = const {},
    this.isActive = false,
  });

  PipelineSession copyWith({
    List<String>? steps,
    int? currentStepIndex,
    Map<int, String>? stepInputs,
    Map<int, String>? stepOutputs,
    bool? isActive,
  }) {
    return PipelineSession(
      steps: steps ?? this.steps,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      stepInputs: stepInputs ?? this.stepInputs,
      stepOutputs: stepOutputs ?? this.stepOutputs,
      isActive: isActive ?? this.isActive,
    );
  }
}

class PipelineSessionNotifier extends StateNotifier<PipelineSession> {
  final Ref _ref;
  PipelineSessionNotifier(this._ref) : super(const PipelineSession());

  void startSession({
    required List<String> steps,
    required String initialInput,
    required BuildContext context,
  }) {
    if (steps.isEmpty) return;

    state = PipelineSession(
      steps: steps,
      currentStepIndex: 0,
      stepInputs: {0: initialInput},
      stepOutputs: const {},
      isActive: true,
    );

    // Navigate to the first tool screen
    final firstToolKey = steps[0];
    final page = getToolPage(firstToolKey);
    if (page != null) {
      Navigator.push(context, FadePageRoute(child: page));
    }
  }

  Future<void> _logExecutionToServer(Map<int, String> finalOutputs) async {
    try {
      final dio = _ref.read(apiClientProvider).instance;
      
      final Map<String, String> inputs = {};
      state.stepInputs.forEach((key, val) => inputs[key.toString()] = val);
      
      final Map<String, String> outputs = {};
      finalOutputs.forEach((key, val) => outputs[key.toString()] = val);

      await dio.post('/tools/workflows/executions', data: {
        'steps': state.steps,
        'step_inputs': inputs,
        'step_outputs': outputs,
        'status': 'success',
      });
    } catch (e) {
      debugPrint('Error logging workflow execution to server: $e');
    }
  }

  void completeStep(BuildContext context, String outputText) {
    if (!state.isActive) return;

    final currentIndex = state.currentStepIndex;
    final updatedOutputs = Map<int, String>.from(state.stepOutputs)..[currentIndex] = outputText;

    if (currentIndex + 1 < state.steps.length) {
      // Flow to next step
      final nextIndex = currentIndex + 1;
      final updatedInputs = Map<int, String>.from(state.stepInputs)..[nextIndex] = outputText;

      state = state.copyWith(
        currentStepIndex: nextIndex,
        stepInputs: updatedInputs,
        stepOutputs: updatedOutputs,
      );

      final nextToolKey = state.steps[nextIndex];
      final page = getToolPage(nextToolKey);
      if (page != null) {
        // Push replacement keeps the navigation stack beautiful and linear
        Navigator.pushReplacement(context, FadePageRoute(child: page));
      }
    } else {
      // Completed the entire pipeline!
      state = state.copyWith(
        stepOutputs: updatedOutputs,
        isActive: false, // Freeze active processing, show summary
      );

      // Async background server execution logging
      _logExecutionToServer(updatedOutputs);

      // Navigate to gorgeous completion summary screen
      importSummaryScreenAndNavigate(context);
    }
  }

  void skipStep(BuildContext context) {
    if (!state.isActive) return;

    final currentIndex = state.currentStepIndex;
    final fallbackInput = state.stepInputs[currentIndex] ?? '';
    completeStep(context, fallbackInput);
  }

  void resetSession() {
    state = const PipelineSession();
  }

  void importSummaryScreenAndNavigate(BuildContext context) {
    // Dynamic import mapping to prevent circular reference, using standard Navigator routing
    // Summary screen is pushReplacements to complete the flow elegantly
    Navigator.pushReplacement(
      context,
      FadePageRoute(
        child: PipelineSummaryScreen(
          steps: state.steps,
          inputs: state.stepInputs,
          outputs: state.stepOutputs,
        ),
      ),
    );
  }
}

final pipelineSessionProvider =
    StateNotifierProvider<PipelineSessionNotifier, PipelineSession>((ref) {
  return PipelineSessionNotifier(ref);
});

class SavedWorkflow {
  final String id;
  final String name;
  final String? description;
  final List<String> steps;
  final DateTime createdAt;

  SavedWorkflow({
    required this.id,
    required this.name,
    this.description,
    required this.steps,
    required this.createdAt,
  });

  factory SavedWorkflow.fromJson(Map<String, dynamic> json) {
    return SavedWorkflow(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      steps: List<String>.from(json['steps'] as List),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

final savedWorkflowsProvider = FutureProvider<List<SavedWorkflow>>((ref) async {
  try {
    final auth = ref.watch(authProvider);
    if (!auth.isAuthenticated || auth.email == null) {
      return const [];
    }
    
    final dio = ref.read(apiClientProvider).instance;
    final response = await dio.get('/tools/workflows');
    final List data = response.data as List;
    return data.map((json) => SavedWorkflow.fromJson(json)).toList();
  } catch (e) {
    debugPrint('Error fetching user workflows from database: $e');
    return const [];
  }
});

