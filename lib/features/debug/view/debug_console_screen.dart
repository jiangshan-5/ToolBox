import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/dynamic_effects.dart';
import '../../auth/provider/auth_provider.dart';
import '../../../core/providers/package_info_provider.dart';

/// 1. Server Stdout Logs Fetcher Provider
final serverLogsProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    final response = await apiClient.instance.get('/debug/server-logs');
    return response.data['logs'] as List<dynamic>;
  } catch (e) {
    return ['⚠️ 无法连接日志服务器: $e', '请检查云端 1.2.0 CD 部署是否完成，或检查安全组。'];
  }
});

/// 2. Database Stats Counts Provider
final dbStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
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
    if (lower.contains('error') ||
        lower.contains('exception') ||
        lower.contains('failed')) {
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
      length: 3,
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
                child: const Icon(
                  Icons.terminal_rounded,
                  size: 20,
                  color: Colors.purpleAccent,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '开发者系统调试台',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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
              Tab(icon: Icon(Icons.cloud_upload_rounded), text: '发布系统更新公告'),
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

              // Tab 3: Version publish form
              const _PublishForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogsTab(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<dynamic>> logsState,
  ) {
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
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
                          style: TextStyle(
                            color: Colors.white30,
                            fontFamily: 'monospace',
                          ),
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
                    child: CircularProgressIndicator(
                      color: Colors.purpleAccent,
                    ),
                  ),
                  error: (err, stack) => Center(
                    child: Text(
                      '❌ 拉取系统日志失败: $err',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontFamily: 'monospace',
                      ),
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

  Widget _buildStatsTab(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Map<String, dynamic>> statsState,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 阿里云 PostgreSQL 物理表行数核验 (实时)',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
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
                                color: isError
                                    ? Colors.redAccent
                                    : Colors.greenAccent,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isError ? '表结构缺失' : '当前存储行数',
                              style: TextStyle(
                                color: isError
                                    ? Colors.redAccent.withOpacity(0.6)
                                    : Colors.white60,
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
                child: Text(
                  '❌ 载入资产大盘失败: $err',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PublishForm extends ConsumerStatefulWidget {
  const _PublishForm();

  @override
  ConsumerState<_PublishForm> createState() => _PublishFormState();
}

class _PublishFormState extends ConsumerState<_PublishForm> {
  final _formKey = GlobalKey<FormState>();
  final _versionNameController = TextEditingController();
  final _versionCodeController = TextEditingController();
  final _changelogController = TextEditingController(
    text: '1. 💥 直接导入书源：现已支持与“阅读”(Legado) App 相同的书源导入功能，管理员可在移动端直接粘贴 URL 或 JSON 格式规则批量导入/热更新书源！\n'
          '2. 🔮 顶级磨砂玻璃态：新增管理员专属毛玻璃书源导入窗口，视觉交互更具赛博深空美感！\n'
          '3. ⚡ 校验与极致去重：智能基于书源唯一标识与 UUID5 进行重复识别与智能覆盖，极致防止重复数据！',
  );
  bool _forceUpdate = false;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    // Load package info to suggest next version and code dynamically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final packageInfo = ref.read(packageInfoProvider);
      final currentCode = int.tryParse(packageInfo.buildNumber) ?? 0;
      
      // Guess next version name (e.g. 1.1.1 -> 1.1.2)
      String nextVersion = packageInfo.version;
      final parts = packageInfo.version.split('.');
      if (parts.length == 3) {
        final patch = int.tryParse(parts[2]) ?? 0;
        nextVersion = '${parts[0]}.${parts[1]}.${patch + 1}';
      } else {
        nextVersion = '1.1.2';
      }
      
      setState(() {
        _versionNameController.text = nextVersion;
        _versionCodeController.text = (currentCode + 1).toString();
      });
    });
  }

  @override
  void dispose() {
    _versionNameController.dispose();
    _versionCodeController.dispose();
    _changelogController.dispose();
    super.dispose();
  }

  Future<void> _submitPublish() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isPublishing = true);
    final apiClient = ref.read(apiClientProvider);

    try {
      final response = await apiClient.instance.post(
        '/system/publish',
        data: {
          'latest_version': _versionNameController.text.trim(),
          'version_code': int.parse(_versionCodeController.text.trim()),
          'changelog': _changelogController.text.trim(),
          'force_update': _forceUpdate,
        },
      );

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 系统更新公告发布成功！已实时推送至所有在线客户端。'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          throw Exception('服务器返回错误状态: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ 发布失败，请检查服务连通性: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '📢 管理员更新通告发布面板',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '此处发布的新版本配置会立即更新后端缓存，并通过实时双向 WebSocket 通道广播至所有在线手机 App，自动拉起更新弹窗。',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              borderColor: Colors.white.withOpacity(0.08),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _versionNameController,
                            label: '最新版本名 (Version Name)',
                            hint: '例如: 1.2.0',
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return '请输入版本名';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _versionCodeController,
                            label: '内部版本代码 (Version Code)',
                            hint: '递增整数，例如: 3',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return '请输入版本代码';
                              }
                              if (int.tryParse(val.trim()) == null) {
                                return '必须为正整数';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '是否强制更新',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '开启后，客户端将无法关闭更新弹窗，必须完成更新才可使用。',
                              style: TextStyle(
                                color: Colors.white30,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _forceUpdate,
                          activeColor: Colors.purpleAccent,
                          onChanged: (val) {
                            setState(() {
                              _forceUpdate = val;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _changelogController,
                      label: '版本更新日志说明 (Changelog)',
                      hint: '输入详细的版本更新说明...',
                      maxLines: 5,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return '请输入更新日志说明';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _isPublishing
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.purpleAccent,
                            ),
                          )
                        : ScaleOnTap(
                            onTap: _submitPublish,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.purpleAccent,
                                    Colors.deepPurpleAccent,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purpleAccent.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                '🚀 立即发布广播并推送',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontFamily: 'monospace',
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
            filled: true,
            fillColor: Colors.white.withOpacity(0.03),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.08),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.purpleAccent,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.05),
              ),
            ),
            errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 10),
          ),
        ),
      ],
    );
  }
}
