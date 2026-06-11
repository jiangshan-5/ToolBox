import 'package:flutter/material.dart';
import '../../../../core/widgets/glass_card.dart';

class DailyBoardMorningNews extends StatelessWidget {
  final bool isLoadingNews;
  final List<String> newsList;
  final ValueChanged<String> onNewsTap;

  const DailyBoardMorningNews({
    super.key,
    required this.isLoadingNews,
    required this.newsList,
    required this.onNewsTap,
  });

  IconData _getNewsIcon(String text, int index, bool isHeader) {
    if (isHeader) {
      return Icons.today_rounded;
    }
    if (index == newsList.length - 1) {
      return Icons.auto_awesome_rounded;
    }
    if (text.contains('航天') || text.contains('卫星')) {
      return Icons.rocket_launch_rounded;
    }
    if (text.contains('人工智能') || text.contains('智能') || text.contains('AI')) {
      return Icons.psychology_rounded;
    }
    if (text.contains('车') || text.contains('电池') || text.contains('出行')) {
      return Icons.electric_car_rounded;
    }
    if (text.contains('计算') || text.contains('芯片') || text.contains('量子')) {
      return Icons.memory_rounded;
    }
    if (text.contains('经济') || text.contains('金融') || text.contains('交易')) {
      return Icons.insights_rounded;
    }
    if (text.contains('医学') || text.contains('健康') || text.contains('生物')) {
      return Icons.medical_services_rounded;
    }
    if (text.contains('天文') || text.contains('宇宙') || text.contains('星')) {
      return Icons.wb_twilight_rounded;
    }
    return Icons.fiber_manual_record_rounded;
  }

  Color _getNewsIconColor(BuildContext context, String text, int index, bool isHeader) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isHeader) {
      return isDark ? Colors.amberAccent : Colors.amber.shade800;
    }
    if (index == newsList.length - 1) {
      return isDark ? Colors.amberAccent : Colors.amber.shade800;
    }
    if (text.contains('航天') || text.contains('计算') || text.contains('天文')) {
      return isDark ? Colors.cyanAccent : Colors.cyan.shade800;
    }
    if (text.contains('人工智能')) {
      return isDark ? Colors.pinkAccent.shade100 : Colors.pink.shade700;
    }
    if (text.contains('车') || text.contains('经济')) {
      return isDark ? Colors.greenAccent : Colors.green.shade800;
    }
    if (text.contains('医学')) {
      return isDark ? Colors.orangeAccent.shade100 : Colors.orange.shade800;
    }
    return isDark ? Colors.cyanAccent : Colors.cyan.shade800;
  }

  Widget _buildParsedNewsText(BuildContext context, String itemText, TextStyle baseStyle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spans = <TextSpan>[];
    final regExp = RegExp(r'\*\*(.*?)\*\*|`(.*?)`');
    int start = 0;
    
    for (final match in regExp.allMatches(itemText)) {
      if (match.start > start) {
        spans.add(TextSpan(text: itemText.substring(start, match.start)));
      }
      if (match.group(1) != null) {
        spans.add(TextSpan(
          text: match.group(1),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.amberAccent : Colors.amber.shade900,
          ),
        ));
      } else if (match.group(2) != null) {
        spans.add(TextSpan(
          text: match.group(2),
          style: TextStyle(
            fontFamily: 'monospace',
            backgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12),
            color: isDark ? Colors.cyanAccent : Colors.cyan.shade800,
            fontWeight: FontWeight.w600,
          ),
        ));
      }
      start = match.end;
    }
    if (start < itemText.length) {
      spans.add(TextSpan(text: itemText.substring(start)));
    }
    if (spans.isEmpty) {
      return Text(itemText, style: baseStyle);
    }
    return Text.rich(
      TextSpan(children: spans),
      style: baseStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final faintTextColor = isDark ? Colors.white38 : Colors.black38;

    return GlassCard(
      borderColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: (isDark ? Colors.cyanAccent : Colors.cyan.shade700).withValues(alpha: 0.1),
                    border: Border.all(
                      color: (isDark ? Colors.cyanAccent : Colors.cyan.shade700).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    "📅 DAILY REPORT",
                    style: TextStyle(
                      color: isDark ? Colors.cyanAccent : Colors.cyan.shade800,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                Text(
                  "新闻源: 后端极速安全网关",
                  style: TextStyle(
                    color: faintTextColor,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            isLoadingNews
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: CircularProgressIndicator(
                        color: isDark ? Colors.cyanAccent : Colors.cyan.shade700,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: newsList.length,
                    separatorBuilder: (context, index) => Divider(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                      height: 16,
                    ),
                    itemBuilder: (context, index) {
                      final item = newsList[index];
                      final isHeader = index == 0;
                      final iconData = _getNewsIcon(item, index, isHeader);
                      final iconColor = _getNewsIconColor(context, item, index, isHeader);

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          hoverColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                          splashColor: (isDark ? Colors.cyanAccent : Colors.cyan.shade700).withValues(alpha: 0.08),
                          onTap: () => onNewsTap(item),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6.0,
                              horizontal: 8.0,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  iconData,
                                  color: iconColor,
                                  size: isHeader ? 15 : 13.5,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildParsedNewsText(
                                    context,
                                    item,
                                    TextStyle(
                                      color: isHeader
                                          ? textColor
                                          : subTextColor,
                                      fontSize: isHeader ? 13.5 : 12.5,
                                      fontWeight: isHeader
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
