import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../widgets/glass_card.dart';
import '../../auth/provider/auth_provider.dart';
import '../../randomizer/view/randomizer_screen.dart';
import '../../converter/view/converter_screen.dart';
import '../../bmi/view/bmi_screen.dart';
import '../../debug/view/debug_console_screen.dart';
import '../provider/tools_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  /// Map database tool keys to compiled Flutter widget views
  Widget? _getToolPage(String toolKey) {
    switch (toolKey) {
      case 'randomizer':
        return const RandomizerScreen();
      case 'unit_converter':
      case 'converter':
        return const ConverterScreen();
      case 'bmi_calculator':
        return const BmiScreen();
      default:
        return null;
    }
  }

  IconData _getToolIcon(String toolKey) {
    switch (toolKey) {
      case 'randomizer':
        return Icons.casino_rounded;
      case 'unit_converter':
      case 'converter':
        return Icons.swap_horiz_rounded;
      case 'bmi_calculator':
        return Icons.monitor_weight_outlined;
      case 'word_counter':
        return Icons.text_fields_rounded;
      case 'password_generator':
        return Icons.lock_reset_rounded;
      case 'world_clock':
        return Icons.alarm_rounded;
      case 'white_noise':
        return Icons.spa_rounded;
      case 'markdown_editor':
        return Icons.edit_note_rounded;
      case 'ai_chat':
        return Icons.psychology_rounded;
      case 'ai_text_processor':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.build_rounded;
    }
  }

  Color _getToolColor(String toolKey) {
    switch (toolKey) {
      case 'randomizer':
        return Colors.orangeAccent;
      case 'unit_converter':
      case 'converter':
        return Colors.cyanAccent;
      case 'bmi_calculator':
        return Colors.pinkAccent;
      case 'word_counter':
        return Colors.lightGreenAccent;
      case 'password_generator':
        return Colors.greenAccent;
      case 'world_clock':
        return Colors.purpleAccent;
      case 'white_noise':
        return Colors.tealAccent;
      case 'markdown_editor':
        return Colors.amberAccent;
      case 'ai_chat':
        return Colors.purpleAccent;
      case 'ai_text_processor':
        return Colors.amberAccent;
      default:
        return Colors.deepPurpleAccent;
    }
  }

  String _getToolChineseName(String toolKey) {
    switch (toolKey) {
      case 'randomizer':
        return '随机选择生成器';
      case 'unit_converter':
      case 'converter':
        return '标准单位转换器';
      case 'bmi_calculator':
        return '健康 BMI 计算器';
      case 'word_counter':
        return '字数与字符统计器';
      case 'password_generator':
        return '密码生成与强度分析';
      case 'world_clock':
        return '多时区时钟与番茄钟';
      case 'white_noise':
        return '白噪音专注冥想';
      case 'markdown_editor':
        return '极简 Markdown 编辑器';
      case 'ai_chat':
        return 'AI 智能多轮对话助理';
      case 'ai_text_processor':
        return 'AI 写作引擎';
      default:
        return '常用系统工具';
    }
  }

  String _formatTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final difference = DateTime.now().difference(dateTime);
      if (difference.inMinutes < 1) {
        return '刚刚';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}分钟前';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}小时前';
      } else {
        return '${dateTime.month}月${dateTime.day}日';
      }
    } catch (_) {
      return '刚刚';
    }
  }

  void _showComingSoonDialog(BuildContext context, String toolName) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassCard(
            borderColor: Colors.deepPurpleAccent.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 56,
                    color: Colors.amberAccent,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    toolName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '💡 功能正在全力开发中\n我们将于近期版本为您解锁这套超高强度的智能化服务，敬请期待！',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(120, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('好 的'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userEmail = ref.watch(authProvider).email ?? "User";
    final categoriesState = ref.watch(categoriesProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Toolbox Pro',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          // On mobile, show a Profile Button to open the drawer
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = MediaQuery.of(context).size.width > 950;
              if (isWide) return const SizedBox();
              return IconButton(
                icon: const Icon(Icons.person_outline_rounded, color: Colors.white70),
                onPressed: () => Scaffold.of(context).openDrawer(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      // Mobile Drawer containing the Personal Center Panel
      drawer: MediaQuery.of(context).size.width <= 950
          ? Drawer(
              backgroundColor: const Color(0xFF0F0C29),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildPersonalCenterContent(context, ref, userEmail),
                ),
              ),
            )
          : null,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 950;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Area: Grid of Tools (compact & beautiful)
                      Expanded(
                        flex: 7,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '欢迎回来，$userEmail',
                              style: const TextStyle(color: Colors.white60, fontSize: 14),
                            ),
                            Expanded(
                              child: Builder(
                                builder: (context) {
                                  final categories = categoriesState.value;
                                  if (categories == null) {
                                    // Instant synchronous render with zero delay!
                                    return _buildStaticGrid(context, isWide);
                                  } else {
                                    // Smoothly render dynamic tools once network resolves
                                    return _buildDynamicGrid(context, categories, isWide);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right Area: Live Personal Center (only on wide screen)
                      if (isWide) ...[
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 3,
                          child: _buildPersonalCenterPanel(context, ref, userEmail),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: userEmail == 'admin@toolbox.com'
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purpleAccent.withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DebugConsoleScreen()),
                  );
                },
                backgroundColor: const Color(0xFF0F0C29),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.purpleAccent.withOpacity(0.5), width: 1.5),
                ),
                child: const Icon(Icons.terminal_rounded, color: Colors.purpleAccent),
              ),
            )
          : null,
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F0C29), Color(0xFF1E1B4B), Color(0xFF111122)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  /// App-Store style Dynamic Category list loaded from Database
  Widget _buildDynamicGrid(BuildContext context, List<dynamic> categories, bool isWide) {
    if (categories.isEmpty) {
      return const Center(
        child: Text('无内置工具，请检查数据库配置', style: TextStyle(color: Colors.white70)),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: categories.length,
      padding: const EdgeInsets.only(bottom: 24),
      itemBuilder: (context, catIndex) {
        final category = categories[catIndex];
        final List<dynamic> catTools = category['tools'] ?? [];

        if (catTools.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 10.0),
              child: Row(
                children: [
                  Icon(
                    _getCategoryIcon(category['icon']),
                    color: Colors.deepPurpleAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category['name'] ?? '分类',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                // Highly optimized dense grid sizes
                int crossAxisCount = isWide
                    ? (constraints.maxWidth > 1100 ? 3 : 2)
                    : (constraints.maxWidth > 600 ? 3 : 2);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.3, // Ultra sleek horizontal card ratio
                  ),
                  itemCount: catTools.length,
                  itemBuilder: (context, toolIndex) {
                    final tool = catTools[toolIndex];
                    final String toolKey = tool['tool_key'] ?? '';
                    final String name = tool['name'] ?? '';
                    final String description = tool['description'] ?? '云端数据库极速计算已就绪';
                    final Color color = _getToolColor(toolKey);
                    final IconData icon = _getToolIcon(toolKey);

                    return GlassCard(
                      onTap: () {
                        final page = _getToolPage(toolKey);
                        if (page != null) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
                        } else {
                          _showComingSoonDialog(context, name);
                        }
                      },
                      borderColor: color.withOpacity(0.2),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: color.withOpacity(0.15), width: 1),
                              ),
                              child: Icon(icon, size: 22, color: color),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: Colors.white54,
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
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// Offline fallback grid rendering preseeded static utilities
  Widget _buildStaticGrid(BuildContext context, bool isWide) {
    final List<Map<String, dynamic>> staticTools = [
      {'title': '随机选择生成器', 'key': 'randomizer', 'desc': '极速随机生成数字，支持快速去重', 'page': const RandomizerScreen()},
      {'title': '标准单位转换器', 'key': 'converter', 'desc': '多种体积长度质量快速一键互转', 'page': const ConverterScreen()},
      {'title': '健康 BMI 计算器', 'key': 'bmi_calculator', 'desc': '标准人体健康指标评测云储存', 'page': const BmiScreen()},
      {'title': '字数与字符统计器', 'key': 'word_counter', 'desc': '统计文本的字数、词数及中英文字符占比', 'page': null},
      {'title': '密码生成与强度分析', 'key': 'password_generator', 'desc': '安全高强度密码快捷生成及熵值分析', 'page': null},
      {'title': '多时区时钟与番茄钟', 'key': 'world_clock', 'desc': '多时区对照与高精度番茄专注时钟', 'page': null},
      {'title': '白噪音专注冥想', 'key': 'white_noise', 'desc': '精选自然白噪音辅助冥想与高效专注', 'page': null},
      {'title': '极极简 Markdown 编辑器', 'key': 'markdown_editor', 'desc': '极简 Markdown 实时预览排版与字数统计', 'page': null},
      {'title': 'AI 智能多轮对话助理', 'key': 'ai_chat', 'desc': '结合大语言模型的高强度多轮文本分析', 'page': null},
      {'title': 'AI 写作引擎', 'key': 'ai_text_processor', 'desc': '一键精准翻译、句式优雅润色与摘要提取', 'page': null},
    ];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 10.0),
          child: Row(
            children: const [
              Icon(
                Icons.handyman_rounded,
                color: Colors.deepPurpleAccent,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                '常用工具',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = isWide
                ? (constraints.maxWidth > 1100 ? 3 : 2)
                : (constraints.maxWidth > 600 ? 3 : 2);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.3,
              ),
              itemCount: staticTools.length,
              itemBuilder: (context, index) {
                final tool = staticTools[index];
                final String toolKey = tool['key'];
                final String title = tool['title'];
                final String desc = tool['desc'];
                final dynamic page = tool['page'];
                final Color color = _getToolColor(toolKey);
                final IconData icon = _getToolIcon(toolKey);

                return GlassCard(
                  onTap: () {
                    if (page != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
                    } else {
                      _showComingSoonDialog(context, title);
                    }
                  },
                  borderColor: color.withOpacity(0.2),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.withOpacity(0.15), width: 1),
                          ),
                          child: Icon(icon, size: 22, color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                desc,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.white54,
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
            );
          },
        ),
      ],
    );
  }

  /// High quality skeleton loader for dynamic content
  Widget _buildLoadingSkeleton(bool isWide) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 3 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.3,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.deepPurpleAccent),
            ),
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(String? iconSlug) {
    switch (iconSlug) {
      case 'build':
        return Icons.handyman_rounded;
      case 'favorite':
        return Icons.favorite_rounded;
      case 'text_fields':
        return Icons.text_fields_rounded;
      case 'psychology':
        return Icons.psychology_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  /// Right side Floating Personal Center Panel Container
  Widget _buildPersonalCenterPanel(BuildContext context, WidgetRef ref, String email) {
    return GlassCard(
      borderColor: Colors.deepPurpleAccent.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _buildPersonalCenterContent(context, ref, email),
      ),
    );
  }

  /// Interactive Personal Center inner layout displaying real database telemetry
  Widget _buildPersonalCenterContent(BuildContext context, WidgetRef ref, String email) {
    final telemetryLogs = ref.watch(telemetryLogsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 👑 VIP Avatar Box
        Center(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Colors.purpleAccent, Colors.deepPurpleAccent],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purpleAccent.withOpacity(0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    email.substring(0, 1).toUpperCase(),
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
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

        // 🔒 Server Node Details
        const Text(
          '🔒 云端服务器节点',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
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
                  const Expanded(
                    child: Text(
                      '数据库已连接 (阿里云深圳)',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('云端存储延迟', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  Text('< 15ms', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // 📊 Live Telemetry Stream
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.timeline_rounded, color: Colors.purpleAccent, size: 16),
                SizedBox(width: 6),
                Text(
                  '📊 数据库 Telemetry 实况',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white54, size: 16),
              onPressed: () => ref.invalidate(telemetryLogsProvider),
            ),
          ],
        ),
        const SizedBox(height: 4),

        Expanded(
          child: telemetryLogs.when(
            data: (logs) {
              if (logs.isEmpty) {
                return const Center(
                  child: Text(
                    '暂无 Telemetry 上报日志\n运行任何工具，数据将瞬间存盘！',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                itemCount: logs.length > 5 ? 5 : logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final String toolKey = log['tool_key'] ?? '';
                  final String status = log['status'] ?? 'success';
                  final int duration = log['duration_ms'] ?? 0;
                  final String createdAt = log['created_at'] ?? '';
                  final Color color = _getToolColor(toolKey);

                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Vertical Timeline indicator
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
                                  color: Colors.white10,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        // Log Detail
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _getToolNameInLog(toolKey),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _formatTime(createdAt),
                                      style: const TextStyle(
                                        color: Colors.white30,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(
                                      status == 'success' ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                                      color: status == 'success' ? Colors.greenAccent : Colors.redAccent,
                                      size: 11,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      status == 'success' ? '计算完成 · ${duration}ms' : '运算异常',
                                      style: TextStyle(
                                        color: status == 'success' ? Colors.greenAccent.withOpacity(0.8) : Colors.redAccent,
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
            loading: () => const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.purpleAccent),
              ),
            ),
            error: (err, stack) => const Center(
              child: Text(
                'Telemetry 数据流拉取失败',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getToolNameInLog(String toolKey) {
    return _getToolChineseName(toolKey);
  }
}
