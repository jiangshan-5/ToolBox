import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:async';

import 'dart:math';

import 'package:just_audio/just_audio.dart';

import '../../../../core/network/api_client.dart';
import '../../auth/provider/auth_provider.dart';
import '../../../features/dashboard/provider/tools_provider.dart';

import 'widgets/noise_breathing_bubble.dart';
import 'widgets/noise_visualizer.dart';
import 'widgets/noise_sound_card.dart';

class WhiteNoiseScreen extends ConsumerStatefulWidget {
  const WhiteNoiseScreen({super.key});

  @override
  ConsumerState<WhiteNoiseScreen> createState() => _WhiteNoiseScreenState();
}

class _WhiteNoiseScreenState extends ConsumerState<WhiteNoiseScreen>
    with TickerProviderStateMixin {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get textColor => isDark ? Colors.white : Colors.black87;
  Color get subTextColor => isDark ? Colors.white70 : Colors.black54;
  Color get faintTextColor => isDark ? Colors.white38 : Colors.black54;
  Color get borderDividerColor =>
      isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

  // Screen Tabs: 'breathing' vs 'mixer'
  String _activeTab = 'breathing';

  // ===========================================================================
  // 1. SOUNDSCAPE MIXER STATE
  // ===========================================================================
  List<Map<String, dynamic>> _sounds = [
    {
      'id': 'rain',
      'icon': Icons.umbrella_rounded,
      'name': '深山秋雨',
      'desc': '幽静山谷中的淅沥雨声，抚平内心焦虑。',
      'color': Colors.blueAccent,
      'url': 'https://cdn.jsdelivr.net/gh/bradtraversy/ambient-sound-mixer@main/audio/rain.mp3',
    },
    {
      'id': 'waves',
      'icon': Icons.waves_rounded,
      'name': '极地海浪',
      'desc': '远古冰川海滩上的潮汐起落，回归静止。',
      'color': Colors.cyanAccent,
      'url': 'https://cdn.jsdelivr.net/gh/bradtraversy/ambient-sound-mixer@main/audio/ocean.mp3',
    },
    {
      'id': 'pines',
      'icon': Icons.forest_rounded,
      'name': '林间松涛',
      'desc': '微风穿过广阔针叶林，带来原野芬芳。',
      'color': Colors.greenAccent,
      'url': 'https://cdn.jsdelivr.net/gh/bradtraversy/ambient-sound-mixer@main/audio/wind.mp3',
    },
    {
      'id': 'fire',
      'icon': Icons.local_fire_department_rounded,
      'name': '壁炉篝火',
      'desc': '深夜小木屋里温暖柴火的噼啪爆裂碎响。',
      'color': Colors.orangeAccent,
      'url': 'https://cdn.jsdelivr.net/gh/bradtraversy/ambient-sound-mixer@main/audio/fireplace.mp3',
    },
    {
      'id': 'brook',
      'icon': Icons.water_rounded,
      'name': '山间溪流',
      'desc': '高山融雪化作林间欢快奔腾的潺潺清泉。',
      'color': Colors.tealAccent,
      'url': 'https://cdn.jsdelivr.net/gh/karthiknvd/noctune@master/sounds/river.mp3',
    },
    {
      'id': 'insects',
      'icon': Icons.audiotrack_rounded,
      'name': '夏夜虫鸣',
      'desc': '繁星点点的仲夏夜里草丛间的自然协奏曲。',
      'color': Colors.amberAccent,
      'url': 'https://cdn.jsdelivr.net/gh/bradtraversy/ambient-sound-mixer@main/audio/night.mp3',
    },
  ];

  // Track volumes (0.0 to 1.0) and whether channel is toggled ON
  final Map<String, double> _channelVolumes = {};
  final Map<String, bool> _channelActive = {};
  bool _isMixerPlaying = false;

  // Track AudioPlayers for each channel
  final Map<String, AudioPlayer> _players = {};

  // Visualizer timer and random bars height
  Timer? _visualizerTimer;
  final List<double> _visualizerHeights = List.generate(24, (_) => 4.0);
  final Random _random = Random();

  // ===========================================================================
  // 2. BREATHING MEDITATION STATE
  // ===========================================================================
  // Breathing modes: '4-7-8', 'box', 'equal'
  String _activeBreathingMode = '4-7-8';
  bool _isBreathingActive = false;

  // Rhythmic phases
  String _breathingPhase = 'inhale'; // inhale, hold, exhale, hold2 (for box)
  int _breathingSecondsRemaining = 0;
  Timer? _breathingTimer;
  Timer? _bubbleSmoothTimer; // High frequency timer for smooth bubble scaling
  double _bubbleScale = 1.0;
  double _elapsedFraction = 0.0; // Current state elapsed fractional progress

  // Cumulative parameters
  int _completedCycles = 0;
  final Map<String, Map<String, dynamic>> _breathingConfigs = {
    '4-7-8': {
      'name': '4-7-8 呼吸减压法',
      'desc': '4秒吸气，7秒屏息，8秒呼气。专为排解焦虑、平心静气及深度助眠研发。',
      'phases': ['inhale', 'hold', 'exhale'],
      'durations': {'inhale': 4, 'hold': 7, 'exhale': 8},
      'glow': Colors.purpleAccent,
    },
    'box': {
      'name': '等时盒式呼吸法',
      'desc': '吸气、屏息、呼气、呼后屏息均等时（各4秒）。特种部队压力重置极简训练。',
      'phases': ['inhale', 'hold', 'exhale', 'hold2'],
      'durations': {'inhale': 4, 'hold': 4, 'exhale': 4, 'hold2': 4},
      'glow': Colors.tealAccent,
    },
    'equal': {
      'name': '5-5 均衡平静法',
      'desc': '5秒吸气，5秒呼气。帮助均匀调息，减缓心率，促使大脑迅速恢复清明。',
      'phases': ['inhale', 'exhale'],
      'durations': {'inhale': 5, 'exhale': 5},
      'glow': Colors.cyanAccent,
    },
  };

  // ===========================================================================
  // 3. SLEEP TIMER STATE
  // ===========================================================================
  Timer? _sleepTimer;
  int _secondsRemaining = 0; // Timer to automatically stop playback

  IconData _mapIconName(String? name) {
    switch (name) {
      case 'umbrella':
        return Icons.umbrella_rounded;
      case 'waves':
        return Icons.waves_rounded;
      case 'forest':
        return Icons.forest_rounded;
      case 'fire':
        return Icons.local_fire_department_rounded;
      case 'water':
        return Icons.water_rounded;
      case 'music':
      case 'insects':
        return Icons.audiotrack_rounded;
      default:
        return Icons.music_note_rounded;
    }
  }

  Color _parseColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) {
      return Colors.blueAccent;
    }
    try {
      String hex = hexString.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return Colors.blueAccent;
    }
  }

  String _resolveAudioUrl(String relativeUrl, String apiBaseUrl) {
    if (relativeUrl.startsWith('http://') || relativeUrl.startsWith('https://')) {
      return relativeUrl;
    }
    String hostUrl = apiBaseUrl.replaceAll('/api/v1', '');
    if (hostUrl.endsWith('/')) {
      hostUrl = hostUrl.substring(0, hostUrl.length - 1);
    }
    String path = relativeUrl;
    if (!path.startsWith('/')) {
      path = '/$path';
    }
    return '$hostUrl$path';
  }

  Future<void> _loadRemoteTracks() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.instance.get('/tools/white_noise');
      final List<dynamic> remoteData = response.data;
      if (remoteData.isEmpty) return;

      final List<Map<String, dynamic>> newSounds = [];
      final Set<String> activeIds = {};

      for (var item in remoteData) {
        final id = item['id'] as String;
        activeIds.add(id);

        final String relativeUrl = item['url'] as String;
        final String fullUrl = _resolveAudioUrl(relativeUrl, apiClient.instance.options.baseUrl);

        newSounds.add({
          'id': id,
          'icon': _mapIconName(item['icon_name'] as String?),
          'name': item['name'] as String,
          'desc': item['description'] as String? ?? '',
          'color': _parseColor(item['color_hex'] as String?),
          'url': fullUrl,
        });

        if (!_players.containsKey(id)) {
          _channelVolumes[id] = 0.5;
          _channelActive[id] = false;

          final player = AudioPlayer();
          player.setLoopMode(LoopMode.one);
          player.setVolume(0.5);
          player.setUrl(fullUrl).catchError((_) => null);
          _players[id] = player;
        } else {
          final existingSound = _sounds.firstWhere((s) => s['id'] == id, orElse: () => {});
          if (existingSound.isNotEmpty && existingSound['url'] != fullUrl) {
            _players[id]?.setUrl(fullUrl).catchError((_) => null);
          }
        }
      }

      final List<String> toRemove = [];
      for (var id in _players.keys) {
        if (!activeIds.contains(id)) {
          _players[id]?.stop().catchError((_) => null);
          _players[id]?.dispose().catchError((_) => null);
          toRemove.add(id);
        }
      }
      for (var id in toRemove) {
        _players.remove(id);
        _channelVolumes.remove(id);
        _channelActive.remove(id);
      }

      if (mounted) {
        setState(() {
          _sounds.clear();
          _sounds.addAll(newSounds);
        });
      }
    } catch (e) {
      debugPrint("Failed to load remote white noise tracks: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize mixer volume map and audio player instances
    for (var sound in _sounds) {
      final id = sound['id'] as String;
      _channelVolumes[id] = 0.5; // default 50%
      _channelActive[id] = false;

      final player = AudioPlayer();
      player.setLoopMode(LoopMode.one);
      player.setVolume(0.5);
      // Preload network URL dynamically
      player.setUrl(sound['url'] as String).catchError((_) {
        return null;
      });
      _players[id] = player;
    }
    _loadRemoteTracks();
  }

  @override
  void dispose() {
    _visualizerTimer?.cancel();
    _breathingTimer?.cancel();
    _bubbleSmoothTimer?.cancel();
    _sleepTimer?.cancel();
    // Teardown all active players to prevent audio leaks
    for (var player in _players.values) {
      player.stop().catchError((_) => null);
      player.dispose().catchError((_) => null);
    }
    super.dispose();
  }

  // ===========================================================================
  // TELEMETRY LOGGING
  // ===========================================================================
  void _logMeditationTelemetry(String type, Map<String, dynamic> extras) {
    try {
      ref
          .read(toolsAnalyticsProvider)
          .logUsage(
            toolKey: 'white_noise',
            parameters: {'action': type, ...extras},
            status: 'success',
            durationMs: 0,
          );
    } catch (_) {}
  }

  // ===========================================================================
  // SLEEP TIMER LOGIC
  // ===========================================================================
  void _setSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    if (minutes == 0) {
      setState(() {
        _secondsRemaining = 0;
      });
      return;
    }
    setState(() {
      _secondsRemaining = minutes * 60;
    });
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _triggerSleepFading();
      }
    });
  }

  void _syncAudioPlayback() {
    for (var sound in _sounds) {
      final id = sound['id'] as String;
      final player = _players[id];
      if (player != null) {
        if (_isMixerPlaying && (_channelActive[id] == true)) {
          player.setVolume(_channelVolumes[id] ?? 0.5).catchError((_) => null);
          if (!player.playing) {
            player.play().catchError((_) => null);
          }
        } else {
          if (player.playing) {
            player.stop().catchError((_) => null);
          }
        }
      }
    }
  }

  void _triggerSleepFading() {
    _sleepTimer?.cancel();
    _stopBreathingCoach();

    // Silently stop all playing channels immediately
    for (var player in _players.values) {
      player.stop().catchError((_) => null);
    }

    if (!mounted) return;

    // Smoothly silence channels
    setState(() {
      _isMixerPlaying = false;
      for (var key in _channelActive.keys) {
        _channelActive[key] = false;
      }
      _visualizerTimer?.cancel();
      _secondsRemaining = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('💤 专注休眠倒计时已到，音景及冥想向导已优雅淡出静音'),
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatSleepTimer() {
    if (_secondsRemaining == 0) return '无休眠定时';
    final int mins = _secondsRemaining ~/ 60;
    final int secs = _secondsRemaining % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // ===========================================================================
  // MIXER PLAYBACK CONTROLLER
  // ===========================================================================
  void _toggleMixerPlay() {
    setState(() {
      _isMixerPlaying = !_isMixerPlaying;
      if (_isMixerPlaying) {
        final hasActive = _channelActive.values.any((isActive) => isActive);
        if (!hasActive) {
          _channelActive[_sounds[0]['id']] = true;
        }
        _startVisualizerAnimation();
        _logMeditationTelemetry('mixer_start', {
          'active_channels': _channelActive.entries
              .where((e) => e.value)
              .map((e) => e.key)
              .toList(),
        });
      } else {
        _visualizerTimer?.cancel();
      }
      _syncAudioPlayback();
    });
  }

  void _toggleChannelActive(String id) {
    setState(() {
      _channelActive[id] = !(_channelActive[id] ?? false);
      if (_channelActive[id] == true) {
        _isMixerPlaying = true;
        _startVisualizerAnimation();
        _logMeditationTelemetry('channel_enable', {'channel_id': id});
      } else {
        final hasActive = _channelActive.values.any((isActive) => isActive);
        if (!hasActive) {
          _isMixerPlaying = false;
          _visualizerTimer?.cancel();
        }
      }
      _syncAudioPlayback();
    });
  }

  void _startVisualizerAnimation() {
    _visualizerTimer?.cancel();
    _visualizerTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      if (!_isMixerPlaying) {
        timer.cancel();
        return;
      }
      setState(() {
        double totalVolumeWeight = 0.0;
        int activeCount = 0;
        for (var sound in _sounds) {
          if (_channelActive[sound['id']] == true) {
            totalVolumeWeight += _channelVolumes[sound['id']] ?? 0.5;
            activeCount++;
          }
        }
        final double volumeAvg = activeCount > 0
            ? (totalVolumeWeight / activeCount)
            : 0.0;
        final double maxWaveHeight = 8.0 + (volumeAvg * 34.0);
        for (var i = 0; i < _visualizerHeights.length; i++) {
          _visualizerHeights[i] = 3.0 + _random.nextDouble() * maxWaveHeight;
        }
      });
    });
  }

  // ===========================================================================
  // BREATHING COACH STATE MANAGER
  // ===========================================================================
  void _toggleBreathingCoach() {
    if (_isBreathingActive) {
      _stopBreathingCoach();
    } else {
      _startBreathingCoach();
    }
  }

  void _startBreathingCoach() {
    _stopBreathingCoach();
    final config = _breathingConfigs[_activeBreathingMode]!;
    final List<String> phases = config['phases'];
    final Map<String, int> durations = config['durations'];
    setState(() {
      _isBreathingActive = true;
      _breathingPhase = phases[0];
      _breathingSecondsRemaining = durations[_breathingPhase]!;
      _completedCycles = 0;
      _elapsedFraction = 0.0;
    });
    _logMeditationTelemetry('breathing_coach_start', {
      'mode': _activeBreathingMode,
    });

    _breathingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_breathingSecondsRemaining > 1) {
        setState(() {
          _breathingSecondsRemaining--;
        });
      } else {
        final currentPhaseIdx = phases.indexOf(_breathingPhase);
        String nextPhase;
        if (currentPhaseIdx < phases.length - 1) {
          nextPhase = phases[currentPhaseIdx + 1];
        } else {
          nextPhase = phases[0];
          setState(() {
            _completedCycles++;
          });
        }

        setState(() {
          _breathingPhase = nextPhase;
          _breathingSecondsRemaining = durations[nextPhase]!;
        });
      }
    });

    const int updatePeriodMs = 40;
    int elapsedTicks = 0;

    _bubbleSmoothTimer = Timer.periodic(
      Duration(milliseconds: updatePeriodMs),
      (timer) {
        if (!mounted || !_isBreathingActive) {
          timer.cancel();
          return;
        }

        final currentDuration = durations[_breathingPhase]!;
        elapsedTicks = (elapsedTicks + updatePeriodMs);
        final currentSecondsElapsed =
            currentDuration - _breathingSecondsRemaining;

        setState(() {
          final double ratio =
              (currentSecondsElapsed + (elapsedTicks % 1000) / 1000.0) /
              currentDuration;
          _elapsedFraction = ratio.clamp(0.0, 1.0);
          switch (_breathingPhase) {
            case 'inhale':
              _bubbleScale = 1.0 + (0.8 * _elapsedFraction);
              break;
            case 'hold':
              _bubbleScale =
                  1.8 +
                  sin(DateTime.now().millisecondsSinceEpoch / 250.0) * 0.03;
              break;
            case 'exhale':
              _bubbleScale = 1.8 - (0.8 * _elapsedFraction);
              break;
            case 'hold2':
              _bubbleScale =
                  1.0 +
                  sin(DateTime.now().millisecondsSinceEpoch / 250.0) * 0.01;
              break;
          }
        });
      },
    );
  }

  void _stopBreathingCoach() {
    _breathingTimer?.cancel();
    _bubbleSmoothTimer?.cancel();
    setState(() {
      _isBreathingActive = false;
      _bubbleScale = 1.0;
      _breathingPhase = 'inhale';
      _breathingSecondsRemaining = 0;
    });
  }

  // ===========================================================================
  // LAYOUT INTERFACE BUILDERS
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '律动呼吸与多声道白噪音',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF070514),
                        const Color(0xFF0F0B24),
                        const Color(0xFF030206),
                      ]
                    : [
                        primaryColor.withOpacity(0.06),
                        const Color(0xFFFAF9FF),
                        Colors.white,
                      ],
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
                _buildSegmentTabs(),
                const SizedBox(height: 20),
                if (_activeTab == 'breathing')
                  _buildBreathingTab()
                else
                  _buildMixerTab(),

                const SizedBox(height: 24),
                _buildSleepTimerPanel(),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentTabs() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.02)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 'breathing'),
              child: Container(
                decoration: BoxDecoration(
                  color: _activeTab == 'breathing'
                      ? primaryColor.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _activeTab == 'breathing'
                        ? primaryColor
                        : Colors.transparent,
                    width: 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.spa_rounded,
                      size: 16,
                      color: _activeTab == 'breathing'
                          ? primaryColor
                          : (isDark ? Colors.white54 : Colors.black45),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '呼吸律动冥想',
                      style: TextStyle(
                        color: _activeTab == 'breathing'
                            ? (isDark ? Colors.white : Colors.black87)
                            : (isDark ? Colors.white54 : Colors.black54),
                        fontSize: 12.5,
                        fontWeight: _activeTab == 'breathing'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 'mixer'),
              child: Container(
                decoration: BoxDecoration(
                  color: _activeTab == 'mixer'
                      ? secondaryColor.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _activeTab == 'mixer'
                        ? secondaryColor
                        : Colors.transparent,
                    width: 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.hearing_rounded,
                      size: 16,
                      color: _activeTab == 'mixer'
                          ? secondaryColor
                          : (isDark ? Colors.white54 : Colors.black45),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '声景多路混音',
                      style: TextStyle(
                        color: _activeTab == 'mixer'
                            ? (isDark ? Colors.white : Colors.black87)
                            : (isDark ? Colors.white54 : Colors.black54),
                        fontSize: 12.5,
                        fontWeight: _activeTab == 'mixer'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreathingTab() {
    final activeConfig = _breathingConfigs[_activeBreathingMode]!;
    final glowColor = activeConfig['glow'] as Color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NoiseBreathingBubble(
          isBreathingActive: _isBreathingActive,
          glowColor: glowColor,
          bubbleScale: _bubbleScale,
          elapsedFraction: _elapsedFraction,
          breathingSecondsRemaining: _breathingSecondsRemaining,
          completedCycles: _completedCycles,
          breathingPhase: _breathingPhase,
          onToggle: _toggleBreathingCoach,
        ),
        const SizedBox(height: 20),
        Text(
          '🧘 调息减压模式配置',
          style: TextStyle(
            color: isDark ? Colors.white : Theme.of(context).colorScheme.primary,
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Column(
          children: _breathingConfigs.entries.map((entry) {
            final key = entry.key;
            final config = entry.value;
            final isSelected = key == _activeBreathingMode;
            final modeColor = config['glow'] as Color;
            return GestureDetector(
              onTap: () {
                if (_isBreathingActive) {
                  _stopBreathingCoach();
                }
                setState(() {
                  _activeBreathingMode = key;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? modeColor.withOpacity(0.08)
                      : (isDark
                            ? Colors.white.withOpacity(0.015)
                            : Colors.black.withOpacity(0.02)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? modeColor.withOpacity(0.4)
                        : (isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.05)),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? modeColor.withOpacity(0.15)
                            : (isDark
                                  ? Colors.white.withOpacity(0.02)
                                  : Colors.black.withOpacity(0.03)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.insights_rounded,
                        color: isSelected ? modeColor : (isDark ? Colors.white30 : Colors.black38),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            config['name'],
                            style: TextStyle(
                              color: isSelected 
                                  ? (isDark ? Colors.white : modeColor)
                                  : textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            config['desc'],
                            style: TextStyle(
                              color: faintTextColor,
                              fontSize: 10,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMixerTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NoiseVisualizer(
          isMixerPlaying: _isMixerPlaying,
          visualizerHeights: _visualizerHeights,
          onToggleMixerPlay: _toggleMixerPlay,
        ),
        const SizedBox(height: 20),
        Text(
          '🎧 混音多声道列表 (自定义音量百分比)',
          style: TextStyle(
            color: isDark ? Colors.white : Theme.of(context).colorScheme.secondary,
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: _sounds.map((sound) {
            final id = sound['id'];
            return NoiseSoundCard(
              icon: sound['icon'],
              name: sound['name'],
              desc: sound['desc'],
              themeColor: sound['color'],
              isActive: _channelActive[id] ?? false,
              volume: _channelVolumes[id] ?? 0.5,
              onToggleActive: (_) => _toggleChannelActive(id),
              onVolumeChanged: (newVol) {
                setState(() {
                  _channelVolumes[id] = newVol;
                  _isMixerPlaying = true;
                  _startVisualizerAnimation();
                  // Dynamically set volume on active player instance
                  _players[id]?.setVolume(newVol).catchError((_) => null);
                  _syncAudioPlayback();
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSleepTimerPanel() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '💤 专注休眠倒计时停止器',
          style: TextStyle(
            color: isDark ? Colors.white : primaryColor,
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.02)
                : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.06),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '定时静音状态',
                    style: TextStyle(color: subTextColor, fontSize: 12),
                  ),
                  Text(
                    _formatSleepTimer(),
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
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
    );
  }

  Widget _buildTimeChip(int mins, String label, {bool isCancel = false}) {
    final bool isSelected = (_secondsRemaining ~/ 60 == mins) && !isCancel;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final color = isCancel ? Colors.redAccent : primaryColor;
    return GestureDetector(
      onTap: () => _setSleepTimer(mins),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.12)
              : (isDark
                    ? Colors.white.withOpacity(0.02)
                    : Colors.black.withOpacity(0.03)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color.withOpacity(0.5)
                : (isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.05)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (isDark ? Colors.white : color)
                : (isDark ? Colors.white54 : Colors.black54),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
