import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbox_app/core/storage/local_storage.dart';
import 'package:toolbox_app/features/novel/model/novel_models.dart';
import 'package:toolbox_app/features/novel/provider/novel_provider.dart';
import 'package:toolbox_app/features/novel/service/novel_api_client.dart';
import 'package:toolbox_app/features/novel/view/novel_reader_screen.dart';
import 'package:toolbox_app/features/bmi/view/bmi_screen.dart';
import 'dart:typed_data';

class MockNovelApiClient implements NovelApiClient {
  bool _isTrial = true;

  final List<ReadingProgress> _shelf = [
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

  @override
  Future<List<Book>> searchNovels(String q, bool inAbyss) async => [];

  @override
  Stream<List<Book>> searchNovelsStream(String q, bool inAbyss) async* {
    yield [];
  }

  @override
  Future<Map<String, dynamic>> syncAbyssSources() async => {'status': 'success'};

  @override
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
    const bookId = 'book-trial-456';
    if (!isTrial) {
      _isTrial = false;
    }
    final book = Book(
      id: bookId,
      title: title,
      author: author,
      coverUrl: coverUrl,
      summary: summary,
      currentSourceId: sourceId,
      isAbyss: isAbyss,
      bookUrl: bookUrl,
      sourceId: sourceId,
      sourceName: 'Mock Source',
    );
    if (!isTrial) {
      final exists = _shelf.any((p) => p.bookId == bookId);
      if (!exists) {
        _shelf.add(ReadingProgress(
          id: 'progress-upgraded',
          userId: 'user-123',
          bookId: bookId,
          lastReadChapterIndex: 1,
          lastReadCharOffset: 0,
          updatedAt: DateTime.now().toIso8601String(),
          book: book,
        ));
      }
    }
    return book;
  }

  @override
  Future<List<ReadingProgress>> getBookshelf(bool inAbyss) async {
    return _shelf;
  }

  @override
  Future<List<BookChapter>> getBookChapters(String bookId, {bool forceRefresh = false}) async {
    if (bookId == 'book-trial-456' && _isTrial) {
      throw Exception('403 Forbidden: trial limit reached');
    }
    return [
      BookChapter(
        id: 'chapter-123',
        bookId: bookId,
        chapterIndex: 1,
        title: '第1章 开端',
        sourceChapterUrl: 'local://import/chapter_1',
      ),
      BookChapter(
        id: 'chapter-124',
        bookId: bookId,
        chapterIndex: 2,
        title: '第2章 发展',
        sourceChapterUrl: 'local://import/chapter_2',
      ),
    ];
  }

