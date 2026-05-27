import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/providers/api_config_provider.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../provider/tools_provider.dart';
import '../dashboard_utils.dart';

class PersonalCenterPanel extends ConsumerWidget {
  final String email;

  const PersonalCenterPanel({
    super.key,
    required this.email,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final secondaryColor = theme.colorScheme.secondary;

    return GlassCard(
      borderColor: secondaryColor.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: PersonalCenterContent(email: email),
      ),
    );
  }
}

class PersonalCenterContent extends ConsumerWidget {
  final String email;

  const PersonalCenterContent({
    super.key,
    required this.email,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final faintTextColor = isDark ? Colors.white38 : Colors.black38;
    final borderDividerColor =
        isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

    final telemetryLogs = ref.watch(telemetryLogsProvider);
    final currentApiUrl = ref.watch(apiBaseUrlProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    email.isEmpty ? "U" : email.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                email.isEmpty ? '游客模式体验中' : email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Premium 尊享会员',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          '🔒 云端服务器节点',
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderDividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '服务地址: $currentApiUrl',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '状态',
                    style: TextStyle(color: faintTextColor, fontSize: 11),
                  ),
                  Text(
                    currentApiUrl.contains('47.106.119.62')
                        ? '公网节点 (深圳)'
                        : '自定义节点',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.timeline_rounded, color: primaryColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  '📊 数据库 Telemetry 实况',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                color: subTextColor,
                size: 16,
              ),
              onPressed: () => ref.invalidate(telemetryLogsProvider),
            ),
          ],
        ),
        const SizedBox(height: 4),
        telemetryLogs.when(
          data: (logs) {
            if (logs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(
                    '暂无 Telemetry 上报日志\n运行任何工具，数据将瞬间存盘！',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: faintTextColor, fontSize: 11),
                  ),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length > 5 ? 5 : logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                final String toolKey = log['tool_key'] ?? '';
                final String status = log['status'] ?? 'success';
                final int duration = log['duration_ms'] ?? 0;
                final String createdAt = log['created_at'] ?? '';
                final Color color = getToolColor(toolKey, context);
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.6),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          if (index != (logs.length > 5 ? 4 : logs.length - 1))
                            Expanded(
                              child: Container(
                                width: 1.5,
                                color: borderDividerColor,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    getToolChineseName(toolKey),
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    formatTime(createdAt),
                                    style: TextStyle(
                                      color: faintTextColor,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(
                                    status == 'success'
                                        ? Icons.check_circle_outline_rounded
                                        : Icons.error_outline_rounded,
                                    color: status == 'success'
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                    size: 11,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    status == 'success'
                                        ? '计算完成 · ${duration}ms'
                                        : '运算异常',
                                    style: TextStyle(
                                      color: status == 'success'
                                          ? Colors.greenAccent.withOpacity(0.8)
                                          : Colors.redAccent,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: primaryColor,
                ),
              ),
            ),
          ),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                'Telemetry 数据流拉取失败',
                style: TextStyle(color: faintTextColor, fontSize: 11),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
