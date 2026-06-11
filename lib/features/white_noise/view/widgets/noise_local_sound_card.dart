import 'package:flutter/material.dart';

class NoiseLocalSoundCard extends StatelessWidget {
  final String name;
  final bool isActive;
  final Color themeColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NoiseLocalSoundCard({
    super.key,
    required this.name,
    required this.isActive,
    required this.themeColor,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color faintTextColor = isDark ? Colors.white38 : Colors.black54;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? themeColor.withOpacity(0.06)
              : (isDark
                  ? Colors.white.withOpacity(0.015)
                  : Colors.black.withOpacity(0.02)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? themeColor.withOpacity(0.4)
                : (isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05)),
            width: 1.2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: themeColor.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? themeColor.withOpacity(0.12)
                        : (isDark
                            ? Colors.white.withOpacity(0.03)
                            : Colors.black.withOpacity(0.03)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isActive ? Icons.music_note_rounded : Icons.music_off_rounded,
                    color: isActive ? themeColor : faintTextColor,
                    size: 14,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Prevent card tap when clicking delete
                    onDelete();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.02)
                          : Colors.black.withOpacity(0.02),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.redAccent,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isActive ? (isDark ? Colors.white : themeColor) : textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isActive ? '播放中' : '已静音',
                  style: TextStyle(
                    color: isActive ? themeColor : faintTextColor,
                    fontSize: 9,
                  ),
                ),
                if (isActive)
                  _buildAnimatedMiniPulse(themeColor)
                else
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: faintTextColor.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedMiniPulse(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          width: 2,
          height: 8,
          margin: const EdgeInsets.only(left: 1.5),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}
