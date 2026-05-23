import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/glass_card.dart';
import '../provider/analytics_provider.dart';

class AnalyticsView extends ConsumerWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(analyticsProvider);

    return analyticsState.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Colors.cyanAccent),
      ),
      error: (e, st) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              '数据同步失败: ${e.toString()}',
              style: const TextStyle(color: Colors.white70),
            ),
            TextButton(
              onPressed: () => ref.read(analyticsProvider.notifier).refresh(),
              child: const Text(
                '重试',
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
          ],
        ),
      ),
      data: (data) => ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          // AI Productivity Assets
          _buildProductivitySummary(data),
          const SizedBox(height: 16),

          // Health Trend Chart
          _buildHealthTrendChart(data),
          const SizedBox(height: 16),

          // Developer Heatmap
          _buildHeatmap(data),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProductivitySummary(AnalyticsDashboardData data) {
    return GlassCard(
      borderColor: Colors.cyanAccent.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Colors.cyanAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'AI 效能与算力资产',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  '本周生成词汇',
                  '${data.aiWordsGenerated}',
                  Colors.cyanAccent,
                ),
                _buildStatItem(
                  '为您节省时间',
                  '${data.aiTimeSavedHours} h',
                  Colors.orangeAccent,
                ),
                _buildStatItem(
                  '驱动模型调用',
                  '${data.aiModelInvocations} 次',
                  Colors.purpleAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildHealthTrendChart(AnalyticsDashboardData data) {
    if (data.healthBmiTrend.isEmpty) {
      return GlassCard(
        borderColor: Colors.pinkAccent.withOpacity(0.3),
        child: const Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(
            child: Text(
              '暂无健康趋势数据。去使用 BMI 计算器记录一下吧！',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ),
      );
    }

    final spots = data.healthBmiTrend.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

    double minBMI = data.healthBmiTrend.reduce((a, b) => a < b ? a : b) - 2.0;
    double maxBMI = data.healthBmiTrend.reduce((a, b) => a > b ? a : b) + 2.0;

    return GlassCard(
      borderColor: Colors.pinkAccent.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.pinkAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.monitor_heart_rounded,
                    color: Colors.pinkAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '个人体征 BMI 趋势 (云端同步)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.white.withOpacity(0.05),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < data.healthTrendDates.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Text(
                                data.healthTrendDates[value.toInt()],
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (data.healthTrendDates.length - 1).toDouble().clamp(
                    1.0,
                    7.0,
                  ),
                  minY: minBMI,
                  maxY: maxBMI,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.pinkAccent,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: Colors.pinkAccent,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.pinkAccent.withOpacity(0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmap(AnalyticsDashboardData data) {
    return GlassCard(
      borderColor: Colors.greenAccent.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.greenAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '云端应用生态活跃度图谱',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                // Determine box size to fit ~18 columns
                final boxSize = (constraints.maxWidth - (17 * 4)) / 18;
                final heatmapLength = 18 * 7;
                return Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: List.generate(heatmapLength, (index) {
                    final intensity = index < data.heatmapActivity.length
                        ? data.heatmapActivity[index]
                        : 0.0;
                    Color color;
                    if (intensity <= 0.0) {
                      color = Colors.white.withOpacity(0.04);
                    } else if (intensity < 0.3) {
                      color = Colors.greenAccent.withOpacity(0.3);
                    } else if (intensity < 0.6) {
                      color = Colors.greenAccent.withOpacity(0.6);
                    } else {
                      color = Colors.greenAccent;
                    }
                    return Container(
                      width: boxSize,
                      height: boxSize,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                );
              },
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '少',
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                ),
                SizedBox(width: 6),
                _ColorBox(opacity: 0.04),
                SizedBox(width: 3),
                _ColorBox(opacity: 0.3),
                SizedBox(width: 3),
                _ColorBox(opacity: 0.6),
                SizedBox(width: 3),
                _ColorBox(opacity: 1.0),
                SizedBox(width: 6),
                Text(
                  '多',
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorBox extends StatelessWidget {
  final double opacity;
  const _ColorBox({required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: opacity <= 0.05
            ? Colors.white.withOpacity(0.04)
            : Colors.greenAccent.withOpacity(opacity),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
