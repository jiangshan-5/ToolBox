import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../provider/novel_provider.dart';

class ReaderSettingsPanel extends ConsumerStatefulWidget {
  final double bottomOffset;
  final NovelState state;
  final double fontSize;
  final double lineHeight;
  final bool isSerif;
  final double dimmerOpacity;
  final bool isPageViewMode;
  final double autoScrollSpeed;
  final bool isAutoScrolling;
  final int activeThemeIndex;
  final List<List<dynamic>> themes;
  final Color themeBg;
  final Color themeText;

  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<double> onLineHeightChanged;
  final ValueChanged<bool> onSerifChanged;
  final ValueChanged<double> onDimmerOpacityChanged;
  final ValueChanged<bool> onPageViewModeChanged;
  final ValueChanged<double> onAutoScrollSpeedChanged;
  final ValueChanged<bool> onAutoScrollingChanged;
  final ValueChanged<int> onThemeIndexChanged;

  final VoidCallback onShowTocDrawer;
  final VoidCallback onShowAnnotationsSheet;

  const ReaderSettingsPanel({
    super.key,
    required this.bottomOffset,
    required this.state,
    required this.fontSize,
    required this.lineHeight,
    required this.isSerif,
    required this.dimmerOpacity,
    required this.isPageViewMode,
    required this.autoScrollSpeed,
    required this.isAutoScrolling,
    required this.activeThemeIndex,
    required this.themes,
    required this.themeBg,
    required this.themeText,
    required this.onFontSizeChanged,
    required this.onLineHeightChanged,
    required this.onSerifChanged,
    required this.onDimmerOpacityChanged,
    required this.onPageViewModeChanged,
    required this.onAutoScrollSpeedChanged,
    required this.onAutoScrollingChanged,
    required this.onThemeIndexChanged,
    required this.onShowTocDrawer,
    required this.onShowAnnotationsSheet,
  });

  @override
  ConsumerState<ReaderSettingsPanel> createState() => _ReaderSettingsPanelState();
}

class _ReaderSettingsPanelState extends ConsumerState<ReaderSettingsPanel> {
  int _activeTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaceColor = theme.colorScheme.surface;
    final onSurfaceColor = theme.colorScheme.onSurface;
    final primaryColor = theme.colorScheme.primary;

