import 'package:flutter/material.dart';
import '../dashboard_utils.dart';

class WorkbenchRecentlyUsed extends StatelessWidget {
  final List<String> recentlyUsed;
  final Color primaryColor;
  final void Function(String toolKey, String title) onToolClicked;

  const WorkbenchRecentlyUsed({
    super.key,
    required this.recentlyUsed,
    required this.primaryColor,
    required this.onToolClicked,
  });

  @override
  Widget build(BuildContext context) {
    if (recentlyUsed.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final faintTextColor = isDark ? Colors.white30 : Colors.black45;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(Icons.history_rounded, color: primaryColor, size: 16),
              const SizedBox(width: 8),
              Text(
                '最近使用的工具',
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 64,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: recentlyUsed.length,
            itemBuilder: (context, index) {
              final toolKey = recentlyUsed[index];
              final name = getToolChineseName(toolKey);
              final color = getToolColor(toolKey, context);
              final icon = getToolIcon(toolKey);
              return GestureDetector(
                onTap: () => onToolClicked(toolKey, name),
                child: Container(
                  width: 175,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '点击即刻唤醒',
                              style: TextStyle(
                                color: faintTextColor,
                                fontSize: 9.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
