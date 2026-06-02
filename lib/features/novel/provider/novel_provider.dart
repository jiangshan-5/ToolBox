import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../model/novel_models.dart';
import '../service/novel_api_client.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_tts/flutter_tts.dart';

class NovelState {
  final List<ReadingProgress> bookshelf;
  final List<ReadingProgress> abyssBookshelf;
  final List<Book> searchResults;
  final ReadingProgress? currentBookProgress;
  final List<BookChapter> chapters;
  final BookChapter? currentChapter;
  final bool isBookshelfLoading;
  final bool isSearchLoading;
  final bool isContentLoading;
  final String? error;

  // TTS playback state
  final bool isTtsPlaying;
  final double ttsSpeed;
  final int? ttsTimerMinutes;
  final int ttsTimeRemainingSeconds;
  final int ttsHighlightCharIndex;

  // Ambient soundscapes mixer state
  final Map<String, double> ambientVolumes;
  final Map<String, bool> ambientActive;

  NovelState({
    this.bookshelf = const [],
    this.abyssBookshelf = const [],
    this.searchResults = const [],
    this.currentBookProgress,
    this.chapters = const [],
    this.currentChapter,
    this.isBookshelfLoading = false,
    this.isSearchLoading = false,
    this.isContentLoading = false,
    this.error,
    this.isTtsPlaying = false,
    this.ttsSpeed = 1.0,
    this.ttsTimerMinutes,
    this.ttsTimeRemainingSeconds = 0,
    this.ttsHighlightCharIndex = 0,
    this.ambientVolumes = const {'rain': 0.5, 'waves': 0.5, 'fire': 0.5},
    this.ambientActive = const {'rain': false, 'waves': false, 'fire': false},
  });

  NovelState copyWith({
    List<ReadingProgress>? bookshelf,
    List<ReadingProgress>? abyssBookshelf,
    List<Book>? searchResults,
    ReadingProgress? currentBookProgress,
    List<BookChapter>? chapters,
    BookChapter? currentChapter,
    bool? isBookshelfLoading,
    bool? isSearchLoading,
    bool? isContentLoading,
    String? error,
    bool? isTtsPlaying,
    double? ttsSpeed,
    int? ttsTimerMinutes,
    int? ttsTimeRemainingSeconds,
    int? ttsHighlightCharIndex,
    Map<String, double>? ambientVolumes,
    Map<String, bool>? ambientActive,
  }) {
    return NovelState(
      bookshelf: bookshelf ?? this.bookshelf,
      abyssBookshelf: abyssBookshelf ?? this.abyssBookshelf,
      searchResults: searchResults ?? this.searchResults,
      currentBookProgress: currentBookProgress ?? this.currentBookProgress,
      chapters: chapters ?? this.chapters,
      currentChapter: currentChapter ?? this.currentChapter,
      isBookshelfLoading: isBookshelfLoading ?? this.isBookshelfLoading,
      isSearchLoading: isSearchLoading ?? this.isSearchLoading,
      isContentLoading: isContentLoading ?? this.isContentLoading,
      error: error,
      isTtsPlaying: isTtsPlaying ?? this.isTtsPlaying,
      ttsSpeed: ttsSpeed ?? this.ttsSpeed,
      ttsTimerMinutes: ttsTimerMinutes ?? this.ttsTimerMinutes,
      ttsTimeRemainingSeconds: ttsTimeRemainingSeconds ?? this.ttsTimeRemainingSeconds,
      ttsHighlightCharIndex: ttsHighlightCharIndex ?? this.ttsHighlightCharIndex,
      ambientVolumes: ambientVolumes ?? this.ambientVolumes,
      ambientActive: ambientActive ?? this.ambientActive,
    );
  }
}

class NovelNotifier extends StateNotifier<NovelState> {
  final NovelApiClient _apiClient;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _ttsTimer;
  Timer? _sleepTimer;
  final FlutterTts _flutterTts = FlutterTts();
  int _ttsBaseIndex = 0;

  // Ambient soundscapes players
  final Map<String, AudioPlayer> _ambientPlayers = {};

  NovelNotifier(this._apiClient) : super(NovelState()) {
    _initAmbientPlayers();
    _initTts();
  }

