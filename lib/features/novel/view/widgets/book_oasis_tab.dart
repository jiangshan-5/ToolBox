import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/novel_models.dart';
import '../../provider/novel_provider.dart';
import '../novel_reader_screen.dart';

class BookOasisTab extends ConsumerStatefulWidget {
  final void Function(String query) onSearchTriggered;
  final bool inAbyss;

  const BookOasisTab({
    super.key,
    required this.onSearchTriggered,
    required this.inAbyss,
  });

  @override
  ConsumerState<BookOasisTab> createState() => _BookOasisTabState();
}

class _BookOasisTabState extends ConsumerState<BookOasisTab> {
  List<Book>? _blindBoxBooks;

  final List<Book> _fallbackBlindBoxBooks = [
    Book(
      id: 'mock_bb_1',
      title: '深渊之下',
      author: '诡秘之主',
      summary: '在无尽的黑暗之中，那些古老而不可名状的存在正在悄然苏醒。只有点燃灵魂，才能照亮前路...',
      coverUrl: 'https://img.biquge.org/1.jpg',
      isAbyss: false,
    ),
    Book(
      id: 'mock_bb_2',
      title: '午夜心跳俱乐部',
      author: '红唇刺客',
      summary: 'PO18超人气大作，深夜降临时的暧昧游戏。隐藏在面具之下的真实欲望，在这一刻彻底爆发...',
      coverUrl: 'https://img.biquge.org/2.jpg',
      isAbyss: false,
    ),
    Book(
      id: 'mock_bb_3',
      title: '量子修仙指南',
      author: '薛定谔的猫',
      summary: '当现代高能物理撞上修真仙侠！波粒二象性金丹，量子纠缠双修，带你领略不一样的硬核仙途！',
      coverUrl: 'https://img.biquge.org/3.jpg',
      isAbyss: false,
    ),
    Book(
      id: 'mock_bb_4',
      title: '极客觉醒',
      author: '比特风暴',
      summary: '代码构建的世界正在崩塌，数字幽灵四处穿梭。一个底层的程序员，如何通过黑客技术拯救未来？',
      coverUrl: 'https://img.biquge.org/4.jpg',
      isAbyss: false,
    )
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(novelProvider);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    if (_blindBoxBooks == null) {
      if (state.exploreRankings.containsKey('每日盲盒') && state.exploreRankings['每日盲盒']!.isNotEmpty) {
        _blindBoxBooks = List.from(state.exploreRankings['每日盲盒']!)..shuffle();
      } else if (state.exploreRankings.isNotEmpty) {
        final allBooks = <Book>[];
        state.exploreRankings.forEach((key, list) {
          if (key != '每日盲盒') {
            allBooks.addAll(list);
          }
        });
        if (allBooks.isNotEmpty) {
          allBooks.shuffle();
          _blindBoxBooks = allBooks.take(5).toList();
        }
      }
      if ((_blindBoxBooks == null || _blindBoxBooks!.isEmpty) && !state.isRankingsLoading) {
        _blindBoxBooks = List.from(_fallbackBlindBoxBooks)..shuffle();
      }
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _blindBoxBooks = null;
        });
        await ref.read(novelProvider.notifier).fetchExploreRankings();
      },
      color: widget.inAbyss ? Colors.purpleAccent : primaryColor,
      backgroundColor: widget.inAbyss ? const Color(0xFF1E083A) : theme.colorScheme.surface,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // 1. 3D Swipeable Blindbox Card
          _buildSectionTitle(
            '🎁 每日盲盒',
            '左滑跳过 · 右滑加架 · 轻触直接阅读',
            onRefresh: () async {
              setState(() {
                _blindBoxBooks = null;
              });
              await ref.read(novelProvider.notifier).fetchExploreRankings();
            },
            isRefreshing: state.isRankingsLoading,
          ),
          if (_blindBoxBooks != null && _blindBoxBooks!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: BlindBoxCardStack(
                books: _blindBoxBooks!,
                inAbyss: widget.inAbyss,
              ),
            )
          else
            SizedBox(
              height: 240,
              child: Center(
                child: CircularProgressIndicator(color: primaryColor.withOpacity(0.3)),
              ),
            ),
          const SizedBox(height: 32),

          // 2. Canvas bubble cloud tag maze
          _buildSectionTitle('🌀 分类星云', '点击气泡快速搜书'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: BubbleCloudTagMaze(
              onTagSelected: widget.onSearchTriggered,
              inAbyss: widget.inAbyss,
            ),
          ),
          const SizedBox(height: 32),

          // 3. Ranking lists
          _buildSectionTitle(
            '🔥 探索热度榜',
            '全网精选实时热度',
            onRefresh: () async {
              setState(() {
                _blindBoxBooks = null;
              });
              await ref.read(novelProvider.notifier).fetchExploreRankings();
            },
            isRefreshing: state.isRankingsLoading,
          ),
          _buildRankListFlow(state),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    String subtitle, {
    VoidCallback? onRefresh,
    bool isRefreshing = false,
  }) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: onSurface,
              letterSpacing: 1.0,
            ),
          ),
          if (onRefresh != null) ...[
            const SizedBox(width: 8),
            RefreshButton(
              onTap: onRefresh,
              isLoading: isRefreshing,
            ),
          ],
          const Spacer(),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankListFlow(NovelState state) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    if (state.isRankingsLoading && state.exploreRankings.isEmpty) {
      return SizedBox(
        height: 280,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor.withOpacity(0.5)),
          ),
        ),
      );
    }

    final rankings = state.exploreRankings;
    if (rankings.isEmpty) {
      return SizedBox(
        height: 280,
        child: Center(
          child: Text(
            '暂无排行数据',
            style: TextStyle(color: onSurface.withOpacity(0.4), fontSize: 13),
          ),
        ),
      );
    }

    final keys = ['人气榜', '热搜榜', '新书榜'];
    final color = widget.inAbyss ? Colors.purpleAccent : primaryColor;

    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: keys.length,
        itemBuilder: (context, index) {
          final key = keys[index];
          final List<Book> books = rankings[key] ?? [];
          final displayBooks = books.take(10).toList();

          return Container(
            width: 260,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: onSurface.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: onSurface.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      key,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: color,
                      ),
                    ),
                    Icon(Icons.trending_up_rounded, size: 16, color: onSurface.withOpacity(0.3)),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: displayBooks.length,
                    itemBuilder: (context, bookIndex) {
                      final book = displayBooks[bookIndex];
                      return GestureDetector(
                        onTap: () {
                          ref.read(novelProvider.notifier).addAndSelectBook(book, widget.inAbyss).then((progress) {
                            if (progress != null && context.mounted) {
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
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5.0),
                          child: Row(
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: bookIndex < 3 ? color.withOpacity(0.2) : onSurface.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${bookIndex + 1}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: bookIndex < 3 ? color : onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  book.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.85)),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                book.author,
                                style: TextStyle(fontSize: 10, color: onSurface.withOpacity(0.4)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class RefreshButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isLoading;

  const RefreshButton({
    super.key,
    required this.onTap,
    required this.isLoading,
  });

  @override
  State<RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<RefreshButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(RefreshButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return GestureDetector(
      onTap: widget.isLoading ? null : () {
        _controller.forward(from: 0.0);
        widget.onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: onSurface.withOpacity(0.06),
          shape: BoxShape.circle,
        ),
        child: RotationTransition(
          turns: _controller,
          child: Icon(
            Icons.refresh_rounded,
            size: 14,
            color: onSurface.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}

// ========================================================
// 📦 3D Swipeable Blindbox Card Stack implementation
// ========================================================
class BlindBoxCardStack extends ConsumerStatefulWidget {
  final List<Book> books;
  final bool inAbyss;

  const BlindBoxCardStack({super.key, required this.books, required this.inAbyss});

  @override
  ConsumerState<BlindBoxCardStack> createState() => _BlindBoxCardStackState();
}

class _BlindBoxCardStackState extends ConsumerState<BlindBoxCardStack> {
  late List<Book> _cards;
  double _swipeOffsetX = 0.0;
  double _swipeOffsetY = 0.0;
  double _rotationAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _cards = List.from(widget.books);
  }

  @override
  void didUpdateWidget(BlindBoxCardStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.books != oldWidget.books) {
      _cards = List.from(widget.books);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _swipeOffsetX += details.delta.dx;
      _swipeOffsetY += details.delta.dy;
      _rotationAngle = (_swipeOffsetX / 300.0) * 0.15;
    });
  }

  void _onPanEnd(DragEndDetails details, BuildContext context) {
    final double velocity = details.velocity.pixelsPerSecond.dx;
    final theme = Theme.of(context);
    if (_swipeOffsetX.abs() > 120 || velocity.abs() > 800) {
      final bool isRight = _swipeOffsetX > 0;
      final double endX = isRight ? 500.0 : -500.0;
      
      setState(() {
        _swipeOffsetX = endX;
      });

      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          final topBook = _cards.first;
          if (isRight) {
            ref.read(novelProvider.notifier).addBookToShelf(topBook, widget.inAbyss);
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('📚 已将《${topBook.title}》加入书架'),
                  backgroundColor: widget.inAbyss ? Colors.purple : theme.colorScheme.primary,
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          }
          setState(() {
            _cards.removeAt(0);
            if (_cards.isEmpty) {
              _cards = List.from(widget.books);
            }
            _swipeOffsetX = 0.0;
            _swipeOffsetY = 0.0;
            _rotationAngle = 0.0;
          });
        }
      });
    } else {
      setState(() {
        _swipeOffsetX = 0.0;
        _swipeOffsetY = 0.0;
        _rotationAngle = 0.0;
      });
    }
  }

  void _startReadingBook(Book book, BuildContext context) {
    ref.read(novelProvider.notifier).addAndSelectBook(book, widget.inAbyss).then((progress) {
      if (progress != null && context.mounted) {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) return const SizedBox(height: 240);
    final theme = Theme.of(context);

    return SizedBox(
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: _cards.asMap().entries.map((entry) {
          final int index = entry.key;
          final book = entry.value;

          if (index > 2) return const SizedBox.shrink();

          final bool isTop = index == 0;
          final double depthScale = 1.0 - (index * 0.05);
          final double depthTranslateY = index * 12.0;

          Widget cardWidget = Container(
            width: double.infinity,
            height: 230,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.inAbyss 
                    ? Colors.purpleAccent.withOpacity(0.2)
                    : theme.colorScheme.onSurface.withOpacity(0.08),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: _buildCardFront(book),
            ),
          );

          if (isTop) {
            return Positioned(
              left: _swipeOffsetX,
              top: _swipeOffsetY,
              right: -_swipeOffsetX,
              child: Transform.rotate(
                angle: _rotationAngle,
                child: GestureDetector(
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: (details) => _onPanEnd(details, context),
                  onTap: () => _startReadingBook(book, context),
                  child: cardWidget,
                ),
              ),
            );
          } else {
            return Positioned(
              top: depthTranslateY,
              left: 20.0 * index,
              right: 20.0 * index,
              child: Transform.scale(
                scale: depthScale,
                child: IgnorePointer(child: cardWidget),
              ),
            );
          }
        }).toList().reversed.toList(),
      ),
    );
  }

  Widget _buildCardFront(Book book) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.inAbyss
              ? [const Color(0xFF1E083A), const Color(0xFF0F041F)]
              : (theme.brightness == Brightness.dark
                  ? [const Color(0xFF161D30), const Color(0xFF0D1220)]
                  : [theme.colorScheme.surfaceContainerLow, theme.colorScheme.surfaceContainerHigh]),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.4 : 0.1),
                    blurRadius: 8,
                    offset: const Offset(2, 4),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: book.coverUrl.isNotEmpty
                    ? Image.network(
                        book.coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildCoverFallback(book.title);
                        },
                      )
                    : _buildCoverFallback(book.title),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('🎲 盲盒抽取', style: TextStyle(fontSize: 9, color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                Text(
                  book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  '作者：${book.author}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                ),
                const SizedBox(height: 12),
                Text(
                  book.summary,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverFallback(String title) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.inAbyss
              ? [Colors.deepPurple, Colors.purpleAccent]
              : (theme.brightness == Brightness.dark
                  ? [const Color(0xFF2C5364), const Color(0xFF0F2027)]
                  : [theme.colorScheme.primaryContainer, theme.colorScheme.secondaryContainer]),
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title.isNotEmpty ? title.substring(0, 1) : '书',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: widget.inAbyss
                  ? Colors.white
                  : (theme.brightness == Brightness.dark ? Colors.white : theme.colorScheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: widget.inAbyss
                  ? Colors.white70
                  : (theme.brightness == Brightness.dark ? Colors.white70 : theme.colorScheme.onPrimaryContainer.withOpacity(0.7)),
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================================
// 🌀 Canvas Bubble Cloud Tag Maze Widget implementation
// ========================================================
class BubbleCloudTagMaze extends StatefulWidget {
  final void Function(String query) onTagSelected;
  final bool inAbyss;

  const BubbleCloudTagMaze({super.key, required this.onTagSelected, required this.inAbyss});

  @override
  State<BubbleCloudTagMaze> createState() => _BubbleCloudTagMazeState();
}

class _BubbleCloudTagMazeState extends State<BubbleCloudTagMaze> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<CloudBubble> _bubbles = [];
  final Random _random = Random();

  final List<String> _regularGenres = ['玄幻', '都市', '科幻', '悬疑', '修仙', '历史', '纯爱', '轻小说'];
  final List<String> _abyssGenres = ['PO18', '海棠', '成人', '大尺度', '密室禁忌', '午夜激情', '肉香', '同人'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Initialize bubbles with positions and physics
    final genres = widget.inAbyss ? _abyssGenres : _regularGenres;
    final double areaWidth = 320;
    final double areaHeight = 160;

    for (int i = 0; i < genres.length; i++) {
      _bubbles.add(
        CloudBubble(
          label: genres[i],
          x: _random.nextDouble() * (areaWidth - 60) + 30,
          y: _random.nextDouble() * (areaHeight - 60) + 30,
          radius: _random.nextDouble() * 10 + 26,
          vx: (_random.nextDouble() - 0.5) * 0.6,
          vy: (_random.nextDouble() - 0.5) * 0.6,
          opacity: 0.12 + _random.nextDouble() * 0.1,
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapUp(TapUpDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPos = box.globalToLocal(details.globalPosition);

    for (final bubble in _bubbles) {
      final dx = localPos.dx - bubble.x;
      final dy = localPos.dy - bubble.y;
      final distance = sqrt(dx * dx + dy * dy);
      if (distance < bubble.radius) {
        widget.onTagSelected(bubble.label);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final double h = 180.0;

        return GestureDetector(
          onTapUp: _onTapUp,
          child: Container(
            height: h,
            decoration: BoxDecoration(
              color: onSurface.withOpacity(0.01),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.inAbyss 
                    ? Colors.purpleAccent.withOpacity(0.15) 
                    : onSurface.withOpacity(0.05),
              ),
            ),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                // 1. Update bubble physics positions
                for (final bubble in _bubbles) {
                  bubble.x += bubble.vx;
                  bubble.y += bubble.vy;
                }

                // 2. Resolve circle-circle collisions (elastic bounce)
                for (int i = 0; i < _bubbles.length; i++) {
                  for (int j = i + 1; j < _bubbles.length; j++) {
                    final b1 = _bubbles[i];
                    final b2 = _bubbles[j];
                    final dx = b2.x - b1.x;
                    final dy = b2.y - b1.y;
                    final dist = sqrt(dx * dx + dy * dy);
                    final minDist = b1.radius + b2.radius;

                    if (dist < minDist) {
                      // Resolve overlap
                      final overlap = minDist - dist;
                      final nx = dx / (dist == 0 ? 1 : dist);
                      final ny = dy / (dist == 0 ? 1 : dist);

                      // Push apart
                      b1.x -= nx * overlap * 0.5;
                      b1.y -= ny * overlap * 0.5;
                      b2.x += nx * overlap * 0.5;
                      b2.y += ny * overlap * 0.5;

                      // Elastic collision velocity change
                      final rvx = b2.vx - b1.vx;
                      final rvy = b2.vy - b1.vy;
                      final velAlongNormal = rvx * nx + rvy * ny;

                      if (velAlongNormal < 0) {
                        const double restitution = 0.9;
                        final impulseScalar = -(1.0 + restitution) * velAlongNormal / 2.0;

                        b1.vx -= nx * impulseScalar;
                        b1.vy -= ny * impulseScalar;
                        b2.vx += nx * impulseScalar;
                        b2.vy += ny * impulseScalar;
                      }
                    }
                  }
                }

                // 3. Wall bounce check & boundary clamp
                for (final bubble in _bubbles) {
                  if (bubble.x - bubble.radius < 0 || bubble.x + bubble.radius > w) {
                    bubble.vx = -bubble.vx;
                    bubble.x = bubble.x.clamp(bubble.radius, w - bubble.radius);
                  }
                  if (bubble.y - bubble.radius < 0 || bubble.y + bubble.radius > h) {
                    bubble.vy = -bubble.vy;
                    bubble.y = bubble.y.clamp(bubble.radius, h - bubble.radius);
                  }
                }

                return CustomPaint(
                  painter: BubbleCloudPainter(
                    bubbles: _bubbles,
                    inAbyss: widget.inAbyss,
                    theme: theme,
                  ),
                  size: Size(w, h),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class CloudBubble {
  final String label;
  double x;
  double y;
  final double radius;
  double vx;
  double vy;
  final double opacity;

  CloudBubble({
    required this.label,
    required this.x,
    required this.y,
    required this.radius,
    required this.vx,
    required this.vy,
    required this.opacity,
  });
}

class BubbleCloudPainter extends CustomPainter {
  final List<CloudBubble> bubbles;
  final bool inAbyss;
  final ThemeData theme;

  BubbleCloudPainter({required this.bubbles, required this.inAbyss, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = inAbyss 
          ? Colors.purpleAccent.withOpacity(0.3) 
          : theme.colorScheme.primary.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final primaryColor = inAbyss ? Colors.purpleAccent : theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    for (final bubble in bubbles) {
      // Draw background bubble
      final bgPaint = Paint()
        ..color = primaryColor.withOpacity(bubble.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(bubble.x, bubble.y), bubble.radius, bgPaint);
      canvas.drawCircle(Offset(bubble.x, bubble.y), bubble.radius, borderPaint);

      // Draw text label centered
      final textSpan = TextSpan(
        text: bubble.label,
        style: TextStyle(
          fontSize: bubble.radius > 30 ? 11.5 : 10,
          fontWeight: FontWeight.bold,
          color: inAbyss
              ? Colors.white70
              : onSurface.withOpacity(0.8),
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(
          bubble.x - textPainter.width / 2,
          bubble.y - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
