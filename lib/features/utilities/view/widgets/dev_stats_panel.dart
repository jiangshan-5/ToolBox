import 'package:flutter/material.dart';

class DevStatsPanel extends StatelessWidget {
  final int inputBytes;
  final int outputBytes;
  final double deltaRatio;

  const DevStatsPanel({
    super.key,
    required this.inputBytes,
    required this.outputBytes,
    required this.deltaRatio,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color faintTextColor = isDark ? Colors.white38 : Colors.black38;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 转换统计指标',
          style: TextStyle(
            color: textColor,
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                isDark,
                faintTextColor,
                "字节数增幅",
                "${deltaRatio >= 0 ? '+' : ''}${deltaRatio.toStringAsFixed(1)}%",
                deltaRatio == 0
                    ? Colors.white54
                    : (deltaRatio < 0 ? Colors.greenAccent : Colors.amberAccent),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context,
                isDark,
                faintTextColor,
                "数据压缩率",
                _calculateRatio(inputBytes, outputBytes),
                deltaRatio < 0 ? Colors.greenAccent : Colors.white70,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    bool isDark,
    Color faintTextColor,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.015) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: faintTextColor, fontSize: 11)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateRatio(int originalBytes, int finalBytes) {
    if (originalBytes == 0) return '0.0%';
    final ratio = (finalBytes / originalBytes);
    if (ratio < 1.0) {
      final saved = (1.0 - ratio) * 100;
      return '节约 ${saved.toStringAsFixed(1)}%';
    } else {
      final increased = (ratio - 1.0) * 100;
      return '扩充 ${increased.toStringAsFixed(1)}%';
    }
  }
}
