import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/novel_models.dart';
import '../../provider/novel_provider.dart';
import '../novel_reader_screen.dart';

class BookOasisTab extends StatefulWidget {
  final void Function(String query) onSearchTriggered;
  final bool inAbyss;

  const BookOasisTab({
    super.key,
    required this.onSearchTriggered,
    required this.inAbyss,
  });

  @override
  State<BookOasisTab> createState() => _BookOasisTabState();
}

class _BookOasisTabState extends State<BookOasisTab> {
  String _selectedMood = '热血';

  final List<String> _moods = ['热血', '治愈', '烧脑', '甜宠', '暗黑', '爆笑', '修仙'];

  final List<Map<String, String>> _blindBoxBooks = [
    {
      'title': '深渊之下',
      'author': '诡秘之主',
      'summary': '在无尽的黑暗之中，那些古老而不可名状的存在正在悄然苏醒。只有点燃灵魂，才能照亮前路...',
      'cover': 'https://img.biquge.org/1.jpg'
    },
    {
      'title': '午夜心跳俱乐部',
      'author': '红唇刺客',
      'summary': 'PO18超人气大作，深夜降临时的暧昧游戏。隐藏在面具之下的真实欲望，在这一刻彻底爆发...',
      'cover': 'https://img.biquge.org/2.jpg'
    },
    {
      'title': '量子修仙指南',
      'author': '薛定谔的猫',
      'summary': '当现代高能物理撞上修真仙侠！波粒二象性金丹，量子纠缠双修，带你领略不一样的硬核仙途！',
      'cover': 'https://img.biquge.org/3.jpg'
    },
    {
      'title': '极客觉醒',
      'author': '比特风暴',
      'summary': '代码构建的世界正在崩塌，数字幽灵四处穿梭。一个底层的程序员，如何通过黑客技术拯救未来？',
      'cover': 'https://img.biquge.org/4.jpg'
    }
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        // 1. Mood chips horizontal bar
        _buildSectionTitle('🔮 当前心境', '心情决定阅读'),
        _buildMoodChips(),
        const SizedBox(height: 24),

        // 2. 3D Swipeable Blindbox Card
        _buildSectionTitle('🎁 每日盲盒', '左滑跳过 · 右滑加架 · 轻触翻转'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: BlindBoxCardStack(
            books: _blindBoxBooks,
            inAbyss: widget.inAbyss,
          ),
        ),
        const SizedBox(height: 32),

        // 3. Canvas bubble cloud tag maze
        _buildSectionTitle('🌀 分类星云', '点击气泡快速搜书'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: BubbleCloudTagMaze(
            onTagSelected: widget.onSearchTriggered,
            inAbyss: widget.inAbyss,
          ),
        ),
        const SizedBox(height: 32),

        // 4. Ranking lists
        _buildSectionTitle('🔥 绿洲风云榜', '全网精选实时热度'),
        _buildRankListFlow(),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.0,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodChips() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _moods.length,
        itemBuilder: (context, index) {
          final mood = _moods[index];
          final isSelected = mood == _selectedMood;
          final color = widget.inAbyss 
              ? Colors.purpleAccent 
              : Colors.pinkAccent;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedMood = mood;
              });
              // Perform a mood-based quick search
              widget.onSearchTriggered(mood);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [color.withOpacity(0.8), color],
                      )
                    : null,
                color: isSelected ? null : Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected 
                      ? color.withOpacity(0.5) 
                      : Colors.white.withOpacity(0.06),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                mood,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRankListFlow() {
    final ranks = [
      {'title': '人气榜', 'books': ['万古第一神', '深空彼岸', '灵境行者']},
      {'title': '热搜榜', 'books': ['赤心巡天', '宿命之环', '光阴之外']},
      {'title': '新书榜', 'books': ['谁让他修仙的', '苟在仙界娶妻', '修仙从长生不老开始']},
    ];

    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: ranks.length,
        itemBuilder: (context, index) {
          final r = ranks[index];
          final color = widget.inAbyss ? Colors.purpleAccent : Colors.pinkAccent;
          
          return Container(
            width: 220,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      r['title'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: color,
                      ),
                    ),
                    const Icon(Icons.trending_up_rounded, size: 16, color: Colors.white30),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: (r['books'] as List<String>).asMap().entries.map((entry) {
                      final i = entry.key;
                      final bName = entry.value;
                      return GestureDetector(
                        onTap: () => widget.onSearchTriggered(bName),
                        child: Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: i == 0 ? color.withOpacity(0.2) : Colors.white10,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: i == 0 ? color : Colors.white60,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                bName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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

// ========================================================
// 📦 3D Swipeable Blindbox Card Stack implementation
// ========================================================
class BlindBoxCardStack extends ConsumerStatefulWidget {
  final List<Map<String, String>> books;
  final bool inAbyss;

  const BlindBoxCardStack({super.key, required this.books, required this.inAbyss});

  @override
  ConsumerState<BlindBoxCardStack> createState() => _BlindBoxCardStackState();
}

class _BlindBoxCardStackState extends ConsumerState<BlindBoxCardStack> with SingleTickerProviderStateMixin {
  late List<Map<String, String>> _cards;
  double _swipeOffsetX = 0.0;
  double _swipeOffsetY = 0.0;
  double _rotationAngle = 0.0;
  bool _isFlipped = false;
  
  late AnimationController _flipController;

  @override
  void initState() {
    super.initState();
    _cards = List.from(widget.books);
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _swipeOffsetX += details.delta.dx;
      _swipeOffsetY += details.delta.dy;
      // Calculate angle based on offset
      _rotationAngle = (_swipeOffsetX / 300.0) * 0.15;
    });
  }

  void _onPanEnd(DragEndDetails details, BuildContext context) {
    final double velocity = details.velocity.pixelsPerSecond.dx;
    if (_swipeOffsetX.abs() > 120 || velocity.abs() > 800) {
      final bool isRight = _swipeOffsetX > 0;
      // Swipe out animation
      final double endX = isRight ? 500.0 : -500.0;
      
      setState(() {
        _swipeOffsetX = endX;
      });

      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          if (isRight) {
            // Trigger Add to Shelf action
            final topBook = _cards.first;
            final bookObj = Book(
              id: '',
              title: topBook['title'] ?? '',
              author: topBook['author'] ?? '',
              coverUrl: topBook['cover'] ?? '',
              summary: topBook['summary'] ?? '',
              isAbyss: widget.inAbyss,
            );
            ref.read(novelProvider.notifier).addBookToShelf(bookObj, widget.inAbyss);
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('📚 已将《${topBook['title']}》加入书架'),
                  backgroundColor: widget.inAbyss ? Colors.purple : Colors.pinkAccent,
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          }
          setState(() {
            _cards.removeAt(0);
            if (_cards.isEmpty) {
              _cards = List.from(widget.books); // Refill stack
            }
            _swipeOffsetX = 0.0;
            _swipeOffsetY = 0.0;
            _rotationAngle = 0.0;
            _isFlipped = false;
            _flipController.reset();
          });
        }
      });
    } else {
      // Revert position
      setState(() {
        _swipeOffsetX = 0.0;
        _swipeOffsetY = 0.0;
        _rotationAngle = 0.0;
      });
    }
  }

  void _toggleFlip() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) return const SizedBox(height: 240);

    return SizedBox(
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: _cards.asMap().entries.map((entry) {
          final int index = entry.key;
          final book = entry.value;

          // Render only top 3 cards for efficiency
          if (index > 2) return const SizedBox.shrink();

          // Stack order: reverse index rendering so top card is drawn last
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
                    : Colors.white.withOpacity(0.08),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: AnimatedBuilder(
                animation: _flipController,
                builder: (context, child) {
                  // Apply 3D Matrix flip transform
                  final double angle = _flipController.value * pi;
                  final isBack = angle > pi / 2;
                  
                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // perspective
                      ..rotateY(angle),
                    alignment: Alignment.center,
                    child: isBack
                        ? Transform(
                            transform: Matrix4.identity()..rotateY(pi),
                            alignment: Alignment.center,
                            child: _buildCardBack(book),
                          )
                        : _buildCardFront(book),
                  );
                },
              ),
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
                  onTap: _toggleFlip,
                  onDoubleTap: () async {
                    final topBook = _cards.first;
                    final bookObj = Book(
                      id: '',
                      title: topBook['title'] ?? '',
                      author: topBook['author'] ?? '',
                      coverUrl: topBook['cover'] ?? '',
                      summary: topBook['summary'] ?? '',
                      isAbyss: widget.inAbyss,
                    );
                    
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(color: Colors.pinkAccent),
                      ),
                    );
                    
                    final progress = await ref.read(novelProvider.notifier).addAndSelectBook(bookObj, widget.inAbyss);
                    
                    if (context.mounted) {
                      Navigator.pop(context); // Dismiss loading
                    }
                    
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
                  },
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
        }).toList().reversed.toList(), // Draw background cards first
      ),
    );
  }

  Widget _buildCardFront(Map<String, String> book) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.inAbyss
              ? [const Color(0xFF1E083A), const Color(0xFF0F041F)]
              : [const Color(0xFF161D30), const Color(0xFF0D1220)],
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
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(2, 4),
                  )
                ],
                gradient: LinearGradient(
                  colors: widget.inAbyss
                      ? [Colors.deepPurple, Colors.purpleAccent]
                      : [const Color(0xFF2C5364), const Color(0xFF0F2027)],
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    book['title']!.substring(0, 1),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    book['title']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                ],
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
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('✨ 今日推荐', style: TextStyle(fontSize: 9, color: Colors.amberAccent)),
                ),
                const SizedBox(height: 10),
                Text(
                  book['title']!,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  '作者：${book['author']}',
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
                const SizedBox(height: 12),
                Text(
                  book['summary']!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.white38, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(Map<String, String> book) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C0A21),
        border: Border.all(
          color: widget.inAbyss ? Colors.purpleAccent.withOpacity(0.3) : Colors.pinkAccent.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                Icons.menu_book_rounded,
                color: widget.inAbyss ? Colors.purpleAccent : Colors.pinkAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                '剧情简介与元数据',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.white10),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Text(
                book['summary']!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12.5,
                  height: 1.6,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              '点击再次翻转 · 右滑一键加入书架',
              style: TextStyle(
                fontSize: 10,
                color: widget.inAbyss ? Colors.purpleAccent.withOpacity(0.6) : Colors.pinkAccent.withOpacity(0.6),
              ),
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
          color: widget.inAbyss
              ? Colors.purpleAccent.withOpacity(0.12 + _random.nextDouble() * 0.1)
              : Colors.pinkAccent.withOpacity(0.12 + _random.nextDouble() * 0.1),
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
    return GestureDetector(
      onTapUp: _onTapUp,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.01),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.inAbyss 
                ? Colors.purpleAccent.withOpacity(0.15) 
                : Colors.white.withOpacity(0.05),
          ),
        ),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            // Update bubble physics positions
            final double w = 340;
            final double h = 180;

            for (final bubble in _bubbles) {
              bubble.x += bubble.vx;
              bubble.y += bubble.vy;

              // Wall bounce check
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
              ),
              size: const Size(double.infinity, 180),
            );
          },
        ),
      ),
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
  final Color color;

  CloudBubble({
    required this.label,
    required this.x,
    required this.y,
    required this.radius,
    required this.vx,
    required this.vy,
    required this.color,
  });
}

class BubbleCloudPainter extends CustomPainter {
  final List<CloudBubble> bubbles;
  final bool inAbyss;

  BubbleCloudPainter({required this.bubbles, required this.inAbyss});

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = inAbyss 
          ? Colors.purpleAccent.withOpacity(0.3) 
          : Colors.pinkAccent.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final bubble in bubbles) {
      // Draw background bubble
      final bgPaint = Paint()
        ..color = bubble.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(bubble.x, bubble.y), bubble.radius, bgPaint);
      canvas.drawCircle(Offset(bubble.x, bubble.y), bubble.radius, borderPaint);

      // Draw text label centered
      final textSpan = TextSpan(
        text: bubble.label,
        style: TextStyle(
          fontSize: bubble.radius > 30 ? 11.5 : 10,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
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