  void _initTts() {
    _flutterTts.setLanguage("zh-CN");
    _flutterTts.setProgressHandler((String text, int start, int end, String word) {
      if (state.isTtsPlaying) {
        state = state.copyWith(ttsHighlightCharIndex: _ttsBaseIndex + start);
      }
    });

    _flutterTts.setCompletionHandler(() {
      if (state.isTtsPlaying) {
        _loadNextChapterForTts();
      }
    });

    _flutterTts.setErrorHandler((msg) {
      pauseTts();
    });
  }

  void _initAmbientPlayers() {
    final urls = {
      'rain': 'https://assets.mixkit.co/active_storage/sfx/2433/2433-84.wav',
      'waves': 'https://assets.mixkit.co/active_storage/sfx/2566/2566-84.wav',
      'fire': 'https://assets.mixkit.co/active_storage/sfx/2432/2432-84.wav',
    };
    urls.forEach((id, url) {
      try {
        final player = AudioPlayer();
        player.setLoopMode(LoopMode.one);
        player.setVolume(0.5);
        player.setUrl(url).catchError((_) => null);
        _ambientPlayers[id] = player;
      } catch (_) {}
    });
  }

  void clearSearchState() {
    state = state.copyWith(searchResults: [], error: null);
  }

  @override
  void dispose() {
    _ttsTimer?.cancel();
    _sleepTimer?.cancel();
    _audioPlayer.dispose();
    _flutterTts.stop();
    for (var player in _ambientPlayers.values) {
      player.stop().catchError((_) => null);
      player.dispose().catchError((_) => null);
    }
    super.dispose();
  }

