import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../auth/provider/auth_provider.dart';
import '../model/novel_models.dart';

class NovelApiClient {
  final ApiClient _apiClient;
  static String? lastFailoverSource;

  NovelApiClient(this._apiClient);

  /// 1. Search novels
  Future<List<Book>> searchNovels(String q, bool inAbyss) async {
    try {
      final response = await _apiClient.instance.get(
        '/novel/search',
        queryParameters: {
          'q': q,
          'in_abyss': inAbyss,
        },
        options: Options(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      final List<dynamic> data = response.data ?? [];
      return data.map((json) => Book.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// 1b. Search novels via SSE stream
  Stream<List<Book>> searchNovelsStream(String q, bool inAbyss) async* {
    try {
      final response = await _apiClient.instance.get<ResponseBody>(
        '/novel/search/stream',
        queryParameters: {
          'q': q,
          'in_abyss': inAbyss,
        },
        options: Options(
          responseType: ResponseType.stream,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      final transformer = StreamTransformer<Uint8List, String>.fromHandlers(
        handleData: (data, sink) {
          sink.add(utf8.decode(data));
        },
      );

      String buffer = '';
      await for (final chunk in response.data!.stream.transform(transformer)) {
        buffer += chunk;
        final lines = buffer.split('\n\n');
        buffer = lines.last; // retain unfinished buffer
        for (int i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();
          if (line.startsWith('data:')) {
            final jsonStr = line.substring(5).trim();
            if (jsonStr.isNotEmpty) {
              try {
                final List<dynamic> list = jsonDecode(jsonStr);
                final books = list.map((json) => Book.fromJson(json)).toList();
                yield books;
              } catch (_) {}
            }
          }
        }
      }

      // Process remaining buffer
      if (buffer.trim().startsWith('data:')) {
        final jsonStr = buffer.trim().substring(5).trim();
        if (jsonStr.isNotEmpty) {
          try {
            final List<dynamic> list = jsonDecode(jsonStr);
            yield list.map((json) => Book.fromJson(json)).toList();
          } catch (_) {}
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 2. Silent sync abyss sources
  Future<Map<String, dynamic>> syncAbyssSources() async {
    try {
      final response = await _apiClient.instance.get('/novel/abyss/sync');
      return response.data ?? {};
    } catch (e) {
      rethrow;
    }
  }

  /// 3. Add to bookshelf
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
    try {
      final response = await _apiClient.instance.post(
        '/novel/bookshelf/add',
        data: {
          'title': title,
          'author': author,
          'cover_url': coverUrl,
          'summary': summary,
          'source_id': sourceId,
          'is_abyss': isAbyss,
          'book_url': bookUrl,
          'is_trial': isTrial,
        },
      );
      return Book.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// 4. Get bookshelf items (ReadingProgress list)
  Future<List<ReadingProgress>> getBookshelf(bool inAbyss) async {
    try {
      final response = await _apiClient.instance.get(
        '/novel/bookshelf',
        queryParameters: {'in_abyss': inAbyss},
      );
      final List<dynamic> data = response.data ?? [];
      return data.map((json) => ReadingProgress.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// 5. Get book chapters (TOC)
  Future<List<BookChapter>> getBookChapters(String bookId, {bool forceRefresh = false}) async {
    try {
      lastFailoverSource = null;
      final response = await _apiClient.instance.get(
        '/novel/chapters',
        queryParameters: {
          'book_id': bookId,
          'force_refresh': forceRefresh,
        },
      );
      final headerVal = response.headers.value('X-Failover-Source');
      if (headerVal != null && headerVal.isNotEmpty) {
        lastFailoverSource = headerVal;
      }
      final List<dynamic> data = response.data ?? [];
      return data.map((json) => BookChapter.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// 6. Get chapter content
  Future<BookChapter> getChapterContent(String bookId, int chapterIndex) async {
    try {
      lastFailoverSource = null;
      final response = await _apiClient.instance.get(
        '/novel/content',
        queryParameters: {
          'book_id': bookId,
          'chapter_index': chapterIndex,
        },
      );
      final headerVal = response.headers.value('X-Failover-Source');
      if (headerVal != null && headerVal.isNotEmpty) {
        lastFailoverSource = headerVal;
      }
      return BookChapter.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// 7. Update reading progress
  Future<ReadingProgress> updateReadingProgress({
    required String bookId,
    required int chapterIndex,
    required int charOffset,
  }) async {
    try {
      final response = await _apiClient.instance.post(
        '/novel/progress',
        data: {
          'book_id': bookId,
          'last_read_chapter_index': chapterIndex,
          'last_read_char_offset': charOffset,
        },
      );
      return ReadingProgress.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// 8. Export EPUB stream bytes
  Future<Uint8List> exportEpub(String bookId) async {
    try {
      final response = await _apiClient.instance.get<List<int>>(
        '/novel/export',
        queryParameters: {'book_id': bookId},
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data ?? []);
    } catch (e) {
      rethrow;
    }
  }

  /// 9. Remove from bookshelf (Batch delete)
  Future<void> removeFromBookshelf(List<String> bookIds) async {
    try {
      await _apiClient.instance.post(
        '/novel/bookshelf/remove',
        data: {
          'book_ids': bookIds,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 10. Direct import book sources from URL or JSON data
  Future<Map<String, dynamic>> importBookSources({
    String? url,
    List<dynamic>? jsonData,
  }) async {
    try {
      final response = await _apiClient.instance.post(
        '/novel/sources/import',
        data: {
          if (url != null) 'url': url,
          if (jsonData != null) 'json_data': jsonData,
        },
      );
      return response.data ?? {};
    } catch (e) {
      rethrow;
    }
  }

  /// 11. Import local book (TXT/EPUB parsed content)
  Future<Book> importLocalBook({
    required String title,
    required String author,
    String? summary,
    String? coverUrl,
    required List<Map<String, String>> chapters,
  }) async {
    try {
      final response = await _apiClient.instance.post(
        '/novel/bookshelf/import-local',
        data: {
          'title': title,
          'author': author,
          if (summary != null) 'summary': summary,
          if (coverUrl != null) 'cover_url': coverUrl,
          'chapters': chapters,
        },
      );
      return Book.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// 12. Upload and import local EPUB or TXT file
  Future<Book> importBookFile({
    required String filePath,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      final response = await _apiClient.instance.post(
        '/novel/bookshelf/import-file',
        data: formData,
      );
      return Book.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}

/// Riverpod provider for NovelApiClient
final novelApiClientProvider = Provider<NovelApiClient>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NovelApiClient(apiClient);
});
