import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/local_storage.dart';

class AiConfigState {
  final String provider; // 'siliconflow', 'deepseek', 'gemini', 'openai', 'mock'
  final String apiKey;
  final String baseUrl;
  final String model;

  AiConfigState({
    required this.provider,
    required this.apiKey,
    required this.baseUrl,
    required this.model,
  });

  AiConfigState copyWith({
    String? provider,
    String? apiKey,
    String? baseUrl,
    String? model,
  }) {
    return AiConfigState(
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
    );
  }
}

class AiConfigNotifier extends StateNotifier<AiConfigState> {
  final LocalStorageService _storage;

  AiConfigNotifier(this._storage)
      : super(AiConfigState(
          provider: _storage.getString('ai_provider') ?? 'mock',
          apiKey: _storage.getString('ai_api_key') ?? '',
          baseUrl: _storage.getString('ai_base_url') ?? '',
          model: _storage.getString('ai_model') ?? '',
        ));

  Future<void> updateConfig({
    required String provider,
    required String apiKey,
    required String baseUrl,
    required String model,
  }) async {
    await _storage.setString('ai_provider', provider);
    await _storage.setString('ai_api_key', apiKey);
    await _storage.setString('ai_base_url', baseUrl);
    await _storage.setString('ai_model', model);

    state = AiConfigState(
      provider: provider,
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
    );
  }

  Future<void> clearConfig() async {
    await _storage.setString('ai_provider', 'mock');
    await _storage.setString('ai_api_key', '');
    await _storage.setString('ai_base_url', '');
    await _storage.setString('ai_model', '');

    state = AiConfigState(
      provider: 'mock',
      apiKey: '',
      baseUrl: '',
      model: '',
    );
  }
}

/// Global AI Configuration provider
final aiConfigProvider = StateNotifierProvider<AiConfigNotifier, AiConfigState>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return AiConfigNotifier(storage);
});
