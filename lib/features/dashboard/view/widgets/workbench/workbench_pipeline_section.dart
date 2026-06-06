import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/pipeline_provider.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../auth/provider/auth_provider.dart';
import '../dashboard_utils.dart';
import 'workbench_dialogs.dart';

class WorkbenchPipelineSection extends ConsumerWidget {
  const WorkbenchPipelineSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final savedWorkflowsAsync = ref.watch(savedWorkflowsProvider);

    final List<Widget> cards = [
      _buildCreateCustomPipelineCard(context, ref),
      _buildPipelineCard(
        context,
        ref,
        title: '内容精修流水链',
        description: '字数 ➔ AI写作 ➔ MD编辑器',
        steps: ['word_counter', 'ai_text_processor', 'markdown_editor'],
        icon: Icons.auto_awesome_motion_rounded,
        color: Colors.purpleAccent,
      ),
      _buildPipelineCard(
        context,
        ref,
        title: '决策投屏炫彩链',
        description: '随机决策 ➔ LED手持弹幕',
        steps: ['randomizer', 'led_banner'],
        icon: Icons.casino_rounded,
        color: Colors.orangeAccent,
      ),
      _buildPipelineCard(
        context,
        ref,
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
              ref,
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
    BuildContext context,
    WidgetRef ref, {
    required SavedWorkflow workflow,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final color = Colors.greenAccent; 
    final icon = Icons.save_as_rounded; 

    final String description = workflow.description != null && workflow.description!.isNotEmpty
        ? workflow.description!
        : workflow.steps.map((key) => getToolChineseName(key)).join(' ➔ ');

    return GestureDetector(
      onTap: () => WorkbenchDialogs.showPipelineLaunchDialog(context, ref, workflow.name, workflow.steps, color),
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
    BuildContext context,
    WidgetRef ref, {
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
      onTap: () => WorkbenchDialogs.showPipelineLaunchDialog(context, ref, title, steps, color),
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

  Widget _buildCreateCustomPipelineCard(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return GestureDetector(
      onTap: () => WorkbenchDialogs.showCustomWorkflowDesignerDialog(context, ref),
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
}
