import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbox_app/core/storage/local_storage.dart';
import 'package:toolbox_app/features/novel/model/novel_models.dart';
import 'package:toolbox_app/features/novel/provider/novel_provider.dart';
import 'package:toolbox_app/features/novel/service/novel_api_client.dart';
import 'package:toolbox_app/features/novel/view/novel_reader_screen.dart';
import 'dart:typed_data';

class MockNovelApiClient implements NovelApiClient {
  @override
  Future<List<ReadingProgress>> getBookshelf(bool inAbyss) async {
    return [
      ReadingProgress(
        id: 'progress-123',
        userId: 'user-123',
        bookId: 'book-local-123',
        lastReadChapterIndex: 1,
        lastReadCharOffset: 0,
        updatedAt: DateTime.now().toIso8601String(),
        book: Book(
          id: 'book-local-123',
          title: '测试导入书',
          author: '测试作者',
          coverUrl: '',
          summary: '本地导入书籍',
          currentSourceId: null,
          isAbyss: false,
          bookUrl: 'local://import',
          sourceId: null,
          sourceName: null,
        ),
      ),
    ];
  }

  @override
  Future<List<BookChapter>> getBookChapters(String bookId, {bool forceRefresh = false}) async {
    return [
      BookChapter(
        id: 'chapter-123',
        bookId: 'book-local-123',
        chapterIndex: 1,
        title: '第1章 开端',
        sourceChapterUrl: 'local://import/chapter_1',
      ),
      BookChapter(
        id: 'chapter-124',
        bookId: 'book-local-123',
        chapterIndex: 2,
        title: '第2章 发展',
        sourceChapterUrl: 'local://import/chapter_2',
      ),
    ];
  }

  @override
  Future<BookChapter> getChapterContent(String bookId, int chapterIndex) async {
    // Mimic backend returning only title and content (as defined in BookChapterContentResponse)
    // The client parses it with BookChapter.fromJson
    final jsonResponse = {
      'title': chapterIndex == 1 ? '第1章 开端' : '第2章 发展',
      'content': '这里是第$chapterIndex章的测试内容。第一页。第二页。第三页。本地导入测试内容。',
    };
    return BookChapter.fromJson(jsonResponse);
  }

  @override
  Future<ReadingProgress> updateReadingProgress({
    required String bookId,
    required int chapterIndex,
    required int charOffset,
  }) async {
    return ReadingProgress(
      id: 'progress-123',
      userId: 'user-123',
      bookId: bookId,
      lastReadChapterIndex: chapterIndex,
      lastReadCharOffset: charOffset,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test local book read screen flow and crash detection', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({
      'novel_reader_is_page_view_mode': true, // Test with page view mode
    });
    final prefs = await SharedPreferences.getInstance();

    final mockClient = MockNovelApiClient();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          novelApiClientProvider.overrideWithValue(mockClient),
        ],
        child: const MaterialApp(
          home: NovelReaderScreen(
            bookId: 'book-local-123',
            inAbyss: false,
          ),
        ),
      ),
    );

    // Initial state: loading
    await tester.pump();

    // Now trigger loading chapters and select the progress
    final container = ProviderScope.containerOf(tester.element(find.byType(NovelReaderScreen)));
    final progressList = await mockClient.getBookshelf(false);
    await container.read(novelProvider.notifier).selectBook(progressList.first);

    await tester.pump(); // trigger build

    final exception = tester.takeException();
    if (exception != null) {
      print('--- TEST CAPTURED EXCEPTION ---');
      print('Exception type: ${exception.runtimeType}');
      print('Exception: $exception');
      if (exception is Error) {
        print('Stack trace: ${exception.stackTrace}');
      }
      print('-------------------------------');
    }

    await tester.pumpAndSettle();
  });
}