  /// 1. Fetch bookshelf items
  Future<void> fetchBookshelf(bool inAbyss) async {
    state = state.copyWith(isBookshelfLoading: true, error: null);
    try {
      final list = await _apiClient.getBookshelf(inAbyss);
      if (inAbyss) {
        state = state.copyWith(abyssBookshelf: list, isBookshelfLoading: false);
      } else {
        state = state.copyWith(bookshelf: list, isBookshelfLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isBookshelfLoading: false, error: e.toString());
    }
  }

  /// 2. Search novels via real-time stream (with dynamic Web compatibility fallback)
  Future<void> search(String q, bool inAbyss) async {
    state = state.copyWith(isSearchLoading: true, error: null, searchResults: []);
    try {
      if (kIsWeb) {
        // Dynamic Fallback: Web environment has constraints on EventSource/SSE streams.
        // We gracefully fallback to standard one-shot HTTP fetch which works 100% on all browsers.
        final books = await _apiClient.searchNovels(q, inAbyss);
        state = state.copyWith(searchResults: books, isSearchLoading: false);
        return;
      }

      // Non-Web environments (Desktop & Mobile): Use premium Server-Sent Events (SSE) stream loading
      final stream = _apiClient.searchNovelsStream(q, inAbyss);
      await for (final books in stream) {
        final currentResults = List<Book>.from(state.searchResults);
        bool hasChanges = false;
        for (final book in books) {
          final bool exists = currentResults.any((b) =>
            b.title.trim() == book.title.trim() &&
            b.author.trim() == book.author.trim() &&
            b.sourceId == book.sourceId
          );
          if (!exists) {
            currentResults.add(book);
            hasChanges = true;
          }
        }
        if (hasChanges) {
          state = state.copyWith(searchResults: currentResults);
        }
      }
      state = state.copyWith(isSearchLoading: false);
    } catch (e) {
      state = state.copyWith(isSearchLoading: false, error: e.toString());
    }
  }

  /// 3. Add a searched book to shelf
  Future<Book?> addBookToShelf(Book book, bool inAbyss, {bool isTrial = false}) async {
    state = state.copyWith(isBookshelfLoading: true, error: null);
    try {
      final newBook = await _apiClient.addToBookshelf(
        title: book.title,
        author: book.author,
        coverUrl: book.coverUrl,
        summary: book.summary,
        sourceId: book.sourceId ?? book.currentSourceId ?? '',
        isAbyss: inAbyss,
        bookUrl: book.bookUrl ?? '',
        isTrial: isTrial,
      );
      // Refresh bookshelf
      await fetchBookshelf(inAbyss);
      return newBook;
    } catch (e) {
      state = state.copyWith(isBookshelfLoading: false, error: e.toString());
      return null;
    }
  }

  /// 3c. Remove books from shelf (Batch delete)
  Future<void> removeBooksFromShelf(List<String> bookIds, bool inAbyss) async {
    state = state.copyWith(isBookshelfLoading: true, error: null);
    try {
      await _apiClient.removeFromBookshelf(bookIds);
      // Refresh bookshelf
      await fetchBookshelf(inAbyss);
    } catch (e) {
      state = state.copyWith(isBookshelfLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// 3b. Add a book to shelf if not present, select it, and return its progress
  Future<ReadingProgress?> addAndSelectBook(Book book, bool inAbyss) async {
    // 1. Check if already in bookshelf
    final list = inAbyss ? state.abyssBookshelf : state.bookshelf;
    ReadingProgress? existing;
    for (final p in list) {
      if (p.book?.title == book.title && p.book?.author == book.author) {
        existing = p;
        break;
      }
    }
    
    if (existing != null) {
      final targetSourceId = book.sourceId ?? book.currentSourceId ?? '';
      final targetBookUrl = book.bookUrl ?? '';
      if (existing.book?.currentSourceId == targetSourceId && existing.book?.bookUrl == targetBookUrl) {
        await selectBook(existing);
        return existing;
      }
    }
    
    // 2. Add to shelf as trial preview
    final newBook = await addBookToShelf(book, inAbyss, isTrial: true);
    if (newBook != null) {
      final added = ReadingProgress(
        id: '',
        userId: '',
        bookId: newBook.id,
        lastReadChapterIndex: 0,
        lastReadCharOffset: 0,
        updatedAt: '',
        book: newBook,
      );
      await selectBook(added);
      return added;
    }
    return null;
  }

  /// Upgrade a trial book to a full bookshelf item
  Future<void> upgradeTrialBook(Book book, bool inAbyss) async {
    state = state.copyWith(isBookshelfLoading: true, error: null);
    try {
      final newBook = await _apiClient.addToBookshelf(
        title: book.title,
        author: book.author,
        coverUrl: book.coverUrl,
        summary: book.summary,
        sourceId: book.sourceId ?? book.currentSourceId ?? '',
        isAbyss: inAbyss,
        bookUrl: book.bookUrl ?? '',
        isTrial: false,
      );
      // Refresh bookshelf
      await fetchBookshelf(inAbyss);
      // Upgrade local progress reference
      final updatedList = inAbyss ? state.abyssBookshelf : state.bookshelf;
      ReadingProgress? upgraded;
      for (final p in updatedList) {
        if (p.bookId == newBook.id) {
          upgraded = p;
          break;
        }
      }
      if (upgraded != null) {
        state = state.copyWith(currentBookProgress: upgraded);
      }
    } catch (e) {
      state = state.copyWith(isBookshelfLoading: false, error: e.toString());
    }
  }

  /// Import local EPUB or TXT file to database bookshelf
  Future<void> importBookFile(String filePath, String fileName, bool inAbyss) async {
    state = state.copyWith(isBookshelfLoading: true, error: null);
    try {
      await _apiClient.importBookFile(filePath: filePath, fileName: fileName);
      await fetchBookshelf(inAbyss);
    } catch (e) {
      state = state.copyWith(isBookshelfLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// 4. Load book details: Chapter list and set current book progress
  Future<void> selectBook(ReadingProgress progress) async {
    state = state.copyWith(
      currentBookProgress: progress,
      chapters: [],
      currentChapter: null,
      error: null,
    );
    await loadChapters(progress.bookId);
  }

  Future<void> loadChapters(String bookId) async {
    state = state.copyWith(isContentLoading: true, error: null);
    try {
      final chs = await _apiClient.getBookChapters(bookId);
      state = state.copyWith(chapters: chs, isContentLoading: false);
      if (chs.isNotEmpty) {
        final progress = state.currentBookProgress;
        int targetIdx = progress?.lastReadChapterIndex ?? 0;
        bool exists = chs.any((c) => c.chapterIndex == targetIdx);
        if (!exists) {
          targetIdx = chs.first.chapterIndex;
        }
        await loadChapterContent(bookId, targetIdx);
      }
    } catch (e) {
      state = state.copyWith(isContentLoading: false, error: e.toString());
    }
  }

  /// 5. Load chapter content
  Future<void> loadChapterContent(String bookId, int chapterIndex) async {
    state = state.copyWith(isContentLoading: true, error: null);
    try {
      final chap = await _apiClient.getChapterContent(bookId, chapterIndex);
      
      // Also update local state progress
      if (state.currentBookProgress != null) {
        final updatedProgress = state.currentBookProgress!.copyWith(
          lastReadChapterIndex: chapterIndex,
          lastReadCharOffset: 0,
        );
        
        // Save state
        state = state.copyWith(
          currentChapter: chap,
          currentBookProgress: updatedProgress,
          isContentLoading: false,
          ttsHighlightCharIndex: 0,
        );

        // Silent backend update
        _apiClient.updateReadingProgress(
          bookId: bookId,
          chapterIndex: chapterIndex,
          charOffset: 0,
        ).ignore();

        // 🚀 方案 C：智能静默后台并发预加载后续 3 章节，后端提前预下载清洗，持久化存入 PostgreSQL 缓存
        for (int i = 1; i <= 3; i++) {
          final nextIdx = chapterIndex + i;
          final hasNext = state.chapters.any((c) => c.chapterIndex == nextIdx);
          if (hasNext) {
            _apiClient.getChapterContent(bookId, nextIdx).ignore();
          }
        }
      } else {
        state = state.copyWith(currentChapter: chap, isContentLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isContentLoading: false, error: e.toString());
    }
  }

  /// 6. Save reading progress
  Future<void> saveProgress(int charOffset) async {
    final curProg = state.currentBookProgress;
    if (curProg == null) return;
    try {
      final updated = curProg.copyWith(lastReadCharOffset: charOffset);
      state = state.copyWith(currentBookProgress: updated);
      
      await _apiClient.updateReadingProgress(
        bookId: curProg.bookId,
        chapterIndex: curProg.lastReadChapterIndex,
        charOffset: charOffset,
      );
    } catch (e) {
      // Silent error
    }
  }

  /// 7. Trigger silent sync of abyss chamber sources
  Future<bool> syncAbyss() async {
    try {
      final res = await _apiClient.syncAbyssSources();
      if (res['status'] == 'success') {
        await fetchBookshelf(true);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 8. Export EPUB file helper
  Future<Uint8List> downloadEpub(String bookId) async {
    return await _apiClient.exportEpub(bookId);
  }

  // ==========================================
  // 🎙️ TTS Audio Player & Word Highlighter Logic
  // ==========================================

  // Ambient soundscapes control methods
  void toggleAmbient(String id) {
    final currentActive = Map<String, bool>.from(state.ambientActive);
    final isActive = !(currentActive[id] ?? false);
    currentActive[id] = isActive;
    state = state.copyWith(ambientActive: currentActive);

    final player = _ambientPlayers[id];
    if (player != null) {
      if (isActive) {
        final baseVol = state.ambientVolumes[id] ?? 0.5;
        final vol = state.isTtsPlaying ? baseVol * 0.35 : baseVol;
        player.setVolume(vol).catchError((_) => null);
        player.play().catchError((_) => null);
      } else {
        player.pause().catchError((_) => null);
      }
    }
  }

  void setAmbientVolume(String id, double volume) {
    final currentVolumes = Map<String, double>.from(state.ambientVolumes);
    currentVolumes[id] = volume;
    state = state.copyWith(ambientVolumes: currentVolumes);

    final player = _ambientPlayers[id];
    if (player != null && (state.ambientActive[id] ?? false)) {
      final vol = state.isTtsPlaying ? volume * 0.35 : volume;
      player.setVolume(vol).catchError((_) => null);
    }
  }

  void _applyDucking(bool isDucked) {
    _ambientPlayers.forEach((id, player) {
      if (state.ambientActive[id] ?? false) {
        final baseVol = state.ambientVolumes[id] ?? 0.5;
        final vol = isDucked ? baseVol * 0.35 : baseVol;
        player.setVolume(vol).catchError((_) => null);
      }
    });
  }

  void pauseAllAudio() {
    pauseTts();
    _ambientPlayers.forEach((id, player) {
      player.pause().catchError((_) => null);
    });
    final resetActive = {'rain': false, 'waves': false, 'fire': false};
    state = state.copyWith(ambientActive: resetActive);
  }

  void startTts() async {
    if (state.currentChapter == null || state.currentChapter!.content == null) return;
    _ttsTimer?.cancel();
    
    try {
      state = state.copyWith(isTtsPlaying: true);
      _applyDucking(true); // Apply Ducking to active ambient players!
      
      _ttsBaseIndex = state.ttsHighlightCharIndex;
      final text = state.currentChapter!.content!;
      final speakText = text.substring(_ttsBaseIndex);

      if (speakText.trim().isNotEmpty) {
        await _flutterTts.setSpeechRate(state.ttsSpeed * 0.5); // standard speed is 0.5 for flutter_tts
        await _flutterTts.speak(speakText);
      } else {
        // Empty content, load next chapter
        _loadNextChapterForTts();
      }
    } catch (e) {
      // Audio engine error fallback: fallback to mock timer
      _startMockTtsTimer();
    }
  }

  void _startMockTtsTimer() {
    final baseIntervalMs = (200 / state.ttsSpeed).round(); // ms per character roughly
    _ttsTimer = Timer.periodic(Duration(milliseconds: baseIntervalMs), (timer) {
      if (!state.isTtsPlaying) {
        timer.cancel();
        return;
      }
      final contentLen = state.currentChapter!.content!.length;
      if (state.ttsHighlightCharIndex >= contentLen - 1) {
        timer.cancel();
        _loadNextChapterForTts();
      } else {
        final nextIndex = state.ttsHighlightCharIndex + 1;
        state = state.copyWith(ttsHighlightCharIndex: nextIndex);
        if (nextIndex % 50 == 0) {
          saveProgress(nextIndex);
        }
      }
    });
  }

  void pauseTts() {
    _ttsTimer?.cancel();
    _flutterTts.stop();
    state = state.copyWith(isTtsPlaying: false);
    _applyDucking(false); // Restore full volume!
  }

  void setTtsSpeed(double speed) async {
    state = state.copyWith(ttsSpeed: speed);
    if (state.isTtsPlaying) {
      await _flutterTts.stop();
      startTts();
    }
  }

  void setTtsHighlightIndex(int index) async {
    if (state.currentChapter == null || state.currentChapter!.content == null) return;
    final len = state.currentChapter!.content!.length;
    final target = index.clamp(0, len - 1);
    state = state.copyWith(ttsHighlightCharIndex: target);
    saveProgress(target);
    
    if (state.isTtsPlaying) {
      await _flutterTts.stop();
      startTts();
    }
  }

  void setTtsTimer(int? minutes) {
    _sleepTimer?.cancel();
    if (minutes == null) {
      state = state.copyWith(ttsTimerMinutes: null, ttsTimeRemainingSeconds: 0);
      return;
    }
    
    state = state.copyWith(
      ttsTimerMinutes: minutes,
      ttsTimeRemainingSeconds: minutes * 60,
    );

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.ttsTimeRemainingSeconds <= 1) {
        timer.cancel();
        pauseTts();
        state = state.copyWith(ttsTimerMinutes: null, ttsTimeRemainingSeconds: 0);
      } else {
        state = state.copyWith(
          ttsTimeRemainingSeconds: state.ttsTimeRemainingSeconds - 1,
        );
      }
    });
  }

  void _loadNextChapterForTts() async {
    final curProg = state.currentBookProgress;
    if (curProg == null) return;
    final nextIndex = curProg.lastReadChapterIndex + 1;
    final totalChapters = state.chapters.length;
    
    // Check if next chapter is available in our loaded list
    final hasNext = state.chapters.any((c) => c.chapterIndex == nextIndex);
    if (hasNext) {
      await loadChapterContent(curProg.bookId, nextIndex);
      startTts();
    } else {
      pauseTts();
    }
  }

  /// 9. Direct import book sources from URL or JSON
  Future<Map<String, dynamic>> importBookSources({
    String? url,
    List<dynamic>? jsonData,
  }) async {
    try {
      final res = await _apiClient.importBookSources(url: url, jsonData: jsonData);
      return res;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

/// Riverpod provider for NovelNotifier
final novelProvider = StateNotifierProvider<NovelNotifier, NovelState>((ref) {
  final apiClient = ref.watch(novelApiClientProvider);
  return NovelNotifier(apiClient);
});
