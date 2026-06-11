import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/novel_models.dart';
import '../../provider/novel_provider.dart';
import '../../service/novel_api_client.dart';

class SourceSwapperContent extends ConsumerStatefulWidget {
  final Book book;
  final bool inAbyss;
  final Function(String sourceId, String bookUrl) onChangeSource;

  const SourceSwapperContent({
    super.key,
    required this.book,
    required this.inAbyss,
    required this.onChangeSource,
  });

  @override
  ConsumerState<SourceSwapperContent> createState() => _SourceSwapperContentState();
}

class _SourceSwapperContentState extends ConsumerState<SourceSwapperContent> {
  List<Book> _sources = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSources();
  }

  Future<void> _fetchSources() async {
    try {
      final results = await ref.read(novelApiClientProvider).searchNovels(
        widget.book.title,
        widget.inAbyss,
      );
      if (mounted) {
        setState(() {
          _sources = results.where((b) => b.title.trim() == widget.book.title.trim()).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurfaceColor = theme.colorScheme.onSurface;
    final primaryColor = theme.colorScheme.primary;

    return Column(
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
            Icon(Icons.swap_horiz_rounded, color: primaryColor),
            const SizedBox(width: 8),
            Text(
              '为《${widget.book.title}》更换书源',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurfaceColor),
            ),
          ],
        ),
        Divider(height: 24, color: onSurfaceColor.withOpacity(0.1)),
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: primaryColor),
                )
              : _error != null
                  ? Center(
                      child: Text(
                        '搜索失败: $_error',
                        style: TextStyle(color: onSurfaceColor.withOpacity(0.38)),
                      ),
                    )
                  : _sources.isEmpty
                      ? Center(
                          child: Text(
                            '未找到其他可用书源',
                            style: TextStyle(color: onSurfaceColor.withOpacity(0.38)),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: _sources.length,
                          itemBuilder: (context, idx) {
                            final candidate = _sources[idx];
                            final sourceName = candidate.sourceName ?? '未知书源';
                            final isCurrent = candidate.sourceId == widget.book.sourceId ||
                                candidate.sourceId == widget.book.currentSourceId;

                            return Card(
                              color: onSurfaceColor.withOpacity(0.04),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isCurrent ? primaryColor.withOpacity(0.5) : onSurfaceColor.withOpacity(0.1),
                                  width: isCurrent ? 1.5 : 1,
                                ),
                              ),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        sourceName,
                                        style: TextStyle(
                                          color: onSurfaceColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (isCurrent)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '当前使用',
                                          style: TextStyle(
                                            color: primaryColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '作者: ${candidate.author}   |   来源: ${candidate.bookUrl ?? "未知"}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: onSurfaceColor.withOpacity(0.4), fontSize: 11),
                                  ),
                                ),
                                trailing: isCurrent
                                    ? Icon(Icons.check_circle_rounded, color: primaryColor)
                                    : Icon(Icons.arrow_forward_ios_rounded, color: onSurfaceColor.withOpacity(0.24), size: 14),
                                onTap: isCurrent
                                    ? null
                                    : () {
                                        widget.onChangeSource(
                                          candidate.sourceId ?? '',
                                          candidate.bookUrl ?? '',
                                        );
                                      },
                                ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
