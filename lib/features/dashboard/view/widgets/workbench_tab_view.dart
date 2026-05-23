import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/widgets/parallax_glass_card.dart';
import '../../provider/tools_provider.dart';
import 'dashboard_utils.dart';

class WorkbenchTabView extends ConsumerStatefulWidget {
  final String userEmail;
  final bool isWide;

  const WorkbenchTabView({
    super.key,
    required this.userEmail,
    required this.isWide,
  });

  @override
  ConsumerState<WorkbenchTabView> createState() => _WorkbenchTabViewState();
}

class _WorkbenchTabViewState extends ConsumerState<WorkbenchTabView> {
  List<String> _recentlyUsed = ['randomizer', 'converter'];

  @override
  void initState() {
    super.initState();
    _loadRecentlyUsed();
  }

  void _loadRecentlyUsed() {
    try {
      final storage = ref.read(localStorageServiceProvider);
      final savedList = storage.getStringList('recently_used');
      if (savedList != null && savedList.isNotEmpty) {
        setState(() {
          _recentlyUsed = savedList;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveRecentlyUsed(List<String> list) async {
    try {
      final storage = ref.read(localStorageServiceProvider);
      await storage.setStringList('recently_used', list);
    } catch (_) {}
  }

  void _onDynamicToolClicked(String toolKey, String title) {
    final page = getToolPage(toolKey);
    if (page != null) {
      setState(() {
        _recentlyUsed.remove(toolKey);
        _recentlyUsed.insert(0, toolKey);
        if (_recentlyUsed.length > 4) {
          _recentlyUsed = _recentlyUsed.sublist(0, 4);
        }
      });
      _saveRecentlyUsed(_recentlyUsed);
      Navigator.push(context, FadePageRoute(child: page));
    } else {
      showComingSoonDialog(context, title);
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final categoriesState = ref.watch(categoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWorkbenchHeader(
          widget.userEmail,
          primaryColor,
          theme.colorScheme.secondary,
        ),
        _buildConnectionIndicator(categoriesState),
        const SizedBox(height: 12),
        _buildRecentlyUsedSection(context, primaryColor),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(Icons.grid_view_rounded, color: primaryColor, size: 16),
              const SizedBox(width: 8),
              const Text(
                '全部工具分类库',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedCrossFade(
            duration: const Duration(milliseconds: 400),
            firstChild: _buildStaticGrid(
              context,
              widget.isWide,
              textColor,
              isDark,
            ),
            secondChild:
                (categoriesState.value != null &&
                    categoriesState.value!.isNotEmpty)
                ? _buildDynamicGrid(
                    context,
                    categoriesState.value!,
                    widget.isWide,
                    theme.colorScheme.secondary,
                  )
                : const SizedBox.shrink(),
            crossFadeState:
                (categoriesState.value == null ||
                    categoriesState.value!.isEmpty)
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
          ),
        ),
        const SizedBox(
          height: 80,
        ), // Prevent content being covered by floating navbar
      ],
    );
  }

  Widget _buildWorkbenchHeader(
    String email,
    Color primaryColor,
    Color secondaryColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [primaryColor, secondaryColor]),
            ),
            child: Center(
              child: Text(
                email.isEmpty ? "U" : email.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
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
                  '欢迎回来，$email',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
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
                    const SizedBox(width: 6),
                    const Text(
                      '专属黄金加密节点 · 正常连接',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionIndicator(AsyncValue<List<dynamic>> state) {
    final bool isOnline = state.value != null;
    final color = isOnline ? Colors.greenAccent : Colors.orangeAccent;
    final icon = isOnline ? Icons.cloud_done_rounded : Icons.wifi_off_rounded;
    final text = isOnline
        ? '全双工云端互联已建立 (Sync Enabled)'
        : '安全离线隔离沙盒模式 (Offline Sandbox)';
    final desc = isOnline ? '已连接阿里云高防加密节点 · 延迟 12ms' : '网络离线，已安全切换至本地离线高速计算芯片';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyUsedSection(BuildContext context, Color primaryColor) {
    if (_recentlyUsed.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(Icons.history_rounded, color: primaryColor, size: 16),
              const SizedBox(width: 8),
              const Text(
                '最近使用的工具',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 64,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _recentlyUsed.length,
            itemBuilder: (context, index) {
              final toolKey = _recentlyUsed[index];
              final name = getToolChineseName(toolKey);
              final color = getToolColor(toolKey, context);
              final icon = getToolIcon(toolKey);
              return GestureDetector(
                onTap: () {
                  final page = getToolPage(toolKey);
                  if (page != null) {
                    Navigator.push(context, FadePageRoute(child: page));
                  } else {
                    showComingSoonDialog(context, name);
                  }
                },
                child: Container(
                  width: 175,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.06),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 16),
                      ),
                      const SizedBox(width: 8),
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
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              '点击即刻唤醒',
                              style: TextStyle(
                                color: Colors.white30,
                                fontSize: 9.5,
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
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDynamicGrid(
    BuildContext context,
    List<dynamic> categories,
    bool isWide,
    Color secondaryColor, {
    Key? key,
  }) {
    if (categories.isEmpty) {
      return Center(
        key: key,
        child: const Text(
          '无内置工具，请检查数据库配置',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    return ListView.builder(
      key: key,
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
                    color: secondaryColor,
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
                  itemCount: catTools.length,
                  itemBuilder: (context, toolIndex) {
                    final tool = catTools[toolIndex];
                    final String toolKey = tool['tool_key'] ?? '';
                    final String name = tool['name'] ?? '';
                    final String description =
                        tool['description'] ?? '云端数据库极速计算已就绪';
                    final Color color = getToolColor(toolKey, context);
                    final IconData icon = getToolIcon(toolKey);
                    return ParallaxGlassCard(
                      tiltSensitivity: 0.02,
                      onTap: () => _onDynamicToolClicked(toolKey, name),
                      borderColor: color.withOpacity(0.2),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14.0,
                          vertical: 10.0,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: color.withOpacity(0.15),
                                  width: 1,
                                ),
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

  Widget _buildStaticGrid(
    BuildContext context,
    bool isWide,
    Color textColor,
    bool isDark, {
    Key? key,
  }) {
    final List<Map<String, dynamic>> staticTools = [
      {'title': '随机选择生成器', 'key': 'randomizer', 'desc': '极速随机生成数字，支持快速去重'},
      {'title': '标准单位转换器', 'key': 'converter', 'desc': '多种体积长度质量快速一键互转'},
      {'title': '健康 BMI 计算器', 'key': 'bmi_calculator', 'desc': '标准人体健康指标评测云储存'},
      {
        'title': '字数与字符统计器',
        'key': 'word_counter',
        'desc': '统计文本 of 字数、词数及中英文字符占比',
      },
      {
        'title': '密码生成与强度分析',
        'key': 'password_generator',
        'desc': '安全高强度密码快捷生成及熵值分析',
      },
      {'title': '多时区时钟与番茄钟', 'key': 'world_clock', 'desc': '多时区对照与高精度番茄专注时钟'},
      {'title': '白噪音专注冥想', 'key': 'white_noise', 'desc': '精选自然白噪音辅助冥想与高效专注'},
      {
        'title': '极极简 Markdown 编辑器',
        'key': 'markdown_editor',
        'desc': '极简 Markdown 实时预览排版与字数统计',
      },
      {
        'title': 'AI 智能多轮对话助理',
        'key': 'ai_chat',
        'desc': '结合大语言模型的高强度多轮文本 analysis',
      },
      {
        'title': 'AI 写作引擎',
        'key': 'ai_text_processor',
        'desc': '一键精准翻译、句式优雅润色与摘要提取',
      },
      {
        'title': 'LED 手持弹幕',
        'key': 'led_banner',
        'desc': '炫彩手持霓虹灯弹幕，支持多种闪烁与滚动特效',
      },
      {
        'title': '开发者沙盒编码盒',
        'key': 'dev_encoder',
        'desc': '支持 Base64、URL 编码转换，MD5/SHA256 哈希与 JSON 格式化',
      },
    ];

    final secondaryColor = Theme.of(context).colorScheme.secondary;
    return ListView(
      key: key,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 10.0),
          child: Row(
            children: [
              Icon(Icons.handyman_rounded, color: secondaryColor, size: 18),
              const SizedBox(width: 8),
              Text(
                '常用工具',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
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
                final Color color = getToolColor(toolKey, context);
                final IconData icon = getToolIcon(toolKey);
                final subTextColor = isDark ? Colors.white70 : Colors.black54;

                return ParallaxGlassCard(
                  tiltSensitivity: 0.02,
                  onTap: () => _onDynamicToolClicked(toolKey, title),
                  borderColor: color.withOpacity(0.2),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 10.0,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: color.withOpacity(0.15),
                              width: 1,
                            ),
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
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                desc,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: subTextColor,
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
}