  @override
  Future<BookChapter> getChapterContent(String bookId, int chapterIndex) async {
    if (bookId == 'ad-book-999') {
      return BookChapter.fromJson({
        'title': '有广告章节',
        'content': '【点击加入书签】顶点小说最新章节.这里是正文。www.abcd.com手机用户请访问x(本章完)',
      });
    }
    return BookChapter.fromJson({
      'title': chapterIndex == 1 ? '第1章 开端' : '第2章 发展',
      'content': '这里是第$chapterIndex章的测试内容。第一页。第二页。第三页。本地导入测试内容。',
    });
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
  Future<Uint8List> exportEpub(String bookId) async => Uint8List(0);

  @override
  Future<void> removeFromBookshelf(List<String> bookIds) async {}

  @override
  Future<Map<String, dynamic>> importBookSources({
    String? url,
    List<dynamic>? jsonData,
  }) async => {'imported_count': 1, 'updated_count': 0};

  @override
  Future<Book> importLocalBook({
    required String title,
    required String author,
    String? summary,
    String? coverUrl,
    required List<Map<String, String>> chapters,
  }) async {
    return Book(
      id: 'book-local-123',
      title: title,
      author: author,
      coverUrl: coverUrl ?? '',
      summary: summary ?? '',
      currentSourceId: null,
      isAbyss: false,
      bookUrl: 'local://import',
      sourceId: null,
      sourceName: null,
    );
  }

  @override
  Future<Book> importBookFile({
    required String filePath,
    required String fileName,
  }) async {
    return Book(
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
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Comprehensive user simulation test for NovelReaderScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({
      'novel_reader_is_page_view_mode': false,
      'novel_reader_font_size': 18.0,
      'novel_reader_line_height': 1.6,
      'novel_reader_is_serif': true,
      'novel_reader_theme_index': 0,
    });
    final prefs = await SharedPreferences.getInstance();
    final mockClient = MockNovelApiClient();

    // 1. Render the screen
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

    // Initial state: skeleton loading
    await tester.pump();

    // Select the book to load chapter list and select chapter index 1 content
    final container = ProviderScope.containerOf(tester.element(find.byType(NovelReaderScreen)));
    final progressList = await mockClient.getBookshelf(false);
    await container.read(novelProvider.notifier).selectBook(progressList.first);
    await tester.pumpAndSettle();

    // Verify initial state shows Chapter title and content
    expect(find.text('第1章 开端'), findsWidgets);
    expect(
      find.byWidgetPredicate((widget) => widget is RichText && widget.text.toPlainText().contains('这里是第1章的测试内容')),
      findsOneWidget,
    );

    // 2. Simulate opening controls overlay (by tapping on the screen)
    final rootGesture = tester.widget<GestureDetector>(
      find.descendant(
        of: find.byType(SafeArea),
        matching: find.byType(GestureDetector),
      ).first,
    );
    rootGesture.onTap!();
    await tester.pumpAndSettle();

    // Tap "设置" on the bottom navigation bar to open settings panel
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();

    // Verify Control Overlay elements exist
    expect(find.byIcon(Icons.text_fields_rounded), findsOneWidget);
    expect(find.byIcon(Icons.format_line_spacing_rounded), findsOneWidget);

    // 3. Test changing Font Size slider
    final sizeSlider = find.byType(Slider).first;
    await tester.drag(sizeSlider, const Offset(30, 0));
    await tester.pumpAndSettle();
    expect(prefs.getDouble('novel_reader_font_size'), isNot(18.0));

    // 4. Test changing Line Height slider
    final heightSlider = find.byType(Slider).at(1);
    await tester.drag(heightSlider, const Offset(20, 0));
    await tester.pumpAndSettle();
    expect(prefs.getDouble('novel_reader_line_height'), isNot(1.6));

    // 5. Test Switch for Serif Font
    final serifSwitch = find.descendant(
      of: find.ancestor(
        of: find.text('选用仿宋/Georgia'),
        matching: find.byType(Row),
      ),
      matching: find.byType(Switch),
    );
    await tester.ensureVisible(serifSwitch);
    await tester.tap(serifSwitch);
    await tester.pumpAndSettle();
    expect(prefs.getBool('novel_reader_is_serif'), false);

    // 6. Test Theme Switching
    await tester.ensureVisible(find.text('极夜'));
    await tester.tap(find.text('极夜'));
    await tester.pumpAndSettle();
    expect(prefs.getInt('novel_reader_theme_index'), 3);

    await tester.ensureVisible(find.text('护眼'));
    await tester.tap(find.text('护眼'));
    await tester.pumpAndSettle();
    expect(prefs.getInt('novel_reader_theme_index'), 2);

    // 7. Test Page Flip Mode Toggle (to PageView)
    await tester.ensureVisible(find.text('左右翻页'));
    await tester.tap(find.text('左右翻页'));
    await tester.pumpAndSettle();
    expect(prefs.getBool('novel_reader_is_page_view_mode'), true);
    // PageView mode displays page indicators like "第 1 / 1 页" or similar
    expect(find.textContaining('页'), findsWidgets);

    // Toggle Page Flip Mode back to vertical scrolling
    await tester.ensureVisible(find.text('纵向滚动'));
    await tester.tap(find.text('纵向滚动'));
    await tester.pumpAndSettle();
    expect(prefs.getBool('novel_reader_is_page_view_mode'), false);

    // Switch to Sound tab inside the settings panel
    await tester.tap(find.text('听书声景'));
    await tester.pumpAndSettle();

    // 8. Test TTS Audio Controls
    expect(find.byIcon(Icons.play_circle_filled_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.play_circle_filled_rounded));
    await tester.pump();
    expect(container.read(novelProvider).isTtsPlaying, true);

    // Test Pause TTS
    await tester.tap(find.byIcon(Icons.pause_circle_filled_rounded));
    await tester.pump();
    expect(container.read(novelProvider).isTtsPlaying, false);

    // 9. Test Soundscape Mixer toggles (Umbrella is for Rain, Waves is for Wave, Fire is for Fire)
    final rainSoundBtn = find.byIcon(Icons.umbrella_rounded);
    await tester.tap(rainSoundBtn);
    await tester.pump();
    expect(container.read(novelProvider).ambientActive['rain'], true);

    await tester.tap(rainSoundBtn);
    await tester.pump();
    expect(container.read(novelProvider).ambientActive['rain'], false);

    // 10. Test TOC (Chapters list) Drawer
    final tocBtn = find.byIcon(Icons.format_list_bulleted_rounded).first;
    await tester.tap(tocBtn);
    await tester.pumpAndSettle(); // opens bottom sheet
    expect(find.text('书籍目录列表'), findsOneWidget);
    expect(find.text('第2章 发展'), findsOneWidget);

    // Select Chapter 2 from sheet
    await tester.tap(find.text('第2章 发展'));
    await tester.pumpAndSettle(); // loads content & closes sheet

    // Verify Chapter 2 content is displayed
    expect(find.text('第2章 发展'), findsWidgets);
    expect(
      find.byWidgetPredicate((widget) => widget is RichText && widget.text.toPlainText().contains('这里是第2章的测试内容')),
      findsOneWidget,
    );

    // Hide controls overlay to expose the bottom paging row
    final closeGesture = tester.widget<GestureDetector>(
      find.descendant(
        of: find.byType(SafeArea),
        matching: find.byType(GestureDetector),
      ).first,
    );
    closeGesture.onTap!();
    await tester.pumpAndSettle();

    // 11. Test Paging Buttons (Prev/Next chapter buttons in scroll mode)
    final prevBtn = tester.widget<TextButton>(find.widgetWithText(TextButton, '上一章'));
    prevBtn.onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Verify it is back to Chapter 1
    expect(find.text('第1章 开端'), findsWidgets);

    // 12. Test Decoy Panic Mode (Double tap to exit to decoy BMI Screen)
    final gestureDetectorFinder = find.descendant(
      of: find.byType(SafeArea),
      matching: find.byType(GestureDetector),
    );
    final allGestureDetectors = tester.widgetList<GestureDetector>(gestureDetectorFinder).toList();
    final targetGD = allGestureDetectors.firstWhere((gd) => gd.onDoubleTap != null);
    targetGD.onDoubleTap!();
    
    // Pump transition frames
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    
    final bmiFinder = find.byType(BmiScreen);
    expect(bmiFinder, findsOneWidget);
  });

  testWidgets('Trial limit reached overlay and upgrading book flow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final mockClient = MockNovelApiClient();

    // 1. Render the screen
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          novelApiClientProvider.overrideWithValue(mockClient),
        ],
        child: const MaterialApp(
          home: NovelReaderScreen(
            bookId: 'book-trial-456',
            inAbyss: false,
          ),
        ),
      ),
    );

    await tester.pump();

    // Select the trial book which throws exception during loadChapters
    final container = ProviderScope.containerOf(tester.element(find.byType(NovelReaderScreen)));
    final trialBook = Book(
      id: 'book-trial-456',
      title: '试读测试书',
      author: '试读作者',
      coverUrl: '',
      summary: '试读内容',
      currentSourceId: 'mock-source',
      isAbyss: false,
      bookUrl: 'local://trial',
    );
    
    final initialProgress = ReadingProgress(
      id: '',
      userId: '',
      bookId: 'book-trial-456',
      lastReadChapterIndex: 1,
      lastReadCharOffset: 0,
      updatedAt: '',
      book: trialBook,
    );
    
    await container.read(novelProvider.notifier).selectBook(initialProgress);
    await tester.pumpAndSettle();

    // Verify trial limit reached overlay is showing
    expect(find.text('🌌 试读额度已满'), findsOneWidget);
    expect(find.textContaining('您已免费试读前 3 章'), findsOneWidget);

    // Tap "加入书架继续阅读" button
    await tester.tap(find.text('加入书架继续阅读'));
    
    // Pump frames to complete mock database insertions and refetches
    await tester.pumpAndSettle();

    // The modal overlay should disappear because the book is upgraded (no longer trial)
    expect(find.text('🌌 试读额度已满'), findsNothing);

    // Verify it retried loading and loaded chapter 1 title & content successfully
    expect(find.text('第1章 开端'), findsWidgets);
  });

  testWidgets('Failover source toast display and auto dismiss', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final mockClient = MockNovelApiClient();

    // 1. Render the screen
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

    await tester.pump();

    // Select the book to load content
    final container = ProviderScope.containerOf(tester.element(find.byType(NovelReaderScreen)));
    final progressList = await mockClient.getBookshelf(false);
    await container.read(novelProvider.notifier).selectBook(progressList.first);
    await tester.pumpAndSettle();

    // Set the static failover source variable to simulate a failover event triggered by the client
    NovelApiClient.lastFailoverSource = '备份源 Delta';
    
    // Tap the screen to trigger a build (which will register addPostFrameCallback)
    final rootGesture = tester.widget<GestureDetector>(
      find.descendant(
        of: find.byType(SafeArea),
        matching: find.byType(GestureDetector),
      ).first,
    );
    rootGesture.onTap!();
    
    // Pump frames to run the post-frame callback and update state
    await tester.pump(); // builds frame with updated overlay, registers callback
    await tester.pump(); // builds next frame showing the toast

    // Verify the Failover HUD Toast shows up
    expect(find.textContaining('当前书源不可用，已自动切源至 [备份源 Delta] 恢复阅读'), findsOneWidget);

    // Pump 4 seconds later to verify it auto dismisses
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(); // frame to update UI

    // Verify the Failover HUD Toast is gone
    expect(find.textContaining('当前书源不可用'), findsNothing);
  });

  testWidgets('Test Auto-Scroll settings and TextureOverlayPainter rendering', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({
      'novel_reader_is_page_view_mode': false,
      'novel_reader_font_size': 18.0,
      'novel_reader_line_height': 1.6,
      'novel_reader_is_serif': true,
      'novel_reader_theme_index': 0,
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

    await tester.pump();
    final container = ProviderScope.containerOf(tester.element(find.byType(NovelReaderScreen)));
    final progressList = await mockClient.getBookshelf(false);
    await container.read(novelProvider.notifier).selectBook(progressList.first);
    await tester.pumpAndSettle();

    // 1. Verify CustomPaint with TextureOverlayPainter is present
    final customPaintFinder = find.byType(CustomPaint);
    expect(customPaintFinder, findsWidgets);

    // 2. Open controls overlay
    final rootGesture = tester.widget<GestureDetector>(
      find.descendant(
        of: find.byType(SafeArea),
        matching: find.byType(GestureDetector),
      ).first,
    );
    rootGesture.onTap!();
    await tester.pumpAndSettle();

    // Tap "设置" on the bottom navigation bar to open settings panel
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();

    // 3. Verify Auto Scroll option exists in vertical scroll mode controls
    expect(find.text('自动滚屏'), findsOneWidget);
    
    // 4. Toggle Auto Scroll Switch
    final autoScrollSwitch = find.descendant(
      of: find.ancestor(
        of: find.text('自动滚屏'),
        matching: find.byType(Row),
      ),
      matching: find.byType(Switch),
    );
    expect(autoScrollSwitch, findsOneWidget);
    await tester.ensureVisible(autoScrollSwitch);
    await tester.tap(autoScrollSwitch);
    await tester.pumpAndSettle();

    // Verify speed adjustment works
    await tester.ensureVisible(find.textContaining('滚屏速度'));
    await tester.tap(find.textContaining('滚屏速度'));
    await tester.pumpAndSettle();
    expect(find.text('4 级'), findsOneWidget);
    await tester.tap(find.text('4 级'));
    await tester.pumpAndSettle();

    // 5. Change Theme to Abyss (theme index 4) to verify painter overlay behavior changes
    await tester.ensureVisible(find.text('深渊'));
    await tester.tap(find.text('深渊'));
    await tester.pumpAndSettle();
    expect(prefs.getInt('novel_reader_theme_index'), 4);
  });

  testWidgets('Test Double-Column mode on wide screens (> 600px)', (WidgetTester tester) async {
    // Set screen size to wide landscape layout (tablet width 800)
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({
      'novel_reader_is_page_view_mode': true,
      'novel_reader_font_size': 18.0,
      'novel_reader_line_height': 1.6,
      'novel_reader_is_serif': true,
      'novel_reader_theme_index': 0,
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

    await tester.pump();
    final container = ProviderScope.containerOf(tester.element(find.byType(NovelReaderScreen)));
    final progressList = await mockClient.getBookshelf(false);
    await container.read(novelProvider.notifier).selectBook(progressList.first);
    await tester.pumpAndSettle();

    // Verify PageView structure is built
    expect(find.byType(PageView), findsOneWidget);
    
    // Verify columns divider is built
    final verticalFoldFinder = find.byWidgetPredicate(
      (widget) => widget is Container && widget.constraints?.maxWidth == 1 && widget.margin is EdgeInsets,
    );
    expect(verticalFoldFinder, findsWidgets);
  });

  testWidgets('Test Dimmer, Sanitization, and Paragraph Highlights/Notes', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({
      'novel_reader_is_page_view_mode': false,
      'novel_reader_font_size': 18.0,
      'novel_reader_line_height': 1.6,
      'novel_reader_is_serif': true,
      'novel_reader_theme_index': 0,
      'novel_reader_dimmer_opacity': 0.1,
    });
    final prefs = await SharedPreferences.getInstance();
    final mockClient = MockNovelApiClient();

    // 1. Render the screen using the ad-polluted book
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          novelApiClientProvider.overrideWithValue(mockClient),
        ],
        child: const MaterialApp(
          home: NovelReaderScreen(
            bookId: 'ad-book-999',
            inAbyss: false,
          ),
        ),
      ),
    );

    await tester.pump();
    final container = ProviderScope.containerOf(tester.element(find.byType(NovelReaderScreen)));
    
    // Setup initial book state
    final initialProgress = ReadingProgress(
      id: '',
      userId: '',
      bookId: 'ad-book-999',
      lastReadChapterIndex: 1,
      lastReadCharOffset: 0,
      updatedAt: '',
      book: Book(
        id: 'ad-book-999',
        title: '广告测试书',
        author: '测试作者',
        coverUrl: '',
        summary: '广告测试内容',
        currentSourceId: null,
        isAbyss: false,
        bookUrl: 'local://adbook',
        sourceId: null,
        sourceName: null,
      ),
    );
    
    await container.read(novelProvider.notifier).selectBook(initialProgress);
    await tester.pumpAndSettle();

    // 2. Verify Dimmer Screen Overlay opacity is applied (should find a Positioned.fill IgnorePointer black container with opacity 0.1)
    final dimmerContainerFinder = find.byWidgetPredicate(
      (widget) => widget is Container && widget.color == Colors.black.withOpacity(0.1),
    );
    expect(dimmerContainerFinder, findsWidgets);

    // 3. Verify Sanitization and full-width space indentation
    // Raw ad-polluted mock was: '【点击加入书签】顶点小说最新章节.这里是正文。www.abcd.com手机用户请访问x(本章完)'
    // Sanitized: '这里是正文。'
    // Formatted: '　　这里是正文。'
    final formattedContent = container.read(novelProvider).currentChapter?.content ?? '';
    expect(formattedContent, '　　这里是正文。');

    // 4. Test paragraph highlight and notes sheet
    // Toggle controls overlay to expose settings panel containing the highlights trigger
    final rootGesture = tester.widget<GestureDetector>(
      find.descendant(
        of: find.byType(SafeArea),
        matching: find.byType(GestureDetector),
      ).first,
    );
    rootGesture.onTap!();
    await tester.pumpAndSettle();

    final quickAccessBtn = find.byIcon(Icons.border_color_rounded).first;
    await tester.tap(quickAccessBtn);
    await tester.pumpAndSettle();

    // Bottom sheet is open showing list of paragraphs
    expect(find.text('本章划线与笔记管理'), findsOneWidget);
    
    // We toggle highlight on the first paragraph
    final highlightBtn = find.widgetWithText(TextButton, '添加划线').first;
    await tester.tap(highlightBtn);
    await tester.pumpAndSettle();

    // Write note
    final noteBtn = find.widgetWithText(TextButton, '写想法').first;
    await tester.tap(noteBtn);
    await tester.pumpAndSettle();

    // Enter note text in dialog
    expect(find.text('写下您的阅读想法'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '这是一个很好的段落！');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    // Check bottom sheet highlights updating
    expect(find.widgetWithText(TextButton, '取消划线'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '编辑想法'), findsOneWidget);

    // Close bottom sheet
    Navigator.pop(tester.element(find.byType(BottomSheet)));
    await tester.pumpAndSettle();

    // Verify highlights are persisted in shared preferences
    final savedHighlights = prefs.getString('novel_highlights_ad-book-999');
    expect(savedHighlights, isNotNull);
    expect(savedHighlights!.contains('这是一个很好的段落！'), isTrue);
  });
}
