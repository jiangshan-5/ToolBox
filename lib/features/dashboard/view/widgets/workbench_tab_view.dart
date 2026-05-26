import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/widgets/parallax_glass_card.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/pipeline_automation_player_screen.dart';
import '../../../../core/providers/pipeline_provider.dart';
import '../../provider/tools_provider.dart';
import '../../../auth/provider/auth_provider.dart';
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
        _buildPipelineSection(context),
        const SizedBox(height: 12),
        _buildRecentlyUsedSection(context, primaryColor),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(Icons.grid_view_rounded, color: primaryColor, size: 16),
              const SizedBox(width: 8),
              Text(
                '全部工具分类库',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.06),
        ),
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
                  style: TextStyle(
                    color: textColor,
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
                    Text(
                      '专属黄金加密节点 · 正常连接',
                      style: TextStyle(color: subTextColor, fontSize: 11),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black45,
                    fontSize: 10,
                  ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final faintTextColor = isDark ? Colors.white30 : Colors.black45;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(Icons.history_rounded, color: primaryColor, size: 16),
              const SizedBox(width: 8),
              Text(
                '最近使用的工具',
                style: TextStyle(
                  color: subTextColor,
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
                    color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
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
                              style: TextStyle(
                                color: textColor,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '点击即刻唤醒',
                              style: TextStyle(
                                color: faintTextColor,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    if (categories.isEmpty) {
      return Center(
        key: key,
        child: Text(
          '无内置工具，请检查数据库配置',
          style: TextStyle(color: subTextColor),
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
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    description,
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
      {
        'title': '今日热闻与卡片工坊',
        'key': 'daily_board',
        'desc': '60秒读懂世界早报与炫彩卡片一言工坊',
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

  Widget _buildPipelineSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    final savedWorkflowsAsync = ref.watch(savedWorkflowsProvider);

    final List<Widget> cards = [
      _buildCreateCustomPipelineCard(context),
      _buildPipelineCard(
        context,
        title: '内容精修流水链',
        description: '字数 ➔ AI写作 ➔ MD编辑器',
        steps: ['word_counter', 'ai_text_processor', 'markdown_editor'],
        icon: Icons.auto_awesome_motion_rounded,
        color: Colors.purpleAccent,
      ),
      _buildPipelineCard(
        context,
        title: '决策投屏炫彩链',
        description: '随机决策 ➔ LED手持弹幕',
        steps: ['randomizer', 'led_banner'],
        icon: Icons.casino_rounded,
        color: Colors.orangeAccent,
      ),
      _buildPipelineCard(
        context,
        title: '开发沙盒数据链',
        description: '字数统计 ➔ 开发者编码盒',
        steps: ['word_counter', 'dev_encoder'],
        icon: Icons.terminal_rounded,
        color: Colors.cyanAccent,
      ),
    ];

    savedWorkflowsAsync.whenOrNull(
      data: (workflows) {
        for (final workflow in workflows) {
          cards.add(
            _buildCustomPipelineCard(
              context,
              workflow: workflow,
            ),
          );
        }
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Colors.purpleAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                '智能工具工作流车间',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: cards,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomPipelineCard(
    BuildContext context, {
    required SavedWorkflow workflow,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final color = Colors.greenAccent; // Custom workflows get premium success color
    final icon = Icons.save_as_rounded; // Save icon indicating it's a saved workflow

    // Assemble step names in Chinese for the description
    final String description = workflow.description != null && workflow.description!.isNotEmpty
        ? workflow.description!
        : workflow.steps.map((key) => getToolChineseName(key)).join(' ➔ ');

    return GestureDetector(
      onTap: () => _showPipelineLaunchDialog(context, workflow.name, workflow.steps, color),
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withOpacity(0.2),
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
                border: Border.all(
                  color: color.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    workflow.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ),
            // Dynamic delete button
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent.withOpacity(0.8),
                size: 18,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () async {
                final bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => Dialog(
                    backgroundColor: Colors.transparent,
                    child: GlassCard(
                      borderColor: Colors.redAccent.withOpacity(0.3),
                      glowColor: Colors.redAccent,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 40),
                            const SizedBox(height: 16),
                            const Text(
                              '确认删除工作流？',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '你确定要从云端删除自定义工作流 "${workflow.name}" 吗？该操作无法恢复。',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: const Text('取消', style: TextStyle(color: Colors.white70)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: const Text(
                                      '确认删除',
                                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );

                if (confirm == true) {
                  try {
                    final dio = ref.read(apiClientProvider).instance;
                    await dio.delete('/tools/workflows/${workflow.id}');
                    ref.invalidate(savedWorkflowsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✨ 自定义工作流已成功从云端删除'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ 删除失败: $e'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPipelineCard(
    BuildContext context, {
    required String title,
    required String description,
    required List<String> steps,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return GestureDetector(
      onTap: () => _showPipelineLaunchDialog(context, title, steps, color),
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: color, size: 20),
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
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPipelineLaunchDialog(
    BuildContext context,
    String pipelineName,
    List<String> steps,
    Color themeColor,
  ) {
    bool autoRun = true;
    final TextEditingController inputController = TextEditingController(
      text: pipelineName == '决策投屏炫彩链'
          ? '今天吃什么？ 汉堡 披萨 饺子 面条 烤肉'
          : 'Cyber Toolbox 极致美学工具箱全新版发布！包含多种超赞功能！',
    );

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : Colors.black87;
        final subTextColor = isDark ? Colors.white70 : Colors.black54;
        final hintTextColor = isDark ? Colors.white24 : Colors.black26;

        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassCard(
            borderColor: themeColor.withOpacity(0.3),
            glowColor: themeColor,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: themeColor.withOpacity(0.3),
                          ),
                        ),
                        child: Icon(Icons.bolt_rounded, color: themeColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          pipelineName,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '⚡ 流水线步骤链条预览',
                    style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(steps.length, (idx) {
                      final name = getToolChineseName(steps[idx]);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${idx + 1}',
                              style: TextStyle(
                                color: themeColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              name,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '📥 输入初始流转数据',
                    style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                      ),
                    ),
                    child: TextField(
                      controller: inputController,
                      maxLines: 4,
                      style: TextStyle(color: textColor, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: '请输入初始阶段文本数据...',
                        hintStyle: TextStyle(color: hintTextColor, fontSize: 13),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Auto Run Toggle Switch
                  StatefulBuilder(
                    builder: (context, setDialogState) {
                      final theme = Theme.of(context);
                      final isDark = theme.brightness == Brightness.dark;
                      final tColor = isDark ? Colors.white : Colors.black87;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: themeColor.withOpacity(0.15),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.rocket_launch_rounded,
                                  color: themeColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '🤖 启用无人值守全自动运算',
                                  style: TextStyle(
                                    color: tColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: autoRun,
                              activeColor: themeColor,
                              onChanged: (val) {
                                setDialogState(() {
                                  autoRun = val;
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.12),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            '取消',
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              colors: [
                                themeColor,
                                themeColor.withBlue(255),
                              ],
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              if (autoRun) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PipelineAutomationPlayerScreen(
                                      steps: steps,
                                      initialInput: inputController.text,
                                    ),
                                  ),
                                );
                              } else {
                                ref.read(pipelineSessionProvider.notifier).startSession(
                                      steps: steps,
                                      initialInput: inputController.text,
                                      context: context,
                                    );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              '⚡ 启动流水线',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCreateCustomPipelineCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return GestureDetector(
      onTap: () => _showCustomWorkflowDesignerDialog(context),
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.pinkAccent.withOpacity(0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.pinkAccent.withOpacity(0.35),
            width: 1.5,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.pinkAccent.withOpacity(0.08),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.pinkAccent.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.pinkAccent.withOpacity(0.3),
                ),
              ),
              child: const Icon(Icons.add_to_photos_rounded, color: Colors.pinkAccent, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '🎨 自定义工作流工坊',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '自由搭配各种沙盒工具链',
                    style: TextStyle(
                      color: subTextColor,
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
  }

  void _showCustomWorkflowDesignerDialog(BuildContext context) {
    final nameController = TextEditingController(
      text: '自定义流水链 #${Random().nextInt(900) + 100}',
    );
    final descController = TextEditingController();
    
    // Checklist of available tool keys
    final List<String> availableTools = [
      'word_counter',
      'ai_text_processor',
      'markdown_editor',
      'randomizer',
      'led_banner',
      'dev_encoder',
      'bmi_calculator',
      'converter',
    ];
    
    List<String> chosenSteps = [];
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final textColor = isDark ? Colors.white : Colors.black87;
            final subTextColor = isDark ? Colors.white70 : Colors.black54;
            final hintTextColor = isDark ? Colors.white24 : Colors.black26;
            final primaryColor = Theme.of(context).colorScheme.primary;

            return Dialog(
              backgroundColor: Colors.transparent,
              child: GlassCard(
                borderColor: Colors.pinkAccent.withOpacity(0.3),
                glowColor: Colors.pinkAccent,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dialog Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.pinkAccent.withOpacity(0.12),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.pinkAccent.withOpacity(0.3)),
                              ),
                              child: const Icon(Icons.palette_rounded, color: Colors.pinkAccent, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '零代码流水线工坊',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Form Name
                        Text(
                          '📝 工作流名称',
                          style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                            ),
                          ),
                          child: TextField(
                            controller: nameController,
                            style: TextStyle(color: textColor, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: '请输入自定义工作流名称...',
                              hintStyle: TextStyle(color: hintTextColor, fontSize: 13),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Tool Library Scroll
                        Text(
                          '🛠️ 选取可用工具加入链条 (点击添加)',
                          style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 72,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: availableTools.length,
                            itemBuilder: (context, index) {
                              final key = availableTools[index];
                              final name = getToolChineseName(key);
                              final icon = getToolIcon(key);
                              final col = getToolColor(key, context);

                              return GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    if (chosenSteps.length < 5) {
                                      chosenSteps.add(key);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('⚠️ 流水线最大支持5个步骤组合'),
                                          backgroundColor: Colors.orangeAccent,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  });
                                },
                                child: Container(
                                  width: 100,
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: col.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: col.withOpacity(0.2)),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(icon, color: col, size: 18),
                                      const SizedBox(height: 4),
                                      Text(
                                        name.substring(0, min(name.length, 5)),
                                        style: TextStyle(color: textColor, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Current Flow Sequence
                        Text(
                          '⛓️ 当前处理链条流向顺序 (点击节点移除)',
                          style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.04)),
                          ),
                          child: chosenSteps.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      '请点击上方工具搭建您的流水链条',
                                      style: TextStyle(color: hintTextColor, fontSize: 12),
                                    ),
                                  ),
                                )
                              : Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: List.generate(chosenSteps.length, (idx) {
                                    final stepKey = chosenSteps[idx];
                                    final name = getToolChineseName(stepKey);
                                    final col = getToolColor(stepKey, context);

                                    return GestureDetector(
                                      onTap: () {
                                        setDialogState(() {
                                          chosenSteps.removeAt(idx);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: col.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: col.withOpacity(0.3)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${idx + 1}',
                                              style: TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              name,
                                              style: TextStyle(color: textColor, fontSize: 11),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(Icons.close_rounded, color: textColor.withOpacity(0.5), size: 10),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                        ),
                        const SizedBox(height: 20),

                        // Action Buttons Row
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(color: Colors.white.withOpacity(0.15)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text('取消', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: chosenSteps.isEmpty
                                    ? null
                                    : () {
                                        Navigator.pop(context);
                                        _showPipelineLaunchDialog(
                                          context,
                                          nameController.text.trim(),
                                          chosenSteps,
                                          Colors.pinkAccent,
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pinkAccent,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text(
                                  '⚡ 立即运行',
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    colors: chosenSteps.isEmpty || isSaving
                                        ? [Colors.grey, Colors.grey]
                                        : [Colors.greenAccent, Colors.tealAccent],
                                  ),
                                ),
                                child: ElevatedButton(
                                  onPressed: chosenSteps.isEmpty || isSaving
                                      ? null
                                      : () async {
                                          final name = nameController.text.trim();
                                          if (name.isEmpty) return;

                                          setDialogState(() {
                                            isSaving = true;
                                          });

                                          try {
                                            final dio = ref.read(apiClientProvider).instance;
                                            await dio.post('/tools/workflows', data: {
                                              'name': name,
                                              'description': descController.text.trim().isEmpty ? null : descController.text.trim(),
                                              'steps': chosenSteps,
                                            });

                                            ref.invalidate(savedWorkflowsProvider);

                                            if (context.mounted) {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('✨ 自定义设计流水线已保存至云端车间！'),
                                                  backgroundColor: Colors.green,
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            setDialogState(() {
                                              isSaving = false;
                                            });
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('❌ 保存工作流失败: $e'),
                                                  backgroundColor: Colors.redAccent,
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: isSaving
                                      ? const SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                          ),
                                        )
                                      : const Text(
                                          '💾 存入车间',
                                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
