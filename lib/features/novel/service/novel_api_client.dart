import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crypto/crypto.dart';
import '../../../core/network/api_client.dart';
import '../../auth/provider/auth_provider.dart';
import '../model/novel_models.dart';
import 'local_parser/local_book_source_db.dart';
import 'local_parser/local_bookshelf_db.dart';
import 'local_parser/local_parser_engine.dart';
import 'local_parser/local_jsonpath_parser.dart';

class SearchUrlOptions {
  final String cleanUrl;
  final String method;
  final Map<String, String> headers;
  final dynamic body;
  final String charset;
  SearchUrlOptions(this.cleanUrl, this.method, this.headers, this.body, this.charset);
}

class NovelApiClient {
  final ApiClient _apiClient;
  static String? lastFailoverSource;
  
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    followRedirects: true,
  ));

  NovelApiClient(this._apiClient) {
    // Make sure databases are initialized on client startup
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

  String _decodeContent(List<int> bytes, Map<String, dynamic> headers) {
    if (bytes.isEmpty) return '';
    
    // Check inte_base64 prefix
    if (bytes.length > 12) {
      try {
        final prefix = String.fromCharCodes(bytes.sublist(0, 12));
        if (prefix == 'inte_base64:') {
          final wrapperText = utf8.decode(bytes.sublist(12));
          final payload = jsonDecode(wrapperText);
          if (payload['c'] != null) {
            bytes = base64.decode(payload['c'].toString());
          }
        }
      } catch (_) {}
    }
    
    try {
      return utf8.decode(bytes);
    } catch (_) {
      try {
        return latin1.decode(bytes);
      } catch (_) {
        return String.fromCharCodes(bytes);
      }
    }
  }

  SearchUrlOptions _parseSearchUrlOptions(String searchUrl) {
    var urlPart = searchUrl;
    String method = 'GET';
    Map<String, String> headers = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    };
    dynamic body;
    String charset = 'utf-8';
    
    if (searchUrl.contains(',')) {
      final idx = searchUrl.indexOf(',');
      final candidateUrl = searchUrl.substring(0, idx).trim();
      final jsonPart = searchUrl.substring(idx + 1).trim();
      if (jsonPart.startsWith('{')) {
        try {
          final options = jsonDecode(jsonPart);
          urlPart = candidateUrl;
          method = (options['method']?.toString() ?? 'GET').toUpperCase();
          charset = options['charset']?.toString()?.toLowerCase() ?? 'utf-8';
          if (options['headers'] is Map) {
            (options['headers'] as Map).forEach((k, v) {
              headers[k.toString()] = v.toString();
            });
          }
          body = options['body'];
        } catch (_) {}
      }
    }
    return SearchUrlOptions(urlPart, method, headers, body, charset);
  }

  /// 1. Search novels
  Future<List<Book>> searchNovels(String q, bool inAbyss) async {
    final List<Book> results = [];
    await for (final chunk in searchNovelsStream(q, inAbyss)) {
      results.addAll(chunk);
    }
    return results;
  }

  /// 1b. Search novels via Stream (Incremental yield)
  Stream<List<Book>> searchNovelsStream(String q, bool inAbyss) async* {
    await _initLocalDbs();
    final sources = LocalBookSourceDb.instance.getAllSources()
        .where((s) => s.isActive && s.isAbyss == inAbyss)
        .toList();
    
    if (sources.isEmpty) {
      yield [];
      return;
    }

    for (final source in sources) {
      try {
        final Map<String, dynamic> ruleJson = jsonDecode(source.ruleJson);
        final searchUrlRule = source.searchUrl.isNotEmpty ? source.searchUrl : ruleJson['searchUrl']?.toString() ?? '';
        if (searchUrlRule.isEmpty) continue;

        final opts = _parseSearchUrlOptions(searchUrlRule);
        
        // URL encode the query based on source charset (normally utf-8 or gbk)
        // Since Dart natively encodes Uri components as UTF-8, we default to UTF-8.
        final encodedQuery = Uri.encodeComponent(q);
        
        var testUrl = opts.cleanUrl
            .replaceAll('{{key}}', encodedQuery)
            .replaceAll('{key}', encodedQuery)
            .replaceAll('{{page}}', '1')
            .replaceAll('{page}', '1');
            
        if (testUrl.contains('%s')) {
          testUrl = testUrl.replaceAll('%s', encodedQuery);
        }

        if (!testUrl.startsWith('http')) {
          testUrl = Uri.parse(source.sourceUrl).resolve(testUrl).toString();
        }

        Response<List<int>> response;
        if (opts.method == 'POST') {
          dynamic bodyData = opts.body;
          if (bodyData is String) {
            bodyData = bodyData
                .replaceAll('{{key}}', q)
                .replaceAll('{key}', q)
                .replaceAll('{{page}}', '1')
                .replaceAll('{page}', '1');
          } else if (bodyData is Map) {
            final Map<String, dynamic> cloned = Map.from(bodyData);
            cloned.forEach((key, val) {
              if (val is String) {
                cloned[key] = val
                    .replaceAll('{{key}}', q)
                    .replaceAll('{key}', q)
                    .replaceAll('{{page}}', '1')
                    .replaceAll('{page}', '1');
              }
            });
            bodyData = cloned;
          }
          response = await _dio.post<List<int>>(
            testUrl,
            data: bodyData,
            options: Options(headers: opts.headers, responseType: ResponseType.bytes),
          );
        } else {
          response = await _dio.get<List<int>>(
            testUrl,
            options: Options(headers: opts.headers, responseType: ResponseType.bytes),
          );
        }

        if (response.statusCode == 200 && response.data != null) {
          final html = _decodeContent(response.data!, response.headers.map);
          final items = LocalParserEngine.evaluateListSelector(html, ruleJson['ruleSearch']?['bookList']?.toString() ?? '', {});
          final List<Book> booksFound = [];
          
          for (final item in items) {
            final variables = <String, dynamic>{};
            final title = LocalParserEngine.evaluateSelector(item, ruleJson['ruleSearch']?['name']?.toString() ?? '', variables);
            var author = LocalParserEngine.evaluateSelector(item, ruleJson['ruleSearch']?['author']?.toString() ?? '', variables);
            final intro = LocalParserEngine.evaluateSelector(item, ruleJson['ruleSearch']?['intro']?.toString() ?? '', variables);
            var coverUrl = LocalParserEngine.evaluateSelector(item, ruleJson['ruleSearch']?['coverUrl']?.toString() ?? '', variables);
            var bookUrl = LocalParserEngine.evaluateSelector(item, ruleJson['ruleSearch']?['bookUrl']?.toString() ?? '', variables);

            if (title.isNotEmpty && bookUrl.isNotEmpty) {
              bookUrl = Uri.parse(source.sourceUrl).resolve(bookUrl).toString();
              if (coverUrl.isNotEmpty) {
                coverUrl = Uri.parse(source.sourceUrl).resolve(coverUrl).toString();
              }
              if (author.isEmpty) author = '未知';

              booksFound.add(Book(
                id: _generateBookId(title, author),
                title: title,
                author: author,
                coverUrl: coverUrl,
                summary: intro,
                isAbyss: inAbyss,
                bookUrl: bookUrl,
                sourceId: source.id,
                sourceName: source.sourceName,
              ));
            }
          }
          if (booksFound.isNotEmpty) {
            yield booksFound;
          }
        }
      } catch (_) {}
    }
  }

  /// 2. Silent sync abyss sources (Falls back locally, pulls online if backend is up)
  Future<Map<String, dynamic>> syncAbyssSources() async {
    await _initLocalDbs();
    try {
      final response = await _apiClient.instance.get('/novel/abyss/sync');
      final Map<String, dynamic> data = response.data ?? {};
      if (data['sources'] is List) {
        final List<dynamic> list = data['sources'];
        final List<BookSourceRule> rules = [];
        for (final item in list) {
          if (item is Map) {
            final name = item['bookSourceName']?.toString() ?? '';
            final sourceUrl = item['bookSourceUrl']?.toString() ?? '';
            if (name.isNotEmpty && sourceUrl.isNotEmpty) {
              rules.add(BookSourceRule(
                id: _generateBookId(name, sourceUrl),
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
      return data;
    } catch (_) {
      // Offline fallback: returns active local abyss sources count
      final sources = LocalBookSourceDb.instance.getAllSources().where((s) => s.isAbyss).toList();
      return {'sources_count': sources.length, 'local': true};
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

  /// 4. Get bookshelf items
  Future<List<ReadingProgress>> getBookshelf(bool inAbyss) async {
    await _initLocalDbs();
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

    final source = LocalBookSourceDb.instance.getSourceById(book.sourceId!);
    if (source == null) return [];
    
    final Map<String, dynamic> ruleJson = jsonDecode(source.ruleJson);
    final ruleToc = ruleJson['ruleToc'] is Map ? ruleJson['ruleToc'] as Map : {};
    
    final variables = <String, dynamic>{};
    
    // Fetch details/TOC page
    final response = await _dio.get<List<int>>(
      book.bookUrl!,
      options: Options(responseType: ResponseType.bytes),
    );
    if (response.statusCode != 200 || response.data == null) return [];
    
    final html = _decodeContent(response.data!, response.headers.map);
    
    // Resolve TOC URL if redirect is required
    final tocUrl = _resolveTocUrl(html, ruleJson, book.bookUrl!, variables);
    var tocHtml = html;
    if (tocUrl != book.bookUrl) {
      final tocResponse = await _dio.get<List<int>>(
        tocUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      if (tocResponse.statusCode == 200 && tocResponse.data != null) {
        tocHtml = _decodeContent(tocResponse.data!, tocResponse.headers.map);
      }
    }

    final chapterListSelector = ruleToc['chapterList']?.toString() ?? '';
    final items = LocalParserEngine.evaluateListSelector(tocHtml, chapterListSelector, variables);
    final List<BookChapter> chapters = [];

    for (int i = 0; i < items.length; i++) {
      final name = LocalParserEngine.evaluateSelector(items[i], ruleToc['chapterName']?.toString() ?? '', variables);
      var url = LocalParserEngine.evaluateSelector(items[i], ruleToc['chapterUrl']?.toString() ?? '', variables);
      if (name.isNotEmpty && url.isNotEmpty) {
        url = Uri.parse(tocUrl).resolve(url).toString();
        chapters.add(BookChapter(
          id: _generateBookId(name, url),
          bookId: bookId,
          chapterIndex: i,
          title: name,
          sourceChapterUrl: url,
        ));
      }
    }
    
    await LocalBookshelfDb.instance.saveChapters(bookId, chapters);
    return chapters;
  }

  String _resolveTocUrl(String htmlContent, Map<String, dynamic> ruleJson, String bookUrl, Map<String, dynamic> variables) {
    final ruleBookInfo = ruleJson['ruleBookInfo'] is Map ? ruleJson['ruleBookInfo'] as Map : {};
    final ruleToc = ruleJson['ruleToc'] is Map ? ruleJson['ruleToc'] as Map : {};
    
    final tocUrlRule = ruleBookInfo['tocUrl']?.toString() ?? ruleToc['tocUrl']?.toString() ?? '';
    final initRule = ruleBookInfo['init']?.toString() ?? ruleToc['init']?.toString() ?? '';
    
    if (tocUrlRule.isEmpty) {
      return bookUrl;
    }
    
    try {
      var contextElement = htmlContent;
      if (initRule.isNotEmpty) {
        final trimmed = htmlContent.trim();
        if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
          try {
            final jsData = jsonDecode(trimmed);
            final initRes = LocalJsonpathParser.evaluateJsonpath(jsData, initRule);
            if (initRes is Map || initRes is List) {
              contextElement = jsonEncode(initRes);
            } else if (initRes != null) {
              contextElement = initRes.toString();
            }
          } catch (_) {}
        } else {
          final initResList = LocalParserEngine.evaluateListSelector(htmlContent, initRule, variables);
          if (initResList.isNotEmpty) {
            contextElement = initResList[0].toString();
          }
        }
      }
      
      final evaluatedTocUrl = LocalParserEngine.evaluateSelector(contextElement, tocUrlRule, variables);
      if (evaluatedTocUrl.isNotEmpty) {
        return Uri.parse(bookUrl).resolve(evaluatedTocUrl).toString();
      }
    } catch (_) {}
    return bookUrl;
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

    final source = LocalBookSourceDb.instance.getSourceById(book.sourceId!);
    if (source == null) return chapter;

    final Map<String, dynamic> ruleJson = jsonDecode(source.ruleJson);
    final ruleContent = ruleJson['ruleContent'] is Map ? ruleJson['ruleContent'] as Map : {};
    
    final contentSelector = ruleContent['content']?.toString() ?? '';
    final nextUrlSelector = ruleContent['nextContentUrl']?.toString() ?? '';
    final replaceRegexRule = ruleContent['replaceRegex']?.toString() ?? '';

    // Fetch initial page
    final response = await _dio.get<List<int>>(
      chapter.sourceChapterUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    if (response.statusCode != 200 || response.data == null) return chapter;
    
    final html = _decodeContent(response.data!, response.headers.map);
    final List<String> contents = [];
    
    final variables = <String, dynamic>{};
    final pageContent = LocalParserEngine.evaluateSelector(html, contentSelector, variables);
    if (pageContent.isNotEmpty) {
      contents.add(pageContent);
    }

    // Handles nextContentUrl pagination loop
    if (nextUrlSelector.isNotEmpty) {
      var nextUrlRaw = LocalParserEngine.evaluateSelector(html, nextUrlSelector, variables);
      var nextUrl = nextUrlRaw.isNotEmpty ? Uri.parse(chapter.sourceChapterUrl).resolve(nextUrlRaw).toString() : '';
      final Set<String> visited = {chapter.sourceChapterUrl};
      
      final nextChapterUrl = (chapterIndex + 1 < chapters.length) ? chapters[chapterIndex + 1].sourceChapterUrl : '';

      while (nextUrl.isNotEmpty && !visited.contains(nextUrl)) {
        // Prevent chapter overflow
        if (nextChapterUrl.isNotEmpty) {
          final nextUri = Uri.parse(nextUrl);
          final nextChapUri = Uri.parse(nextChapterUrl);
          if (nextUri.path == nextChapUri.path && nextUri.host == nextChapUri.host) {
            break;
          }
        }

        visited.add(nextUrl);
        try {
          final nextResponse = await _dio.get<List<int>>(
            nextUrl,
            options: Options(responseType: ResponseType.bytes),
          );
          if (nextResponse.statusCode == 200 && nextResponse.data != null) {
            final nextHtml = _decodeContent(nextResponse.data!, nextResponse.headers.map);
            final nextPart = LocalParserEngine.evaluateSelector(nextHtml, contentSelector, variables);
            if (nextPart.isNotEmpty) {
              contents.add(nextPart);
            }
            final nextRaw = LocalParserEngine.evaluateSelector(nextHtml, nextUrlSelector, variables);
            nextUrl = nextRaw.isNotEmpty ? Uri.parse(nextUrl).resolve(nextRaw).toString() : '';
          } else {
            break;
          }
        } catch (_) {
          break;
        }
      }
    }

    var fullContent = contents.join('\n');
    
    // Apply replaceRegex rules
    if (replaceRegexRule.isNotEmpty) {
      final lines = fullContent.split('\n').map((l) => l.trim()).toList();
      final cleanedText = lines.join('\n');
      fullContent = LocalParserEngine.evaluateSelector(cleanedText, replaceRegexRule, variables);
    }

    // Format content with indentations and double line breaks
    final lines = fullContent.split('\n').map((l) => l.trim()).toList();
    final List<String> formatted = [];
    for (final line in lines) {
      if (line.isNotEmpty) {
        final stripped = line.replaceFirst(RegExp(r'^[　 \t]+'), '');
        if (stripped.isNotEmpty) {
          formatted.add('　　' + stripped);
        }
      }
    }
    
    final finalContent = formatted.join('\n\n');
    final updatedChapter = chapter.copyWith(content: finalContent);
    
    // Update cache
    chapters[chapterIndex] = updatedChapter;
    await LocalBookshelfDb.instance.saveChapters(bookId, chapters);
    
    return updatedChapter;
  }

  /// 7. Update reading progress
  Future<ReadingProgress> updateReadingProgress({
    required String bookId,
    required int chapterIndex,
    required int charOffset,
  }) async {
    await _initLocalDbs();
    return await LocalBookshelfDb.instance.updateReadingProgress(
      bookId: bookId,
      chapterIndex: chapterIndex,
      charOffset: charOffset,
    );
  }

  /// 8. Export EPUB stream bytes
  Future<Uint8List> exportEpub(String bookId) async {
    // Return empty bytes placeholder for local EPUB exporter
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
        final response = await _dio.get<dynamic>(url);
        if (response.data is List) {
          sources = response.data;
        } else if (response.data is String) {
          sources = jsonDecode(response.data);
        }
      } else if (jsonData != null) {
        sources = jsonData;
      }
    } catch (_) {
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
    // Standard stub returning a mock book for file uploading
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

/// Riverpod provider for NovelApiClient
final novelApiClientProvider = Provider<NovelApiClient>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NovelApiClient(apiClient);
});
