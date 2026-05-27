import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

import '../../../../../core/providers/pipeline_provider.dart';
import '../../../../../core/widgets/pipeline_automation_player_screen.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/providers/api_config_provider.dart';
import '../../../../auth/provider/auth_provider.dart';
import '../../../provider/tools_provider.dart';
import '../dashboard_utils.dart';

class WorkbenchDialogs {
  WorkbenchDialogs._();

  static Map<String, dynamic>? _getStaticToolDetails(String key) {
    const List<Map<String, dynamic>> staticTools = [
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
        'desc': '极极简 Markdown 实时预览排版与字数统计',
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
    for (final tool in staticTools) {
      if (tool['key'] == key) return tool;
    }
    return null;
  }

  static void showPipelineLaunchDialog(
    BuildContext context,
    WidgetRef ref,
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

  static void showCustomWorkflowDesignerDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController(
      text: '自定义流水链 #${Random().nextInt(900) + 100}',
    );
    final descController = TextEditingController();

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

                        Text(
                          '⛓️ 当前处理链条流向顺序 (拖拽换位排序/点击关闭移除)',
                          style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 70,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.06),
                            ),
                          ),
                          child: chosenSteps.isEmpty
                              ? Center(
                                  child: Text(
                                    '请点击上方工具搭建您的流水链条',
                                    style: TextStyle(color: hintTextColor, fontSize: 12),
                                  ),
                                )
                              : ReorderableListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  buildDefaultDragHandles: true,
                                  onReorder: (oldIndex, newIndex) {
                                    setDialogState(() {
                                      if (newIndex > oldIndex) {
                                        newIndex -= 1;
                                      }
                                      final item = chosenSteps.removeAt(oldIndex);
                                      chosenSteps.insert(newIndex, item);
                                    });
                                  },
                                  itemCount: chosenSteps.length,
                                  itemBuilder: (context, idx) {
                                    final stepKey = chosenSteps[idx];
                                    final name = getToolChineseName(stepKey);
                                    final col = getToolColor(stepKey, context);

                                    return Container(
                                      key: ValueKey('$stepKey-$idx'),
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: col.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: col.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.drag_indicator_rounded,
                                            color: col.withOpacity(0.6),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: col.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${idx + 1}',
                                              style: TextStyle(
                                                color: col,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            name,
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          GestureDetector(
                                            onTap: () {
                                              setDialogState(() {
                                                chosenSteps.removeAt(idx);
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                color: Colors.redAccent.withOpacity(0.15),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close_rounded,
                                                color: Colors.redAccent,
                                                size: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 20),

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
                                        showPipelineLaunchDialog(
                                          context,
                                          ref,
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

  static void showAddToolsDialog(
    BuildContext context,
    List<String> disabledTools,
    void Function(String toolKey) onToolAdded,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : Colors.black87;
        final subTextColor = isDark ? Colors.white70 : Colors.black54;

        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassCard(
            borderColor: Colors.pinkAccent.withOpacity(0.3),
            glowColor: Colors.pinkAccent,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.pinkAccent.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_circle_outline_rounded, color: Colors.pinkAccent, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '添加工具至主页',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: disabledTools.length,
                        itemBuilder: (context, index) {
                          final toolKey = disabledTools[index];
                          final details = _getStaticToolDetails(toolKey);
                          final name = details != null ? details['title'] : getToolChineseName(toolKey);
                          final desc = details != null ? details['desc'] : '工具';
                          final color = getToolColor(toolKey, context);
                          final icon = getToolIcon(toolKey);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: color.withOpacity(0.15)),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: color.withOpacity(0.1),
                                child: Icon(icon, color: color, size: 20),
                              ),
                              title: Text(
                                name,
                                style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                desc,
                                style: TextStyle(color: subTextColor, fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.add_circle_rounded, color: Colors.pinkAccent),
                                onPressed: () {
                                  onToolAdded(toolKey);
                                  Navigator.pop(context);
                                  final remaining = List<String>.from(disabledTools)..remove(toolKey);
                                  if (remaining.isNotEmpty) {
                                    showAddToolsDialog(context, remaining, onToolAdded);
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('关闭', style: TextStyle(color: subTextColor)),
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
  }
}
