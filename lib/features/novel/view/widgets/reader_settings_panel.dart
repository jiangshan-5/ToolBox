import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../provider/novel_provider.dart';

class ReaderSettingsPanel extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F0C29).withOpacity(0.85),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Font size slider
                  Row(
                    children: [
                      const Icon(Icons.text_fields_rounded, color: Colors.white54, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: fontSize,
                          min: 14.0,
                          max: 28.0,
                          activeColor: Colors.pinkAccent,
                          inactiveColor: Colors.white12,
                          onChanged: onFontSizeChanged,
                        ),
                      ),
                      Text(
                        '${fontSize.toInt()} px',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  // 1.5 Line height slider
                  Row(
                    children: [
                      const Icon(Icons.format_line_spacing_rounded, color: Colors.white54, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: lineHeight,
                          min: 1.2,
                          max: 2.2,
                          activeColor: Colors.pinkAccent,
                          inactiveColor: Colors.white12,
                          onChanged: onLineHeightChanged,
                        ),
                      ),
                      Text(
                        '行高 ${lineHeight.toStringAsFixed(1)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  // 2. Serif switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('选用仿宋/Georgia', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Switch(
                        value: isSerif,
                        activeColor: Colors.pinkAccent,
                        onChanged: onSerifChanged,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 2.5 Brightness Dimmer Slider
                  Row(
                    children: [
                      const Icon(Icons.brightness_medium_rounded, color: Colors.white54, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: dimmerOpacity,
                          min: 0.0,
                          max: 0.85,
                          activeColor: Colors.pinkAccent,
                          inactiveColor: Colors.white12,
                          onChanged: onDimmerOpacityChanged,
                        ),
                      ),
                      Text(
                        '应用亮度 ${((1.0 - dimmerOpacity) * 100).toInt()}%',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 2.6 Annotations & Highlights Launcher
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('划线想法管理', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      TextButton.icon(
                        onPressed: onShowAnnotationsSheet,
                        icon: const Icon(Icons.border_color_rounded, size: 14, color: Colors.pinkAccent),
                        label: const Text('管理本章想法', style: TextStyle(color: Colors.pinkAccent, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Page flip mode toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('翻页模式', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => onPageViewModeChanged(false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: !isPageViewMode ? Colors.pinkAccent : Colors.white12,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('纵向滚动', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => onPageViewModeChanged(true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isPageViewMode ? Colors.pinkAccent : Colors.white12,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('左右翻页', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!isPageViewMode) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('自动滚屏', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Row(
                          children: [
                            PopupMenuButton<double>(
                              initialValue: autoScrollSpeed,
                              onSelected: onAutoScrollSpeedChanged,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '滚屏速度 ${autoScrollSpeed.toInt()}级',
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ),
                              itemBuilder: (context) => [1.0, 2.0, 3.0, 4.0, 5.0]
                                  .map((s) => PopupMenuItem(value: s, child: Text('${s.toInt()} 级')))
                                  .toList(),
                            ),
                            const SizedBox(width: 10),
                            Switch(
                              value: isAutoScrolling,
                              activeColor: Colors.pinkAccent,
                              onChanged: onAutoScrollingChanged,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  // 3. Color theme pickers
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: themes.length,
                      itemBuilder: (context, idx) {
                        final th = themes[idx];
                        final Color bg = th[0];
                        final String name = th[2];
                        final isSel = idx == activeThemeIndex;

                        return GestureDetector(
                          onTap: () => onThemeIndexChanged(idx),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSel ? Colors.pinkAccent : Colors.white10,
                                width: isSel ? 2 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              name,
                              style: TextStyle(
                                color: th[1],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 24, color: Colors.white10),
                  // 4. TTS bottom drawer trigger & control bar
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          state.isTtsPlaying 
                              ? Icons.pause_circle_filled_rounded 
                              : Icons.play_circle_filled_rounded,
                          size: 32,
                          color: Colors.amberAccent,
                        ),
                        onPressed: () {
                          if (state.isTtsPlaying) {
                            ref.read(novelProvider.notifier).pauseTts();
                          } else {
                            ref.read(novelProvider.notifier).startTts();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          'AI 极净听书',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      // Speed adjuster
                      PopupMenuButton<double>(
                        initialValue: state.ttsSpeed,
                        onSelected: (speed) {
                          ref.read(novelProvider.notifier).setTtsSpeed(speed);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '语速 ${state.ttsSpeed}x',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ),
                        itemBuilder: (context) => [0.8, 1.0, 1.2, 1.5, 1.8, 2.0]
                            .map((s) => PopupMenuItem(value: s, child: Text('${s}x')))
                            .toList(),
                      ),
                      const SizedBox(width: 10),
                      // Sleep Timer Adjuster
                      PopupMenuButton<int?>(
                        initialValue: state.ttsTimerMinutes,
                        onSelected: (minutes) {
                          ref.read(novelProvider.notifier).setTtsTimer(minutes);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            state.ttsTimerMinutes == null 
                                ? '定时关闭' 
                                : '${state.ttsTimeRemainingSeconds ~/ 60}m',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
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
                  const Divider(height: 20, color: Colors.white10),
                  // 5. 听书与冥想声景空间混音控制面板
                  _buildAmbientMixerSection(ref),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmbientMixerSection(WidgetRef ref) {
    final ambientSounds = [
      {'id': 'rain', 'name': '幽谷秋雨', 'icon': Icons.umbrella_rounded, 'color': Colors.blueAccent},
      {'id': 'waves', 'name': '极地海浪', 'icon': Icons.waves_rounded, 'color': Colors.cyanAccent},
      {'id': 'fire', 'name': '壁炉柴火', 'icon': Icons.local_fire_department_rounded, 'color': Colors.orangeAccent},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.music_note_rounded, color: Colors.cyanAccent, size: 14),
            const SizedBox(width: 6),
            const Flexible(
              child: Text(
                '听书背景声景混音 (Ducking 智能避让)',
                style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (state.isTtsPlaying) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '避让中 -35%',
                  style: TextStyle(color: Colors.cyanAccent, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Column(
          children: ambientSounds.map((sound) {
            final id = sound['id'] as String;
            final name = sound['name'] as String;
            final icon = sound['icon'] as IconData;
            final color = sound['color'] as Color;
            
            final isActive = state.ambientActive[id] ?? false;
            final volume = state.ambientVolumes[id] ?? 0.5;

            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      ref.read(novelProvider.notifier).toggleAmbient(id);
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isActive ? color.withOpacity(0.2) : Colors.white10,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isActive ? color : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Icon(icon, color: isActive ? color : Colors.white38, size: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(name, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                        activeTrackColor: color.withOpacity(0.8),
                        inactiveTrackColor: Colors.white12,
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
                    style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
