import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import '../provider/novel_provider.dart';
import '../model/novel_models.dart';
import '../service/novel_api_client.dart';
import '../../../core/storage/local_storage.dart';
import 'package:flutter/services.dart';
import '../../bmi/view/bmi_screen.dart';
import '../../dashboard/view/widgets/dashboard_utils.dart';

// Extracted subcomponents
import 'widgets/novel_reader_skeleton.dart';
import 'widgets/texture_overlay_painter.dart';
import 'widgets/reader_annotations_sheet.dart';
import 'widgets/reader_settings_panel.dart';
import 'widgets/reader_page_view.dart';
import 'widgets/novel_source_swapper.dart';

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
  final double _marginHorizontal = 20.0;
  bool _isPageViewMode = false;
  String? _failoverMessage;
  Timer? _failoverTimer;

  // In-memory highlights cache to solve page swipe stuttering
  Map<String, Map<String, dynamic>>? _cachedHighlights;
  String? _cachedHighlightsBookId;

  // Trial Reading progress tracking
  final Set<int> _readChapters = {};
  bool _hasPromptedAddToShelf = false;

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

  late ScrollController _scrollController;
  late final NovelNotifier _novelNotifier;
  bool _showControlOverlay = false;
  bool _showSettingsPanel = false;

  // Reading position memory & auto-scroll states
  DateTime _lastSaveTime = DateTime.now();
  bool _isAutoScrolling = false;
  bool _isAutoScrollPausedByUser = false;
  double _autoScrollSpeed = 2.0; // speed level: 1 to 5
  Timer? _autoScrollTimer;
  double _dimmerOpacity = 0.0;

  bool _landingOnLastPage = false;

  bool _isScrolling = false;
  Timer? _scrollStopTimer;

  @override
  void initState() {
    super.initState();
    _novelNotifier = ref.read(novelProvider.notifier);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadPreferences();
    _initSensors();
    
    // Consistency Guard: Ensure correct book is loaded if provider is out of sync
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final state = ref.read(novelProvider);
        if (state.currentBookProgress?.bookId != widget.bookId ||
            (state.currentChapter != null && state.currentChapter!.bookId != widget.bookId)) {
          _novelNotifier.loadChapters(widget.bookId);
        }
      }
    });
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
    
    // 1. Immediately stop all TTS and ambient loops
    _novelNotifier.stopAllAudio();
    
    // 2. Perform a physical haptic vibration
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}

    // 3. Immediately redirect back to safe environment (Decoy mode)
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        FadePageRoute(child: const BmiScreen()),
        (route) => route.isFirst,
      );
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
        _dimmerOpacity = prefs.getDouble('novel_reader_dimmer_opacity') ?? 0.0;
        
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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _autoScrollTimer?.cancel();
    _scrollStopTimer?.cancel();
    _sensorsSubscription?.cancel();
    _failoverTimer?.cancel();
    // Stop all audio playbacks on exit to avoid background ghost running
    _novelNotifier.stopAllAudio();
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

  void _onScroll() {
    if (_isPageViewMode) return;
    if (!_scrollController.hasClients) return;

    if (!_isScrolling) {
      setState(() {
        _isScrolling = true;
      });
    }
    _scrollStopTimer?.cancel();
    _scrollStopTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isScrolling = false;
        });
      }
    });
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;
    
    final currentOffset = _scrollController.offset;
    final double scrollRatio = currentOffset / maxScroll;
    
    final now = DateTime.now();
    if (now.difference(_lastSaveTime) > const Duration(seconds: 2)) {
      _lastSaveTime = now;
      final state = ref.read(novelProvider);
      final content = state.currentChapter?.content;
      if (content != null && content.isNotEmpty) {
        final offset = (scrollRatio * content.length).toInt().clamp(0, content.length);
        _novelNotifier.saveProgress(offset);
      }
    }
  }

  void _restoreScrollPosition(NovelState state) {
    if (_isPageViewMode) return;
    if (!_scrollController.hasClients) return;
    
    final content = state.currentChapter?.content;
    if (content == null || content.isEmpty) return;
    
    final int charOffset = state.currentBookProgress?.lastReadCharOffset ?? 0;
    final double ratio = (charOffset / content.length).clamp(0.0, 1.0);
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll > 0) {
      _scrollController.jumpTo(ratio * maxScroll);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          final maxScroll2 = _scrollController.position.maxScrollExtent;
          _scrollController.jumpTo(ratio * maxScroll2);
        }
      });
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (!_isAutoScrolling) return;
    
    final double pixelsPerTick = [0.3, 0.6, 1.0, 1.6, 2.5][(_autoScrollSpeed.toInt() - 1).clamp(0, 4)];
    
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted || !_isAutoScrolling || _isPageViewMode) {
        timer.cancel();
        return;
      }
      
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentOffset = _scrollController.offset;
        
        if (currentOffset >= maxScroll) {
          setState(() {
            _isAutoScrolling = false;
          });
          timer.cancel();
          return;
        }
        
        _scrollController.jumpTo(currentOffset + pixelsPerTick);
      }
    });
  }
  
  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  void _onPrevChapter(NovelState state) {
    if (state.currentBookProgress == null) return;
    final int listIdx = state.chapters.indexWhere((c) => c.chapterIndex == state.currentChapter?.chapterIndex);
    if (listIdx > 0) {
      setState(() {
        _landingOnLastPage = true;
      });
      ref.read(novelProvider.notifier).loadChapterContent(widget.bookId, state.chapters[listIdx - 1].chapterIndex);
    }
  }

  void _onNextChapter(NovelState state) {
    if (state.currentBookProgress == null) return;
    final int listIdx = state.chapters.indexWhere((c) => c.chapterIndex == state.currentChapter?.chapterIndex);
    if (listIdx != -1 && listIdx < state.chapters.length - 1) {
      setState(() {
        _landingOnLastPage = false;
      });
      ref.read(novelProvider.notifier).loadChapterContent(widget.bookId, state.chapters[listIdx + 1].chapterIndex);
    }
  }

  Widget _buildReaderBodyText(NovelState state, String content, Color themeText) {
    final textStyle = TextStyle(
      fontSize: _fontSize,
      height: _lineHeight,
      color: themeText,
      fontFamily: _isSerif ? 'Serif' : null,
    );

    if (state.isTtsPlaying && state.ttsHighlightCharIndex > 0) {
      final int idx = state.ttsHighlightCharIndex;
      final int len = content.length;
      if (idx < len) {
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
    }

    final textSpan = _buildFormattedTextSpan(
      content,
      widget.bookId,
      state.currentChapter?.chapterIndex ?? 1,
      textStyle,
      themeText,
    );

    return GestureDetector(
      onLongPress: () {
        ReaderAnnotationsSheet.show(
          context: context,
          ref: ref,
          bookId: widget.bookId,
          chapterIndex: state.currentChapter?.chapterIndex ?? 1,
          content: content,
          onUpdate: () => setState(() {}),
        );
      },
      child: RichText(text: textSpan),
    );
  }

  Widget _buildBottomPagingRow(NovelState state, Color themeText) {
    final total = state.chapters.length;
    final int listIdx = state.chapters.indexWhere((c) => c.chapterIndex == state.currentChapter?.chapterIndex);
    final displayIndex = listIdx != -1 ? listIdx + 1 : 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: listIdx > 0 ? () => _onPrevChapter(state) : null,
          icon: const Icon(Icons.arrow_back_rounded, size: 16),
          label: const Text('上一章'),
          style: TextButton.styleFrom(foregroundColor: themeText.withOpacity(0.8)),
        ),
        Text(
          '章节 $displayIndex / $total',
          style: TextStyle(fontSize: 12, color: themeText.withOpacity(0.5)),
        ),
        TextButton.icon(
          onPressed: (listIdx != -1 && listIdx < total - 1) ? () => _onNextChapter(state) : null,
          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
          label: const Text('下一章'),
          style: TextButton.styleFrom(foregroundColor: themeText.withOpacity(0.8)),
        ),
      ],
    );
  }

  Widget _buildHeaderOverlay(Color themeText) {
    final theme = Theme.of(context);
    final surfaceColor = theme.colorScheme.surface;
    final onSurfaceColor = theme.colorScheme.onSurface;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            color: surfaceColor.withOpacity(0.85),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: onSurfaceColor.withOpacity(0.7)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.swap_horiz_rounded, color: onSurfaceColor.withOpacity(0.7)),
                    tooltip: '换源',
                    onPressed: _showSourceSwappingDialog,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.format_list_bulleted_rounded, color: onSurfaceColor.withOpacity(0.7)),
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

  void _showSourceSwappingDialog() {
    final book = ref.read(novelProvider).currentBookProgress?.book;
    if (book == null) return;

    final theme = Theme.of(context);
    final surfaceColor = theme.colorScheme.surface;
    final onSurfaceColor = theme.colorScheme.onSurface;
    final primaryColor = theme.colorScheme.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
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
                color: surfaceColor.withOpacity(0.85),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                border: Border.all(color: onSurfaceColor.withOpacity(0.08)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: SourceSwapperContent(
                book: book,
                inAbyss: widget.inAbyss,
                onChangeSource: (newSourceId, newBookUrl) async {
                  Navigator.pop(context); // Close bottom sheet
                  // Show full screen loading dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    ),
                  );
                  try {
                    await ref.read(novelProvider.notifier).changeBookSource(
                      book.id,
                      newSourceId,
                      newBookUrl,
                    );
                    if (mounted) {
                      Navigator.pop(context); // Close loading dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('换源成功，正在重新加载内容...'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.pop(context); // Close loading dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('换源失败: $e'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ),
        );
      },
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

            final theme = Theme.of(context);
            final surfaceColor = theme.colorScheme.surface;
            final onSurfaceColor = theme.colorScheme.onSurface;
            final primaryColor = theme.colorScheme.primary;

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
                    color: surfaceColor.withOpacity(0.85),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    border: Border.all(color: onSurfaceColor.withOpacity(0.08)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: onSurfaceColor.withOpacity(0.24),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.format_list_bulleted_rounded, color: primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            '书籍目录列表',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurfaceColor),
                          ),
                          const Spacer(),
                          Text(
                            '共 ${chList.length} 章',
                            style: TextStyle(fontSize: 12, color: onSurfaceColor.withOpacity(0.38)),
                          ),
                        ],
                      ),
                      Divider(height: 24, color: onSurfaceColor.withOpacity(0.1)),
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
                                  color: isCur ? primaryColor : onSurfaceColor.withOpacity(0.7),
                                  fontWeight: isCur ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              trailing: isCur
                                  ? Icon(Icons.menu_book_rounded, color: primaryColor, size: 16)
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

  Widget _buildBottomNavigationBar(Color themeText, NovelState state) {
    final theme = Theme.of(context);
    final surfaceColor = theme.colorScheme.surface;
    final onSurfaceColor = theme.colorScheme.onSurface;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: surfaceColor.withOpacity(0.85),
              border: Border(top: BorderSide(color: onSurfaceColor.withOpacity(0.08))),
            ),
            padding: EdgeInsets.only(
              top: 10,
              bottom: MediaQuery.of(context).padding.bottom + 10,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.format_list_bulleted_rounded,
                  label: '目录',
                  onTap: () {
                    _showTocDrawer();
                  },
                ),
                _buildNavItem(
                  icon: Icons.border_color_rounded,
                  label: '划线想法',
                  onTap: () {
                    final content = state.currentChapter?.content ?? '';
                    ReaderAnnotationsSheet.show(
                      context: context,
                      ref: ref,
                      bookId: widget.bookId,
                      chapterIndex: state.currentChapter?.chapterIndex ?? 1,
                      content: content,
                      onUpdate: () => setState(() {}),
                    );
                  },
                ),
                _buildNavItem(
                  icon: Icons.settings_rounded,
                  label: '设置',
                  isActive: _showSettingsPanel,
                  onTap: () {
                    setState(() {
                      _showSettingsPanel = !_showSettingsPanel;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurface.withOpacity(0.6);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : inactiveColor,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : inactiveColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextSpan _buildFormattedTextSpan(String pageText, String bookId, int chapterIndex, TextStyle textStyle, Color themeText) {
    final highlights = _loadHighlights(bookId);
    final chapterHighlights = highlights[chapterIndex.toString()] ?? {};

    List<Map<String, dynamic>> runs = [
      {'text': pageText, 'isHighlighted': false}
    ];

    chapterHighlights.forEach((pKey, data) {
      final bool isHigh = data['isHighlighted'] ?? false;
      if (isHigh && pKey.trim().isNotEmpty) {
        final List<Map<String, dynamic>> newRuns = [];
        for (final run in runs) {
          if (run['isHighlighted'] as bool) {
            newRuns.add(run);
            continue;
          }
          final String rText = run['text'] as String;
          final int index = rText.indexOf(pKey);
          if (index != -1) {
            if (index > 0) {
              newRuns.add({'text': rText.substring(0, index), 'isHighlighted': false});
            }
            newRuns.add({'text': pKey, 'isHighlighted': true});
            if (index + pKey.length < rText.length) {
              newRuns.add({'text': rText.substring(index + pKey.length), 'isHighlighted': false});
            }
          } else {
            newRuns.add(run);
          }
        }
        runs = newRuns;
      }
    });

    return TextSpan(
      style: textStyle,
      children: runs.map((run) {
        final text = run['text'] as String;
        final isHigh = run['isHighlighted'] as bool;
        if (isHigh) {
          return TextSpan(
            text: text,
            style: TextStyle(
              backgroundColor: Colors.yellow.withOpacity(0.3),
              decoration: TextDecoration.underline,
              decorationColor: Colors.amber,
            ),
          );
        } else {
          return TextSpan(text: text);
        }
      }).toList(),
    );
  }

  Map<String, Map<String, dynamic>> _loadHighlights(String bookId) {
    if (_cachedHighlights != null && _cachedHighlightsBookId == bookId) {
      return _cachedHighlights!;
    }
    _cachedHighlightsBookId = bookId;
    _cachedHighlights = ReaderAnnotationsSheet.loadHighlights(ref, bookId);
    return _cachedHighlights!;
  }

  void _showAddToBookshelfPrompt(BuildContext context, Book? book) {
    if (book == null) return;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final theme = Theme.of(context);
        final surfaceColor = theme.colorScheme.surface;
        final onSurfaceColor = theme.colorScheme.onSurface;
        final primaryColor = theme.colorScheme.primary;

        return AlertDialog(
          backgroundColor: surfaceColor.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: primaryColor.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          title: const Row(
            children: [
              Icon(Icons.bookmark_add_rounded, color: Colors.amberAccent, size: 24),
              SizedBox(width: 8),
              Text(
                '加入书架',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            '喜欢这本书吗？您已阅读 5 章，是否将《${book.title}》加入书架以保存您的阅读进度？',
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消', style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                try {
                  await ref.read(novelProvider.notifier).upgradeTrialBook(book, widget.inAbyss);
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('📚 已将《${book.title}》加入书架'),
                      backgroundColor: widget.inAbyss ? Colors.purple : Colors.pinkAccent,
                    ),
                  );
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('❌ 加入失败: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              child: const Text('加入书架', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(novelProvider);
    ref.listen<NovelState>(novelProvider, (previous, next) {
      if (previous?.currentChapter != next.currentChapter && next.currentChapter != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _restoreScrollPosition(next);
        });

        // Track trial reading chapters progress
        final progress = next.currentBookProgress;
        if (progress != null && progress.inBookshelf == false) {
          final chapterIndex = next.currentChapter!.chapterIndex;
          _readChapters.add(chapterIndex);
          if (_readChapters.length >= 5 && !_hasPromptedAddToShelf) {
            _hasPromptedAddToShelf = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showAddToBookshelfPrompt(context, next.currentBookProgress?.book);
            });
          }
        }
      }
    });

    final themeBg = _themes[_activeThemeIndex][0] as Color;
    final themeText = _themes[_activeThemeIndex][1] as Color;

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

    if (isTrialLimitReached) {
      final theme = Theme.of(context);
      final surfaceColor = theme.colorScheme.surface;
      final onSurfaceColor = theme.colorScheme.onSurface;
      final primaryColor = theme.colorScheme.primary;

      return Scaffold(
        backgroundColor: themeBg,
        body: Stack(
          children: [
            Container(color: Colors.black.withOpacity(0.65)),
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: surfaceColor.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.2),
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
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        color: primaryColor,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '🌌 试读额度已满',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: onSurfaceColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '您已免费试读前 3 章。加入书架后可解锁整本书籍并同步云端阅读进度。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: onSurfaceColor.withOpacity(0.7),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
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
                      child: Text(
                        '返回书架',
                        style: TextStyle(color: onSurfaceColor.withOpacity(0.38), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final bool isBookMismatch = state.currentBookProgress?.bookId != widget.bookId ||
        (state.currentChapter != null && state.currentChapter!.bookId != widget.bookId);
    if (isBookMismatch || (state.isContentLoading && state.currentChapter == null)) {
      return NovelReaderSkeleton(
        themeBg: themeBg,
        themeText: themeText,
        onBack: () => Navigator.pop(context),
      );
    }

    final chapter = state.currentChapter;
    if (chapter == null) {
      return Scaffold(
        backgroundColor: themeBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: themeText.withOpacity(0.7)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
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

    final String content = (chapter.content ?? "暂无内容").replaceAll(RegExp(r'\n+'), '\n');

    final textStyle = TextStyle(
      fontSize: _fontSize,
      height: _lineHeight,
      color: themeText,
      fontFamily: _isSerif ? 'Serif' : null,
    );

    return Scaffold(
      backgroundColor: themeBg,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: TextureOverlayPainter(_activeThemeIndex),
              ),
            ),
          ),
          if (state.isContentLoading)
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                minHeight: 3,
              ),
            ),
          if (_isPageViewMode)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  if (_isAutoScrollPausedByUser) {
                    setState(() {
                      _isAutoScrolling = true;
                      _isAutoScrollPausedByUser = false;
                    });
                    _startAutoScroll();
                  } else {
                    setState(() {
                      _showControlOverlay = !_showControlOverlay;
                      if (!_showControlOverlay) {
                        _showSettingsPanel = false;
                      }
                    });
                  }
                },
                onDoubleTap: _triggerPanicMode,
                child: ReaderPageView(
                  bookId: widget.bookId,
                  state: state,
                  content: content,
                  textStyle: textStyle,
                  marginHorizontal: _marginHorizontal,
                  activeThemeIndex: _activeThemeIndex,
                  themes: _themes,
                  landingOnLastPage: _landingOnLastPage,
                  onLandingOnLastPageHandled: () {
                    setState(() {
                      _landingOnLastPage = false;
                    });
                  },
                  onPrevChapter: () => _onPrevChapter(state),
                  onNextChapter: () => _onNextChapter(state),
                  onShowAnnotationsSheet: (state, text) {
                    ReaderAnnotationsSheet.show(
                      context: context,
                      ref: ref,
                      bookId: widget.bookId,
                      chapterIndex: state.currentChapter?.chapterIndex ?? 1,
                      content: state.currentChapter?.content ?? '',
                      onUpdate: () {
                        setState(() {
                          _cachedHighlights = null;
                        });
                      },
                    );
                  },
                  buildFormattedTextSpan: (pageText, textStyle, themeText) {
                    return _buildFormattedTextSpan(
                      pageText,
                      widget.bookId,
                      state.currentChapter?.chapterIndex ?? 1,
                      textStyle,
                      themeText,
                    );
                  },
                ),
              ),
            )
          else
            SafeArea(
              child: GestureDetector(
                onTap: () {
                  if (_isAutoScrollPausedByUser) {
                    setState(() {
                      _isAutoScrolling = true;
                      _isAutoScrollPausedByUser = false;
                    });
                    _startAutoScroll();
                  } else {
                    setState(() {
                      _showControlOverlay = !_showControlOverlay;
                      if (!_showControlOverlay) {
                        _showSettingsPanel = false;
                      }
                    });
                  }
                },
                onDoubleTap: _triggerPanicMode,
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity == null) return;
                  if (details.primaryVelocity! > 300) {
                    _onPrevChapter(state);
                  } else if (details.primaryVelocity! < -300) {
                    _onNextChapter(state);
                  }
                },
                child: Container(
                  color: Colors.transparent,
                  padding: EdgeInsets.symmetric(horizontal: _marginHorizontal),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
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
                      Expanded(
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is ScrollStartNotification) {
                              if (notification.dragDetails != null && _isAutoScrolling) {
                                setState(() {
                                  _isAutoScrolling = false;
                                  _isAutoScrollPausedByUser = true;
                                });
                                _stopAutoScroll();
                              }
                            }
                            return false;
                          },
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),
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
                                _buildReaderBodyText(state, content, themeText),
                                const SizedBox(height: 50),
                                _buildBottomPagingRow(state, themeText),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_showControlOverlay) ...[
            _buildHeaderOverlay(themeText),
            _buildBottomNavigationBar(themeText, state),
            if (_showSettingsPanel)
              ReaderSettingsPanel(
                bottomOffset: 64.0 + MediaQuery.of(context).padding.bottom,
                state: state,
                fontSize: _fontSize,
                lineHeight: _lineHeight,
                isSerif: _isSerif,
                dimmerOpacity: _dimmerOpacity,
                isPageViewMode: _isPageViewMode,
                autoScrollSpeed: _autoScrollSpeed,
                isAutoScrolling: _isAutoScrolling,
                activeThemeIndex: _activeThemeIndex,
                themes: _themes,
                themeBg: themeBg,
                themeText: themeText,
                onFontSizeChanged: (val) {
                  setState(() {
                    _fontSize = val;
                  });
                  ref.read(sharedPreferencesProvider).setDouble('novel_reader_font_size', val);
                },
                onLineHeightChanged: (val) {
                  setState(() {
                    _lineHeight = val;
                  });
                  ref.read(sharedPreferencesProvider).setDouble('novel_reader_line_height', val);
                },
                onSerifChanged: (val) {
                  setState(() {
                    _isSerif = val;
                  });
                  ref.read(sharedPreferencesProvider).setBool('novel_reader_is_serif', val);
                },
                onDimmerOpacityChanged: (val) {
                  setState(() {
                    _dimmerOpacity = val;
                  });
                  ref.read(sharedPreferencesProvider).setDouble('novel_reader_dimmer_opacity', val);
                },
                onPageViewModeChanged: (val) {
                  setState(() {
                    _isPageViewMode = val;
                  });
                  ref.read(sharedPreferencesProvider).setBool('novel_reader_is_page_view_mode', val);
                },
                onAutoScrollSpeedChanged: (val) {
                  setState(() {
                    _autoScrollSpeed = val;
                  });
                  if (_isAutoScrolling) {
                    _startAutoScroll();
                  }
                },
                onAutoScrollingChanged: (val) {
                  setState(() {
                    _isAutoScrolling = val;
                    _isAutoScrollPausedByUser = false;
                  });
                  if (val) {
                    _startAutoScroll();
                  } else {
                    _stopAutoScroll();
                  }
                },
                onThemeIndexChanged: (val) {
                  setState(() {
                    _activeThemeIndex = val;
                  });
                  ref.read(sharedPreferencesProvider).setInt('novel_reader_theme_index', val);
                },
                onShowTocDrawer: _showTocDrawer,
                onShowAnnotationsSheet: () {
                  ReaderAnnotationsSheet.show(
                    context: context,
                    ref: ref,
                    bookId: widget.bookId,
                    chapterIndex: state.currentChapter?.chapterIndex ?? 1,
                    content: content,
                    onUpdate: () => setState(() {}),
                  );
                },
              ),
          ],

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

          if (_dimmerOpacity > 0.0)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black.withOpacity(_dimmerOpacity),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


