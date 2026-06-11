import 'package:flutter/material.dart';
import '../../../../core/widgets/glass_card.dart';

class DevJsonSpacingOptions extends StatelessWidget {
  final int jsonSpacing;
  final ValueChanged<int> onJsonSpacingChanged;

  const DevJsonSpacingOptions({
    super.key,
    required this.jsonSpacing,
    required this.onJsonSpacingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color subTextColor = isDark ? Colors.white70 : Colors.black54;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return GlassCard(
      borderColor: primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.space_bar_rounded,
                  color: primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  "JSON 缩进空格数",
                  style: TextStyle(color: subTextColor, fontSize: 12),
                ),
              ],
            ),
            Row(
              children: [2, 4, 8].map((spaces) {
                final active = jsonSpacing == spaces;
                return GestureDetector(
                  onTap: () => onJsonSpacingChanged(spaces),
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? primaryColor.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: active
                            ? primaryColor
                            : (isDark ? Colors.white10 : Colors.black12),
                      ),
                    ),
                    child: Text(
                      "$spaces 个空格",
                      style: TextStyle(
                        color: active
                            ? primaryColor
                            : (isDark ? Colors.white30 : Colors.black54),
                        fontSize: 11,
                        fontWeight: active
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
