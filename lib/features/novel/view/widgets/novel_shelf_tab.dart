import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../model/novel_models.dart';
import '../../provider/novel_provider.dart';
import '../novel_reader_screen.dart';

class NovelShelfTab extends ConsumerStatefulWidget {
  final bool inAbyss;
  final VoidCallback onOpenSearch;

  const NovelShelfTab({
    super.key,
    required this.inAbyss,
    required this.onOpenSearch,
  });

  @override
  ConsumerState<NovelShelfTab> createState() => _NovelShelfTabState();
}

class _NovelShelfTabState extends ConsumerState<NovelShelfTab> {
  bool _isMultiSelectMode = false;
  final Set<String> _selectedBookIds = {};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(novelProvider);
    final list = widget.inAbyss ? state.abyssBookshelf : state.bookshelf;
    final themeColor = widget.inAbyss ? Colors.purpleAccent : Colors.pinkAccent;

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
                color: widget.inAbyss 
                    ? Colors.purple.withOpacity(0.08)
                    : Colors.pinkAccent.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.inAbyss
                      ? Colors.purple.withOpacity(0.2)
                      : Colors.pinkAccent.withOpacity(0.2),
                ),
              ),
              child: Icon(
                widget.inAbyss ? Icons.auto_stories_rounded : Icons.library_books_rounded,
                size: 50,
                color: themeColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.inAbyss ? '👻 深渊里空无一物...' : '📖 您的书架空空如也',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.inAbyss ? Colors.purpleAccent : Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.inAbyss ? '去寻找那些尘封的午夜书源吧' : '全网百万小说，一键抓取纯净净化阅读',
              style: const TextStyle(fontSize: 13, color: Colors.white54),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: widget.onOpenSearch,
              icon: const Icon(Icons.search_rounded, size: 18),
              label: Text(widget.inAbyss ? '搜罗深夜书源' : '去搜书架书籍'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.inAbyss ? Colors.purple : Colors.pinkAccent,
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

    return PopScope(
      canPop: !_isMultiSelectMode,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_isMultiSelectMode) {
          setState(() {
            _isMultiSelectMode = false;
            _selectedBookIds.clear();
          });
        }
      },
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => ref.read(novelProvider.notifier).fetchBookshelf(widget.inAbyss),
            color: themeColor,
            backgroundColor: const Color(0xFF0F0C29),
            child: GridView.builder(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: _isMultiSelectMode ? 100 : 20,
              ),
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

                return _buildBookShelfCard(context, ref, progress, book, themeColor);
              },
            ),
          ),
          
          // Sliding Glassmorphism Select Actions Bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            bottom: _isMultiSelectMode ? 20 : -100,
            left: 16,
            right: 16,
            height: 64,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1B3A).withOpacity(0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: themeColor.withOpacity(0.25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Select All / Deselect All Action
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            final allSelected = _selectedBookIds.length == list.length;
                            if (allSelected) {
                              _selectedBookIds.clear();
                            } else {
                              _selectedBookIds.clear();
                              for (var item in list) {
                                if (item.book != null) {
                                  _selectedBookIds.add(item.book!.id);
                                }
                              }
                            }
                          });
                        },
                        icon: Icon(
                          _selectedBookIds.length == list.length
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          color: themeColor,
                          size: 18,
                        ),
                        label: Text(
                          _selectedBookIds.length == list.length ? '全不选' : '全选',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                      const Spacer(),
                      // Count Indicator
                      Text(
                        '已选 ${_selectedBookIds.length} 本',
                        style: TextStyle(
                          color: themeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      // Cancel Button
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isMultiSelectMode = false;
                            _selectedBookIds.clear();
                          });
                        },
                        child: const Text(
                          '取消',
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Batch Delete Action
                      ElevatedButton.icon(
                        onPressed: _selectedBookIds.isEmpty
                            ? null
                            : () => _confirmBatchDelete(context, ref, list),
                        icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                        label: const Text(
                          '移除',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withOpacity(0.9),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.white12,
                          disabledForegroundColor: Colors.white30,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookShelfCard(
    BuildContext context,
    WidgetRef ref,
    ReadingProgress progress,
    Book book,
    Color themeColor,
  ) {
    final double percent = progress.lastReadChapterIndex > 0
        ? (progress.lastReadChapterIndex / 100.0).clamp(0.01, 1.0)
        : 0.0;

    final isSelected = _selectedBookIds.contains(book.id);

    return GestureDetector(
      onTap: () async {
        if (_isMultiSelectMode) {
          setState(() {
            if (isSelected) {
              _selectedBookIds.remove(book.id);
              if (_selectedBookIds.isEmpty) {
                _isMultiSelectMode = false;
              }
            } else {
              _selectedBookIds.add(book.id);
            }
          });
        } else {
          await ref.read(novelProvider.notifier).selectBook(progress);
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NovelReaderScreen(
                  bookId: book.id,
                  inAbyss: widget.inAbyss,
                ),
              ),
            );
          }
        }
      },
      onLongPress: () {
        if (_isMultiSelectMode) {
          // In multi-select, long press toggles selection
          setState(() {
            if (isSelected) {
              _selectedBookIds.remove(book.id);
              if (_selectedBookIds.isEmpty) {
                _isMultiSelectMode = false;
              }
            } else {
              _selectedBookIds.add(book.id);
            }
          });
        } else {
          _showBookOptionsBottomSheet(context, ref, progress, book, themeColor);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Wood Shelf Background Plate
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
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1B3A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? themeColor
                          : (widget.inAbyss 
                              ? Colors.purpleAccent.withOpacity(0.2)
                              : Colors.white.withOpacity(0.08)),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected 
                            ? themeColor.withOpacity(0.25)
                            : Colors.black.withOpacity(0.3),
                        blurRadius: isSelected ? 8 : 6,
                        offset: const Offset(3, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        book.coverUrl.isNotEmpty && book.coverUrl.startsWith('http')
                            ? Image.network(
                                book.coverUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildFallbackCover(book),
                              )
                            : _buildFallbackCover(book),
                        
                        // Dark overlay when selected or in multi-select mode
                        if (_isMultiSelectMode)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            color: isSelected
                                ? themeColor.withOpacity(0.2)
                                : Colors.black45,
                          ),
                      ],
                    ),
                  ),
                ),
                // Progress Indicator Tag
                if (!_isMultiSelectMode)
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
                                  : themeColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                
                // Checkbox indicator in multi-select mode
                if (_isMultiSelectMode)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 20,
                        color: isSelected ? themeColor : Colors.white60,
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
    final firstChar = book.title.isNotEmpty ? book.title.substring(0, 1) : '书';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.inAbyss
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

  void _confirmBatchDelete(BuildContext context, WidgetRef ref, List<ReadingProgress> list) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF140F2D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: (widget.inAbyss ? Colors.purpleAccent : Colors.pinkAccent).withOpacity(0.3),
            width: 1.5,
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
            const SizedBox(width: 8),
            Text(
              '确认删除',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          '确定要从书架移除这 ${_selectedBookIds.length} 本书籍吗？该操作同时清理对应的阅读进度与章节缓存。',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              
              final idsToDelete = _selectedBookIds.toList();
              
              setState(() {
                _isMultiSelectMode = false;
                _selectedBookIds.clear();
              });

              try {
                await ref.read(novelProvider.notifier).removeBooksFromShelf(idsToDelete, widget.inAbyss);
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('🧹 成功移除 ${idsToDelete.length} 本书籍'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('❌ 移除失败: $e'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('确定删除', style: TextStyle(color: Colors.white)),
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
    Color themeColor,
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
                    leading: Icon(Icons.checklist_rounded, color: themeColor),
                    title: const Text('批量管理书籍', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _isMultiSelectMode = true;
                        _selectedBookIds.clear();
                        _selectedBookIds.add(book.id);
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                    title: const Text('从书架彻底移除该书籍', style: TextStyle(color: Colors.white)),
                    onTap: () async {
                      Navigator.pop(context);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      try {
                        await ref.read(novelProvider.notifier).removeBooksFromShelf([book.id], widget.inAbyss);
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('🧹 书籍已成功从书架移除')),
                        );
                      } catch (e) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text('❌ 移除失败: $e'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
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
