import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/glass_card.dart';
import '../../auth/provider/auth_provider.dart';

/// 1. Server Stdout Logs Fetcher Provider
final serverLogsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    final response = await apiClient.instance.get('/debug/server-logs');
    return response.data['logs'] as List<dynamic>;
  } catch (e) {
    return ['⚠️ 无法连接日志服务器: $e', '请检查云端 1.2.0 CD 部署是否完成，或检查安全组。'];
  }
});

/// 2. Database Stats Counts Provider
final dbStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    final response = await apiClient.instance.get('/debug/db-stats');
    return response.data['database_counts'] as Map<String, dynamic>;
  } catch (e) {
    return {'status': 'error', 'message': e.toString()};
  }
});

class DebugConsoleScreen extends ConsumerWidget {
  const DebugConsoleScreen({super.key});

  /// Monospace color code logic for standard logs stream
  Color _getLogLevelColor(String logLine) {
    final lower = logLine.toLowerCase();
    if (lower.contains('error') || lower.contains('exception') || lower.contains('failed')) {
      return const Color(0xFFFF5252); // Soft Red
    }
    if (lower.contains('warning') || lower.contains('warn')) {
      return const Color(0xFFFFAB40); // Soft Orange
    }
    if (lower.contains('info')) {
      return const Color(0xFF40C4FF); // Soft Cyan
    }
    if (lower.contains('debug')) {
      return Colors.greenAccent;
    }
    return Colors.white70;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsState = ref.watch(serverLogsProvider);
    final statsState = ref.watch(dbStatsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A071E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F0C29),
          elevation: 4,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.deepPurpleAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.terminal_rounded, size: 20, color: Colors.purpleAccent),
              ),
              const SizedBox(width: 12),
              const Text(
                '开发者系统调试台',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          bottom: const TabBar(
            indicatorColor: Colors.purpleAccent,
            labelColor: Colors.purpleAccent,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(icon: Icon(Icons.receipt_long_rounded), text: '云端控制台 Stdout'),
              Tab(icon: Icon(Icons.dns_rounded), text: 'PostgreSQL 数据库实况'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: '强力清空本地缓存并拉取',
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
              onPressed: () {
                ref.invalidate(serverLogsProvider);
                ref.invalidate(dbStatsProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚡ 云端系统数据已强制重刷...'),
                    backgroundColor: Colors.deepPurpleAccent,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F0C29), Color(0xFF0A071E)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: TabBarView(
            children: [
              // Tab 1: Server Stdout Log Tail view
              _buildLogsTab(context, ref, logsState),

              // Tab 2: PostgreSQL integrity charts
              _buildStatsTab(context, ref, statsState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogsTab(BuildContext context, WidgetRef ref, AsyncValue<List<dynamic>> logsState) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🔔 云端 Uvicorn 实时运行日志 (Tail -100 行)',
                style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              logsState.maybeWhen(
                data: (logs) => ElevatedButton.icon(
                  onPressed: () {
                    final allLogs = logs.join('\n');
                    Clipboard.setData(ClipboardData(text: allLogs));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📋 诊断日志已完美复制到系统剪贴板！'),
                        backgroundColor: Colors.purple,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  label: const Text('复制日志'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white12,
                    foregroundColor: Colors.white70,
                    minimumSize: const Size(90, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                orElse: () => const SizedBox(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GlassCard(
              borderColor: Colors.white.withOpacity(0.08),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: logsState.when(
                  data: (logs) {
                    if (logs.isEmpty) {
                      return const Center(
                        child: Text(
                          '📭 目前尚无任何云端控制台输出',
                          style: TextStyle(color: Colors.white30, fontFamily: 'monospace'),
                        ),
                      );
                    }
                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final line = logs[index].toString();
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: SelectableText(
                            line,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: _getLogLevelColor(line),
                              height: 1.4,
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.purpleAccent),
                  ),
                  error: (err, stack) => Center(
                    child: Text(
                      '❌ 拉取系统日志失败: $err',
                      style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab(BuildContext context, WidgetRef ref, AsyncValue<Map<String, dynamic>> statsState) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 阿里云 PostgreSQL 物理表行数核验 (实时)',
            style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: statsState.when(
              data: (stats) {
                if (stats.containsKey('status') && stats['status'] == 'error') {
                  return Center(
                    child: Text(
                      '⚠️ 获取数据库数据失败: ${stats['message']}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.6,
                  ),
                  itemCount: stats.length,
                  itemBuilder: (context, index) {
                    final key = stats.keys.elementAt(index);
                    final value = stats[key];
                    final isError = value.toString().startsWith('Error');

                    return GlassCard(
                      borderColor: isError 
                          ? Colors.redAccent.withOpacity(0.2) 
                          : Colors.purpleAccent.withOpacity(0.15),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              key.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isError ? '未挂载' : value.toString(),
                              style: TextStyle(
                                color: isError ? Colors.redAccent : Colors.greenAccent,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isError ? '表结构缺失' : '当前存储行数',
                              style: TextStyle(
                                color: isError ? Colors.redAccent.withOpacity(0.6) : Colors.white60,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.purpleAccent),
              ),
              error: (err, stack) => Center(
                child: Text('❌ 载入资产大盘失败: $err', style: const TextStyle(color: Colors.redAccent)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
