import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../provider/novel_provider.dart';
import 'novel_text_paginator.dart';

class ReaderPageView extends ConsumerStatefulWidget {
  final String bookId;
  final NovelState state;
  final String content;
  final TextStyle textStyle;
  final double marginHorizontal;
  final int activeThemeIndex;
  final List<List<dynamic>> themes;
  final bool landingOnLastPage;
  final VoidCallback onLandingOnLastPageHandled;
  final VoidCallback onPrevChapter;
  final VoidCallback onNextChapter;
  final Function(NovelState state, String text) onShowAnnotationsSheet;
  final TextSpan Function(String pageText, TextStyle textStyle, Color themeText) buildFormattedTextSpan;

  const ReaderPageView({
    super.key,
    required this.bookId,
    required this.state,
    required this.content,
    required this.textStyle,
    required this.marginHorizontal,
    required this.activeThemeIndex,
    required this.themes,
    required this.landingOnLastPage,
    required this.onLandingOnLastPageHandled,
    required this.onPrevChapter,
    required this.onNextChapter,
    required this.onShowAnnotationsSheet,
    required this.buildFormattedTextSpan,
  });

  @override
  ConsumerState<ReaderPageView> createState() => _ReaderPageViewState();
}

class _ReaderPageViewState extends ConsumerState<ReaderPageView> {
  String? _lastContent;
  double? _lastFontSize;
  double? _lastLineHeight;
  bool? _lastSerif;
  double? _lastWidth;
  double? _lastHeight;
  List<int>? _cachedPageOffsets;

