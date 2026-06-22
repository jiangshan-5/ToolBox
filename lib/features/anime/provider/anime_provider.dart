import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/local_storage.dart';
import '../model/anime.dart';
import '../service/anime_service.dart';

// ==========================================
// 1. Search Query State
// ==========================================
class AnimeSearchState {
  final String keyword;
  final bool isLoading;
  final List<AnimeSearchItem> results;
  final String? error;

  AnimeSearchState({
    this.keyword = '',
    this.isLoading = false,
    this.results = const [],
    this.error,
  });

  AnimeSearchState copyWith({
    String? keyword,
    bool? isLoading,
    List<AnimeSearchItem>? results,
    String? error,
  }) {
    return AnimeSearchState(
      keyword: keyword ?? this.keyword,
      isLoading: isLoading ?? this.isLoading,
      results: results ?? this.results,
      error: error, // allows setting to null
    );
  }
}

class AnimeSearchNotifier extends StateNotifier<AnimeSearchState> {
  final AnimeService _service;

  AnimeSearchNotifier(this._service) : super(AnimeSearchState());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;
    state = state.copyWith(keyword: query, isLoading: true, error: null);
    try {
      final results = await _service.searchAnime(query);
      state = state.copyWith(isLoading: false, results: results);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearSearch() {
    state = AnimeSearchState();
  }
}

final animeSearchProvider =
    StateNotifierProvider<AnimeSearchNotifier, AnimeSearchState>((ref) {
  final service = ref.watch(animeServiceProvider);
  return AnimeSearchNotifier(service);
});

// ==========================================
// 2. Search History State (Local Persistence)
// ==========================================
class AnimeSearchHistoryNotifier extends StateNotifier<List<String>> {
  final LocalStorageService _storage;
  static const String _historyKey = 'anime_search_history_list';

  AnimeSearchHistoryNotifier(this._storage) : super([]) {
    _loadHistory();
  }

  void _loadHistory() {
    try {
      final list = _storage.getStringList(_historyKey);
      if (list != null) {
        state = list;
      }
    } catch (_) {}
  }

  Future<void> addQuery(String q) async {
    final query = q.trim();
    if (query.isEmpty) return;

    final list = List<String>.from(state);
    list.remove(query);
    list.insert(0, query);

    // Limit to max 10 history items
    if (list.length > 10) {
      list.removeLast();
    }

    state = list;
    try {
      await _storage.setStringList(_historyKey, list);
    } catch (_) {}
  }

  Future<void> clearHistory() async {
    state = [];
    try {
      await _storage.remove(_historyKey);
    } catch (_) {}
  }
}

final animeSearchHistoryProvider =
    StateNotifierProvider<AnimeSearchHistoryNotifier, List<String>>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return AnimeSearchHistoryNotifier(storage);
});

// ==========================================
// 3. Details & Episodes State
// ==========================================
class AnimeDetailState {
  final bool isLoading;
  final AnimeDetail? detail;
  final String? error;

  AnimeDetailState({
    this.isLoading = false,
    this.detail,
    this.error,
  });

  AnimeDetailState copyWith({
    bool? isLoading,
    AnimeDetail? detail,
    String? error,
  }) {
    return AnimeDetailState(
      isLoading: isLoading ?? this.isLoading,
      detail: detail ?? this.detail,
      error: error,
    );
  }
}

class AnimeDetailNotifier extends StateNotifier<AnimeDetailState> {
  final AnimeService _service;

  AnimeDetailNotifier(this._service) : super(AnimeDetailState());

  Future<void> loadDetail(String url) async {
    state = AnimeDetailState(isLoading: true);
    try {
      final detail = await _service.getAnimeDetail(url);
      if (detail != null) {
        state = AnimeDetailState(detail: detail);
      } else {
        state = AnimeDetailState(error: '无法获取详情数据，请重试');
      }
    } catch (e) {
      state = AnimeDetailState(error: e.toString());
    }
  }
}

final animeDetailProvider =
    StateNotifierProvider<AnimeDetailNotifier, AnimeDetailState>((ref) {
  final service = ref.watch(animeServiceProvider);
  return AnimeDetailNotifier(service);
});

// ==========================================
// 4. Watch History/Progress State (Cloud Sync)
// ==========================================
class AnimeHistoryNotifier extends StateNotifier<AsyncValue<List<AnimeProgress>>> {
  final AnimeService _service;

  AnimeHistoryNotifier(this._service) : super(const AsyncValue.loading()) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    state = const AsyncValue.loading();
    try {
      final list = await _service.getWatchProgress();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> syncProgress({
    required String animeId,
    required String animeTitle,
    String? coverUrl,
    required String animeUrl,
    required String episodeTitle,
    required String episodeUrl,
    required int episodeIndex,
    required int position,
    bool isCompleted = false,
    bool? inFavorites,
  }) async {
    try {
      final updated = await _service.syncWatchProgress(
        animeId: animeId,
        animeTitle: animeTitle,
        coverUrl: coverUrl,
        animeUrl: animeUrl,
        episodeTitle: episodeTitle,
        episodeUrl: episodeUrl,
        episodeIndex: episodeIndex,
        position: position,
        isCompleted: isCompleted,
        inFavorites: inFavorites,
      );

      if (updated != null && state.hasValue) {
        final list = List<AnimeProgress>.from(state.value!);
        list.removeWhere((item) => item.animeId == animeId);
        list.insert(0, updated);
        state = AsyncValue.data(list);
      }
    } catch (e) {
      debugPrint("syncProgress error: $e");
    }
  }
}

final animeHistoryProvider =
    StateNotifierProvider<AnimeHistoryNotifier, AsyncValue<List<AnimeProgress>>>((ref) {
  final service = ref.watch(animeServiceProvider);
  return AnimeHistoryNotifier(service);
});
