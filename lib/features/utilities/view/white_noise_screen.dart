import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../features/dashboard/provider/tools_provider.dart';

class WhiteNoiseScreen extends ConsumerStatefulWidget {
  const WhiteNoiseScreen({super.key});

  @override
  ConsumerState<WhiteNoiseScreen> createState() => _WhiteNoiseScreenState();
}

class _WhiteNoiseScreenState extends ConsumerState<WhiteNoiseScreen> with TickerProviderStateMixin {
  String? _activeSoundId;
  bool _isPlaying = false;
  Timer? _countdownTimer;
  int _secondsRemaining = 0; // Timer to automatically stop playback

  late AnimationController _waveController;

  final List<Map<String, dynamic>> _sounds = [
    {
      'id': 'rain',
      'emoji': '🌧️',
      'name': '深山秋雨',
      'desc': '幽静山谷中的淅沥雨声，抚平焦虑。',
      'color': Colors.blueAccent,
    },
    {
      'id': 'waves',
      'emoji': '🌊',
      'name': '极地海浪',
      'desc': '远古冰川海滩上的潮汐起落，回归宁静。',
      'color': Colors.cyanAccent,
    },
    {
      'id': 'pines',
      'emoji': '🌲',
      'name': '林间松涛',
      'desc': '微风穿过广阔针叶林沙沙作响。',
      'color': Colors.greenAccent,
    },
    {
      'id': 'fire',
      'emoji': '☕',
      'name': '壁炉篝火',
      'desc': '深夜小木屋里温暖柴火的噼啪碎响。',
      'color': Colors.orangeAccent,
    },
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _togglePlay(String soundId) {
    if (_activeSoundId == soundId) {
      // Toggle play state
      setState(() {
        _isPlaying = !_isPlaying;
      });
    } else {
      // Switch sound — log telemetry for new selection
      setState(() {
        _activeSoundId = soundId;
        _isPlaying = true;
      });
      _logSoundUsage(soundId);
    }
  }

  void _logSoundUsage(String soundId) {
    try {
      ref.read(toolsAnalyticsProvider).logUsage(
        toolKey: 'white_noise',
        parameters: {'sound_id': soundId},
        status: 'success',
        durationMs: 0,
      );
    } catch (_) {}
  }

  void _setTimer(int minutes) {
    _countdownTimer?.cancel();
    if (minutes == 0) {
      setState(() {
        _secondsRemaining = 0;
      });
      return;
    }

    setState(() {
      _secondsRemaining = minutes * 60;
      _isPlaying = true;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _stopPlayback();
      }
    });
  }

  void _stopPlayback() {
    _countdownTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _secondsRemaining = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('💤 专注休眠定时已到，音频自动静音'),
        backgroundColor: Color(0xFF0F0C29),
      ),
    );
  }

  String _formatTimer() {
    if (_secondsRemaining == 0) return '未设置定时';
    final int mins = _secondsRemaining ~/ 60;
    final int secs = _secondsRemaining % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '白噪音专注冥想',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          // Theme Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0C091F), Color(0xFF140F2D), Color(0xFF06050C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                // Top Animation Core Visual Card
                _buildMeditationPanel(),
                const SizedBox(height: 24),

                // Sound choices grid
                const Text(
                  '🎧 环境疗愈音景',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _sounds.length,
                  itemBuilder: (context, index) {
                    final sound = _sounds[index];
                    final isCurrent = _activeSoundId == sound['id'];
                    final isActivePlay = isCurrent && _isPlaying;

                    return GestureDetector(
                      onTap: () => _togglePlay(sound['id']),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? sound['color'].withOpacity(0.12)
                              : Colors.white.withOpacity(0.015),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isCurrent
                                ? sound['color'].withOpacity(0.5)
                                : Colors.white.withOpacity(0.05),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(sound['emoji'], style: const TextStyle(fontSize: 22)),
                                if (isActivePlay)
                                  const Icon(Icons.volume_up_rounded, color: Colors.purpleAccent, size: 18)
                                else if (isCurrent)
                                  const Icon(Icons.volume_off_rounded, color: Colors.white30, size: 18),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sound['name'],
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  sound['desc'],
                                  style: const TextStyle(color: Colors.white38, fontSize: 9.5, height: 1.3),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Sleep Timer Panel
                const Text(
                  '💤 休眠倒计时停止器',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('倒计时状态', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text(
                            _formatTimer(),
                            style: const TextStyle(color: Colors.purpleAccent, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTimeChip(15, '15分钟'),
                          _buildTimeChip(30, '30分钟'),
                          _buildTimeChip(45, '45分钟'),
                          _buildTimeChip(0, '无定时', isCancel: true),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeditationPanel() {
    final activeSound = _sounds.firstWhere(
      (s) => s['id'] == _activeSoundId,
      orElse: () => _sounds[0],
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        children: [
          // Animated ripples
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isPlaying)
                  ...List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        final progress = (_waveController.value + index / 3) % 1.0;
                        return Container(
                          width: 80 + progress * 100,
                          height: 80 + progress * 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: activeSound['color'].withOpacity(1.0 - progress),
                              width: 1.5,
                            ),
                          ),
                        );
                      },
                    );
                  }),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _isPlaying
                        ? activeSound['color'].withOpacity(0.15)
                        : Colors.white.withOpacity(0.02),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isPlaying ? activeSound['color'] : Colors.white24,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _isPlaying ? activeSound['emoji'] : '🧘',
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _isPlaying ? '正在沉浸式播放「${activeSound['name']}」' : '选择下方声音开启沉浸专注',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            '佩戴耳机播放效果更佳。音频文件已经安全缓存在设备本地。',
            style: TextStyle(color: Colors.white30, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeChip(int mins, String label, {bool isCancel = false}) {
    final bool isSelected = (_secondsRemaining ~/ 60 == mins) && !isCancel;
    final color = isCancel ? Colors.redAccent : Colors.purpleAccent;

    return GestureDetector(
      onTap: () => _setTimer(mins),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.5) : Colors.white.withOpacity(0.05),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
