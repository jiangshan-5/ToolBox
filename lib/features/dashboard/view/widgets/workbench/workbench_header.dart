import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkbenchHeader extends StatelessWidget {
  final String email;
  final Color primaryColor;
  final Color secondaryColor;

  const WorkbenchHeader({
    super.key,
    required this.email,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final name = email.isEmpty || !email.contains('@')
        ? '游客'
        : email.split('@').first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withValues(alpha: isDark ? 0.16 : 0.10),
            secondaryColor.withValues(alpha: isDark ? 0.10 : 0.08),
            isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.white.withValues(alpha: 0.72),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : primaryColor.withValues(alpha: 0.10),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: isDark ? 0.10 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Monogram Avatar with fine-tuned HSL gradient
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.26),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    name.isEmpty ? 'U' : name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '欢迎回来，$name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '常用工具、自动流水线与个人设置已整理就绪',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: subTextColor.withValues(alpha: 0.82),
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: secondaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: secondaryColor.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(
                  Icons.dashboard_customize_rounded,
                  color: secondaryColor,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _WorkbenchMetricPill(
                icon: Icons.grid_view_rounded,
                label: '14 个工具',
                color: primaryColor,
              ),
              _WorkbenchMetricPill(
                icon: Icons.bolt_rounded,
                label: '4 条工作流',
                color: secondaryColor,
              ),
              const _WorkbenchMetricPill(
                icon: Icons.security_rounded,
                label: '本地安全缓存',
                color: Colors.greenAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkbenchMetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _WorkbenchMetricPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.10 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class ConnectionIndicator extends StatelessWidget {
  final AsyncValue<List<dynamic>> state;

  const ConnectionIndicator({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final tools = state.asData?.value ?? const <dynamic>[];
    final isLoading = state.isLoading && state.asData == null;
    final isOnline = !isLoading && tools.isNotEmpty;
    final color = isLoading
        ? Colors.cyanAccent
        : isOnline
        ? Colors.greenAccent
        : Colors.orangeAccent;
    final icon = isLoading
        ? Icons.sync_rounded
        : isOnline
        ? Icons.cloud_done_rounded
        : Icons.wifi_off_rounded;
    final text = isLoading
        ? '正在连接云端工具库'
        : isOnline
        ? '云端工具库已同步'
        : '本地工具库模式';
    final desc = isLoading
        ? '正在拉取工具分类与工作流配置'
        : isOnline
        ? '${tools.length} 个远程分类已就绪，可自动同步使用记录'
        : '游客或离线状态下，已切换至内置工具与本地缓存';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.05 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18), width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: isDark ? color : color.withValues(alpha: 0.86),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black45,
                    fontSize: 10,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
