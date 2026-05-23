import 'package:flutter/material.dart';
import '../../../../core/widgets/glass_card.dart';

class NoiseVisualizer extends StatelessWidget {
  final bool isMixerPlaying;
  final List<double> visualizerHeights;
  final VoidCallback onToggleMixerPlay;

  const NoiseVisualizer({
    super.key,
    required this.isMixerPlaying,
    required this.visualizerHeights,
    required this.onToggleMixerPlay,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color faintTextColor = isDark ? Colors.white38 : Colors.black38;

    return GlassCard(
      glowColor: isMixerPlaying
          ? Colors.cyanAccent
          : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: visualizerHeights.map((h) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: 5,
                    height: isMixerPlaying ? h : 4.0,
                    decoration: BoxDecoration(
                      color: isMixerPlaying
                          ? Colors.cyanAccent.withOpacity(0.8)
                          : Colors.white12,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        if (isMixerPlaying)
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
                      isMixerPlaying ? '大自然环绕声效混音中' : '声景播放已静音',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '支持开启多声道声效，混合出独属您的冥想空间',
                      style: TextStyle(color: faintTextColor, fontSize: 10),
                    ),
                  ],
                ),
                IconButton(
                  iconSize: 42,
                  icon: Icon(
                    isMixerPlaying ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
                    color: Colors.cyanAccent,
                  ),
                  onPressed: onToggleMixerPlay,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
