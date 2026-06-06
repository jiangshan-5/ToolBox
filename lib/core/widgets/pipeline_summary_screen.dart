import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dashboard/view/widgets/dashboard_utils.dart';
import '../../features/auth/provider/auth_provider.dart';
import '../providers/pipeline_provider.dart';
import '../widgets/glass_card.dart';
import 'dynamic_background.dart';

class PipelineSummaryScreen extends ConsumerWidget {
  final List<String> steps;
  final Map<int, String> inputs;
  final Map<int, String> outputs;

  const PipelineSummaryScreen({
    super.key,
    required this.steps,
    required this.inputs,
    required this.outputs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      body: Stack(
        children: [
          // Cyberpunk Background Adaptive Grid/Gradient
          const DynamicBackground(child: SizedBox.expand()),
          SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                const SizedBox(height: 20),
                // Glowing Celebration Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withOpacity(0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.cyanAccent.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withOpacity(0.15),
                              blurRadius: 30,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.task_alt_rounded,
                          color: Colors.cyanAccent,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '⚡ 智能流水线执行完毕 🏁',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '恭喜！所有关联步骤已被完整且准确的处理完毕',
                        style: TextStyle(color: subTextColor.withOpacity(0.6), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Pipeline Step Cards List
                ...List.generate(steps.length, (index) {
                  final toolKey = steps[index];
                  final toolName = getToolChineseName(toolKey);
                  final icon = getToolIcon(toolKey);
                  final color = getToolColor(toolKey, context);
                  final input = inputs[index] ?? '';
                  final output = outputs[index] ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: GlassCard(
                      borderColor: color.withOpacity(0.15),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: color.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Icon(icon, color: color, size: 16),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '步骤 ${index + 1}: $toolName',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                                    ),
                                  ),
                                  child: const Text(
                                    'SUCCESS',
                                    style: TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Input section
                            Text(
                              '📥 阶段输入数据',
                              style: TextStyle(color: subTextColor, fontSize: 10),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                                ),
                              ),
                              child: Text(
                                input.isEmpty ? '[空文本]' : input,
                                style: TextStyle(
                                  color: isDark ? Colors.white60 : Colors.black87,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Output section
                            Text(
                              '📤 阶段输出数据',
                              style: TextStyle(color: subTextColor, fontSize: 10),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: color.withOpacity(0.15),
                                ),
                              ),
                              child: Text(
                                output.isEmpty ? '[空文本]' : output,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 16),
                
                // Save Workflow Button (Premium / Dynamic Conversion Driver)
                Builder(
                  builder: (context) {
                    final auth = ref.watch(authProvider);
                    final isRegisteredUser = auth.isAuthenticated && auth.email != null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: GestureDetector(
                        onTap: () {
                          if (isRegisteredUser) {
                            _showSaveWorkflowDialog(context, ref);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🔒 请先在主页登录以使用云端工作流保存功能'),
                                backgroundColor: Colors.orange,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isRegisteredUser
                                ? Colors.greenAccent.withOpacity(0.08)
                                : (isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isRegisteredUser
                                  ? Colors.greenAccent.withOpacity(0.25)
                                  : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
                              width: 1.2,
                            ),
                            boxShadow: isRegisteredUser
                                ? [
                                    BoxShadow(
                                      color: Colors.greenAccent.withOpacity(0.1),
                                      blurRadius: 12,
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isRegisteredUser ? Icons.save_as_rounded : Icons.lock_outline_rounded,
                                color: isRegisteredUser ? Colors.greenAccent : subTextColor.withOpacity(0.6),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isRegisteredUser ? '💾 另存为自定义工作流' : '🔒 登录以解锁保存工作流功能',
                                style: TextStyle(
                                  color: isRegisteredUser ? Colors.greenAccent : subTextColor.withOpacity(0.6),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Assemble all outputs into a single clean summary report
                          final List<String> report = [];
                          for (int i = 0; i < steps.length; i++) {
                            final name = getToolChineseName(steps[i]);
                            final out = outputs[i] ?? '';
                            report.add('【第 ${i + 1} 步: $name】\n$out');
                          }
                          Clipboard.setData(
                            ClipboardData(text: report.join('\n\n')),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✨ 已成功打包复制整个流水线链条数据'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7B2FBE), Color(0xFF5C4AE8)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purpleAccent.withOpacity(0.2),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.copy_all_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Text(
                                '打包复制链数据',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.home_max_rounded,
                                color: textColor,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '返回工作台',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSaveWorkflowDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController(
      text: '我的自定义工作流 ${DateTime.now().toString().substring(0, 16)}',
    );
    final descController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final textColor = isDark ? Colors.white : Colors.black87;
            final subTextColor = isDark ? Colors.white70 : Colors.black54;
            final hintTextColor = isDark ? Colors.white24 : Colors.black26;

            return Dialog(
              backgroundColor: Colors.transparent,
              child: GlassCard(
                borderColor: Colors.greenAccent.withOpacity(0.3),
                glowColor: Colors.greenAccent,
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
                              color: Colors.greenAccent.withOpacity(0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.greenAccent.withOpacity(0.3),
                              ),
                            ),
                            child: const Icon(Icons.save_as_rounded, color: Colors.greenAccent, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '另存为自定义工作流',
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
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                          ),
                        ),
                        child: TextField(
                          controller: nameController,
                          style: TextStyle(color: textColor, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: '请输入工作流名称...',
                            hintStyle: TextStyle(color: hintTextColor, fontSize: 13),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ℹ️ 工作流描述 (可选)',
                        style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                          ),
                        ),
                        child: TextField(
                          controller: descController,
                          maxLines: 2,
                          style: TextStyle(color: textColor, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: '描述一下这个工作流的用途...',
                            hintStyle: TextStyle(color: hintTextColor, fontSize: 13),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSaving ? null : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(
                                  color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.12),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: isSaving
                                      ? [Colors.grey, Colors.grey]
                                      : [
                                          Colors.greenAccent,
                                          Colors.tealAccent,
                                        ],
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        final name = nameController.text.trim();
                                        if (name.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('❌ 工作流名称不能为空'),
                                              backgroundColor: Colors.red,
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                          return;
                                        }

                                        setState(() {
                                          isSaving = true;
                                        });

                                        try {
                                          final dio = ref.read(apiClientProvider).instance;
                                          await dio.post('/tools/workflows', data: {
                                            'name': name,
                                            'description': descController.text.trim().isEmpty ? null : descController.text.trim(),
                                            'steps': steps,
                                          });

                                          ref.invalidate(savedWorkflowsProvider);

                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('✨ 自定义工作流保存成功！可在主页工作流车间调用'),
                                                backgroundColor: Colors.green,
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          setState(() {
                                            isSaving = false;
                                          });
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('❌ 保存工作流失败: $e'),
                                                backgroundColor: Colors.red,
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
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
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
                                        '💾 保存工作流',
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
      },
    );
  }
}
