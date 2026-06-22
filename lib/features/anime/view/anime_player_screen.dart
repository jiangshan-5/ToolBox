import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../model/anime.dart';
import '../provider/anime_provider.dart';
import '../service/anime_service.dart';

class AnimePlayerScreen extends ConsumerStatefulWidget {
  final AnimeDetail animeDetail;
  final int initialEpisodeIndex;
  final int startSeekOffset; // in seconds

  const AnimePlayerScreen({
    super.key,
    required this.animeDetail,
    required this.initialEpisodeIndex,
    this.startSeekOffset = 0,
  });

  @override
  ConsumerState<AnimePlayerScreen> createState() => _AnimePlayerScreenState();
}

class _AnimePlayerScreenState extends ConsumerState<AnimePlayerScreen> {
  int _currentEpisodeIndex = 0;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMsg;
  Timer? _progressSyncTimer;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _currentEpisodeIndex = widget.initialEpisodeIndex;
    _initializePlayer(startAtSeconds: widget.startSeekOffset);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _progressSyncTimer?.cancel();
    _saveCurrentProgressSync(); // Final sync before exiting
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer({int startAtSeconds = 0}) async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    _progressSyncTimer?.cancel();
    _chewieController?.dispose();
    _videoPlayerController?.dispose();

    final episode = widget.animeDetail.episodes[_currentEpisodeIndex];

    try {
      // 1. Resolve play stream URL from FastAPI backend
      final resolvedUrl = await ref
          .read(animeServiceProvider)
          .getPlayUrl(episode.episodeUrl, episode.title);

      if (resolvedUrl == null || resolvedUrl.isEmpty || _isDisposed) {
        throw Exception('无法解析视频播放源链接');
      }

      // 2. Initialize video player
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(resolvedUrl),
      );

      await _videoPlayerController!.initialize();

      if (_isDisposed) return;

      // 3. Initialize Chewie controller
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        allowedScreenSleep: false, // Keep screen awake
        playbackSpeeds: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0],
        deviceOrientationsOnEnterFullScreen: [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        deviceOrientationsAfterFullScreen: [
          DeviceOrientation.portraitUp,
        ],
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.deepOrangeAccent),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                '视频播放出错: $errorMessage\n可能流文件已失效，请尝试切换剧集或返回重试。',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          );
        },
      );

      // Seek to saved position if greater than 0
      if (startAtSeconds > 0) {
        await _videoPlayerController!.seekTo(Duration(seconds: startAtSeconds));
      }

      setState(() {
        _isLoading = false;
      });

      // 4. Start periodic watch progress synchronization timer (every 10 seconds)
      _progressSyncTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _saveCurrentProgressSync();
      });

    } catch (e) {
      if (!_isDisposed) {
        setState(() {
          _isLoading = false;
          _errorMsg = e.toString().contains('Exception:')
              ? e.toString().replaceAll('Exception:', '')
              : '视频源解析或播放器初始化失败，请稍后重试。';
        });
      }
    }
  }

  void _saveCurrentProgressSync() {
    if (_videoPlayerController == null || !_videoPlayerController!.value.isInitialized) {
      return;
    }

    final episode = widget.animeDetail.episodes[_currentEpisodeIndex];
    final position = _videoPlayerController!.value.position.inSeconds;
    final duration = _videoPlayerController!.value.duration.inSeconds;
    final isCompleted = duration > 0 && (position >= duration - 10); // completed if 10s left

    ref.read(animeHistoryProvider.notifier).syncProgress(
          animeId: widget.animeDetail.animeId,
          animeTitle: widget.animeDetail.title,
          coverUrl: widget.animeDetail.coverUrl,
          animeUrl: widget.animeDetail.animeUrl,
          episodeTitle: episode.title,
          episodeUrl: episode.episodeUrl,
          episodeIndex: _currentEpisodeIndex,
          position: position,
          isCompleted: isCompleted,
        );
  }

  void _switchToEpisode(int index) {
    if (index < 0 || index >= widget.animeDetail.episodes.length) return;
    
    // Save current progress before switching
    _saveCurrentProgressSync();

    setState(() {
      _currentEpisodeIndex = index;
    });
    _initializePlayer();
  }

  @override
  Widget build(BuildContext context) {
    final episode = widget.animeDetail.episodes[_currentEpisodeIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with back button and title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              color: Colors.black,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.animeDetail.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '当前播放: ${episode.title}',
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Video Player Center Area
            Expanded(
              child: Container(
                color: Colors.black,
                child: _buildPlayerArea(),
              ),
            ),

            // Bottom Playlist / Navigation Controls
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Next / Previous buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _currentEpisodeIndex > 0
                            ? () => _switchToEpisode(_currentEpisodeIndex - 1)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.08),
                          disabledBackgroundColor: Colors.white.withOpacity(0.02),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.skip_previous_rounded, color: Colors.white70),
                        label: const Text('上一集', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ),
                      ElevatedButton.icon(
                        onPressed: _currentEpisodeIndex < widget.animeDetail.episodes.length - 1
                            ? () => _switchToEpisode(_currentEpisodeIndex + 1)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrangeAccent,
                          disabledBackgroundColor: Colors.white.withOpacity(0.02),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
                        label: const Text('下一集', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '快捷选集',
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  // Bottom grid/list of quick selections
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: widget.animeDetail.episodes.length,
                      itemBuilder: (context, idx) {
                        final ep = widget.animeDetail.episodes[idx];
                        final isCurrent = idx == _currentEpisodeIndex;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: InkWell(
                            onTap: () => _switchToEpisode(idx),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? Colors.deepOrangeAccent.withOpacity(0.2)
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isCurrent
                                      ? Colors.deepOrangeAccent
                                      : Colors.white.withOpacity(0.05),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                ep.title,
                                style: TextStyle(
                                  color: isCurrent ? Colors.deepOrangeAccent : Colors.white70,
                                  fontSize: 12,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerArea() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.deepOrangeAccent),
            SizedBox(height: 16),
            Text(
              '正在加载真实流媒体播放链接...',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_errorMsg != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMsg!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _initializePlayer(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrangeAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: const Text('点击重试', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_chewieController != null) {
      return AspectRatio(
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        child: Chewie(controller: _chewieController!),
      );
    }

    return const SizedBox.shrink();
  }
}
