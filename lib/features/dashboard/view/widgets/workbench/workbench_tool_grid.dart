import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/parallax_glass_card.dart';
import '../../../provider/tools_provider.dart';
import '../dashboard_utils.dart';
import 'dashed_border_painter.dart';
import 'workbench_dialogs.dart';

class WorkbenchToolGrid extends ConsumerWidget {
  final List<String> myToolsKeys;
  final bool isEditingTools;
  final AnimationController wiggleController;
  final bool isWide;
  final void Function(String toolKey, String title) onToolClicked;
  final void Function(List<String> updatedKeys) onToolsReordered;
  final void Function(String toolKey) onToolRemoved;
  final void Function(String toolKey) onToolAdded;
  final VoidCallback onEditModeTriggered;

  const WorkbenchToolGrid({
    super.key,
    required this.myToolsKeys,
    required this.isEditingTools,
    required this.wiggleController,
    required this.isWide,
    required this.onToolClicked,
    required this.onToolsReordered,
    required this.onToolRemoved,
    required this.onToolAdded,
    required this.onEditModeTriggered,
  });

  static const List<String> _masterToolKeys = [
    'randomizer',
    'converter',
    'bmi_calculator',
    'word_counter',
    'password_generator',
    'world_clock',
    'white_noise',
    'markdown_editor',
    'ai_chat',
    'ai_text_processor',
    'led_banner',
    'dev_encoder',
    'daily_board',
    'novel_reader',
  ];

  static const List<Map<String, dynamic>> staticToolsList = [
    {'title': '随机选择生成器', 'key': 'randomizer', 'desc': '极速随机生成数字，支持快速去重'},
    {'title': '标准单位转换器', 'key': 'converter', 'desc': '多种体积长度质量快速一键互转'},
    {'title': '健康 BMI 计算器', 'key': 'bmi_calculator', 'desc': '标准人体健康指标评测云储存'},
    {'title': '字数与字符统计器', 'key': 'word_counter', 'desc': '统计文本字数、词数及中英文字符占比'},
    {
      'title': '密码生成与强度分析',
      'key': 'password_generator',
      'desc': '安全高强度密码快捷生成及熵值分析',
    },
    {'title': '多时区时钟与番茄钟', 'key': 'world_clock', 'desc': '多时区对照与高精度番茄专注时钟'},
    {'title': '白噪音专注冥想', 'key': 'white_noise', 'desc': '精选自然白噪音辅助冥想与高效专注'},
    {
      'title': '极简 Markdown 编辑器',
      'key': 'markdown_editor',
      'desc': '极简 Markdown 实时预览排版与字数统计',
    },
    {'title': 'AI 智能多轮对话助理', 'key': 'ai_chat', 'desc': '结合大语言模型的高强度多轮文本分析'},
    {
      'title': 'AI 写作引擎',
      'key': 'ai_text_processor',
      'desc': '一键精准翻译、句式优雅润色与摘要提取',
    },
    {'title': 'LED 手持弹幕', 'key': 'led_banner', 'desc': '炫彩手持霓虹灯弹幕，支持多种闪烁与滚动特效'},
    {
      'title': '开发者沙盒编码盒',
      'key': 'dev_encoder',
      'desc': '支持 Base64、URL 编码转换，MD5/SHA256 哈希与 JSON 格式化',
    },
    {'title': '今日热闻与卡片工坊', 'key': 'daily_board', 'desc': '60秒读懂世界早报与炫彩卡片一言工坊'},
    {
      'title': '智能去噪小说阅读器',
      'key': 'novel_reader',
      'desc': '支持多源自愈、仿真翻页、TTS听书与密室隔离',
    },
  ];

  Map<String, dynamic>? _getStaticToolDetails(String key) {
    for (final tool in staticToolsList) {
      if (tool['key'] == key) return tool;
    }
    return null;
  }

  bool _isLargeTool(String toolKey) {
    return toolKey == 'ai_chat' ||
        toolKey == 'ai_text_processor' ||
        toolKey == 'novel_reader';
  }

