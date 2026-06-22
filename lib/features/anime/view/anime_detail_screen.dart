import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

import '../../../../core/widgets/dynamic_background.dart';
import '../model/anime.dart';
import '../provider/anime_provider.dart';
import 'anime_player_screen.dart';

class AnimeDetailScreen extends ConsumerStatefulWidget {
  final String animeUrl;
  final String animeTitle;
  final String? coverUrl;

  const AnimeDetailScreen({
    super.key,
    required this.animeUrl,
    required this.animeTitle,
    this.coverUrl,
  });

  @override
  ConsumerState<AnimeDetailScreen> createState() => _AnimeDetailScreenState();
}

class _AnimeDetailScreenState extends ConsumerState<AnimeDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(animeDetailProvider.notifier).loadDetail(widget.animeUrl);
      ref.read(animeHistoryProvider.notifier).loadHistory();
    });
  }

  AnimeProgress? _getMatchingProgress(List<AnimeProgress> historyList, String animeId) {
    try {
      return historyList.firstWhere((element) => element.animeId == animeId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(animeDetailProvider);
    final historyAsync = ref.watch(animeHistoryProvider);
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final themeColor = Colors.deepOrangeAccent;

    // Detect if we have watch progress for this anime
    AnimeProgress? progress;
    historyAsync.whenData((historyList) {
      if (detailState.detail != null) {
        progress = _getMatchingProgress(historyList, detailState.detail!.animeId);
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: onSurface.withOpacity(0.7)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (detailState.detail != null)
            IconButton(
              icon: Icon(
                progress?.inFavorites == true ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: progress?.inFavorites == true ? Colors.redAccent : onSurface.withOpacity(0.7),
              ),
              onPressed: () {
                final d = detailState.detail!;
                ref.read(animeHistoryProvider.notifier).syncProgress(
                      animeId: d.animeId,
                      animeTitle: d.title,
                      coverUrl: d.coverUrl,
                      animeUrl: d.animeUrl,
                      episodeTitle: progress?.lastWatchEpisodeTitle ?? d.episodes.first.title,
                      episodeUrl: progress?.lastWatchEpisodeUrl ?? d.episodes.first.episodeUrl,
                      episodeIndex: progress?.lastWatchEpisodeIndex ?? 0,
                      position: progress?.lastWatchPosition ?? 0,
                      inFavorites: !(progress?.inFavorites ?? false),
                    );
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          const DynamicBackground(child: SizedBox.expand()),
          if (detailState.isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.deepOrangeAccent),
                  SizedBox(height: 16),
                  Text('加载剧集列表中，请稍候...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            )
          else if (detailState.error != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 16),
                  Text(detailState.error!, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(animeDetailProvider.notifier).loadDetail(widget.animeUrl),
                    style: ElevatedButton.styleFrom(backgroundColor: themeColor),
                    child: const Text('重试', style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
            )
          else if (detailState.detail != null)
            _buildDetailContent(detailState.detail!, progress, themeColor),
        ],
      ),
    );
  }

  Widget _buildDetailContent(AnimeDetail detail, AnimeProgress? progress, Color themeColor) {
    final hasProgress = progress != null && progress.lastWatchEpisodeTitle != null;

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Cover and Info Header
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cover Thumbnail Image
                        Hero(
                          tag: 'anime_cover_${detail.animeId}',
                          child: Container(
                            width: 110,
                            height: 155,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: detail.coverUrl != null && detail.coverUrl!.isNotEmpty
                                  ? Image.network(detail.coverUrl!, fit: BoxFit.cover)
                                  : Container(color: Colors.white10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Metadata Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                detail.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (detail.genres != null && detail.genres!.isNotEmpty)
                                Text(
                                  detail.genres!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.5),
                                    height: 1.4,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: themeColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: themeColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  '全网聚合：共 ${detail.episodes.length} 集',
                                  style: TextStyle(
                                    color: themeColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Description Accordion
              if (detail.description != null && detail.description!.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '简介',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            detail.description!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Episode Section Label
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
                  child: Text(
                    '剧集播放列表',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Episode Grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final episode = detail.episodes[index];
                      final isLastWatched = hasProgress && progress.lastWatchEpisodeIndex == index;

                      return InkWell(
                        onTap: () => _playEpisode(detail, index),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isLastWatched
                                ? themeColor.withOpacity(0.2)
                                : Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isLastWatched
                                  ? themeColor.withOpacity(0.6)
                                  : Colors.white.withOpacity(0.05),
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            episode.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isLastWatched ? themeColor : Colors.white70,
                              fontSize: 12,
                              fontWeight: isLastWatched ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: detail.episodes.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
        
        // Floating bottom resume action bar
        if (hasProgress) _buildResumeFloatingBar(detail, progress, themeColor),
      ],
    );
  }

  Widget _buildResumeFloatingBar(AnimeDetail detail, AnimeProgress progress, Color themeColor) {
    // Format friendly position display
    final min = progress.lastWatchPosition ~/ 60;
    final sec = progress.lastWatchPosition % 60;
    final posText = '$min分$sec秒';

    return Container(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 12.0,
        bottom: 12.0 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: themeColor.withOpacity(0.12),
            child: Row(
              children: [
                const Icon(Icons.history_toggle_off_rounded, color: Colors.deepOrangeAccent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '记忆播放位置: ${progress.lastWatchEpisodeTitle}',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '上次看到 $posText',
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _playEpisode(detail, progress.lastWatchEpisodeIndex, resumePosition: progress.lastWatchPosition),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                  label: const Text('继续观看', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _playEpisode(AnimeDetail detail, int episodeIndex, {int resumePosition = 0}) {
    if (episodeIndex < 0 || episodeIndex >= detail.episodes.length) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnimePlayerScreen(
          animeDetail: detail,
          initialEpisodeIndex: episodeIndex,
          startSeekOffset: resumePosition,
        ),
      ),
    ).then((_) {
      // Refresh reading progress list when returning back to detail screen
      ref.read(animeHistoryProvider.notifier).loadHistory();
    });
  }
}
