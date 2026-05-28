import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../model/novel_models.dart';
import '../provider/novel_provider.dart';
import 'novel_reader_screen.dart';
import '../../../../core/widgets/dynamic_background.dart';

class NovelSearchScreen extends ConsumerStatefulWidget {
  final bool inAbyss;
  final String? initialQuery;

  const NovelSearchScreen({
    super.key,
    required this.inAbyss,
    this.initialQuery,
  });

  @override
  ConsumerState<NovelSearchScreen> createState() => _NovelSearchScreenState();
}

class _NovelSearchScreenState extends ConsumerState<NovelSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(novelProvider.notifier).clearSearchState();
      if (widget.initialQuery != null) {
        _searchController.text = widget.initialQuery!;
        _performSearch();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _hasSearched = true;
    });
    ref.read(novelProvider.notifier).search(query, widget.inAbyss);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(novelProvider);
    final themeColor = widget.inAbyss ? Colors.purpleAccent : Colors.pinkAccent;

    // Force a dark theme for the search screen to ensure high readability of all text
    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: widget.inAbyss ? Colors.purpleAccent : Colors.pinkAccent,
        brightness: Brightness.dark,
        surface: const Color(0xFF0F0C29), // deep midnight purple-blue space background
      ),
      useMaterial3: true,
    );

    return Theme(
      data: darkTheme,
      child: Builder(
        builder: (context) {
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                widget.inAbyss ? '👻 密室禁忌搜索' : '🔍 极净全网搜书',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            body: Stack(
              children: [
                const DynamicBackground(child: SizedBox.expand()),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        // Search Bar Input
                        _buildSearchBar(themeColor),
                        const SizedBox(height: 18),
                        
                        // Results view
                        Expanded(
                          child: _buildResultsContent(state, themeColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(Color themeColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: widget.inAbyss ? '输入深夜敏感书名或敏感词...' : '输入书名、作者名，一键智能穿梭...',
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded, color: themeColor, size: 20),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send_rounded, size: 18),
                color: themeColor,
                onPressed: _performSearch,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onSubmitted: (_) => _performSearch(),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsContent(NovelState state, Color themeColor) {
    if (state.isSearchLoading && state.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: themeColor),
            const SizedBox(height: 16),
            const Text(
              '正在并发穿梭各书源进行检索...',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (state.error != null && state.searchResults.isEmpty) {
      return Center(
        child: Text(
          '⚠️ 检索失败: ${state.error}',
          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.manage_search_rounded, size: 64, color: themeColor.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text(
              '搜索结果采用并发加速获取，去杂存真',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (state.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_dissatisfied_rounded, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              '🕵️ 换个书名搜搜看，或检查网络连接',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (state.error != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 0.8),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '部分书源检索超时，已展示已搜到的书籍',
                    style: TextStyle(color: Colors.redAccent.withOpacity(0.9), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (state.isSearchLoading) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                color: themeColor,
                backgroundColor: themeColor.withOpacity(0.1),
                minHeight: 2,
              ),
            ),
          ),
        ],
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: state.searchResults.length,
            itemBuilder: (context, index) {
              final book = state.searchResults[index];
              return _buildBookSearchItem(book, themeColor);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookSearchItem(Book book, Color themeColor) {
    // Check if book is already on shelf
    final state = ref.watch(novelProvider);
    final bookshelf = widget.inAbyss ? state.abyssBookshelf : state.bookshelf;
    final bool alreadyAdded = bookshelf.any((p) => p.book?.title == book.title && p.book?.author == book.author);

    return GestureDetector(
      onTap: () async {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: Colors.pinkAccent),
          ),
        );
        
        final progress = await ref.read(novelProvider.notifier).addAndSelectBook(book, widget.inAbyss);
        
        if (mounted) {
          Navigator.pop(context); // Dismiss loading
        }
        
        if (progress != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NovelReaderScreen(
                bookId: progress.bookId,
                inAbyss: widget.inAbyss,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fallback solid gradient cover
            Container(
              width: 50,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                  colors: widget.inAbyss
                      ? [Colors.deepPurple, Colors.purple]
                      : [const Color(0xFF1E202C), const Color(0xFF323545)],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                book.title.isNotEmpty ? book.title.substring(0, 1) : '书',
                style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '作者：${book.author}',
                        style: const TextStyle(fontSize: 11.5, color: Colors.white54),
                      ),
                      if (book.sourceName != null && book.sourceName!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: themeColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: themeColor.withOpacity(0.24), width: 0.5),
                          ),
                          child: Text(
                            book.sourceName!,
                            style: TextStyle(fontSize: 9, color: themeColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    book.summary.isNotEmpty ? book.summary : '该书源暂未提供简介，点击直接加入书架开始阅读。',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.white30, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Action button
            IconButton(
              icon: Icon(
                alreadyAdded ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                color: alreadyAdded ? Colors.greenAccent : themeColor,
                size: 24,
              ),
              onPressed: alreadyAdded
                  ? null
                  : () async {
                      final newBook = await ref.read(novelProvider.notifier).addBookToShelf(book, widget.inAbyss);
                      if (newBook != null && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🎉 成功将《${book.title}》加入书架'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}
