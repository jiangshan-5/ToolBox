import 'package:flutter/material.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/dynamic_effects.dart';

class DailyBoardPushController extends StatelessWidget {
  final bool pushOnStartup;
  final bool pushDaily10am;
  final int pushNewsCount;
  final bool isPeriodicPushRunning;
  final int pushIntervalSeconds;
  final List<Map<String, dynamic>> pushHistory;
  final ValueChanged<bool> onPushOnStartupChanged;
  final ValueChanged<bool> onPushDaily10amChanged;
  final ValueChanged<int> onPushNewsCountChanged;
  final ValueChanged<bool> onPeriodicPushRunningChanged;
  final ValueChanged<int> onPushIntervalSecondsChanged;
  final VoidCallback onTriggerImmediatePush;
  final VoidCallback onTriggerDelayedPush;
  final VoidCallback onClearHistory;

  const DailyBoardPushController({
    super.key,
    required this.pushOnStartup,
    required this.pushDaily10am,
    required this.pushNewsCount,
    required this.isPeriodicPushRunning,
    required this.pushIntervalSeconds,
    required this.pushHistory,
    required this.onPushOnStartupChanged,
    required this.onPushDaily10amChanged,
    required this.onPushNewsCountChanged,
    required this.onPeriodicPushRunningChanged,
    required this.onPushIntervalSecondsChanged,
    required this.onTriggerImmediatePush,
    required this.onTriggerDelayedPush,
    required this.onClearHistory,
  });

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.settings_suggest_rounded, color: isDark ? Colors.cyanAccent : Colors.cyan.shade800, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "推送参数配置",
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.cyanAccent : Colors.cyan.shade700).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: (isDark ? Colors.cyanAccent : Colors.cyan.shade700).withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    "SIMULATION MODE",
                    style: TextStyle(
                      color: isDark ? Colors.cyanAccent : Colors.cyan.shade800,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Startup Push Toggle
            _buildSettingRow(
              context,
              icon: Icons.launch_rounded,
              title: "开屏立即推送",
              subtitle: "应用启动加载完毕后自动推送最新时事",
              value: pushOnStartup,
              onChanged: onPushOnStartupChanged,
            ),
            Divider(color: isDark ? Colors.white10 : Colors.black12, height: 20),

            // Daily 10 AM scheduled push toggle
            _buildSettingRow(
              context,
              icon: Icons.notifications_active_rounded,
              title: "每天早上10点定时推送",
              subtitle: "默认开启，支持后台推送最新的60秒时事早报",
              value: pushDaily10am,
              onChanged: onPushDaily10amChanged,
            ),
            Divider(color: isDark ? Colors.white10 : Colors.black12, height: 20),

            // Content count slider
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.list_alt_rounded, color: isDark ? Colors.cyanAccent : Colors.cyan.shade800, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          "单次推送条数",
                          style: TextStyle(color: subTextColor, fontSize: 12.5),
                        ),
                      ],
                    ),
                    Text(
                      "$pushNewsCount 条",
                      style: TextStyle(
                        color: isDark ? Colors.cyanAccent : Colors.cyan.shade800,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "从今日 60 秒时事速递中甄选的新闻条数限制",
                  style: TextStyle(color: faintTextColor, fontSize: 10),
                ),
                Slider(
                  value: pushNewsCount.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: isDark ? Colors.cyanAccent : Colors.cyan.shade600,
                  inactiveColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                  onChanged: (val) => onPushNewsCountChanged(val.toInt()),
                ),
              ],
            ),
            Divider(color: isDark ? Colors.white10 : Colors.black12, height: 20),

            // Periodic Poll Trigger
            _buildSettingRow(
              context,
              icon: Icons.loop_rounded,
              title: "自动定时轮询广播",
              subtitle: "按固定时间间隔在后台循环轮播推送",
              value: isPeriodicPushRunning,
              onChanged: onPeriodicPushRunningChanged,
            ),
            const SizedBox(height: 12),

            // Interval slider
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, color: isDark ? Colors.cyanAccent : Colors.cyan.shade800, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          "轮询时间间隔",
                          style: TextStyle(color: subTextColor, fontSize: 12.5),
                        ),
                      ],
                    ),
                    Text(
                      "$pushIntervalSeconds 秒",
                      style: TextStyle(
                        color: isPeriodicPushRunning ? faintTextColor : (isDark ? Colors.cyanAccent : Colors.cyan.shade800),
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: pushIntervalSeconds.toDouble(),
                  min: 5,
                  max: 60,
                  divisions: 11,
                  activeColor: isPeriodicPushRunning ? (isDark ? Colors.white24 : Colors.black12) : (isDark ? Colors.cyanAccent : Colors.cyan.shade600),
                  inactiveColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                  onChanged: isPeriodicPushRunning
                      ? null
                      : (val) => onPushIntervalSecondsChanged(val.toInt()),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action Buttons Row (Immediate & Background 5s)
            Row(
              children: [
                Expanded(
                  child: ScaleOnTap(
                    onTap: onTriggerImmediatePush,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: isDark
                              ? [Colors.cyanAccent, const Color(0xFF00E5FF)]
                              : [Colors.cyan.shade400, Colors.cyan.shade600],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isDark ? Colors.cyanAccent : Colors.cyan).withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, color: isDark ? Colors.black87 : Colors.white, size: 15),
                          const SizedBox(width: 6),
                          Text(
                            "立即发送推送",
                            style: TextStyle(
                              color: isDark ? Colors.black87 : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ScaleOnTap(
                    onTap: onTriggerDelayedPush,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
                        border: Border.all(
                          color: (isDark ? Colors.cyanAccent : Colors.cyan.shade700).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.hourglass_empty_rounded, color: isDark ? Colors.cyanAccent : Colors.cyan.shade800, size: 15),
                          const SizedBox(width: 6),
                          Text(
                            "5秒延时后台推送",
                            style: TextStyle(
                              color: isDark ? Colors.cyanAccent : Colors.cyan.shade800,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Push History Log Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.cyanAccent : Colors.cyan.shade800,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: isDark ? Colors.cyanAccent : Colors.cyan.shade800,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "系统推送历史与日志",
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (pushHistory.isNotEmpty)
                        GestureDetector(
                          onTap: onClearHistory,
                          child: const Text(
                            "清空日志",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  pushHistory.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(
                            child: Text(
                              "📡 暂无模拟推送记录，点击上方按钮触发",
                              style: TextStyle(color: faintTextColor, fontSize: 11),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pushHistory.length.clamp(0, 3), // limit visible to 3 items
                          separatorBuilder: (context, index) => Divider(
                            color: isDark ? Colors.white10 : Colors.black12,
                            height: 16,
                          ),
                          itemBuilder: (context, index) {
                            final log = pushHistory[index];
                            final time = log['time'] ?? '';
                            final title = log['title'] ?? '';
                            final items = log['items'] as List<dynamic>? ?? [];

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                          color: isDark ? Colors.cyanAccent : Colors.cyan.shade800,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      time,
                                      style: TextStyle(
                                        color: faintTextColor,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ...items.map((newsItem) => Padding(
                                      padding: const EdgeInsets.only(left: 6.0, bottom: 3.0),
                                      child: Text(
                                        "• $newsItem",
                                        style: TextStyle(
                                          color: subTextColor,
                                          fontSize: 10.5,
                                          height: 1.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )),
                              ],
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final faintTextColor = isDark ? Colors.white38 : Colors.black38;

    return Row(
      children: [
        Icon(icon, color: isDark ? Colors.cyanAccent : Colors.cyan.shade800, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: faintTextColor,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: (isDark ? Colors.cyanAccent : Colors.cyan).withValues(alpha: 0.2),
          activeColor: isDark ? Colors.cyanAccent : Colors.cyan.shade700,
          inactiveThumbColor: isDark ? Colors.white54 : Colors.grey.shade400,
          inactiveTrackColor: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ],
    );
  }
}