    return Positioned(
      bottom: widget.bottomOffset,
      left: 0,
      right: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: surfaceColor.withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: onSurfaceColor.withOpacity(0.08)),
            ),
            child: SafeArea(
              top: false,
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tab selector header
                  Row(
                    children: [
                      Expanded(child: _buildTabButton(0, '阅读排版', primaryColor, onSurfaceColor)),
                      Expanded(child: _buildTabButton(1, '听书声景', primaryColor, onSurfaceColor)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Tab content
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: _activeTabIndex == 0 
                        ? _buildLayoutTab(primaryColor, onSurfaceColor) 
                        : _buildSoundTab(primaryColor, onSurfaceColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String title, Color primaryColor, Color onSurfaceColor) {
    final isSelected = _activeTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTabIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? primaryColor : onSurfaceColor.withOpacity(0.6),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLayoutTab(Color primaryColor, Color onSurfaceColor) {
    // Increase thumb size & track height for better mobile touch controls
    final sliderThemeData = SliderThemeData(
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
      activeTrackColor: primaryColor,
      inactiveTrackColor: onSurfaceColor.withOpacity(0.12),
      thumbColor: primaryColor,
    );

    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Section 1: 视觉与排版调节 (Visual & Typography adjustments)
            _buildSection(
              title: '基础排版调节',
              icon: Icons.tune_rounded,
              primaryColor: primaryColor,
              onSurfaceColor: onSurfaceColor,
              children: [
                // 1. Font size slider
                Row(
                  children: [
                    Icon(Icons.text_fields_rounded, color: onSurfaceColor.withOpacity(0.54), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: sliderThemeData,
                        child: Slider(
                          value: widget.fontSize,
                          min: 14.0,
                          max: 28.0,
                          onChanged: widget.onFontSizeChanged,
                        ),
                      ),
                    ),
                    Text(
                      '${widget.fontSize.toInt()} px',
                      style: TextStyle(color: onSurfaceColor.withOpacity(0.7), fontSize: 11, fontFamily: 'monospace'),
                    ),
                  ],
                ),
                const SizedBox(height: 16), // Generous spacing for touch usability
                // 2. Line height slider
                Row(
                  children: [
                    Icon(Icons.format_line_spacing_rounded, color: onSurfaceColor.withOpacity(0.54), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: sliderThemeData,
                        child: Slider(
                          value: widget.lineHeight,
                          min: 1.2,
                          max: 2.2,
                          onChanged: widget.onLineHeightChanged,
                        ),
                      ),
                    ),
                    Text(
                      '行高 ${widget.lineHeight.toStringAsFixed(1)}',
                      style: TextStyle(color: onSurfaceColor.withOpacity(0.7), fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 16), // Generous spacing for touch usability
                // 3. Brightness Dimmer Slider (REVERSED: right is brighter!)
                Row(
                  children: [
                    Icon(Icons.brightness_medium_rounded, color: onSurfaceColor.withOpacity(0.54), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: sliderThemeData,
                        child: Slider(
                          value: (1.0 - widget.dimmerOpacity).clamp(0.15, 1.0),
                          min: 0.15,
                          max: 1.0,
                          onChanged: (val) {
                            widget.onDimmerOpacityChanged(1.0 - val);
                          },
                        ),
                      ),
                    ),
                    Text(
                      '亮度 ${((1.0 - widget.dimmerOpacity) * 100).toInt()}%',
                      style: TextStyle(color: onSurfaceColor.withOpacity(0.7), fontSize: 11, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ],
            ),

            // Section 2: 翻页与滚屏 (Paging & Scroll Modes)
            _buildSection(
              title: '翻页与滚屏设置',
              icon: Icons.swap_calls_rounded,
              primaryColor: primaryColor,
              onSurfaceColor: onSurfaceColor,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('翻页模式', style: TextStyle(color: onSurfaceColor.withOpacity(0.7), fontSize: 12)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => widget.onPageViewModeChanged(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: !widget.isPageViewMode ? primaryColor : onSurfaceColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '纵向滚动',
                              style: TextStyle(
                                color: !widget.isPageViewMode ? Colors.white : onSurfaceColor.withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => widget.onPageViewModeChanged(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: widget.isPageViewMode ? primaryColor : onSurfaceColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '左右翻页',
                              style: TextStyle(
                                color: widget.isPageViewMode ? Colors.white : onSurfaceColor.withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (!widget.isPageViewMode) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text('自动滚屏', style: TextStyle(color: onSurfaceColor.withOpacity(0.7), fontSize: 12)),
                      const Spacer(),
                      PopupMenuButton<double>(
                        initialValue: widget.autoScrollSpeed,
                        onSelected: widget.onAutoScrollSpeedChanged,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: onSurfaceColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '滚屏速度 ${widget.autoScrollSpeed.toInt()}级',
                            style: TextStyle(color: onSurfaceColor.withOpacity(0.7), fontSize: 11),
                          ),
                        ),
                        itemBuilder: (context) => [1.0, 2.0, 3.0, 4.0, 5.0]
                            .map((s) => PopupMenuItem(value: s, child: Text('${s.toInt()} 级')))
                            .toList(),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 30,
                        child: Switch(
                          value: widget.isAutoScrolling,
                          activeColor: primaryColor,
                          activeTrackColor: primaryColor.withOpacity(0.5),
                          inactiveThumbColor: onSurfaceColor.withOpacity(0.4),
                          inactiveTrackColor: onSurfaceColor.withOpacity(0.12),
                          onChanged: widget.onAutoScrollingChanged,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),

            // Section 3: 主题与字体 (Themes & Typography)
            _buildSection(
              title: '阅读背景与字体',
              icon: Icons.palette_rounded,
              primaryColor: primaryColor,
              onSurfaceColor: onSurfaceColor,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('选用仿宋/Georgia', style: TextStyle(color: onSurfaceColor.withOpacity(0.7), fontSize: 12)),
                    SizedBox(
                      height: 30,
                      child: Switch(
                        value: widget.isSerif,
                        activeColor: primaryColor,
                        activeTrackColor: primaryColor.withOpacity(0.5),
                        inactiveThumbColor: onSurfaceColor.withOpacity(0.4),
                        inactiveTrackColor: onSurfaceColor.withOpacity(0.12),
                        onChanged: widget.onSerifChanged,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 32,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: widget.themes.length,
                    itemBuilder: (context, idx) {
                      final th = widget.themes[idx];
                      final Color bg = th[0];
                      final String name = th[2];
                      final isSel = idx == widget.activeThemeIndex;

                      return GestureDetector(
                        onTap: () => widget.onThemeIndexChanged(idx),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSel ? primaryColor : onSurfaceColor.withOpacity(0.1),
                              width: isSel ? 2 : 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            name,
                            style: TextStyle(
                              color: th[1],
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundTab(Color primaryColor, Color onSurfaceColor) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Section 1: TTS 播报控制 (AI Read Aloud)
            _buildSection(
              title: 'AI 极净听书',
              icon: Icons.record_voice_over_rounded,
              primaryColor: primaryColor,
              onSurfaceColor: onSurfaceColor,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        widget.state.isTtsPlaying 
                            ? Icons.pause_circle_filled_rounded 
                            : Icons.play_circle_filled_rounded,
                        size: 32,
                        color: Colors.amberAccent,
                      ),
                      onPressed: () {
                        if (widget.state.isTtsPlaying) {
                          ref.read(novelProvider.notifier).pauseTts();
                        } else {
                          ref.read(novelProvider.notifier).startTts();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.state.isTtsPlaying ? '播放中' : '已暂停',
                      style: TextStyle(color: onSurfaceColor.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    // Speed adjuster
                    PopupMenuButton<double>(
                      initialValue: widget.state.ttsSpeed,
                      onSelected: (speed) {
                        ref.read(novelProvider.notifier).setTtsSpeed(speed);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: onSurfaceColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '语速 ${widget.state.ttsSpeed}x',
                          style: TextStyle(color: onSurfaceColor.withOpacity(0.7), fontSize: 11),
                        ),
                      ),
                      itemBuilder: (context) => [0.8, 1.0, 1.2, 1.5, 1.8, 2.0]
                          .map((s) => PopupMenuItem(value: s, child: Text('${s}x')))
                          .toList(),
                    ),
                    const SizedBox(width: 8),
                    // Sleep Timer Adjuster
                    PopupMenuButton<int?>(
                      initialValue: widget.state.ttsTimerMinutes,
                      onSelected: (minutes) {
                        ref.read(novelProvider.notifier).setTtsTimer(minutes);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: onSurfaceColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.state.ttsTimerMinutes == null 
                              ? '定时关闭' 
                              : '${widget.state.ttsTimeRemainingSeconds ~/ 60}m',
                          style: TextStyle(color: onSurfaceColor.withOpacity(0.7), fontSize: 11),
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
              ],
            ),

            // Section 2: 背景声景混音 (Ambient mixers)
            _buildSection(
              title: '背景声景混音 (智能避让)',
              icon: Icons.music_note_rounded,
              primaryColor: primaryColor,
              onSurfaceColor: onSurfaceColor,
              children: [
                Row(
                  children: [
                    Text(
                      '背景声景混音 (Ducking 智能避让)',
                      style: TextStyle(color: onSurfaceColor.withOpacity(0.6), fontSize: 11),
                    ),
                    if (widget.state.isTtsPlaying) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '避让中 -35%',
                          style: TextStyle(color: Colors.cyanAccent, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                _buildAmbientMixerList(onSurfaceColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmbientMixerList(Color onSurfaceColor) {
    final ambientSounds = [
      {'id': 'rain', 'name': '幽谷秋雨', 'icon': Icons.umbrella_rounded, 'color': Colors.blueAccent},
      {'id': 'waves', 'name': '极地海浪', 'icon': Icons.waves_rounded, 'color': Colors.cyanAccent},
      {'id': 'fire', 'name': '壁炉柴火', 'icon': Icons.local_fire_department_rounded, 'color': Colors.orangeAccent},
    ];

    final ambientSliderTheme = SliderThemeData(
      trackHeight: 3,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
    );

    return Column(
      children: ambientSounds.map((sound) {
        final id = sound['id'] as String;
        final name = sound['name'] as String;
        final icon = sound['icon'] as IconData;
        final color = sound['color'] as Color;
        
        final isActive = widget.state.ambientActive[id] ?? false;
        final volume = widget.state.ambientVolumes[id] ?? 0.5;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  ref.read(novelProvider.notifier).toggleAmbient(id);
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isActive ? color.withOpacity(0.2) : onSurfaceColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive ? color : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: isActive ? color : onSurfaceColor.withOpacity(0.38), size: 12),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                name, 
                style: TextStyle(color: onSurfaceColor.withOpacity(0.7), fontSize: 11),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SliderTheme(
                  data: ambientSliderTheme.copyWith(
                    activeTrackColor: color.withOpacity(0.8),
                    inactiveTrackColor: onSurfaceColor.withOpacity(0.12),
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
                style: TextStyle(color: onSurfaceColor.withOpacity(0.38), fontSize: 10, fontFamily: 'monospace'),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required Color primaryColor,
    required Color onSurfaceColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: onSurfaceColor.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: onSurfaceColor.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: onSurfaceColor.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
