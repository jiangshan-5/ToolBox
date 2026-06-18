import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../model/novel_models.dart';
import '../provider/novel_provider.dart';
import 'novel_reader_screen.dart';
import '../../../../core/widgets/dynamic_background.dart';
import '../../../../core/storage/local_storage.dart';

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
  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(novelProvider.notifier).clearSearchState();
      if (widget.initialQuery != null) {
        _searchController.text = widget.initialQuery!;
        _performSearch();
      }
    });
  }

  void _loadSearchHistory() {
    final storage = ref.read(localStorageServiceProvider);
    final key = widget.inAbyss ? 'novel_abyss_search_history' : 'novel_search_history';
    setState(() {
      _searchHistory = storage.getStringList(key) ?? [];
    });
  }

  Future<void> _saveSearchHistory(List<String> history) async {
    final storage = ref.read(localStorageServiceProvider);
    final key = widget.inAbyss ? 'novel_abyss_search_history' : 'novel_search_history';
    await storage.setStringList(key, history);
  }

  void _addToHistory(String query) {
    if (query.isEmpty) return;
    final history = List<String>.from(_searchHistory);
    history.remove(query);
    history.insert(0, query);
    if (history.length > 15) {
      history.removeRange(15, history.length);
    }
    setState(() {
      _searchHistory = history;
    });
    _saveSearchHistory(history);
  }

  void _removeFromHistory(String query) {
    final history = List<String>.from(_searchHistory);
    history.remove(query);
    setState(() {
      _searchHistory = history;
    });
    _saveSearchHistory(history);
  }

  void _clearHistory() {
    setState(() {
      _searchHistory = [];
    });
    _saveSearchHistory([]);
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
    _addToHistory(query);
    ref.read(novelProvider.notifier).search(query, widget.inAbyss);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(novelProvider);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final themeColor = widget.inAbyss ? Colors.purpleAccent : primaryColor;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: onSurface.withOpacity(0.7)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.inAbyss ? '👻 密室禁忌搜索' : '🔍 极净全网搜书',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface),
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
  }

  Widget _buildSearchBar(Color themeColor) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: onSurface.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: onSurface.withOpacity(0.08)),
          ),
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: onSurface, fontSize: 14),
            decoration: InputDecoration(
              hintText: widget.inAbyss ? '输入深夜敏感书名或敏感词...' : '输入书名、作者名，一键智能穿梭...',
              hintStyle: TextStyle(color: onSurface.withOpacity(0.3), fontSize: 13),
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

  Widget _buildSearchHistory(Color themeColor) {
    if (_searchHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.manage_search_rounded, size: 64, color: themeColor.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              '搜索结果采用并发加速获取，去杂存真',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 13),
            ),
          ],
        ),
      );
    }

    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '历史搜索',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: onSurface.withOpacity(0.8),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: onSurface.withOpacity(0.5), size: 20),
                onPressed: _clearHistory,
                tooltip: '清空历史记录',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: _searchHistory.map((query) => _buildHistoryChip(query, themeColor)).toList(),
          ),
          const SizedBox(height: 48),
          Center(
            child: Column(
              children: [
                Icon(Icons.manage_search_rounded, size: 48, color: themeColor.withOpacity(0.25)),
                const SizedBox(height: 12),
                Text(
                  '搜索结果采用并发加速获取，去杂存真',
                  style: TextStyle(color: onSurface.withOpacity(0.3), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryChip(String query, Color themeColor) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: onSurface.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: onSurface.withOpacity(0.08), width: 0.8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            _searchController.text = query;
            _performSearch();
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 6, top: 5, bottom: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    query,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: onSurface.withOpacity(0.85),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _removeFromHistory(query),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: onSurface.withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsContent(NovelState state, Color themeColor) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    if (state.isSearchLoading && state.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: themeColor),
            const SizedBox(height: 16),
            Text(
              '正在并发穿梭各书源进行检索...',
              style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (state.searchError != null && state.searchResults.isEmpty) {
      return Center(
        child: Text(
          '⚠️ 检索失败: ${state.searchError}',
          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
        ),
      );
    }

    if (!_hasSearched) {
      return _buildSearchHistory(themeColor);
    }

    if (state.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_dissatisfied_rounded, size: 64, color: onSurface.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              '🕵️ 换个书名搜搜看，或检查网络连接',
              style: TextStyle(color: onSurface.withOpacity(0.4), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (state.searchError != null) ...[
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
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    // Check if book is already on shelf
    final state = ref.watch(novelProvider);
    final bookshelf = widget.inAbyss ? state.abyssBookshelf : state.bookshelf;
    final bool alreadyAdded = bookshelf.any((p) => p.book?.title == book.title && p.book?.author == book.author);

    return GestureDetector(
      onTap: () {
        // Synchronously calculate target bookId using same MD5 algorithm
        final bytes = utf8.encode('${book.title}|${book.author}');
        final calculatedId = md5.convert(bytes).toString();
        
        // Trigger add and select in the background asynchronously
        ref.read(novelProvider.notifier).addAndSelectBook(book, widget.inAbyss);
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NovelReaderScreen(
              bookId: calculatedId,
              inAbyss: widget.inAbyss,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: onSurface.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: onSurface.withOpacity(0.04)),
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
                      : (theme.brightness == Brightness.dark
                          ? [const Color(0xFF1E202C), const Color(0xFF323545)]
                          : [theme.colorScheme.primaryContainer, theme.colorScheme.secondaryContainer]),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                book.title.isNotEmpty ? book.title.substring(0, 1) : '书',
                style: TextStyle(
                  fontSize: 16, 
                  color: widget.inAbyss
                      ? Colors.white
                      : (theme.brightness == Brightness.dark ? Colors.white : theme.colorScheme.onPrimaryContainer), 
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: onSurface),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '作者：${book.author}',
                        style: TextStyle(fontSize: 11.5, color: onSurface.withOpacity(0.6)),
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
                    style: TextStyle(fontSize: 11, color: onSurface.withOpacity(0.4), height: 1.4),
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
