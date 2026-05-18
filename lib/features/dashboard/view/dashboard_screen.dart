import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/glass_card.dart';
import '../../auth/provider/auth_provider.dart';
import '../../randomizer/view/randomizer_screen.dart';
import '../../converter/view/converter_screen.dart';
import '../../bmi/view/bmi_screen.dart';
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
      case 'ai_chat':
        return Colors.purpleAccent;
      case 'ai_text_processor':
        return Colors.amberAccent;
      default:
        return Colors.deepPurpleAccent;
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildHeader(userEmail),
                  const SizedBox(height: 24),
                  Expanded(
                    child: categoriesState.when(
                      data: (categories) => _buildDynamicGrid(context, categories),
                      loading: () => _buildLoadingSkeleton(),
                      error: (err, stack) {
                        // Safe fallback to local preseeded static tools if server offline
                        print("Dynamic tools fetch failed, showing static: $err");
                        return _buildStaticGrid(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildHeader(String email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Toolbox Pro',
          style: TextStyle(
            fontSize: 36, 
            fontWeight: FontWeight.bold, 
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '欢迎回来，$email', 
          style: const TextStyle(color: Colors.white60, fontSize: 16),
        ),
      ],
    );
  }

  /// App-Store style Dynamic Category list loaded from Database
  Widget _buildDynamicGrid(BuildContext context, List<dynamic> categories) {
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
              padding: const EdgeInsets.only(top: 20.0, bottom: 12.0),
              child: Row(
                children: [
                  Icon(
                    _getCategoryIcon(category['icon']), 
                    color: Colors.deepPurpleAccent, 
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category['name'] ?? '分类',
                    style: const TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth > 800 ? 3 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.25,
                  ),
                  itemCount: catTools.length,
                  itemBuilder: (context, toolIndex) {
                    final tool = catTools[toolIndex];
                    final String toolKey = tool['tool_key'] ?? '';
                    final String name = tool['name'] ?? '';
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
                      borderColor: color.withOpacity(0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(icon, size: 30, color: color),
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15, 
                                fontWeight: FontWeight.bold, 
                                color: Colors.white,
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
  Widget _buildStaticGrid(BuildContext context) {
    final List<Map<String, dynamic>> staticTools = [
      {'title': '随机选择生成器', 'key': 'randomizer', 'page': const RandomizerScreen()},
      {'title': '标准单位转换器', 'key': 'converter', 'page': const ConverterScreen()},
      {'title': '健康 BMI 计算器', 'key': 'bmi_calculator', 'page': const BmiScreen()},
      {'title': 'AI 智能多轮助理', 'key': 'ai_chat', 'page': null},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 800 ? 3 : 2;
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: staticTools.length,
          itemBuilder: (context, index) {
            final tool = staticTools[index];
            final String toolKey = tool['key'];
            final String title = tool['title'];
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
              borderColor: color.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, size: 32, color: color),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// High quality skeleton loader for dynamic content
  Widget _buildLoadingSkeleton() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurpleAccent),
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
}
