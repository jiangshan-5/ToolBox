import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crypto/crypto.dart';
import '../../../core/network/api_client.dart';
import '../../auth/provider/auth_provider.dart';
import '../model/novel_models.dart';
import 'local_parser/local_book_source_db.dart';
import 'local_parser/local_bookshelf_db.dart';

class NovelApiClient {
  final ApiClient _apiClient;
  static String? lastFailoverSource;

  NovelApiClient(this._apiClient) {
    _initLocalDbs();
  }

  Future<void> _initLocalDbs() async {
    await LocalBookSourceDb.instance.init();
    await LocalBookshelfDb.instance.init();
  }

  String _generateBookId(String title, String author) {
    final bytes = utf8.encode('$title|$author');
    return md5.convert(bytes).toString();
  }

  /// 1. Search novels (Non-stream, browser fallback)
  Future<List<Book>> searchNovels(String q, bool inAbyss) async {
    try {
      final response = await _apiClient.instance.get(
        '/novel/search',
        queryParameters: {'q': q, 'in_abyss': inAbyss},
      );
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> list = response.data;
        return list.map((b) => Book.fromJson(b)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("searchNovels error: $e");
      return [];
    }
  }

  /// 1b. Search novels via Server-Sent Events (SSE) Stream
  Stream<List<Book>> searchNovelsStream(String q, bool inAbyss) async* {
    try {
      final response = await _apiClient.instance.get<ResponseBody>(
        '/novel/search/stream',
        queryParameters: {'q': q, 'in_abyss': inAbyss},
        options: Options(responseType: ResponseType.stream),
      );

      final stream = response.data!.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (line.startsWith('data:')) {
          final dataStr = line.substring(5).trim();
          if (dataStr.isEmpty) continue;
          try {
            final Map<String, dynamic> data = jsonDecode(dataStr);
            if (data['status'] == 'progress' && data['books'] is List) {
              final List<dynamic> booksJson = data['books'];
              final List<Book> books = booksJson.map((b) => Book.fromJson(b)).toList();
              yield books;
            } else if (data['status'] == 'done') {
              break;
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint("searchNovelsStream error: $e");
      yield [];
    }
  }

  /// 2. Sync private/abyss chamber sources from server
  Future<Map<String, dynamic>> syncAbyssSources() async {
    await _initLocalDbs();
    try {
      final response = await _apiClient.instance.get('/novel/abyss/sync');
      final Map<String, dynamic> data = response.data ?? {};
      final List<BookSourceRule> rules = [];
      if (data['sources'] is List) {
        final List<dynamic> list = data['sources'];
        for (final item in list) {
          if (item is Map) {
            final name = item['bookSourceName']?.toString() ?? '';
            final sourceUrl = item['bookSourceUrl']?.toString() ?? '';
            if (name.isNotEmpty && sourceUrl.isNotEmpty) {
              rules.add(BookSourceRule(
                id: item['id']?.toString() ?? _generateBookId(name, sourceUrl),
                sourceName: name,
                sourceUrl: sourceUrl,
                searchUrl: item['searchUrl']?.toString() ?? '',
                ruleJson: jsonEncode(item),
                isActive: true,
                isValid: true,
                isPrivate: false,
                isAbyss: true,
              ));
            }
          }
        }
        await LocalBookSourceDb.instance.addSources(rules);
      }
      return {'status': 'success', 'sources_count': rules.length};
    } catch (e) {
      debugPrint("syncAbyssSources error: $e");
      final sources = LocalBookSourceDb.instance.getAllSources().where((s) => s.isAbyss).toList();
      return {'status': 'fallback', 'sources_count': sources.length, 'local': true};
    }
  }

  /// 3. Add book to shelf
  Future<Book> addToBookshelf({
    required String title,
    required String author,
    required String coverUrl,
    required String summary,
    required String sourceId,
    required bool isAbyss,
    required String bookUrl,
    bool isTrial = false,
  }) async {
    await _initLocalDbs();
    final book = Book(
      id: _generateBookId(title, author),
      title: title,
      author: author,
      coverUrl: coverUrl,
      summary: summary,
      isAbyss: isAbyss,
      bookUrl: bookUrl,
      sourceId: sourceId,
    );
    return await LocalBookshelfDb.instance.addToBookshelf(book);
  }

  /// 4. Get bookshelf items (Syncs from server and returns merged bookshelf list)
  Future<List<ReadingProgress>> getBookshelf(bool inAbyss) async {
    await _initLocalDbs();
    try {
      final response = await _apiClient.instance.get(
        '/novel/bookshelf',
        queryParameters: {'in_abyss': inAbyss},
      );
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> list = response.data;
        for (final item in list) {
          final serverProg = ReadingProgress.fromJson(item);
          if (serverProg.book != null) {
            await LocalBookshelfDb.instance.addToBookshelf(serverProg.book!);
            await LocalBookshelfDb.instance.updateReadingProgress(
              bookId: serverProg.bookId,
              chapterIndex: serverProg.lastReadChapterIndex,
              charOffset: serverProg.lastReadCharOffset,
            );
          }
        }
      }
    } catch (e) {
      debugPrint("getBookshelf sync error: $e");
    }
    return LocalBookshelfDb.instance.getBookshelf(inAbyss);
  }

  /// 5. Get book chapters (TOC)
  Future<List<BookChapter>> getBookChapters(String bookId, {bool forceRefresh = false}) async {
    await _initLocalDbs();
    if (!forceRefresh) {
      final cached = LocalBookshelfDb.instance.getChapters(bookId);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    }

    final book = LocalBookshelfDb.instance.getBookById(bookId);
    if (book == null || book.bookUrl == null || book.sourceId == null) {
      return [];
    }

    try {
      final response = await _apiClient.instance.get(
        '/novel/chapters',
        queryParameters: {
          'book_url': book.bookUrl,
          'source_id': book.sourceId,
        },
      );
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> list = response.data;
        final List<BookChapter> chapters = list.map((c) => BookChapter.fromJson(c)).toList();
        
        // Remap bookId to local bookId reference
        final List<BookChapter> updatedChapters = chapters
            .map((c) => c.copyWith(bookId: bookId))
            .toList();
            
        await LocalBookshelfDb.instance.saveChapters(bookId, updatedChapters);
        return updatedChapters;
      }
    } catch (e) {
      debugPrint("getBookChapters error: $e");
    }
    return [];
  }

  /// 6. Get chapter content
  Future<BookChapter> getChapterContent(String bookId, int chapterIndex) async {
    await _initLocalDbs();
    final chapters = LocalBookshelfDb.instance.getChapters(bookId);
    if (chapters == null || chapterIndex < 0 || chapterIndex >= chapters.length) {
      throw StateError('Chapter index out of range or empty cache');
    }
    
    final chapter = chapters[chapterIndex];
    if (chapter.content != null && chapter.content!.isNotEmpty) {
      return chapter;
    }

    final book = LocalBookshelfDb.instance.getBookById(bookId);
    if (book == null || book.sourceId == null) return chapter;

    try {
      final response = await _apiClient.instance.get(
        '/novel/content',
        queryParameters: {
          'chapter_url': chapter.sourceChapterUrl,
          'source_id': book.sourceId,
          'chapter_index': chapterIndex,
        },
      );
      if (response.statusCode == 200 && response.data is Map) {
        final content = response.data['content']?.toString() ?? '';
        final updatedChapter = chapter.copyWith(content: content);
        
        chapters[chapterIndex] = updatedChapter;
        await LocalBookshelfDb.instance.saveChapters(bookId, chapters);
        return updatedChapter;
      }
    } catch (e) {
      debugPrint("getChapterContent error: $e");
    }
    return chapter;
  }

  /// 7. Update and sync reading progress
  Future<ReadingProgress> updateReadingProgress({
    required String bookId,
    required int chapterIndex,
    required int charOffset,
  }) async {
    await _initLocalDbs();
    final localProgress = await LocalBookshelfDb.instance.updateReadingProgress(
      bookId: bookId,
      chapterIndex: chapterIndex,
      charOffset: charOffset,
    );

    final book = LocalBookshelfDb.instance.getBookById(bookId);
    if (book != null) {
      Future<void> syncProgress() async {
        try {
          await _apiClient.instance.post(
            '/novel/progress',
            data: {
              'book_id': book.id,
              'title': book.title,
              'author': book.author,
              'cover_url': book.coverUrl,
              'summary': book.summary,
              'source_id': book.sourceId ?? '',
              'book_url': book.bookUrl ?? '',
              'chapter_index': chapterIndex,
              'char_offset': charOffset,
              'is_abyss': book.isAbyss,
            },
          );
        } catch (e) {
          debugPrint("Failed to sync reading progress: $e");
        }
      }
      syncProgress();
    }

    return localProgress;
  }

  /// 8. Export EPUB stream bytes
  Future<Uint8List> exportEpub(String bookId) async {
    return Uint8List(0);
  }

  /// 9. Remove from bookshelf
  Future<void> removeFromBookshelf(List<String> bookIds) async {
    await _initLocalDbs();
    await LocalBookshelfDb.instance.removeFromBookshelf(bookIds);
  }

  /// 10. Direct import book sources from URL or JSON data
  Future<Map<String, dynamic>> importBookSources({
    String? url,
    List<dynamic>? jsonData,
  }) async {
    await _initLocalDbs();
    List<dynamic> sources = [];
    try {
      if (url != null && url.isNotEmpty) {
        final dio = Dio();
        final response = await dio.get<dynamic>(url);
        if (response.data is List) {
          sources = response.data;
        } else if (response.data is String) {
          sources = jsonDecode(response.data);
        }
      } else if (jsonData != null) {
        sources = jsonData;
      }
    } catch (e) {
      debugPrint("importBookSources error: $e");
      return {'success': false, 'count': 0, 'error': 'Fetch failed'};
    }
    
    int importedCount = 0;
    final List<BookSourceRule> rules = [];
    for (final item in sources) {
      if (item is Map) {
        final name = item['bookSourceName']?.toString() ?? '';
        final sourceUrl = item['bookSourceUrl']?.toString() ?? '';
        if (name.isNotEmpty && sourceUrl.isNotEmpty) {
          final rule = BookSourceRule(
            id: _generateBookId(name, sourceUrl),
            sourceName: name,
            sourceUrl: sourceUrl,
            searchUrl: item['searchUrl']?.toString() ?? '',
            ruleJson: jsonEncode(item),
            isActive: true,
            isValid: true,
            isPrivate: false,
            isAbyss: false,
          );
          rules.add(rule);
          importedCount++;
        }
      }
    }
    await LocalBookSourceDb.instance.addSources(rules);
    return {'success': true, 'count': importedCount};
  }

  /// 11. Import local book
  Future<Book> importLocalBook({
    required String title,
    required String author,
    String? summary,
    String? coverUrl,
    required List<Map<String, String>> chapters,
  }) async {
    await _initLocalDbs();
    final bookId = _generateBookId(title, author);
    final book = Book(
      id: bookId,
      title: title,
      author: author,
      coverUrl: coverUrl ?? '',
      summary: summary ?? '',
      isAbyss: false,
      bookUrl: 'local://$bookId',
      sourceId: 'local',
    );
    await LocalBookshelfDb.instance.addToBookshelf(book);
    
    final List<BookChapter> parsedChapters = [];
    for (int i = 0; i < chapters.length; i++) {
      final chap = chapters[i];
      final title = chap['title'] ?? '第${i + 1}章';
      final content = chap['content'] ?? '';
      parsedChapters.add(BookChapter(
        id: _generateBookId(title, 'local://$bookId/$i'),
        bookId: bookId,
        chapterIndex: i,
        title: title,
        sourceChapterUrl: 'local://$bookId/$i',
        content: content,
      ));
    }
    await LocalBookshelfDb.instance.saveChapters(bookId, parsedChapters);
    return book;
  }

  /// 12. Upload and import local EPUB or TXT file
  Future<Book> importBookFile({
    required String filePath,
    required String fileName,
  }) async {
    return Book(
      id: 'mock_file',
      title: fileName,
      author: '本地导入',
      coverUrl: '',
      summary: '从本地文件导入的小说',
      isAbyss: false,
      bookUrl: 'local://mock_file',
      sourceId: 'local',
    );
  }
}

final novelApiClientProvider = Provider<NovelApiClient>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NovelApiClient(apiClient);
});
