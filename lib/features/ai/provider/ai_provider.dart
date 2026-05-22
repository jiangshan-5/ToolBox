import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/storage/local_storage.dart';
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

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      role: json['role'] as String,
      content: json['content'] as String,
      usageTokens: (json['usageTokens'] ?? json['usage_tokens']) as int?,
      provider: json['provider'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        if (usageTokens != null) 'usageTokens': usageTokens,
        if (provider != null) 'provider': provider,
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

  AiChatNotifier(this._ref) : super(AiChatState(messages: [])) {
    loadHistory();
  }

  /// Load chat history: from SharedPreferences for guests, or backend DB for logged-in users.
  Future<void> loadHistory() async {
    final authState = _ref.read(authProvider);
    final isGuest = !authState.isAuthenticated || authState.email == null;

    if (isGuest) {
      try {
        final storage = _ref.read(localStorageServiceProvider);
        final cached = storage.getString('guest_ai_chat_history');
        if (cached != null) {
          final List<dynamic> decoded = jsonDecode(cached);
          final messages = decoded
              .map((item) => Message.fromJson(item as Map<String, dynamic>))
              .toList();
          state = state.copyWith(messages: messages);
        }
      } catch (e) {
        print('Failed to load guest chat history: $e');
      }
    } else {
      state = state.copyWith(isLoading: true, error: null);
      try {
        final apiClient = _ref.read(apiClientProvider);
        final response = await apiClient.instance.get('/ai/chat/history');
        if (!mounted) return;
        
        final List<dynamic> list = response.data;
        final messages = list
            .map((item) => Message.fromJson(item as Map<String, dynamic>))
            .toList();
        state = state.copyWith(messages: messages, isLoading: false);
      } on DioException catch (e) {
        if (!mounted) return;
        state = state.copyWith(
          isLoading: false,
          error: e.error?.toString() ?? '获取云端历史记录失败',
        );
      } catch (e) {
        if (!mounted) return;
        state = state.copyWith(
          isLoading: false,
          error: '获取历史记录出现未知异常: $e',
        );
      }
    }
  }

  /// Helper to save guest chat messages locally.
  Future<void> _saveLocalHistoryIfGuest() async {
    final authState = _ref.read(authProvider);
    final isGuest = !authState.isAuthenticated || authState.email == null;
    if (isGuest) {
      try {
        final storage = _ref.read(localStorageServiceProvider);
        final serialized = jsonEncode(state.messages.map((m) => m.toJson()).toList());
        await storage.setString('guest_ai_chat_history', serialized);
      } catch (e) {
        print('Failed to save guest chat history: $e');
      }
    }
  }

  /// Send message and dynamically sync multi-turn history to the backend
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = Message(role: 'user', content: text);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );
    await _saveLocalHistoryIfGuest();

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

      if (!mounted) return;

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
      await _saveLocalHistoryIfGuest();

      // Async upload AI Telemetry to Cloud without blocking UI
      final authState = _ref.read(authProvider);
      if (authState.isAuthenticated && authState.email != null) {
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
          if (!mounted) return;
          _ref.invalidate(analyticsProvider);
        } catch (telemetryError) {
          print('Telemetry sync failed: $telemetryError');
        }
      }

    } on DioException catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.error?.toString() ?? '对话生成超时，请稍后重试',
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: '对话出现未知异常: $e',
      );
    }
  }

  Future<void> clearHistory() async {
    final authState = _ref.read(authProvider);
    final isGuest = !authState.isAuthenticated || authState.email == null;

    state = AiChatState(messages: []);

    if (isGuest) {
      try {
        final storage = _ref.read(localStorageServiceProvider);
        await storage.setString('guest_ai_chat_history', '[]');
      } catch (e) {
        print('Failed to clear guest chat history: $e');
      }
    } else {
      try {
        final apiClient = _ref.read(apiClientProvider);
        await apiClient.instance.delete('/ai/chat/history');
      } catch (e) {
        print('Failed to clear cloud chat history: $e');
      }
    }
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

      if (!mounted) return;

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
        if (!mounted) return;
        _ref.invalidate(analyticsProvider);
      } catch (telemetryError) {
        print('TextProcessor telemetry sync failed: $telemetryError');
      }
    } on DioException catch (e) {
      if (!mounted) return;
      state = AiTextProcessorState(
        isLoading: false,
        error: e.error?.toString() ?? '文本处理失败，请稍后重试',
      );
    } catch (e) {
      if (!mounted) return;
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

