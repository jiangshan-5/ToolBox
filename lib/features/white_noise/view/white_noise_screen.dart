import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:async';

import 'dart:math';
import 'dart:convert';

import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';

import '../../auth/provider/auth_provider.dart';
import '../../../features/dashboard/provider/tools_provider.dart';
import '../../../../core/storage/local_storage.dart';

import 'widgets/noise_breathing_bubble.dart';
import 'widgets/noise_visualizer.dart';
import 'widgets/noise_sound_card.dart';
import 'widgets/noise_local_sound_card.dart';
import 'widgets/noise_default_sounds.dart';
import 'widgets/noise_breathing_configs.dart';

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

  // Scroll controller and pagination for lazy loading
  late final ScrollController _scrollController = ScrollController();
  int _displayedCount = 15;
  double _systemVolume = 0.5;
  bool _isDraggingVolume = false;
  Timer? _dragEndTimer;

  // ===========================================================================
  // 1. SOUNDSCAPE MIXER STATE
  // ===========================================================================
  // Separate list states
  List<Map<String, dynamic>> _remoteSounds = [];
  List<Map<String, dynamic>> _localSounds = [];
  bool _isLazyLoading = false;

  // Track volumes (0.0 to 1.0) and whether channel is toggled ON
  final Map<String, double> _channelVolumes = {};
  final Map<String, bool> _channelActive = {};
  bool _isMixerPlaying = false;

  // Track AudioPlayers for each channel
  final Map<String, AudioPlayer> _players = {};


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

  // Cumulative parameters
  int _completedCycles = 0;
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

        if (!_channelVolumes.containsKey(id)) {
          _channelVolumes[id] = 0.5;
          _channelActive[id] = false;
        } else {
          final existingSound = _remoteSounds.firstWhere((s) => s['id'] == id, orElse: () => {});
          if (existingSound.isNotEmpty && existingSound['url'] != fullUrl) {
            final player = _players[id];
            if (player != null) {
              player.setUrl(fullUrl).catchError((_) => null);
            }
          }
        }
      }

      final List<String> toRemove = [];
      for (var id in _channelVolumes.keys.toList()) {
        if (!activeIds.contains(id) && !_localSounds.any((s) => s['id'] == id)) {
          final player = _players.remove(id);
          if (player != null) {
            player.stop().catchError((_) => null);
            player.dispose().catchError((_) => null);
          }
          toRemove.add(id);
        }
      }
      for (var id in toRemove) {
        _channelVolumes.remove(id);
        _channelActive.remove(id);
      }

      if (mounted) {
        setState(() {
          _remoteSounds = newSounds;
        });
      }
    } catch (e) {
      debugPrint("Failed to load remote white noise tracks: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    final apiClient = ref.read(apiClientProvider);
    final apiBaseUrl = apiClient.instance.options.baseUrl;

    // Copy default sounds to remote sounds initially, resolving the backend URLs
    _remoteSounds = defaultWhiteNoiseSounds.map((sound) {
      final String originalUrl = sound['url'] as String;
      final String fullUrl = _resolveAudioUrl(originalUrl, apiBaseUrl);
      return {
        ...sound,
        'url': fullUrl,
      };
    }).toList();

    _displayedCount = 10; // Set initial paging count to 10 for true lazy loading

    // Initialize mixer volume map
    for (var sound in _remoteSounds) {
      final id = sound['id'] as String;
      _channelVolumes[id] = 0.5; // default 50%
      _channelActive[id] = false;
    }
    _loadLocalTracks();
    _loadRemoteTracks();
    _scrollController.addListener(_scrollListener);
    _initSystemVolume();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _breathingTimer?.cancel();
    _sleepTimer?.cancel();
    _dragEndTimer?.cancel();
    FlutterVolumeController.removeListener();
    // Teardown all active players to prevent audio leaks
    for (var player in _players.values) {
      player.stop().catchError((_) => null);
      player.dispose().catchError((_) => null);
    }
    super.dispose();
  }

  void _scrollListener() {
    if (_activeTab != 'mixer') return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLazyLoading && _displayedCount < _remoteSounds.length) {
        setState(() {
          _isLazyLoading = true;
        });
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            setState(() {
              _displayedCount = min(_displayedCount + 10, _remoteSounds.length);
              _isLazyLoading = false;
            });
          }
        });
      }
    }
  }

  Future<void> _initSystemVolume() async {
    try {
      await FlutterVolumeController.setAndroidAudioStream(stream: AudioStream.music);
      final vol = await FlutterVolumeController.getVolume(stream: AudioStream.music);
      if (vol != null && mounted) {
        setState(() {
          _systemVolume = vol;
          for (var key in _channelVolumes.keys) {
            _channelVolumes[key] = vol;
          }
        });
      }
    } catch (e) {
      debugPrint("Error initializing system volume: $e");
    }

    FlutterVolumeController.addListener((volume) {
      if (mounted && !_isDraggingVolume) {
        setState(() {
          _systemVolume = volume;
          for (var key in _channelVolumes.keys) {
            _channelVolumes[key] = volume;
          }
        });
      }
    });
  }

  Future<void> _importLocalAudioSource() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      if (result == null || result.files.single.path == null) {
        return;
      }
      final filePath = result.files.single.path!;
      final originalFileName = result.files.single.name;
      
      String defaultName = originalFileName;
      final dotIndex = defaultName.lastIndexOf('.');
      if (dotIndex != -1) {
        defaultName = defaultName.substring(0, dotIndex);
      }
      
      if (!mounted) return;
      
      final String? customName = await _showImportNameDialog(defaultName);
      if (customName == null || customName.trim().isEmpty) {
        return;
      }
      
      final String finalName = customName.trim();
      final String newId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      
      final newTrack = {
        'id': newId,
        'icon': Icons.audiotrack_rounded,
        'name': finalName,
        'desc': '本地导入: $originalFileName',
        'color': Colors.purpleAccent,
        'url': filePath,
        'is_local': true,
      };
      
      setState(() {
        _localSounds.insert(0, newTrack);
        _channelVolumes[newId] = 0.5;
        _channelActive[newId] = false;
      });
      
      await _saveLocalTracks();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎵 成功导入本地音源: $finalName'),
            backgroundColor: Colors.purple.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error picking/importing file: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 导入失败: $e'),
            backgroundColor: Colors.redAccent.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<String?> _showImportNameDialog(String defaultName) async {
    final TextEditingController textController = TextEditingController(text: defaultName);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0F0B24) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark ? Colors.purpleAccent.withOpacity(0.2) : Colors.black12,
              width: 1,
            ),
          ),
          title: Row(
            children: [
              Icon(Icons.drive_file_rename_outline_rounded, color: isDark ? Colors.purpleAccent : Colors.purple),
              const SizedBox(width: 10),
              Text(
                '命名您的本地音源',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '请为导入的音频设置一个便于识别的名字：',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                autofocus: true,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                decoration: InputDecoration(
                  hintText: '输入音源名称',
                  hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38),
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.black12,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.purpleAccent : Colors.purple,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(
                '取消',
                style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, textController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.purpleAccent.withOpacity(0.2) : Colors.purple.withOpacity(0.1),
                foregroundColor: isDark ? Colors.purpleAccent : Colors.purple,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteLocalTrack(String id) async {
    final track = _localSounds.firstWhere((s) => s['id'] == id, orElse: () => {});
    if (track.isEmpty) return;

    final player = _players.remove(id);
    if (player != null) {
      await player.stop().catchError((_) => null);
      await player.dispose().catchError((_) => null);
    }

    setState(() {
      _localSounds.removeWhere((s) => s['id'] == id);
      _channelActive.remove(id);
      _channelVolumes.remove(id);
      
      final hasActive = _channelActive.values.any((isActive) => isActive);
      if (!hasActive) {
        _isMixerPlaying = false;
      }
    });

    await _saveLocalTracks();
    _syncAudioPlayback();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🗑️ 已删除本地音源: ${track['name']}'),
          backgroundColor: Colors.redAccent.withOpacity(0.8),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveLocalTracks() async {
    try {
      final List<String> listJson = _localSounds.map((t) {
        return jsonEncode({
          'id': t['id'],
          'name': t['name'],
          'desc': t['desc'],
          'url': t['url'],
          'is_local': true,
        });
      }).toList();
      await ref.read(localStorageServiceProvider).setStringList('user_imported_white_noise_tracks', listJson);
    } catch (e) {
      debugPrint("Error saving local tracks: $e");
    }
  }

  void _loadLocalTracks() {
    try {
      final listJson = ref.read(localStorageServiceProvider).getStringList('user_imported_white_noise_tracks');
      if (listJson != null && listJson.isNotEmpty) {
        final List<Map<String, dynamic>> loaded = [];
        for (var str in listJson) {
          try {
            final map = jsonDecode(str) as Map<String, dynamic>;
            loaded.add({
              'id': map['id'],
              'icon': Icons.audiotrack_rounded,
              'name': map['name'],
              'desc': map['desc'],
              'color': Colors.purpleAccent,
              'url': map['url'],
              'is_local': true,
            });
          } catch (e) {
            debugPrint("Error decoding local track: $e");
          }
        }
        if (loaded.isNotEmpty) {
          setState(() {
            _localSounds = loaded;
            
            for (var track in loaded) {
              final id = track['id'];
              if (!_channelVolumes.containsKey(id)) {
                _channelVolumes[id] = 0.5;
                _channelActive[id] = false;
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading local tracks: $e");
    }
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
    final allSounds = [..._localSounds, ..._remoteSounds];
    for (var sound in allSounds) {
      final id = sound['id'] as String;
      final url = sound['url'] as String;
      final isActive = _channelActive[id] == true;

      if (isActive) {
        var player = _players[id];
        if (player == null) {
          player = AudioPlayer();
          _players[id] = player;
          player.setLoopMode(LoopMode.one).catchError((_) => null);
          player.setVolume(1.0).catchError((_) => null);
          
          Future<void> loadFuture;
          if (sound['is_local'] == true) {
            loadFuture = player.setFilePath(url);
          } else {
            loadFuture = player.setUrl(url);
          }
          
          loadFuture.then((_) {
            if (_isMixerPlaying && (_channelActive[id] == true)) {
              _players[id]?.play().catchError((_) => null);
            }
          }).catchError((e) {
            debugPrint("Error loading audio $id: $e");
          });
        } else {
          player.setVolume(1.0).catchError((_) => null);
          if (_isMixerPlaying) {
            if (!player.playing) {
              player.play().catchError((_) => null);
            }
          } else {
            if (player.playing) {
              player.pause().catchError((_) => null);
            }
          }
        }
      } else {
        final player = _players.remove(id);
        if (player != null) {
          player.stop().catchError((_) => null);
          player.dispose().catchError((_) => null);
        }
      }
    }
  }

  void _triggerSleepFading() {
    _sleepTimer?.cancel();
    _stopBreathingCoach();

    if (!mounted) return;

    // Smoothly silence channels
    setState(() {
      _isMixerPlaying = false;
      for (var key in _channelActive.keys) {
        _channelActive[key] = false;
      }
      _secondsRemaining = 0;
    });
    _syncAudioPlayback();
    
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
          final firstId = _remoteSounds.isNotEmpty ? _remoteSounds[0]['id'] : defaultWhiteNoiseSounds[0]['id'];
          _channelActive[firstId] = true;
        }
        _logMeditationTelemetry('mixer_start', {
          'active_channels': _channelActive.entries
              .where((e) => e.value)
              .map((e) => e.key)
              .toList(),
        });
      }
      _syncAudioPlayback();
    });
  }

  void _toggleChannelActive(String id) {
    setState(() {
      _channelActive[id] = !(_channelActive[id] ?? false);
      if (_channelActive[id] == true) {
        _isMixerPlaying = true;
        _logMeditationTelemetry('channel_enable', {'channel_id': id});
      } else {
        final hasActive = _channelActive.values.any((isActive) => isActive);
        if (!hasActive) {
          _isMixerPlaying = false;
        }
      }
      _syncAudioPlayback();
    });
  }

  double _getMaxWaveHeight() {
    double totalVolumeWeight = 0.0;
    int activeCount = 0;
    final allSounds = [..._localSounds, ..._remoteSounds];
    for (var sound in allSounds) {
      if (_channelActive[sound['id']] == true) {
        totalVolumeWeight += _channelVolumes[sound['id']] ?? 0.5;
        activeCount++;
      }
    }
    final double volumeAvg = activeCount > 0
        ? (totalVolumeWeight / activeCount)
        : 0.0;
    return 8.0 + (volumeAvg * 34.0);
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
    final config = breathingConfigs[_activeBreathingMode]!;
    final List<String> phases = config['phases'];
    final Map<String, int> durations = config['durations'];
    setState(() {
      _isBreathingActive = true;
      _breathingPhase = phases[0];
      _breathingSecondsRemaining = durations[_breathingPhase]!;
      _completedCycles = 0;
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
  }

  void _stopBreathingCoach() {
    _breathingTimer?.cancel();
    setState(() {
      _isBreathingActive = false;
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
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: GestureDetector(
                onTap: _importLocalAudioSource,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.purpleAccent : Colors.purple).withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (isDark ? Colors.purpleAccent : Colors.purple).withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.add_to_photos_rounded,
                    size: 16,
                    color: isDark ? Colors.purpleAccent : Colors.purple,
                  ),
                ),
              ),
            ),
          ),
        ],
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
              controller: _scrollController,
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
    final activeConfig = breathingConfigs[_activeBreathingMode]!;
    final glowColor = activeConfig['glow'] as Color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NoiseBreathingBubble(
          isBreathingActive: _isBreathingActive,
          glowColor: glowColor,
          breathingSecondsRemaining: _breathingSecondsRemaining,
          completedCycles: _completedCycles,
          breathingPhase: _breathingPhase,
          onToggle: _toggleBreathingCoach,
          phaseDuration: activeConfig['durations'][_breathingPhase] ?? 4,
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
          children: breathingConfigs.entries.map((entry) {
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
          maxWaveHeight: _getMaxWaveHeight(),
          onToggleMixerPlay: _toggleMixerPlay,
        ),
        const SizedBox(height: 20),
        _buildLocalSoundsSection(),
        const SizedBox(height: 24),
        _buildSystemSoundsSection(),
      ],
    );
  }

  Widget _buildLocalSoundsSection() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '📥 我的导入 (${_localSounds.length})',
              style: TextStyle(
                color: isDark ? Colors.purpleAccent : primaryColor,
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_localSounds.isNotEmpty)
              Text(
                '点击开关，点击 × 删除',
                style: TextStyle(
                  color: faintTextColor,
                  fontSize: 10,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (_localSounds.isEmpty)
          GestureDetector(
            onTap: _importLocalAudioSource,
            child: Container(
              height: 76,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.015)
                    : Colors.black.withOpacity(0.015),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.purpleAccent.withOpacity(0.15)
                      : Colors.purple.withOpacity(0.15),
                  width: 1.2,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_to_photos_rounded,
                      color: isDark ? Colors.purpleAccent : primaryColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '暂无导入音源，可点击此处快速导入本地音频',
                      style: TextStyle(
                        color: faintTextColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 96,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _localSounds.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final sound = _localSounds[index];
                final id = sound['id'];
                return NoiseLocalSoundCard(
                  name: sound['name'],
                  isActive: _channelActive[id] ?? false,
                  themeColor: sound['color'] ?? Colors.purpleAccent,
                  onTap: () => _toggleChannelActive(id),
                  onDelete: () => _deleteLocalTrack(id),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSystemSoundsSection() {
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🎧 预设白噪音环境音 (滑动按需加载)',
          style: TextStyle(
            color: isDark ? Colors.white : secondaryColor,
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: _remoteSounds.take(_displayedCount).map((sound) {
            final id = sound['id'];
            return NoiseSoundCard(
              icon: sound['icon'],
              name: sound['name'],
              desc: sound['desc'],
              themeColor: sound['color'],
              isActive: _channelActive[id] ?? false,
              volume: _systemVolume,
              isLocal: sound['is_local'] == true,
              onDelete: () => _deleteLocalTrack(id),
              onToggleActive: (_) => _toggleChannelActive(id),
              onVolumeChangeStart: () {
                _dragEndTimer?.cancel();
                _isDraggingVolume = true;
              },
              onVolumeChangeEnd: (newVol) {
                _dragEndTimer?.cancel();
                _dragEndTimer = Timer(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    setState(() {
                      _isDraggingVolume = false;
                    });
                  }
                });
              },
              onVolumeChanged: (newVol) {
                setState(() {
                  _systemVolume = newVol;
                  for (var key in _channelVolumes.keys) {
                    _channelVolumes[key] = newVol;
                  }
                  _isMixerPlaying = true;
                });
                FlutterVolumeController.setVolume(newVol, stream: AudioStream.music).catchError((_) => null);
              },
            );
          }).toList(),
        ),
        if (_isLazyLoading) ...[
          const SizedBox(height: 20),
          const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.purpleAccent),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ] else if (_remoteSounds.length > _displayedCount) ...[
          const SizedBox(height: 12),
          Center(
            child: Text(
              '已加载 $_displayedCount / ${_remoteSounds.length} 个环境声景 (继续下滑加载更多)',
              style: TextStyle(
                color: faintTextColor,
                fontSize: 11,
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 12),
          Center(
            child: Text(
              '已显示全部 ${_remoteSounds.length} 个环境声景',
              style: TextStyle(
                color: faintTextColor,
                fontSize: 11,
              ),
            ),
          ),
        ],
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
