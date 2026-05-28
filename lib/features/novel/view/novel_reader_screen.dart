import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../model/novel_models.dart';
import '../provider/novel_provider.dart';

class NovelReaderScreen extends ConsumerStatefulWidget {
  final String bookId;
  final bool inAbyss;

  const NovelReaderScreen({
    super.key,
    required this.bookId,
    required this.inAbyss,
  });

  @override
  ConsumerState<NovelReaderScreen> createState() => _NovelReaderScreenState();
}

class _NovelReaderScreenState extends ConsumerState<NovelReaderScreen> with SingleTickerProviderStateMixin {
  // Reading Typography configurations
  double _fontSize = 18.0;
  double _lineHeight = 1.6;
  bool _isSerif = true; // Georgia/Serif vs default
  double _marginHorizontal = 20.0;

  // Eye-care color themes: [Background Color, Text Color, Name]
  final List<List<dynamic>> _themes = [
    [const Color(0xFFF7F1E3), const Color(0xFF2C2518), '宣纸'],
    [const Color(0xFFE3F2FD), const Color(0xFF0D47A1), '海洋'],
    [const Color(0xFFE8F5E9), const Color(0xFF1B5E20), '护眼'],
    [const Color(0xFF1A1A24), const Color(0xFFA0A0C0), '极夜'],
    [const Color(0xFF0A0714), const Color(0xFFD0D0FF), '深渊'],
  ];
  int _activeThemeIndex = 0;