  Widget _buildToolItem({
    required BuildContext context,
    required String toolKey,
    required String title,
    required String description,
    required Color color,
    required IconData icon,
    required double width,
    required bool isLarge,
    required bool isDark,
    required Color textColor,
    required Color subTextColor,
  }) {
    final cardChild = ParallaxGlassCard(
      tiltSensitivity: isEditingTools ? 0.0 : 0.02,
      onTap: isEditingTools ? null : () => onToolClicked(toolKey, title),
      borderColor: color.withOpacity(isDark ? 0.25 : 0.15),
      glowColor: color,
      child: isLarge
          ? Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 10.0,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(isDark ? 0.12 : 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: color.withOpacity(isDark ? 0.2 : 0.1),
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
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            if (toolKey.startsWith('ai_')) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.purpleAccent, color],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'AI',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ] else if (toolKey == 'novel_reader') ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: color.withOpacity(0.3),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  'PRO',
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: subTextColor,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: textColor.withOpacity(0.3),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(isDark ? 0.12 : 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: color.withOpacity(isDark ? 0.2 : 0.1),
                            width: 1,
                          ),
                        ),
                        child: Icon(icon, size: 18, color: color),
                      ),
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 11,
                        color: textColor.withOpacity(0.25),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            height: 1.2,
                            letterSpacing: 0.15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 9.5, color: subTextColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );

    return SizedBox(
      width: width,
      height: isLarge ? 76 : 110,
      child: RepaintBoundary(
        child: _buildReorderableToolCard(
          toolKey: toolKey,
          child: _buildWiggleWrapper(
            child: _buildToolCardWithDeleteBadge(
              toolKey: toolKey,
              cardChild: cardChild,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textColor = theme.brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;
    final isDark = theme.brightness == Brightness.dark;
    final categoriesState = ref.watch(categoriesProvider);

    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 400),
      firstChild: _buildStaticGrid(context, isWide, textColor, isDark),
      secondChild:
          (categoriesState.value != null && categoriesState.value!.isNotEmpty)
          ? _buildDynamicGrid(
              context,
              categoriesState.value!,
              isWide,
              theme.colorScheme.secondary,
            )
          : const SizedBox.shrink(),
      crossFadeState:
          (categoriesState.value == null || categoriesState.value!.isEmpty)
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
    );
  }

  Widget _buildDynamicGrid(
    BuildContext context,
    List<dynamic> categories,
    bool isWide,
    Color secondaryColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    if (categories.isEmpty) {
      return Center(
        child: Text('无内置工具，请检查数据库配置', style: TextStyle(color: subTextColor)),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      padding: const EdgeInsets.only(bottom: 24),
      itemBuilder: (context, catIndex) {
        final category = categories[catIndex];
        final List<dynamic> catToolsRaw = category['tools'] ?? [];
        final List<dynamic> catTools =
            catToolsRaw
                .where((t) => myToolsKeys.contains(t['tool_key']))
                .toList()
              ..sort((a, b) {
                final idxA = myToolsKeys.indexOf(a['tool_key']);
                final idxB = myToolsKeys.indexOf(b['tool_key']);
                return idxA.compareTo(idxB);
              });
        final List<String> catDisabledTools = catToolsRaw
            .map((t) => t['tool_key'] as String)
            .where((key) => !myToolsKeys.contains(key))
            .toList();

        if (catTools.isEmpty && catDisabledTools.isEmpty)
          return const SizedBox();
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
                final double maxWidth = constraints.maxWidth;
                final crossAxisCount = _resolveCrossAxisCount(maxWidth, isWide);

                const double spacing = 12;
                final double normalWidth =
                    (maxWidth - (crossAxisCount - 1) * spacing) /
                    crossAxisCount;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    ...catTools.map((tool) {
                      final String toolKey = tool['tool_key'] ?? '';
                      final String name = tool['name'] ?? '';
                      final String description =
                          tool['description'] ?? '云端数据库极速计算已就绪';
                      final Color color = getToolColor(toolKey, context);
                      final IconData icon = getToolIcon(toolKey);
                      final isLarge = _isLargeTool(toolKey);
                      final double itemWidth = isLarge
                          ? (crossAxisCount == 2
                                ? maxWidth
                                : (2 * normalWidth + spacing))
                          : normalWidth;

                      return _buildToolItem(
                        context: context,
                        toolKey: toolKey,
                        title: name,
                        description: description,
                        color: color,
                        icon: icon,
                        width: itemWidth,
                        isLarge: isLarge,
                        isDark: isDark,
                        textColor: textColor,
                        subTextColor: subTextColor,
                      );
                    }),
                    _buildAddToolCard(
                      context,
                      disabledToolsList: catDisabledTools,
                      width: normalWidth,
                    ),
                  ],
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
    bool isDark,
  ) {
    final List<Map<String, dynamic>> activeStaticTools = [];
    for (final key in myToolsKeys) {
      final details = _getStaticToolDetails(key);
      if (details != null) {
        activeStaticTools.add(details);
      }
    }

    final List<String> disabledStaticTools = _masterToolKeys
        .where((key) => !myToolsKeys.contains(key))
        .toList();

    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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
            final double maxWidth = constraints.maxWidth;
            final crossAxisCount = _resolveCrossAxisCount(maxWidth, isWide);

            const double spacing = 12;
            final double normalWidth =
                (maxWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                ...activeStaticTools.map((tool) {
                  final String toolKey = tool['key'];
                  final String title = tool['title'];
                  final String desc = tool['desc'];
                  final Color color = getToolColor(toolKey, context);
                  final IconData icon = getToolIcon(toolKey);
                  final isLarge = _isLargeTool(toolKey);
                  final double itemWidth = isLarge
                      ? (crossAxisCount == 2
                            ? maxWidth
                            : (2 * normalWidth + spacing))
                      : normalWidth;

                  return _buildToolItem(
                    context: context,
                    toolKey: toolKey,
                    title: title,
                    description: desc,
                    color: color,
                    icon: icon,
                    width: itemWidth,
                    isLarge: isLarge,
                    isDark: isDark,
                    textColor: textColor,
                    subTextColor: subTextColor,
                  );
                }),
                _buildAddToolCard(
                  context,
                  disabledToolsList: disabledStaticTools,
                  width: normalWidth,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildWiggleWrapper({required Widget child}) {
    if (!isEditingTools) return child;
    return AnimatedBuilder(
      animation: wiggleController,
      builder: (context, child) {
        final angle = sin(wiggleController.value * 2 * pi) * 0.015;
        return Transform.rotate(angle: angle, child: child);
      },
      child: child,
    );
  }

  int _resolveCrossAxisCount(double maxWidth, bool isWide) {
    if (isWide) return maxWidth > 1100 ? 3 : 2;
    if (maxWidth > 620) return 3;
    if (maxWidth > 340) return 2;
    return 1;
  }

  Widget _buildReorderableToolCard({
    required String toolKey,
    required Widget child,
  }) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data != toolKey,
      onAcceptWithDetails: (details) {
        final draggedKey = details.data;
        final oldIndex = myToolsKeys.indexOf(draggedKey);
        final newIndex = myToolsKeys.indexOf(toolKey);
        if (oldIndex != -1 && newIndex != -1) {
          final updatedKeys = List<String>.from(myToolsKeys);
          updatedKeys.removeAt(oldIndex);
          updatedKeys.insert(newIndex, draggedKey);
          onToolsReordered(updatedKeys);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isHovered
                ? Border.all(color: Colors.pinkAccent, width: 2)
                : null,
          ),
          child: GestureDetector(
            onTap: isEditingTools ? () {} : null,
            child: LongPressDraggable<String>(
              data: toolKey,
              delay: isEditingTools
                  ? Duration.zero
                  : const Duration(milliseconds: 500),
              onDragStarted: () {
                if (!isEditingTools) {
                  onEditModeTriggered();
                }
              },
              feedback: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: 220,
                  height: 90,
                  child: Opacity(opacity: 0.8, child: child),
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.25, child: child),
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolCardWithDeleteBadge({
    required String toolKey,
    required Widget cardChild,
  }) {
    if (!isEditingTools) return cardChild;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        cardChild,
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: () => onToolRemoved(toolKey),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddToolCard(
    BuildContext context, {
    required List<String> disabledToolsList,
    required double width,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black54;

    return SizedBox(
      width: width,
      height: 110,
      child: ParallaxGlassCard(
        tiltSensitivity: 0.01,
        onTap: () {
          if (disabledToolsList.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('💡 该分类下的所有工具都已启用！'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
          WorkbenchDialogs.showAddToolsDialog(
            context,
            disabledToolsList,
            onToolAdded,
          );
        },
        borderColor: Colors.transparent,
        child: CustomPaint(
          painter: DashedBorderPainter(
            color: Colors.pinkAccent.withOpacity(0.3),
            borderRadius: 24.0,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.005)
                  : Colors.black.withOpacity(0.005),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 12.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.pinkAccent.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 22,
                      color: Colors.pinkAccent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '添加工具',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
