import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import '../model/novel_models.dart';
import '../provider/novel_provider.dart';
import '../service/novel_api_client.dart';
import '../../../core/storage/local_storage.dart';
import 'dart:math';
import 'package:flutter/services.dart';

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
  bool _isPageViewMode = false;
  String? _failoverMessage;
  Timer? _failoverTimer;

  // Cached pagination fields
  String? _lastContent;
  double? _lastFontSize;
  double? _lastLineHeight;
  bool? _lastSerif;
  double? _lastWidth;
  double? _lastHeight;
  List<int>? _cachedPageOffsets;

  // Sensors & Panic Mode states
  StreamSubscription? _sensorsSubscription;
  bool _isPanicTriggered = false;

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
    _loadPreferences();
    _initSensors();
  }

  void _initSensors() {
    try {
      _sensorsSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
        if (!mounted || _isPanicTriggered) return;
        // Z-axis goes below -8.0 when phone is flipped face down on a flat surface
        if (event.z < -8.0) {
          _triggerPanicMode();
        }
      });
    } catch (_) {}
  }

  void _triggerPanicMode() {
    if (_isPanicTriggered) return;
    _isPanicTriggered = true;
    
    // 1. Immediately pause all TTS and ambient loops
    ref.read(novelProvider.notifier).pauseAllAudio();
    
    // 2. Perform a physical haptic vibration
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}

    // 3. Immediately redirect back to safe environment
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚡ 极密避让机制已激活：深渊进程休眠，已切回安全时事卡片板！'),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(); // Go back to the workbench/shelf
    }
  }


  void _loadPreferences() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      setState(() {
        _fontSize = prefs.getDouble('novel_reader_font_size') ?? 18.0;
        _lineHeight = prefs.getDouble('novel_reader_line_height') ?? 1.6;
        _isSerif = prefs.getBool('novel_reader_is_serif') ?? true;
        _isPageViewMode = prefs.getBool('novel_reader_is_page_view_mode') ?? false;
        
        final savedThemeIndex = prefs.getInt('novel_reader_theme_index');
        if (savedThemeIndex != null && savedThemeIndex >= 0 && savedThemeIndex < _themes.length) {
          _activeThemeIndex = savedThemeIndex;
        } else {
          _autoApplyTimeTheme();
        }
      });
    } catch (_) {
      _autoApplyTimeTheme();
    }
  }

  void _checkFailover() {
    if (NovelApiClient.lastFailoverSource != null) {
      final source = NovelApiClient.lastFailoverSource;
      NovelApiClient.lastFailoverSource = null;
      
      setState(() {
        _failoverMessage = "当前书源不可用，已自动切源至 [$source] 恢复阅读";
      });
      
      _failoverTimer?.cancel();
      _failoverTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _failoverMessage = null;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _sensorsSubscription?.cancel();
    _failoverTimer?.cancel();
    // Pause all audio playbacks on exit to avoid background ghost running
    ref.read(novelProvider.notifier).pauseAllAudio();
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
      return _NovelReaderSkeleton(themeBg: themeBg, themeText: themeText);
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

    final bool isTrial = state.currentBookProgress != null &&
        !state.bookshelf.any((p) => p.bookId == state.currentBookProgress!.bookId) &&
        !state.abyssBookshelf.any((p) => p.bookId == state.currentBookProgress!.bookId);
    
    final bool isTrialLimitReached = isTrial && 
        (state.error != null && (state.error!.contains("403") || state.error!.contains("Forbidden") || state.error!.contains("trial") || state.error!.contains("limit")));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (NovelApiClient.lastFailoverSource != null) {
        _checkFailover();
      }
    });

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
              onDoubleTap: _triggerPanicMode,
              onHorizontalDragEnd: (details) {
                if (_isPageViewMode) return;
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! > 300) {
                  _onPrevChapter(state);
                } else if (details.primaryVelocity! < -300) {
                  _onNextChapter(state);
                }
              },
              child: Container(
                color: Colors.transparent,
                padding: EdgeInsets.symmetric(horizontal: _isPageViewMode ? 0 : _marginHorizontal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isPageViewMode) ...[
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
                            '${(state.currentBookProgress?.lastReadChapterIndex ?? 1).clamp(1, state.chapters.isEmpty ? 1 : state.chapters.length)} / ${state.chapters.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: themeText.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16, color: Colors.black12),
                    ],
                    // Scrollable novel content
                    Expanded(
                      child: _isPageViewMode
                          ? _buildPageViewReader(content, themeText)
                          : SingleChildScrollView(
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

          // 4. Failover HUD Banner Toast
          if (_failoverMessage != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 20,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Colors.black87),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _failoverMessage!,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
          // 5. Trial Limit Glassmorphic Modal Overlay
          if (isTrialLimitReached)
            Positioned.fill(
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    color: Colors.black.withOpacity(0.85),
                    child: Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.85,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: const Color(0xFF140D33).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.pinkAccent.withOpacity(0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pinkAccent.withOpacity(0.2),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.pinkAccent.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock_outline_rounded,
                                color: Colors.pinkAccent,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              '🌌 试读额度已满',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '您已免费试读前 3 章。加入书架后可解锁整本书籍并同步云端阅读进度。',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pinkAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: () async {
                                  final book = state.currentBookProgress?.book;
                                  if (book != null) {
                                    await ref.read(novelProvider.notifier).upgradeTrialBook(book, widget.inAbyss);
                                    // Retry loading chapter content
                                    final currentIdx = state.currentBookProgress?.lastReadChapterIndex ?? 1;
                                    ref.read(novelProvider.notifier).loadChapterContent(widget.bookId, currentIdx);
                                  }
                                },
                                child: const Text(
                                  '加入书架继续阅读',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                '返回书架',
                                style: TextStyle(color: Colors.white38, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
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
    final total = state.chapters.length;
    final rawIdx = state.currentBookProgress?.lastReadChapterIndex ?? 1;
    final curIdx = rawIdx <= 0 ? 1 : (rawIdx > total && total > 0 ? total : rawIdx);

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
                  // 1. Font size slider
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
                            ref.read(sharedPreferencesProvider).setDouble('novel_reader_font_size', val);
                          },
                        ),
                      ),
                      Text(
                        '${_fontSize.toInt()} px',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  // 1.5 Line height slider
                  Row(
                    children: [
                      const Icon(Icons.format_line_spacing_rounded, color: Colors.white54, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: _lineHeight,
                          min: 1.2,
                          max: 2.2,
                          activeColor: Colors.pinkAccent,
                          inactiveColor: Colors.white12,
                          onChanged: (val) {
                            setState(() {
                              _lineHeight = val;
                            });
                            ref.read(sharedPreferencesProvider).setDouble('novel_reader_line_height', val);
                          },
                        ),
                      ),
                      Text(
                        '行高 ${_lineHeight.toStringAsFixed(1)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  // 2. Serif switch
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
                          ref.read(sharedPreferencesProvider).setBool('novel_reader_is_serif', val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Page flip mode toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('翻页模式', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isPageViewMode = false;
                              });
                              ref.read(sharedPreferencesProvider).setBool('novel_reader_is_page_view_mode', false);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: !_isPageViewMode ? Colors.pinkAccent : Colors.white12,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('纵向滚动', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isPageViewMode = true;
                              });
                              ref.read(sharedPreferencesProvider).setBool('novel_reader_is_page_view_mode', true);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _isPageViewMode ? Colors.pinkAccent : Colors.white12,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('左右翻页', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          ),
                        ],
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
                            ref.read(sharedPreferencesProvider).setInt('novel_reader_theme_index', idx);
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
                  const Divider(height: 20, color: Colors.white10),
                  // 5. 听书与冥想声景空间混音控制面板
                  _buildAmbientMixerSection(state),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmbientMixerSection(NovelState state) {
    final ambientSounds = [
      {'id': 'rain', 'name': '幽谷秋雨', 'icon': Icons.umbrella_rounded, 'color': Colors.blueAccent},
      {'id': 'waves', 'name': '极地海浪', 'icon': Icons.waves_rounded, 'color': Colors.cyanAccent},
      {'id': 'fire', 'name': '壁炉柴火', 'icon': Icons.local_fire_department_rounded, 'color': Colors.orangeAccent},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.music_note_rounded, color: Colors.cyanAccent, size: 14),
            const SizedBox(width: 6),
            const Text(
              '听书背景声景混音 (Ducking 智能避让)',
              style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            if (state.isTtsPlaying) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '避让中 -35%',
                  style: TextStyle(color: Colors.cyanAccent, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Column(
          children: ambientSounds.map((sound) {
            final id = sound['id'] as String;
            final name = sound['name'] as String;
            final icon = sound['icon'] as IconData;
            final color = sound['color'] as Color;
            
            final isActive = state.ambientActive[id] ?? false;
            final volume = state.ambientVolumes[id] ?? 0.5;

            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      ref.read(novelProvider.notifier).toggleAmbient(id);
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isActive ? color.withOpacity(0.2) : Colors.white10,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isActive ? color : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Icon(icon, color: isActive ? color : Colors.white38, size: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(name, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                        activeTrackColor: color.withOpacity(0.8),
                        inactiveTrackColor: Colors.white12,
                        thumbColor: color,
                      ),
                      child: Slider(
                        value: volume,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (val) {
                          ref.read(novelProvider.notifier).setAmbientVolume(id, val);
                        },
                      ),
                    ),
                  ),
                  Text(
                    '${(volume * 100).toInt()}%',
                    style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
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
            final rawIndex = state.currentBookProgress?.lastReadChapterIndex ?? 1;
            final curIndex = rawIndex <= 0 ? 1 : rawIndex;

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

  List<int> _getPageOffsets(String content, TextStyle textStyle, double maxWidth, double maxHeight) {
    if (_cachedPageOffsets != null &&
        _lastContent == content &&
        _lastFontSize == _fontSize &&
        _lastLineHeight == _lineHeight &&
        _lastSerif == _isSerif &&
        _lastWidth == maxWidth &&
        _lastHeight == maxHeight) {
      return _cachedPageOffsets!;
    }
    
    _lastContent = content;
    _lastFontSize = _fontSize;
    _lastLineHeight = _lineHeight;
    _lastSerif = _isSerif;
    _lastWidth = maxWidth;
    _lastHeight = maxHeight;
    
    _cachedPageOffsets = NovelTextPaginator.paginate(content, textStyle, maxWidth, maxHeight);
    return _cachedPageOffsets!;
  }

  Widget _buildPageViewReader(String content, Color themeText) {
    final state = ref.watch(novelProvider);
    final textStyle = TextStyle(
      fontSize: _fontSize,
      height: _lineHeight,
      color: themeText,
      fontFamily: _isSerif ? 'Serif' : null,
    );

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    
    final double paddingHorizontal = _marginHorizontal * 2;
    final double topSafeArea = mediaQuery.padding.top;
    final double bottomSafeArea = mediaQuery.padding.bottom;
    
    final double reservedHeight = topSafeArea + bottomSafeArea + 38 + 30 + 40;
    
    final double maxWidth = screenWidth - paddingHorizontal;
    final double maxHeight = screenHeight - reservedHeight;

    final String titleHeader = "${state.currentChapter!.title}\n\n\n";
    final String textToPaginate = titleHeader + content;
    final int titleLen = titleHeader.length;

    final pageOffsets = _getPageOffsets(textToPaginate, textStyle, maxWidth, maxHeight);
    final totalPages = pageOffsets.length - 1;

    final int lastOffset = (state.currentBookProgress?.lastReadCharOffset ?? 0) + titleLen;
    int initialPage = 0;
    for (int i = 0; i < totalPages; i++) {
      if (lastOffset >= pageOffsets[i] && lastOffset < pageOffsets[i + 1]) {
        initialPage = i;
        break;
      }
    }

    final bool hasNextChapter = state.currentBookProgress != null &&
        state.currentBookProgress!.lastReadChapterIndex < state.chapters.length;
    final int itemCount = totalPages + (hasNextChapter ? 1 : 0);

    return PageView.builder(
      controller: PageController(initialPage: initialPage),
      itemCount: itemCount,
      onPageChanged: (pageIndex) {
        if (pageIndex < totalPages) {
          final startOffset = pageOffsets[pageIndex];
          ref.read(novelProvider.notifier).saveProgress(max(0, startOffset - titleLen));
        }
      },
      itemBuilder: (context, pageIndex) {
        if (pageIndex == totalPages) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _onNextChapter(state);
          });
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: themeText.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text('正在加载下一章...', style: TextStyle(color: themeText.withOpacity(0.5), fontSize: 13)),
              ],
            ),
          );
        }

        final start = pageOffsets[pageIndex];
        final end = pageOffsets[pageIndex + 1];
        final pageText = textToPaginate.substring(start, end);

        Widget textWidget;
        final int ttsIndex = state.ttsHighlightCharIndex + titleLen;
        if (state.isTtsPlaying && ttsIndex >= start && ttsIndex < end) {
          final relativeIdx = ttsIndex - start;
          final relativeEnd = (relativeIdx + 12).clamp(relativeIdx, pageText.length);
          textWidget = RichText(
            text: TextSpan(
              style: textStyle,
              children: [
                TextSpan(text: pageText.substring(0, relativeIdx)),
                TextSpan(
                  text: pageText.substring(relativeIdx, relativeEnd),
                  style: const TextStyle(
                    color: Colors.amber,
                    backgroundColor: Colors.black26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(text: pageText.substring(relativeEnd)),
              ],
            ),
          );
        } else {
          textWidget = Text(pageText, style: textStyle);
        }

        return Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      state.currentChapter!.title,
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
                    '第 ${pageIndex + 1} / $totalPages 页',
                    style: TextStyle(
                      fontSize: 12,
                      color: themeText.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16, color: Colors.black12),
              Expanded(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: textWidget,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}

class _NovelReaderSkeleton extends StatefulWidget {
  final Color themeBg;
  final Color themeText;

  const _NovelReaderSkeleton({
    required this.themeBg,
    required this.themeText,
  });

  @override
  State<_NovelReaderSkeleton> createState() => _NovelReaderSkeletonState();
}

class _NovelReaderSkeletonState extends State<_NovelReaderSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shimmerColor = widget.themeText.withOpacity(0.15);
    return Scaffold(
      backgroundColor: widget.themeBg,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: 0.3 + (_controller.value * 0.5), // Pulses between 0.3 and 0.8
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top header line
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(width: 80, height: 12, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4))),
                        Container(width: 40, height: 12, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4))),
                      ],
                    ),
                    const SizedBox(height: 48),
                    // Title skeleton
                    Container(width: 160, height: 28, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(6))),
                    const SizedBox(height: 36),
                    // Paragraph 1
                    _buildParagraph(shimmerColor, [0.95, 0.9, 0.92, 0.4]),
                    const SizedBox(height: 24),
                    // Paragraph 2
                    _buildParagraph(shimmerColor, [0.93, 0.95, 0.85, 0.35]),
                    const SizedBox(height: 24),
                    // Paragraph 3
                    _buildParagraph(shimmerColor, [0.9, 0.92, 0.94, 0.78, 0.45]),
                    const SizedBox(height: 24),
                    // Paragraph 4
                    _buildParagraph(shimmerColor, [0.95, 0.93, 0.3]),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildParagraph(Color color, List<double> widths) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widths.map((w) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FractionallySizedBox(
            widthFactor: w,
            child: Container(
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class NovelTextPaginator {
  static List<int> paginate(
    String text,
    TextStyle style,
    double maxWidth,
    double maxHeight,
  ) {
    final List<int> pages = [0];
    if (text.isEmpty) return pages;

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    int start = 0;
    while (start < text.length) {
      int end = text.length;
      int low = start + 1;
      int high = text.length;

      while (low <= high) {
        int mid = (low + high) ~/ 2;
        final sub = text.substring(start, mid);
        textPainter.text = TextSpan(text: sub, style: style);
        textPainter.layout(maxWidth: maxWidth);

        if (textPainter.height <= maxHeight) {
          end = mid;
          low = mid + 1;
        } else {
          high = mid - 1;
        }
      }

      if (end <= start) {
        end = start + 1;
      }

      pages.add(end);
      start = end;
    }

    return pages;
  }
}
