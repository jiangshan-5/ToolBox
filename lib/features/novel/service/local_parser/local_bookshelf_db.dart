import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../model/novel_models.dart';

class LocalBookshelfDb {
  static final LocalBookshelfDb instance = LocalBookshelfDb._internal();
  LocalBookshelfDb._internal();

  List<Book> _books = [];
  List<ReadingProgress> _progress = [];
  final Map<String, List<BookChapter>> _chaptersCache = {};
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final docDir = await getApplicationDocumentsDirectory();
      
      // Load Books
      final booksFile = File('${docDir.path}/local_books.json');
      if (await booksFile.exists()) {
        final content = await booksFile.readAsString();
        final List<dynamic> list = jsonDecode(content);
        _books = list.map((item) => Book.fromJson(item)).toList();
      }

      // Load Progress
      final progressFile = File('${docDir.path}/local_progress.json');
      if (await progressFile.exists()) {
        final content = await progressFile.readAsString();
        final List<dynamic> list = jsonDecode(content);
        _progress = list.map((item) => ReadingProgress.fromJson(item)).toList();
      }

      // Load Chapters Cache
      final chaptersFile = File('${docDir.path}/local_chapters_cache.json');
      if (await chaptersFile.exists()) {
        final content = await chaptersFile.readAsString();
        final Map<String, dynamic> map = jsonDecode(content);
        map.forEach((key, val) {
          final List<dynamic> list = val;
          _chaptersCache[key] = list.map((item) => BookChapter.fromJson(item)).toList();
        });
      }
    } catch (_) {}
    _initialized = true;
  }

  Future<void> saveBooks() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final file = File('${docDir.path}/local_books.json');
      await file.writeAsString(jsonEncode(_books.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> saveProgress() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final file = File('${docDir.path}/local_progress.json');
      await file.writeAsString(jsonEncode(_progress.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> saveChaptersCache() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final file = File('${docDir.path}/local_chapters_cache.json');
      final Map<String, dynamic> dumpMap = {};
      _chaptersCache.forEach((key, value) {
        dumpMap[key] = value.map((e) => e.toJson()).toList();
      });
      await file.writeAsString(jsonEncode(dumpMap));
    } catch (_) {}
  }

  List<Book> getBooks(bool inAbyss) {
    return _books.where((b) => b.isAbyss == inAbyss).toList();
  }

  List<ReadingProgress> getBookshelf(bool inAbyss) {
    // Return reading progress list joined with book data
    final list = _progress.where((p) {
      final b = getBookById(p.bookId);
      return b != null && b.isAbyss == inAbyss;
    }).toList();

    return list.map((p) {
      final b = getBookById(p.bookId);
      return ReadingProgress(
        id: p.id,
        userId: p.userId,
        bookId: p.bookId,
        lastReadChapterIndex: p.lastReadChapterIndex,
        lastReadCharOffset: p.lastReadCharOffset,
        updatedAt: p.updatedAt,
        book: b,
      );
    }).toList();
  }

  Book? getBookById(String id) {
    try {
      return _books.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Book> addToBookshelf(Book book, {bool inBookshelf = true}) async {
    _books.removeWhere((b) => b.id == book.id);
    _books.add(book);
    await saveBooks();

    // Create progress if not exists or upgrade if explicitly true
    final index = _progress.indexWhere((p) => p.bookId == book.id);
    if (index == -1) {
      final p = ReadingProgress(
        id: book.id, // use book id as progress id
        userId: 'local_user',
        bookId: book.id,
        lastReadChapterIndex: 0,
        lastReadCharOffset: 0,
        updatedAt: DateTime.now().toIso8601String(),
        book: book,
        inBookshelf: inBookshelf,
      );
      _progress.add(p);
      await saveProgress();
    } else {
      if (inBookshelf && !_progress[index].inBookshelf) {
        _progress[index] = _progress[index].copyWith(
          inBookshelf: true,
          updatedAt: DateTime.now().toIso8601String(),
        );
        await saveProgress();
      }
    }
    return book;
  }

  Future<void> removeFromBookshelf(List<String> bookIds) async {
    _books.removeWhere((b) => bookIds.contains(b.id));
    _progress.removeWhere((p) => bookIds.contains(p.bookId));
    for (final id in bookIds) {
      _chaptersCache.remove(id);
    }
    await saveBooks();
    await saveProgress();
    await saveChaptersCache();
  }

  Future<ReadingProgress> updateReadingProgress({
    required String bookId,
    required int chapterIndex,
    required int charOffset,
  }) async {
    for (int i = 0; i < _progress.length; i++) {
      if (_progress[i].bookId == bookId) {
        final p = _progress[i];
        _progress[i] = ReadingProgress(
          id: p.id,
          userId: p.userId,
          bookId: p.bookId,
          lastReadChapterIndex: chapterIndex,
          lastReadCharOffset: charOffset,
          updatedAt: DateTime.now().toIso8601String(),
          book: p.book,
          inBookshelf: p.inBookshelf,
        );
        await saveProgress();
        return _progress[i];
      }
    }
    // Fallback if not found
    final p = ReadingProgress(
      id: bookId,
      userId: 'local_user',
      bookId: bookId,
      lastReadChapterIndex: chapterIndex,
      lastReadCharOffset: charOffset,
      updatedAt: DateTime.now().toIso8601String(),
      book: getBookById(bookId),
      inBookshelf: true,
    );
    _progress.add(p);
    await saveProgress();
    return p;
  }

  List<BookChapter>? getChapters(String bookId) {
    return _chaptersCache[bookId];
  }

  Future<void> saveChapters(String bookId, List<BookChapter> chapters) async {
    _chaptersCache[bookId] = chapters;
    await saveChaptersCache();
  }
}
