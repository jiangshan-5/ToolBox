import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:math';
import '../../../features/dashboard/provider/tools_provider.dart';
import '../../../core/widgets/glass_card.dart';

class WhiteNoiseScreen extends ConsumerStatefulWidget {
  const WhiteNoiseScreen({super.key});

  @override
  ConsumerState<WhiteNoiseScreen> createState() => _WhiteNoiseScreenState();
}

class _WhiteNoiseScreenState extends ConsumerState<WhiteNoiseScreen> with TickerProviderStateMixin {
  // Screen Tabs: 'breathing' vs 'mixer'
  String _activeTab = 'breathing';

  // ===========================================================================
  // 1. SOUNDSCAPE MIXER STATE
  // ===========================================================================
  final List<Map<String, dynamic>> _sounds = [
    {
      'id': 'rain',
      'emoji': '🌧️',
      'name': '深山秋雨',
      'desc': '幽静山谷中的淅沥雨声，抚平内心焦虑。',
      'color': Colors.blueAccent,
    },
    {
      'id': 'waves',
      'emoji': '🌊',
      'name': '极地海浪',
      'desc': '远古冰川海滩上的潮汐起落，回归静止。',
      'color': Colors.cyanAccent,
    },
    {
      'id': 'pines',
      'emoji': '🌲',
      'name': '林间松涛',
      'desc': '微风穿过广阔针叶林，带来原野芬芳。',
      'color': Colors.greenAccent,
    },
    {
      'id': 'fire',
      'emoji': '🔥',
      'name': '壁炉篝火',
      'desc': '深夜小木屋里温暖柴火的噼啪爆裂碎响。',
      'color': Colors.orangeAccent,
    },
    {
      'id': 'brook',
      'emoji': '🏞️',
      'name': '山间溪流',
      'desc': '高山融雪化作林间欢快奔腾的潺潺清泉。',
      'color': Colors.tealAccent,
    },
    {
      'id': 'insects',
      'emoji': '🦗',
      'name': '夏夜虫鸣',
      'desc': '繁星点点的仲夏夜里草丛间的自然协奏曲。',
      'color': Colors.amberAccent,
    },
  ];

  // Track volumes (0.0 to 1.0) and whether channel is toggled ON
  final Map<String, double> _channelVolumes = {};
  final Map<String, bool> _channelActive = {};
  bool _isMixerPlaying = false;

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

  @override
  void initState() {
    super.initState();
    // Initialize mixer volume map
    for (var sound in _sounds) {
      _channelVolumes[sound['id']] = 0.5; // default 50%
      _channelActive[sound['id']] = false;
    }
  }

  @override
  void dispose() {
    _visualizerTimer?.cancel();
    _breathingTimer?.cancel();
    _bubbleSmoothTimer?.cancel();
    _sleepTimer?.cancel();
    super.dispose();
  }

