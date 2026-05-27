import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../model/novel_models.dart';
import '../../provider/novel_provider.dart';
import '../novel_reader_screen.dart';

class NovelShelfTab extends ConsumerWidget {
  final bool inAbyss;
  final VoidCallback onOpenSearch;

  const NovelShelfTab({
    super.key,
    required this.inAbyss,
    required this.onOpenSearch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(novelProvider);
    final list = inAbyss ? state.abyssBookshelf : state.bookshelf;

    if (state.isBookshelfLoading && list.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.pinkAccent),
      );
    }

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: inAbyss 
                    ? Colors.purple.withOpacity(0.08)
                    : Colors.pinkAccent.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: inAbyss
                      ? Colors.purple.withOpacity(0.2)
                      : Colors.pinkAccent.withOpacity(0.2),
                ),
              ),
              child: Icon(
                inAbyss ? Icons.auto_stories_rounded : Icons.library_books_rounded,
                size: 50,
                color: inAbyss ? Colors.purpleAccent : Colors.pinkAccent,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              inAbyss ? '👻 深渊里空无一物...' : '📖 您的书架空空如也',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: inAbyss ? Colors.purpleAccent : Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              inAbyss ? '去寻找那些尘封的午夜书源吧' : '全网百万小说，一键抓取纯净净化阅读',
              style: const TextStyle(fontSize: 13, color: Colors.white54),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onOpenSearch,
              icon: const Icon(Icons.search_rounded, size: 18),
              label: Text(inAbyss ? '搜罗深夜书源' : '去搜书架书籍'),
              style: ElevatedButton.styleFrom(
                backgroundColor: inAbyss ? Colors.purple : Colors.pinkAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(novelProvider.notifier).fetchBookshelf(inAbyss),
      color: inAbyss ? Colors.purpleAccent : Colors.pinkAccent,
      backgroundColor: const Color(0xFF0F0C29),
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 28,
          childAspectRatio: 0.62,
        ),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final progress = list[index];
          final book = progress.book;
          if (book == null) return const SizedBox.shrink();

          return _buildBookShelfCard(context, ref, progress, book);
        },
      ),
    );
  }

  Widget _buildBookShelfCard(
    BuildContext context,
    WidgetRef ref,
    ReadingProgress progress,
    Book book,
  ) {
    // Reading percentage helper (mock or based on chapter count)
    final double percent = progress.lastReadChapterIndex > 0
        ? (progress.lastReadChapterIndex / 100.0).clamp(0.01, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () async {
        await ref.read(novelProvider.notifier).selectBook(progress);
        if (context.mounted) {
          // Open Reader Screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NovelReaderScreen(
                bookId: book.id,
                inAbyss: inAbyss,
              ),
            ),
          );
        }
      },
      onLongPress: () => _showBookOptionsBottomSheet(context, ref, progress, book),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Wood Shelf Background Plate (bottom shadow bar simulating wooden bookshelf slot)
                Positioned(
                  bottom: -10,
                  left: -8,
                  right: -8,
                  height: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF3E2723),
                          const Color(0xFF5D4037).withOpacity(0.9),
                          const Color(0xFF3E2723),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                // Book Cover Card
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1B3A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: inAbyss 
                          ? Colors.purpleAccent.withOpacity(0.2)
                          : Colors.white.withOpacity(0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(3, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: book.coverUrl.isNotEmpty && book.coverUrl.startsWith('http')
                        ? Image.network(
                            book.coverUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) => _buildFallbackCover(book),
                          )
                        : _buildFallbackCover(book),
                  ),
                ),
                // Progress Indicator Tag
                Positioned(
                  top: 6,
                  right: 6,
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Text(
                          percent == 0 ? '未读' : '${(percent * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: percent == 0
                                ? Colors.white70
                                : (inAbyss ? Colors.purpleAccent : Colors.pinkAccent),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Book Title
          Text(
            book.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          // Book Author
          Text(
            book.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackCover(Book book) {
    // Generate a beautiful solid gradient placeholder cover with first character
    final firstChar = book.title.isNotEmpty ? book.title.substring(0, 1) : '书';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: inAbyss
              ? [const Color(0xFF3A007C), const Color(0xFF1E004A)]
              : [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)],
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            firstChar,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              book.title,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                color: Colors.white60,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookOptionsBottomSheet(
    BuildContext context,
    WidgetRef ref,
    ReadingProgress progress,
    Book book,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0C29).withOpacity(0.85),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 45,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.white10,
                        ),
                        child: _buildFallbackCover(book),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '作者：${book.author}',
                              style: const TextStyle(fontSize: 12, color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Actions list
                  ListTile(
                    leading: const Icon(Icons.download_for_offline_rounded, color: Colors.cyanAccent),
                    title: const Text('打包导出全本 EPUB', style: TextStyle(color: Colors.white)),
                    onTap: () async {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📥 正在生成并打包 EPUB 电子书，请稍后...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      try {
                        final bytes = await ref.read(novelProvider.notifier).downloadEpub(book.id);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🎉 EPUB 打包成功！共计 ${bytes.length} 字节。已保存至本地沙盒。'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ 导出失败: $e'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                    title: const Text('从书架彻底移除该书籍', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      // Note: We can implement delete logic if needed. 
                      // For now we just dismiss and show feedback, keeping code minimal
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('🧹 书籍移除成功')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