  late PageController _pageController;
  bool _showControlOverlay = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _autoApplyTimeTheme();
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Pause TTS on exit to avoid background ghost running and network spam
    ref.read(novelProvider.notifier).pauseTts();
    super.dispose();
  }

  /// Time-based eye-care auto-adjustment theme loader
  void _autoApplyTimeTheme() {
    final hour = DateTime.now().hour;
    if (widget.inAbyss) {
      _activeThemeIndex = 4; // Force deep dark in abyss
      return;
    }
    if (hour >= 18 || hour < 6) {
      _activeThemeIndex = 3; // Night
    } else {
      _activeThemeIndex = 0; // Day Paper
    }
  }

  void _onPrevChapter(NovelState state) {
    if (state.currentBookProgress == null) return;
    final curIdx = state.currentBookProgress!.lastReadChapterIndex;
    if (curIdx > 1) {
      ref.read(novelProvider.notifier).loadChapterContent(widget.bookId, curIdx - 1);
    }
  }

  void _onNextChapter(NovelState state) {
    if (state.currentBookProgress == null) return;
    final curIdx = state.currentBookProgress!.lastReadChapterIndex;
    if (curIdx < state.chapters.length) {
      ref.read(novelProvider.notifier).loadChapterContent(widget.bookId, curIdx + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(novelProvider);
    final themeBg = _themes[_activeThemeIndex][0] as Color;
    final themeText = _themes[_activeThemeIndex][1] as Color;

    if (state.isContentLoading && state.currentChapter == null) {
      return Scaffold(
        backgroundColor: themeBg,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.pinkAccent),
        ),
      );
    }

    final chapter = state.currentChapter;
    if (chapter == null) {
      return Scaffold(
        backgroundColor: themeBg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('⚠️ 章节内容加载失败', style: TextStyle(color: themeText)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(novelProvider.notifier).loadChapters(widget.bookId),
                child: const Text('重 试'),
              )
            ],
          ),
        ),
      );
    }

    final String content = chapter.content ?? "暂无内容";

    return Scaffold(
      backgroundColor: themeBg,
      body: Stack(
        children: [
          // 1. Reading Content Layer
          SafeArea(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showControlOverlay = !_showControlOverlay;
                });
              },
              child: Container(
                color: Colors.transparent,
                padding: EdgeInsets.symmetric(horizontal: _marginHorizontal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    // Header Bar showing book details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            chapter.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: themeText.withOpacity(0.5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '${state.currentBookProgress?.lastReadChapterIndex ?? 0} / ${state.chapters.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: themeText.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16, color: Colors.black12),
                    // Scrollable novel content
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            // Render title inside page
                            Text(
                              chapter.title,
                              style: TextStyle(
                                fontSize: _fontSize + 4,
                                fontWeight: FontWeight.bold,
                                color: themeText,
                                fontFamily: _isSerif ? 'Serif' : null,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Rich body text with TTS Highlight support
                            _buildReaderBodyText(content, themeText),
                            const SizedBox(height: 50),
                            // Quick chapter paging
                            _buildBottomPagingRow(state, themeText),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Head & Bottom Glassmorphic Control Overlay Drawer
          if (_showControlOverlay) ...[
            _buildHeaderOverlay(themeText),
            _buildBottomControlsOverlay(state, themeBg, themeText),
          ] else ...[
            // 3. Subtle Glassmorphic Floating Quick Access Dock when overlays are hidden
            Positioned(
              bottom: 24,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: themeText.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: themeText.withOpacity(0.12), width: 0.8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDockButton(
                          icon: Icons.format_list_bulleted_rounded,
                          tooltip: '章节目录',
                          onTap: _showTocDrawer,
                          themeText: themeText,
                        ),
                        Container(
                          width: 1,
                          height: 14,
                          color: themeText.withOpacity(0.12),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                        ),
                        _buildDockButton(
                          icon: Icons.settings_rounded,
                          tooltip: '阅读设置',
                          onTap: () {
                            setState(() {
                              _showControlOverlay = true;
                            });
                          },
                          themeText: themeText,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReaderBodyText(String content, Color themeText) {
    final state = ref.watch(novelProvider);
    final textStyle = TextStyle(
      fontSize: _fontSize,
      height: _lineHeight,
      color: themeText,
      fontFamily: _isSerif ? 'Serif' : null,
    );

    if (!state.isTtsPlaying || state.ttsHighlightCharIndex == 0) {
      return Text(content, style: textStyle);
    }

    // Split text for dynamic word highlighting
    final int idx = state.ttsHighlightCharIndex;
    final int len = content.length;
    if (idx >= len) {
      return Text(content, style: textStyle);
    }

    // Highlighting a window of 12 characters to look like reading flow
    final int endIdx = (idx + 12).clamp(idx, len);

    return RichText(
      text: TextSpan(
        style: textStyle,
        children: [
          TextSpan(text: content.substring(0, idx)),
          TextSpan(
            text: content.substring(idx, endIdx),
            style: const TextStyle(
              color: Colors.amber,
              backgroundColor: Colors.black26,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: content.substring(endIdx)),
        ],
      ),
    );
  }

  Widget _buildBottomPagingRow(NovelState state, Color themeText) {
    final curIdx = state.currentBookProgress?.lastReadChapterIndex ?? 1;
    final total = state.chapters.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: curIdx > 1 ? () => _onPrevChapter(state) : null,
          icon: const Icon(Icons.arrow_back_rounded, size: 16),
          label: const Text('上一章'),
          style: TextButton.styleFrom(foregroundColor: themeText.withOpacity(0.8)),
        ),
        Text(
          '章节 $curIdx / $total',
          style: TextStyle(fontSize: 12, color: themeText.withOpacity(0.5)),
        ),
        TextButton.icon(
          onPressed: curIdx < total ? () => _onNextChapter(state) : null,
          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
          label: const Text('下一章'),
          style: TextButton.styleFrom(foregroundColor: themeText.withOpacity(0.8)),
        ),
      ],
    );
  }

  Widget _buildHeaderOverlay(Color themeText) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            color: const Color(0xFF0F0C29).withOpacity(0.8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  // TOC Directory Trigger
                  IconButton(
                    icon: const Icon(Icons.format_list_bulleted_rounded, color: Colors.white70),
                    onPressed: _showTocDrawer,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControlsOverlay(
    NovelState state,
    Color themeBg,
    Color themeText,
  ) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F0C29).withOpacity(0.85),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Sliders for fontSize and lineHeight
                  Row(
                    children: [
                      const Icon(Icons.text_fields_rounded, color: Colors.white54, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: _fontSize,
                          min: 14.0,
                          max: 28.0,
                          activeColor: Colors.pinkAccent,
                          inactiveColor: Colors.white12,
                          onChanged: (val) {
                            setState(() {
                              _fontSize = val;
                            });
                          },
                        ),
                      ),
                      Text(
                        '${_fontSize.toInt()} px',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  // 2. Serif switch, margin options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('选用仿宋/Georgia', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Switch(
                        value: _isSerif,
                        activeColor: Colors.pinkAccent,
                        onChanged: (val) {
                          setState(() {
                            _isSerif = val;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // 3. Color theme pickers
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _themes.length,
                      itemBuilder: (context, idx) {
                        final th = _themes[idx];
                        final Color bg = th[0];
                        final String name = th[2];
                        final isSel = idx == _activeThemeIndex;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _activeThemeIndex = idx;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSel ? Colors.pinkAccent : Colors.white10,
                                width: isSel ? 2 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              name,
                              style: TextStyle(
                                color: th[1],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 24, color: Colors.white10),
                  // 4. TTS bottom drawer trigger & control bar
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          state.isTtsPlaying 
                              ? Icons.pause_circle_filled_rounded 
                              : Icons.play_circle_filled_rounded,
                          size: 32,
                          color: Colors.amberAccent,
                        ),
                        onPressed: () {
                          if (state.isTtsPlaying) {
                            ref.read(novelProvider.notifier).pauseTts();
                          } else {
                            ref.read(novelProvider.notifier).startTts();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'AI 极净听书',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      // Speed adjuster
                      PopupMenuButton<double>(
                        initialValue: state.ttsSpeed,
                        onSelected: (speed) {
                          ref.read(novelProvider.notifier).setTtsSpeed(speed);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '语速 ${state.ttsSpeed}x',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ),
                        itemBuilder: (context) => [0.8, 1.0, 1.2, 1.5, 1.8, 2.0]
                            .map((s) => PopupMenuItem(value: s, child: Text('${s}x')))
                            .toList(),
                      ),
                      const SizedBox(width: 10),
                      // Sleep Timer Adjuster
                      PopupMenuButton<int?>(
                        initialValue: state.ttsTimerMinutes,
                        onSelected: (minutes) {
                          ref.read(novelProvider.notifier).setTtsTimer(minutes);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            state.ttsTimerMinutes == null 
                                ? '定时关闭' 
                                : '${state.ttsTimeRemainingSeconds ~/ 60}m',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem<int?>(value: null, child: Text('无')),
                          const PopupMenuItem<int?>(value: 10, child: Text('10 分钟')),
                          const PopupMenuItem<int?>(value: 20, child: Text('20 分钟')),
                          const PopupMenuItem<int?>(value: 30, child: Text('30 分钟')),
                          const PopupMenuItem<int?>(value: 60, child: Text('60 分钟')),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTocDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final state = ref.watch(novelProvider);
            final chList = state.chapters;
            final curIndex = state.currentBookProgress?.lastReadChapterIndex ?? 1;

            return ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.75,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0C29).withOpacity(0.85),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.format_list_bulleted_rounded, color: Colors.pinkAccent),
                          const SizedBox(width: 8),
                          const Text(
                            '书籍目录列表',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const Spacer(),
                          Text(
                            '共 ${chList.length} 章',
                            style: const TextStyle(fontSize: 12, color: Colors.white38),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: Colors.white10),
                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: chList.length,
                          itemBuilder: (context, idx) {
                            final ch = chList[idx];
                            final isCur = ch.chapterIndex == curIndex;

                            return ListTile(
                              dense: true,
                              title: Text(
                                ch.title,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: isCur ? Colors.pinkAccent : Colors.white70,
                                  fontWeight: isCur ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              trailing: isCur
                                  ? const Icon(Icons.menu_book_rounded, color: Colors.pinkAccent, size: 16)
                                  : null,
                              onTap: () {
                                Navigator.pop(context);
                                ref.read(novelProvider.notifier).loadChapterContent(widget.bookId, ch.chapterIndex);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDockButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required Color themeText,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Icon(
              icon,
              color: themeText.withOpacity(0.7),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