  // ===========================================================================
  // TELEMETRY LOGGING
  // ===========================================================================
  void _logMeditationTelemetry(String type, Map<String, dynamic> extras) {
    try {
      ref.read(toolsAnalyticsProvider).logUsage(
        toolKey: 'white_noise',
        parameters: {
          'action': type,
          ...extras,
        },
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

  void _triggerSleepFading() {
    _sleepTimer?.cancel();
    _stopBreathingCoach();
    
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
        backgroundColor: Color(0xFF0F0720),
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
        // Ensure at least one channel is active if none are
        final hasActive = _channelActive.values.any((isActive) => isActive);
        if (!hasActive) {
          _channelActive[_sounds[0]['id']] = true;
        }
        _startVisualizerAnimation();
        _logMeditationTelemetry('mixer_start', {
          'active_channels': _channelActive.entries.where((e) => e.value).map((e) => e.key).toList(),
        });
      } else {
        _visualizerTimer?.cancel();
      }
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
        // If all channels disabled, stop playing
        final hasActive = _channelActive.values.any((isActive) => isActive);
        if (!hasActive) {
          _isMixerPlaying = false;
          _visualizerTimer?.cancel();
        }
      }
    });
  }

  void _startVisualizerAnimation() {
    _visualizerTimer?.cancel();
    _visualizerTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isMixerPlaying) {
        timer.cancel();
        return;
      }
      setState(() {
        // Calculate dynamic height multipliers based on active sound volumes
        double totalVolumeWeight = 0.0;
        int activeCount = 0;
        for (var sound in _sounds) {
          if (_channelActive[sound['id']] == true) {
            totalVolumeWeight += _channelVolumes[sound['id']] ?? 0.5;
            activeCount++;
          }
        }
        final double volumeAvg = activeCount > 0 ? (totalVolumeWeight / activeCount) : 0.0;
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

    _logMeditationTelemetry('breathing_coach_start', {'mode': _activeBreathingMode});
    
    // Rhythmic interval state switcher
    _breathingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_breathingSecondsRemaining > 1) {
        setState(() {
          _breathingSecondsRemaining--;
        });
      } else {
        // Stage Complete, cycle to next state
        final currentPhaseIdx = phases.indexOf(_breathingPhase);
        String nextPhase;
        if (currentPhaseIdx < phases.length - 1) {
          nextPhase = phases[currentPhaseIdx + 1];
        } else {
          // Whole cycle finished!
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

    // High frequency micro-step timer for high-fidelity bubble scale animation
    const int updatePeriodMs = 40;
    int elapsedTicks = 0;
    
    _bubbleSmoothTimer = Timer.periodic(const Duration(milliseconds: updatePeriodMs), (timer) {
      if (!mounted || !_isBreathingActive) {
        timer.cancel();
        return;
      }
      
      final currentDuration = durations[_breathingPhase]!;
      elapsedTicks = (elapsedTicks + updatePeriodMs);
      
      // Keep track of fraction inside current phase
      final currentSecondsElapsed = currentDuration - _breathingSecondsRemaining;
      
      setState(() {
        // Base elapsed proportion
        final double ratio = (currentSecondsElapsed + (elapsedTicks % 1000) / 1000.0) / currentDuration;
        _elapsedFraction = ratio.clamp(0.0, 1.0);

        // Map phases to target sizes with custom curves
        switch (_breathingPhase) {
          case 'inhale':
            // Smoothly scale up from 1.0 to 1.8
            _bubbleScale = 1.0 + (0.8 * _elapsedFraction);
            break;
          case 'hold':
            // Pulsate gently around 1.8 using a tiny sine wave to express tension
            _bubbleScale = 1.8 + sin(DateTime.now().millisecondsSinceEpoch / 250.0) * 0.03;
            break;
          case 'exhale':
            // Smoothly scale down from 1.8 back to 1.0
            _bubbleScale = 1.8 - (0.8 * _elapsedFraction);
            break;
          case 'hold2':
            // Stays small at 1.0
            _bubbleScale = 1.0 + sin(DateTime.now().millisecondsSinceEpoch / 250.0) * 0.01;
            break;
        }
      });
    });
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
          '律动呼吸与多声道白噪音',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          // Cyberpunk dark mesh backdrop
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF070514), Color(0xFF0F0B24), Color(0xFF030206)],
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
                // 1. Sliding Segment Tab Buttons
                _buildSegmentTabs(),
                const SizedBox(height: 20),

                // 2. Active Tab Panel
                if (_activeTab == 'breathing')
                  _buildBreathingTab()
                else
                  _buildMixerTab(),
                
                const SizedBox(height: 24),

                // 3. Sleep Timer Panel (Always Visible at bottom to keep it synchronized)
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
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 'breathing'),
              child: Container(
                decoration: BoxDecoration(
                  color: _activeTab == 'breathing' 
                      ? Colors.purpleAccent.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _activeTab == 'breathing' ? Colors.purpleAccent : Colors.transparent,
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
                      color: _activeTab == 'breathing' ? Colors.purpleAccent : Colors.white54,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '呼吸律动冥想',
                      style: TextStyle(
                        color: _activeTab == 'breathing' ? Colors.white : Colors.white54,
                        fontSize: 12.5,
                        fontWeight: _activeTab == 'breathing' ? FontWeight.bold : FontWeight.normal,
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
                      ? Colors.cyanAccent.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _activeTab == 'mixer' ? Colors.cyanAccent : Colors.transparent,
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
                      color: _activeTab == 'mixer' ? Colors.cyanAccent : Colors.white54,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '声景多路混音',
                      style: TextStyle(
                        color: _activeTab == 'mixer' ? Colors.white : Colors.white54,
                        fontSize: 12.5,
                        fontWeight: _activeTab == 'mixer' ? FontWeight.bold : FontWeight.normal,
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

  // ===========================================================================
  // WIDGET BUILDER: BREATHING TAB
  // ===========================================================================
  Widget _buildBreathingTab() {
    final activeConfig = _breathingConfigs[_activeBreathingMode]!;
    final glowColor = activeConfig['glow'] as Color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Interactive color-shifting breathing coach bubble card
        GlassCard(
          glowColor: _isBreathingActive ? glowColor : Colors.white.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            child: Column(
              children: [
                Center(
                  child: SizedBox(
                    height: 220,
                    width: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Dynamic Ripple Halo effects
                        if (_isBreathingActive)
                          ...List.generate(2, (idx) {
                            final delayOffset = (idx + 1) / 3.0;
                            final currentScale = _bubbleScale + (delayOffset * 0.15);
                            return Transform.scale(
                              scale: currentScale.clamp(1.0, 2.5),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: glowColor.withOpacity((0.15 - (idx * 0.05)) * (1.0 - _elapsedFraction)),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            );
                          }),
                        
                        // Core Breathing Bubble
                        Transform.scale(
                          scale: _bubbleScale,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  _isBreathingActive ? glowColor.withOpacity(0.25) : Colors.white.withOpacity(0.02),
                                  _isBreathingActive ? glowColor.withOpacity(0.08) : Colors.white.withOpacity(0.005),
                                ],
                              ),
                              border: Border.all(
                                color: _isBreathingActive ? glowColor : Colors.white30,
                                width: _isBreathingActive ? 2.5 : 1.5,
                              ),
                              boxShadow: [
                                if (_isBreathingActive)
                                  BoxShadow(
                                    color: glowColor.withOpacity(0.35),
                                    blurRadius: 18,
                                    spreadRadius: 2,
                                  ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _getBreathingPhaseEmoji(),
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Real-time metadata indicators
                Text(
                  _getBreathingPhaseText(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isBreathingActive ? '当前周期倒计时：$_breathingSecondsRemaining 秒' : '选择模式开启科学吐纳',
                  style: const TextStyle(color: Colors.white38, fontSize: 11.5),
                ),
                if (_isBreathingActive && _completedCycles > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    '已成功调息：$_completedCycles 次循环',
                    style: TextStyle(color: glowColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
                const SizedBox(height: 20),

                // Primary Breath Switch Button
                GestureDetector(
                  onTap: _toggleBreathingCoach,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isBreathingActive
                            ? [Colors.redAccent, Colors.deepOrangeAccent]
                            : [glowColor.withOpacity(0.8), glowColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (_isBreathingActive ? Colors.redAccent : glowColor).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isBreathingActive ? Icons.pause_circle_filled_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isBreathingActive ? '停止呼吸向导' : '开始放松调息',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 2. Multi-Segment pill selection cards
        const Text(
          '🧘 调息减压模式配置',
          style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
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
                      : Colors.white.withOpacity(0.015),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? modeColor.withOpacity(0.4) : Colors.white.withOpacity(0.05),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isSelected ? modeColor.withOpacity(0.15) : Colors.white.withOpacity(0.02),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.insights_rounded,
                        color: isSelected ? modeColor : Colors.white30,
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
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            config['desc'],
                            style: const TextStyle(color: Colors.white38, fontSize: 10, height: 1.3),
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

  String _getBreathingPhaseEmoji() {
    if (!_isBreathingActive) return '🧘';
    switch (_breathingPhase) {
      case 'inhale':
        return '🌬️';
      case 'hold':
      case 'hold2':
        return '⚓';
      case 'exhale':
        return '💨';
      default:
        return '🧘';
    }
  }

  String _getBreathingPhaseText() {
    if (!_isBreathingActive) return '开始吸气放松调息';
    switch (_breathingPhase) {
      case 'inhale':
        return '💨 缓慢吸气...';
      case 'hold':
        return '🧘 屏住呼吸，专注静止...';
      case 'exhale':
        return '🌬️ 吐出焦虑，全身放松...';
      case 'hold2':
        return '🔒 保持空肺，安宁凝神...';
      default:
        return '平静放松中...';
    }
  }

  // ===========================================================================
  // WIDGET BUILDER: MIXER TAB
  // ===========================================================================
  Widget _buildMixerTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Neon Spectrum Visualizer Card
        GlassCard(
          glowColor: _isMixerPlaying ? Colors.cyanAccent : Colors.white.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                // visualizer row
                SizedBox(
                  height: 56,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _visualizerHeights.map((h) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width: 5,
                        height: _isMixerPlaying ? h : 4.0,
                        decoration: BoxDecoration(
                          color: _isMixerPlaying 
                              ? Colors.cyanAccent.withOpacity(0.8)
                              : Colors.white12,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            if (_isMixerPlaying)
                              BoxShadow(
                                color: Colors.cyanAccent.withOpacity(0.4),
                                blurRadius: 4,
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isMixerPlaying ? '大自然环绕声效混音中' : '声景播放已静音',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '支持开启多声道声效，混合出独属您的冥想空间',
                          style: TextStyle(color: Colors.white30, fontSize: 10),
                        ),
                      ],
                    ),
                    
                    // Mixer Master Toggle Button
                    IconButton(
                      iconSize: 42,
                      icon: Icon(
                        _isMixerPlaying ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
                        color: Colors.cyanAccent,
                      ),
                      onPressed: _toggleMixerPlay,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 2. Nature channels slider grid list
        const Text(
          '🎧 混音多声道列表 (自定义音量百分比)',
          style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Column(
          children: _sounds.map((sound) {
            final id = sound['id'];
            final isCurrentActive = _channelActive[id] ?? false;
            final double currentVal = _channelVolumes[id] ?? 0.5;
            final themeColor = sound['color'] as Color;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isCurrentActive
                    ? themeColor.withOpacity(0.04)
                    : Colors.white.withOpacity(0.015),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isCurrentActive ? themeColor.withOpacity(0.3) : Colors.white.withOpacity(0.04),
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isCurrentActive ? themeColor.withOpacity(0.12) : Colors.white.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(sound['emoji'], style: const TextStyle(fontSize: 20)),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sound['name'],
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                sound['desc'],
                                style: const TextStyle(color: Colors.white38, fontSize: 9.5),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Toggle Switch
                      Switch(
                        activeThumbColor: themeColor,
                        activeTrackColor: themeColor.withOpacity(0.2),
                        inactiveThumbColor: Colors.white30,
                        inactiveTrackColor: Colors.white10,
                        value: isCurrentActive,
                        onChanged: (_) => _toggleChannelActive(id),
                      ),
                    ],
                  ),
                  
                  // volume slider
                  if (isCurrentActive) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.volume_down_rounded, color: Colors.white30, size: 14),
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: themeColor,
                              inactiveTrackColor: Colors.white10,
                              thumbColor: Colors.white,
                              overlayColor: themeColor.withOpacity(0.1),
                              trackHeight: 2.5,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            ),
                            child: Slider(
                              value: currentVal,
                              onChanged: (newVol) {
                                setState(() {
                                  _channelVolumes[id] = newVol;
                                  _isMixerPlaying = true;
                                  _startVisualizerAnimation();
                                });
                              },
                            ),
                          ),
                        ),
                        Text(
                          '${(currentVal * 100).toInt()}%',
                          style: TextStyle(color: themeColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ===========================================================================
  // WIDGET BUILDER: SLEEP TIMER PANEL
  // ===========================================================================
  Widget _buildSleepTimerPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💤 专注休眠倒计时停止器',
          style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('定时静音状态', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  Text(
                    _formatSleepTimer(),
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
    );
  }

  Widget _buildTimeChip(int mins, String label, {bool isCancel = false}) {
    final bool isSelected = (_secondsRemaining ~/ 60 == mins) && !isCancel;
    final color = isCancel ? Colors.redAccent : Colors.purpleAccent;

    return GestureDetector(
      onTap: () => _setSleepTimer(mins),
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
