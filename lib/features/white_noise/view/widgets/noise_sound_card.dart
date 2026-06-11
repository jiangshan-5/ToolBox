import 'package:flutter/material.dart';

class NoiseSoundCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final String desc;
  final Color themeColor;
  final bool isActive;
  final double volume;
  final ValueChanged<bool> onToggleActive;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback? onVolumeChangeStart;
  final ValueChanged<double>? onVolumeChangeEnd;
  final bool isLocal;
  final VoidCallback? onDelete;

  const NoiseSoundCard({
    super.key,
    required this.icon,
    required this.name,
    required this.desc,
    required this.themeColor,
    required this.isActive,
    required this.volume,
    required this.onToggleActive,
    required this.onVolumeChanged,
    this.onVolumeChangeStart,
    this.onVolumeChangeEnd,
    this.isLocal = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color faintTextColor = isDark ? Colors.white38 : Colors.black54;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onToggleActive(!isActive),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? themeColor.withOpacity(0.04)
              : (isDark
                    ? Colors.white.withOpacity(0.015)
                    : Colors.black.withOpacity(0.02)),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive
                ? themeColor.withOpacity(0.3)
                : (isDark
                      ? Colors.white.withOpacity(0.04)
                      : Colors.black.withOpacity(0.04)),
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? themeColor.withOpacity(0.12)
                              : (isDark
                                    ? Colors.white.withOpacity(0.02)
                                    : Colors.black.withOpacity(0.03)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: isActive ? themeColor : (isDark ? Colors.white60 : Colors.black45),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              desc,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: faintTextColor, fontSize: 9.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLocal && onDelete != null) ...[
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onDelete,
                  ),
                  const SizedBox(width: 8),
                ],
                Switch(
                  activeThumbColor: themeColor,
                  activeTrackColor: themeColor.withOpacity(0.2),
                  inactiveThumbColor: isDark ? Colors.white30 : Colors.grey.shade400,
                  inactiveTrackColor: isDark ? Colors.white10 : Colors.black12,
                  value: isActive,
                  onChanged: onToggleActive,
                ),
              ],
            ),
            if (isActive) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.volume_down_rounded,
                    color: faintTextColor,
                    size: 14,
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: themeColor,
                        inactiveTrackColor: isDark ? Colors.white10 : Colors.black12,
                        thumbColor: isDark ? Colors.white : themeColor,
                        overlayColor: themeColor.withOpacity(0.1),
                        trackHeight: 2.5,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                      ),
                      child: Slider(
                        value: volume,
                        onChanged: onVolumeChanged,
                        onChangeStart: onVolumeChangeStart != null ? (_) => onVolumeChangeStart!() : null,
                        onChangeEnd: onVolumeChangeEnd,
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
      ),
    );
  }
}
