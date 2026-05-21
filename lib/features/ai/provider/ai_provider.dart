import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../auth/provider/auth_provider.dart';
import '../../dashboard/provider/analytics_provider.dart';
import 'ai_config_provider.dart';

class Message {
  final String role;
  final String content;
  final int? usageTokens;
  final String? provider;

  Message({
    required this.role,
    required this.content,
    this.usageTokens,
    this.provider,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };
}

class AiChatState {
  final List<Message> messages;
  final bool isLoading;
  final String? error;

  AiChatState({
    required this.messages,
    this.isLoading = false,
    this.error,
  });

  AiChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? error,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AiChatNotifier extends StateNotifier<AiChatState> {
  final Ref _ref;

  AiChatNotifier(this._ref) : super(AiChatState(messages: []));

  /// Send message and dynamically sync multi-turn history to the backend
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = Message(role: 'user', content: text);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      final apiClient = _ref.read(apiClientProvider);
      final aiConfig = _ref.read(aiConfigProvider);
      
      // Convert in-memory messages to json array for conversation memory
      final historyList = state.messages
          .sublist(0, state.messages.length - 1)
          .map((m) => m.toJson())
          .toList();

      final response = await apiClient.instance.post(
        '/ai/chat',
        data: {
          'message': text,
          'history': historyList,
        },
        options: Options(
          headers: {
            'X-AI-Provider': aiConfig.provider,
            'X-AI-Key': aiConfig.apiKey,
            'X-AI-Base-URL': aiConfig.baseUrl,
            'X-AI-Model': aiConfig.model,
          },
        ),
      );

      final reply = response.data['reply'] as String;
      final provider = response.data['provider'] as String?;
      final usageTokens = response.data['usage_tokens'] as int?;

      final botMessage = Message(
        role: 'model',
        content: reply,
        usageTokens: usageTokens,
        provider: provider,
      );
      state = state.copyWith(
        messages: [...state.messages, botMessage],
        isLoading: false,
      );

      // Async upload AI Telemetry to Cloud without blocking UI
      try {
        final wordsGenerated = reply.length;
        // Estimate 1.5 seconds saved per word compared to manual research/typing
        final timeSavedSeconds = (wordsGenerated * 1.5).round();
        
        await apiClient.instance.post(
          '/analytics/telemetry',
          data: {
            'provider': provider ?? aiConfig.provider,
            'model_name': aiConfig.model,
            'words_generated': wordsGenerated,
            'time_saved_seconds': timeSavedSeconds,
          },
        );
        _ref.invalidate(analyticsProvider);
      } catch (telemetryError) {
        print('Telemetry sync failed: $telemetryError');
      }

    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.error?.toString() ?? '对话生成超时，请稍后重试',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '对话出现未知异常: $e',
      );
    }
  }

  void clearHistory() {
    state = AiChatState(messages: []);
  }
}

/// Global dynamic multi-turn chat agent provider
final aiChatProvider = StateNotifierProvider.autoDispose<AiChatNotifier, AiChatState>((ref) {
  return AiChatNotifier(ref);
});

class AiTextProcessorState {
  final bool isLoading;
  final String? result;
  final String? error;

  AiTextProcessorState({
    this.isLoading = false,
    this.result,
    this.error,
  });

  AiTextProcessorState copyWith({
    bool? isLoading,
    String? result,
    String? error,
  }) {
    return AiTextProcessorState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      error: error,
    );
  }
}

class AiTextProcessorNotifier extends StateNotifier<AiTextProcessorState> {
  final Ref _ref;

  AiTextProcessorNotifier(this._ref) : super(AiTextProcessorState());

  /// Call text processor for advanced rewrite/polishing/translation
  Future<void> processText({
    required String text,
    required String action,
    String? targetLanguage,
  }) async {
    if (text.trim().isEmpty) return;

    state = AiTextProcessorState(isLoading: true);

    try {
      final apiClient = _ref.read(apiClientProvider);
      final aiConfig = _ref.read(aiConfigProvider);
      
      final response = await apiClient.instance.post(
        '/ai/process-text',
        data: {
          'text': text,
          'action': action,
          'target_language': targetLanguage ?? 'en',
        },
        options: Options(
          headers: {
            'X-AI-Provider': aiConfig.provider,
            'X-AI-Key': aiConfig.apiKey,
            'X-AI-Base-URL': aiConfig.baseUrl,
            'X-AI-Model': aiConfig.model,
          },
        ),
      );

      final resultText = response.data['result'] as String;
      state = AiTextProcessorState(
        isLoading: false,
        result: resultText,
      );

      // Async upload AI Telemetry to Cloud — mirrors AiChatNotifier
      try {
        final wordsGenerated = resultText.length;
        final timeSavedSeconds = (wordsGenerated * 1.5).round();
        await apiClient.instance.post(
          '/analytics/telemetry',
          data: {
            'provider': aiConfig.provider,
            'model_name': aiConfig.model,
            'words_generated': wordsGenerated,
            'time_saved_seconds': timeSavedSeconds,
          },
        );
        _ref.invalidate(analyticsProvider);
      } catch (telemetryError) {
        print('TextProcessor telemetry sync failed: $telemetryError');
      }
    } on DioException catch (e) {
      state = AiTextProcessorState(
        isLoading: false,
        error: e.error?.toString() ?? '文本处理失败，请稍后重试',
      );
    } catch (e) {
      state = AiTextProcessorState(
        isLoading: false,
        error: '文本处理出现异常: $e',
      );
    }
  }

  void clearResult() {
    state = AiTextProcessorState();
  }
}

/// Global text processing agent provider
final aiTextProcessorProvider = StateNotifierProvider.autoDispose<AiTextProcessorNotifier, AiTextProcessorState>((ref) {
  return AiTextProcessorNotifier(ref);
});