  String? _lastBookId;
  int? _lastChapterIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<int> _getPageOffsets(String content, TextStyle textStyle, double maxWidth, double maxHeight) {
    if (_cachedPageOffsets != null &&
        _lastContent == content &&
        _lastFontSize == textStyle.fontSize &&
        _lastLineHeight == textStyle.height &&
        _lastSerif == (textStyle.fontFamily == 'Serif') &&
        _lastWidth == maxWidth &&
        _lastHeight == maxHeight) {
      return _cachedPageOffsets!;
    }

    _lastContent = content;
    _lastFontSize = textStyle.fontSize;
    _lastLineHeight = textStyle.height;
    _lastSerif = textStyle.fontFamily == 'Serif';
    _lastWidth = maxWidth;
    _lastHeight = maxHeight;

    _cachedPageOffsets = NovelTextPaginator.paginate(content, textStyle, maxWidth, maxHeight);
    return _cachedPageOffsets!;
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final content = widget.content;
    final themeText = widget.textStyle.color ?? Colors.black;

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    final double paddingHorizontal = widget.marginHorizontal * 2;
    final double topSafeArea = mediaQuery.padding.top;
    final double bottomSafeArea = mediaQuery.padding.bottom;

    final double reservedHeight = topSafeArea + bottomSafeArea + 38 + 30 + 40;
    final double maxHeight = screenHeight - reservedHeight;

    final String titleHeader = "${state.currentChapter!.title}\n\n\n";
    final String textToPaginate = titleHeader + content;
    final int titleLen = titleHeader.length;

    final double? oldFontSize = _lastFontSize;
    final double? oldLineHeight = _lastLineHeight;
    final bool? oldSerif = _lastSerif;

    final bool isDoubleColumn = screenWidth > 600;
    final double gap = isDoubleColumn ? 40.0 : 0.0;
    final double columnWidth = isDoubleColumn
        ? (screenWidth - paddingHorizontal - gap) / 2
        : (screenWidth - paddingHorizontal);

    final pageOffsets = _getPageOffsets(textToPaginate, widget.textStyle, columnWidth, maxHeight);
    final totalPages = pageOffsets.length - 1;
    final int totalScreens = isDoubleColumn ? (totalPages / 2).ceil() : totalPages;

    final bool paginationConfigChanged = oldFontSize != null && (
        oldFontSize != widget.textStyle.fontSize ||
        oldLineHeight != widget.textStyle.height ||
        oldSerif != (widget.textStyle.fontFamily == 'Serif')
    );

    final bool hasPrevChapter = state.currentBookProgress != null &&
        state.currentBookProgress!.lastReadChapterIndex > 1;
    final bool hasNextChapter = state.currentBookProgress != null &&
        state.currentBookProgress!.lastReadChapterIndex < state.chapters.length;

    final currentChapterIndex = state.currentBookProgress?.lastReadChapterIndex;
    final currentBookId = widget.bookId;

    int initialPageScreen = 0;
    if (widget.landingOnLastPage) {
      initialPageScreen = max(0, totalScreens - 1);
      final int contentPageIndex = isDoubleColumn ? initialPageScreen * 2 : initialPageScreen;
      if (contentPageIndex < pageOffsets.length) {
        final startOffset = pageOffsets[contentPageIndex];
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(novelProvider.notifier).saveProgress(max(0, startOffset - titleLen));
          }
        });
      }
      widget.onLandingOnLastPageHandled();
    } else {
      int initialPage = 0;
      final int lastOffset = (state.currentBookProgress?.lastReadCharOffset ?? 0) + titleLen;
      for (int i = 0; i < totalPages; i++) {
        if (lastOffset >= pageOffsets[i] && lastOffset < pageOffsets[i + 1]) {
          initialPage = i;
          break;
        }
      }
      initialPageScreen = isDoubleColumn ? (initialPage ~/ 2) : initialPage;
    }

    final int itemOffsetShift = hasPrevChapter ? 1 : 0;
    final int itemCount = totalScreens + itemOffsetShift + (hasNextChapter ? 1 : 0);
    final int initialPageViewPage = initialPageScreen + itemOffsetShift;

    if (_lastBookId != currentBookId ||
        _lastChapterIndex != currentChapterIndex ||
        paginationConfigChanged) {
      final oldController = _pageController;
      _lastBookId = currentBookId;
      _lastChapterIndex = currentChapterIndex;
      _pageController = PageController(initialPage: initialPageViewPage);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        oldController.dispose();
      });
    }

    final themeBg = widget.themes[widget.activeThemeIndex][0] as Color;

    return PageView.builder(
      key: ValueKey('${widget.bookId}_${state.currentBookProgress?.lastReadChapterIndex}_${widget.textStyle.fontSize}_${widget.textStyle.height}_${widget.textStyle.fontFamily}_$isDoubleColumn'),
      controller: _pageController,
      itemCount: itemCount,
      onPageChanged: (pageIndex) {
        if (hasPrevChapter && pageIndex == 0) {
          widget.onPrevChapter();
          return;
        }
        if (pageIndex == totalScreens + itemOffsetShift) {
          widget.onNextChapter();
          return;
        }
        if (pageIndex < totalScreens + itemOffsetShift) {
          final contentScreenIndex = pageIndex - itemOffsetShift;
          final int contentPageIndex = isDoubleColumn ? contentScreenIndex * 2 : contentScreenIndex;
          if (contentPageIndex >= 0 && contentPageIndex < pageOffsets.length) {
            final startOffset = pageOffsets[contentPageIndex];
            if (mounted) {
              ref.read(novelProvider.notifier).saveProgress(max(0, startOffset - titleLen));
            }
          }
        }
      },
      itemBuilder: (context, pageIndex) {
        if (hasPrevChapter && pageIndex == 0) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: themeText.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text('正在加载上一章...', style: TextStyle(color: themeText.withOpacity(0.5), fontSize: 13)),
              ],
            ),
          );
        }

        if (pageIndex == totalScreens + itemOffsetShift) {
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

        final contentScreenIndex = pageIndex - itemOffsetShift;
        Widget pageChild;

        if (isDoubleColumn) {
          final leftPageIndex = contentScreenIndex * 2;
          final rightPageIndex = leftPageIndex + 1;

          Widget leftWidget = const SizedBox();
          Widget rightWidget = const SizedBox();

          if (leftPageIndex < totalPages) {
            final start = pageOffsets[leftPageIndex];
            final end = pageOffsets[leftPageIndex + 1];
            final pageText = textToPaginate.substring(start, end);
            leftWidget = _buildColumnTextWidget(state, pageText, leftPageIndex, start, end, widget.textStyle);
          }

          if (rightPageIndex < totalPages) {
            final start = pageOffsets[rightPageIndex];
            final end = pageOffsets[rightPageIndex + 1];
            final pageText = textToPaginate.substring(start, end);
            rightWidget = _buildColumnTextWidget(state, pageText, rightPageIndex, start, end, widget.textStyle);
          }

          pageChild = Container(
            padding: EdgeInsets.symmetric(horizontal: widget.marginHorizontal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  state.currentChapter!.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: themeText.withOpacity(0.35),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: leftWidget,
                        ),
                      ),
                      Container(
                        width: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        color: themeText.withOpacity(0.08),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: rightWidget,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}",
                      style: TextStyle(
                        fontSize: 10,
                        color: themeText.withOpacity(0.35),
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      '第 ${contentScreenIndex + 1} / $totalScreens 页',
                      style: TextStyle(
                        fontSize: 10,
                        color: themeText.withOpacity(0.35),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        } else {
          final start = pageOffsets[contentScreenIndex];
          final end = pageOffsets[contentScreenIndex + 1];
          final pageText = textToPaginate.substring(start, end);
          final textWidget = _buildColumnTextWidget(state, pageText, contentScreenIndex, start, end, widget.textStyle);

          pageChild = Container(
            padding: EdgeInsets.symmetric(horizontal: widget.marginHorizontal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  state.currentChapter!.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: themeText.withOpacity(0.35),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: textWidget,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}",
                      style: TextStyle(
                        fontSize: 10,
                        color: themeText.withOpacity(0.35),
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      '第 ${contentScreenIndex + 1} / $totalPages 页',
                      style: TextStyle(
                        fontSize: 10,
                        color: themeText.withOpacity(0.35),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        }

        return AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
            double pageVal = 0.0;
            if (_pageController.hasClients && _pageController.position.haveDimensions) {
              pageVal = _pageController.page ?? initialPageViewPage.toDouble();
            } else {
              pageVal = initialPageViewPage.toDouble();
            }

            final double delta = pageIndex - pageVal;

            if (delta < -1.0 || delta > 1.0) {
              return const SizedBox.shrink();
            }

            double translationX = 0.0;
            double scale = 1.0;
            double opacity = 1.0;

            if (delta < 0) {
              scale = 1.0 + (delta * 0.06);
              opacity = (1.0 + delta).clamp(0.1, 1.0);
              translationX = -delta * screenWidth * 0.45;
            } else {
              translationX = 0.0;
              scale = 1.0;
              opacity = 1.0;
            }

            return Transform(
              transform: Matrix4.translationValues(translationX, 0.0, 0.0)..scale(scale),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  decoration: BoxDecoration(
                    color: themeBg,
                    boxShadow: delta > 0
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity((1.0 - delta).clamp(0.0, 0.25)),
                              blurRadius: 12,
                              offset: const Offset(-6, 0),
                            )
                          ]
                        : null,
                  ),
                  child: child,
                ),
              ),
            );
          },
          child: pageChild,
        );
      },
    );
  }

  Widget _buildColumnTextWidget(
    NovelState state,
    String pageText,
    int pageIndex,
    int start,
    int end,
    TextStyle textStyle,
  ) {
    final int titleLen = "${state.currentChapter!.title}\n\n\n".length;
    final int ttsIndex = state.ttsHighlightCharIndex + titleLen;
    final Color themeText = textStyle.color ?? Colors.black;

    if (state.isTtsPlaying && ttsIndex >= start && ttsIndex < end) {
      final relativeIdx = ttsIndex - start;
      final relativeEnd = (relativeIdx + 12).clamp(relativeIdx, pageText.length);
      return RichText(
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
      final textSpan = widget.buildFormattedTextSpan(
        pageText,
        textStyle,
        themeText,
      );
      return GestureDetector(
        onLongPress: () {
          widget.onShowAnnotationsSheet(state, pageText);
        },
        child: RichText(text: textSpan),
      );
    }
  }
}
