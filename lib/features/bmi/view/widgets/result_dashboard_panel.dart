import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/dynamic_effects.dart';
import '../../provider/bmi_provider.dart';
import '../../../utilities/provider/markdown_editor_provider.dart';
import '../../../utilities/view/markdown_editor_screen.dart';

class BmiResultDashboardPanel extends ConsumerWidget {
  const BmiResultDashboardPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final faintTextColor = isDark ? Colors.white38 : Colors.black38;
    final borderDividerColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

    final state = ref.watch(bmiProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        Row(
          children: [
            Icon(Icons.dashboard_customize_rounded, color: textColor, size: 20),
            const SizedBox(width: 8),
            Text(
              '体征目标与健康诊断仪',
              style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StaggerEntrance(
          index: 0,
          child: PulseGlow(
            color: const Color(0xFFFF007F),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF26103A), Color(0xFF4C0E5A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFFF007F).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text('BMI 身体质量指数', style: TextStyle(color: subTextColor, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text(
                    state.bmi!.toStringAsFixed(1),
                    style: TextStyle(fontSize: 68, fontWeight: FontWeight.bold, color: textColor, letterSpacing: -1),
                  ),
                  const SizedBox(height: 14),
                  _buildBmiGauge(isDark, state.bmi!),
                  const SizedBox(height: 14),
                  Text(
                    state.message,
                    style: TextStyle(color: state.messageColor, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildBmrTdeeCard(
                isDark: isDark,
                subTextColor: subTextColor,
                borderDividerColor: borderDividerColor,
                title: '基础代谢率 (BMR)',
                value: '${state.bmr!.toStringAsFixed(0)} kcal',
                desc: '维持基本生命体征所需的最低卡路里。',
                icon: Icons.flash_on_rounded,
                color: const Color(0xFFFF8C00),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBmrTdeeCard(
                isDark: isDark,
                subTextColor: subTextColor,
                borderDividerColor: borderDividerColor,
                title: '每日总消耗 (TDEE)',
                value: '${state.tdee!.toStringAsFixed(0)} kcal',
                desc: '结合日常活动后，维持体重的实际卡路里消耗。',
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFFF3D00),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderDividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.track_changes_rounded, color: Colors.cyanAccent, size: 18),
                  const SizedBox(width: 8),
                  Text('计划靶点卡路里建议', style: TextStyle(color: subTextColor, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('日建议摄入量:', style: TextStyle(color: faintTextColor, fontSize: 12)),
                  Text(
                    '${state.suggestedCalories!.toStringAsFixed(0)} kcal',
                    style: TextStyle(
                      color: state.suggestedCalories! < state.tdee! ? Colors.cyanAccent : const Color(0xFFFF5252),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: state.suggestedCalories! / 4000.0,
                backgroundColor: isDark ? Colors.white10 : Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(state.suggestedCalories! < state.tdee! ? Colors.cyanAccent : const Color(0xFFFF5252)),
                minHeight: 5,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Icon(Icons.analytics_rounded, color: Color(0xFFFF8C00), size: 18),
            const SizedBox(width: 8),
            Text('三大宏量营养重量指标', style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildNutritionGramCard(
                isDark: isDark,
                subTextColor: subTextColor,
                borderDividerColor: borderDividerColor,
                label: '🍗 蛋白质',
                value: '${state.proteinGrams!.toStringAsFixed(1)} g',
                color: const Color(0xFFFF8C00),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildNutritionGramCard(
                isDark: isDark,
                subTextColor: subTextColor,
                borderDividerColor: borderDividerColor,
                label: '🍞 碳水',
                value: '${state.carbGrams!.toStringAsFixed(1)} g',
                color: const Color(0xFF00E5FF),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildNutritionGramCard(
                isDark: isDark,
                subTextColor: subTextColor,
                borderDividerColor: borderDividerColor,
                label: '🥑 脂肪',
                value: '${state.fatGrams!.toStringAsFixed(1)} g',
                color: const Color(0xFF00E676),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ScaleOnTap(
          onTap: () => _handleSaveNotebook(context, ref, state),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF007F), Color(0xFFFF5E62)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF007F).withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '保存健康报告至笔记本',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBmiGauge(bool isDark, double bmi) {
    double progress = (bmi - 15.0) / (35.0 - 15.0);
    progress = progress.clamp(0.0, 1.0);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: isDark ? Colors.white10 : Colors.black12,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('15.0 (偏瘦)', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10)),
            Text('24.0 (正常)', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 10, fontWeight: FontWeight.bold)),
            Text('35.0 (肥胖)', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _buildBmrTdeeCard({
    required bool isDark,
    required Color subTextColor,
    required Color borderDividerColor,
    required String title,
    required String value,
    required String desc,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.015) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderDividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 9.5, height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionGramCard({
    required bool isDark,
    required Color subTextColor,
    required Color borderDividerColor,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.01) : Colors.black.withOpacity(0.015),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderDividerColor),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: subTextColor, fontSize: 10)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _handleSaveNotebook(BuildContext context, WidgetRef ref, BmiState state) {
    final report = '''# 🩺 Body Biometric & Macronutrients Report
- **体征检测年龄**: ${state.age} 岁
- **性别分类**: ${state.gender == 'male' ? '男性 (Male)' : '女性 (Female)'}
- **身体质量指数 (BMI)**: ${state.bmi!.toStringAsFixed(1)} (${state.message})
- **基础代谢率 (BMR)**: ${state.bmr!.toStringAsFixed(0)} kcal
- **日建议消耗量 (TDEE)**: ${state.tdee!.toStringAsFixed(0)} kcal
- **每日靶向卡路里推荐**: ${state.suggestedCalories!.toStringAsFixed(0)} kcal
- **宏量营养配比方案**: 蛋白质 ${state.proteinPercent}% / 碳水 ${state.carbPercent}% / 脂肪 ${state.fatPercent}%
- **宏量摄入指标克数**:
  - 🍗 蛋白质: ${state.proteinGrams!.toStringAsFixed(1)} g
  - 🍞 碳水化合物: ${state.carbGrams!.toStringAsFixed(1)} g
  - 🥑 脂肪: ${state.fatGrams!.toStringAsFixed(1)} g
''';

    ref.read(markdownEditorCacheProvider.notifier).appendNote(report);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('健康报告已成功保存至本地 Markdown 笔记本'),
        backgroundColor: const Color(0xFF0D0A26),
        action: SnackBarAction(
          label: '去看看',
          textColor: Colors.purpleAccent,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MarkdownEditorScreen()),
            );
          },
        ),
      ),
    );
  }
}
