import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/glass_card.dart';
import '../provider/analytics_provider.dart';
import 'widgets/dashboard_utils.dart';

class AnalyticsView extends ConsumerWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    final analyticsState = ref.watch(analyticsProvider);

    return analyticsState.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: primaryColor),
      ),
      error: (e, st) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              '数据同步失败: ${e.toString()}',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
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
          _buildProductivitySummary(context, data),
          const SizedBox(height: 16),

          // Health Trend Chart
          _buildHealthTrendChart(context, data),
          const SizedBox(height: 16),

          // Developer Heatmap
          _buildHeatmap(context, data),
          const SizedBox(height: 16),

          // Executions History Timeline
          _buildExecutionsHistory(context, ref),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildProductivitySummary(BuildContext context, AnalyticsDashboardData data) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final primaryColor = theme.colorScheme.primary;

    return GlassCard(
      borderColor: primaryColor.withOpacity(0.3),
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
                    color: primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.bolt_rounded,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'AI 效能与算力资产',
                  style: TextStyle(
                    color: textColor,
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
                  context,
                  '本周生成词汇',
                  '${data.aiWordsGenerated}',
                  primaryColor,
                ),
                _buildStatItem(
                  context,
                  '为您节省时间',
                  '${data.aiTimeSavedHours} h',
                  Colors.orangeAccent,
                ),
                _buildStatItem(
                  context,
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

  Widget _buildStatItem(BuildContext context, String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final faintTextColor = isDark ? Colors.white38 : Colors.black38;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: faintTextColor, fontSize: 11),
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

  Widget _buildHealthTrendChart(BuildContext context, AnalyticsDashboardData data) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final faintTextColor = isDark ? Colors.white38 : Colors.black38;

    if (data.healthBmiTrend.isEmpty) {
      return GlassCard(
        borderColor: Colors.pinkAccent.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Text(
              '暂无健康趋势数据。去使用 BMI 计算器记录一下吧！',
              style: TextStyle(color: subTextColor),
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
                Text(
                  '个人体征 BMI 趋势 (云端同步)',
                  style: TextStyle(
                    color: textColor,
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
                        color: textColor.withOpacity(0.05),
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
                                style: TextStyle(
                                  color: faintTextColor,
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
                            style: TextStyle(
                              color: subTextColor,
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
                  minY: minY(minBMI),
                  maxY: maxY(maxBMI),
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
                            color: isDark ? Colors.white : Colors.black,
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

  double minY(double val) => val.isInfinite || val.isNaN ? 15.0 : val;
  double maxY(double val) => val.isInfinite || val.isNaN ? 30.0 : val;

  Widget _buildHeatmap(BuildContext context, AnalyticsDashboardData data) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final faintTextColor = isDark ? Colors.white38 : Colors.black38;

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
                Text(
                  '云端应用生态活跃度图谱',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
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
                      color = textColor.withOpacity(0.04);
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '少',
                  style: TextStyle(color: faintTextColor, fontSize: 10),
                ),
                const SizedBox(width: 6),
                _ColorBox(opacity: 0.04, isDark: isDark),
                const SizedBox(width: 3),
                _ColorBox(opacity: 0.3, isDark: isDark),
                const SizedBox(width: 3),
                _ColorBox(opacity: 0.6, isDark: isDark),
                const SizedBox(width: 3),
                _ColorBox(opacity: 1.0, isDark: isDark),
                const SizedBox(width: 6),
                Text(
                  '多',
                  style: TextStyle(color: faintTextColor, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutionsHistory(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final faintTextColor = isDark ? Colors.white38 : Colors.black38;
    final primaryColor = theme.colorScheme.primary;

    final executionsAsync = ref.watch(workflowExecutionsProvider);

    return GlassCard(
      borderColor: primaryColor.withOpacity(0.25),
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
                    color: primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '🗄️ 全工具历史流水线运行记录',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            executionsAsync.when(
              loading: () => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2),
                ),
              ),
              error: (e, st) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text('获取流水线记录失败', style: TextStyle(color: subTextColor)),
                ),
              ),
              data: (logs) {
                if (logs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Column(
                        children: [
                          Icon(Icons.history_toggle_off_rounded, color: faintTextColor, size: 36),
                          const SizedBox(height: 8),
                          Text(
                            '暂无流水线运行记录。\n快去工作流车间组合运行一套试试吧！',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: faintTextColor, fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.length,
                  separatorBuilder: (c, i) => Divider(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                    height: 16,
                  ),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final timeStr = formatTime(log.createdAt.toIso8601String());

                    return Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.all(12),
                        expandedAlignment: Alignment.topLeft,
                        iconColor: primaryColor,
                        collapsedIconColor: subTextColor,
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
                              ),
                              child: const Text(
                                'SUCCESS',
                                style: TextStyle(color: Colors.greenAccent, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '流水线 #${log.id.substring(0, 6)}',
                                style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              timeStr,
                              style: TextStyle(color: faintTextColor, fontSize: 11),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: List.generate(log.steps.length, (idx) {
                              final stepKey = log.steps[idx];
                              final stepName = getToolChineseName(stepKey);
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (idx > 0)
                                    Icon(Icons.arrow_right_rounded, color: faintTextColor, size: 14),
                                  Text(
                                    stepName,
                                    style: TextStyle(color: primaryColor, fontSize: 10.5, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(log.steps.length, (idx) {
                                final stepKey = log.steps[idx];
                                final stepName = getToolChineseName(stepKey);
                                final stepInput = log.stepInputs[idx] ?? '';
                                final stepOutput = log.stepOutputs[idx] ?? '';

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(getToolIcon(stepKey), color: getToolColor(stepKey, context), size: 12),
                                          const SizedBox(width: 6),
                                          Text(
                                            '步骤 ${idx + 1}: $stepName',
                                            style: TextStyle(color: textColor, fontSize: 11.5, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 18.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '📥 输入:',
                                              style: TextStyle(color: faintTextColor, fontSize: 10),
                                            ),
                                            Text(
                                              stepInput.isEmpty ? '[空]' : stepInput,
                                              style: TextStyle(color: subTextColor, fontSize: 11),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '📤 输出:',
                                              style: TextStyle(color: faintTextColor, fontSize: 10),
                                            ),
                                            Text(
                                              stepOutput.isEmpty ? '[空]' : stepOutput,
                                              style: TextStyle(color: getToolColor(stepKey, context), fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorBox extends StatelessWidget {
  final double opacity;
  final bool isDark;
  const _ColorBox({required this.opacity, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: opacity <= 0.05
            ? (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04))
            : Colors.greenAccent.withOpacity(opacity),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
