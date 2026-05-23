import 'package:flutter/material.dart';

class NoiseSoundCard extends StatelessWidget {
  final String emoji;
  final String name;
  final String desc;
  final Color themeColor;
  final bool isActive;
  final double volume;
  final ValueChanged<bool> onToggleActive;
  final ValueChanged<double> onVolumeChanged;

  const NoiseSoundCard({
    super.key,
    required this.emoji,
    required this.name,
    required this.desc,
    required this.themeColor,
    required this.isActive,
    required this.volume,
    required this.onToggleActive,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color faintTextColor = isDark ? Colors.white38 : Colors.black38;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isActive
            ? themeColor.withOpacity(0.04)
            : (isDark ? Colors.white.withOpacity(0.015) : Colors.black.withOpacity(0.02)),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? themeColor.withOpacity(0.3)
              : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
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
                      color: isActive
                          ? themeColor.withOpacity(0.12)
                          : (isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.03)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        style: TextStyle(color: faintTextColor, fontSize: 9.5),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                activeThumbColor: themeColor,
                activeTrackColor: themeColor.withOpacity(0.2),
                inactiveThumbColor: Colors.white30,
                inactiveTrackColor: Colors.white10,
                value: isActive,
                onChanged: onToggleActive,
              ),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.volume_down_rounded, color: faintTextColor, size: 14),
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
                      value: volume,
                      onChanged: onVolumeChanged,
                    ),
                  ),
                ),
                Text(
                  '${(volume * 100).toInt()}%',
                  style: TextStyle(
                    color: themeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
