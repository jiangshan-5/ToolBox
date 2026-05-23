import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/dynamic_effects.dart';
import '../../provider/bmi_provider.dart';

class BmiMacrosSandboxPanel extends ConsumerWidget {
  const BmiMacrosSandboxPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final faintTextColor = isDark ? Colors.white38 : Colors.black38;
    final borderDividerColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

    final state = ref.watch(bmiProvider);
    final notifier = ref.read(bmiProvider.notifier);

    final proteinPercent = state.proteinPercent;
    final carbPercent = state.carbPercent;
    final fatPercent = state.fatPercent;

    final total = proteinPercent + carbPercent + fatPercent;
    final isBalanced = total == 100;

    final presets = [
      {'title': '均衡饮食配比', 'p': 30, 'c': 40, 'f': 30},
      {'title': '极低碳生酮', 'p': 20, 'c': 5, 'f': 75},
      {'title': '高蛋白增肌', 'p': 40, 'c': 40, 'f': 20},
    ];

    return Container(
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
              const Icon(Icons.restaurant_menu_rounded, color: Color(0xFFFF8C00), size: 18),
              const SizedBox(width: 8),
              Text(
                '三大营养素分配比重沙盒',
                style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: presets.map((p) {
                final isCurrent = proteinPercent == p['p'] &&
                    carbPercent == p['c'] &&
                    fatPercent == p['f'];
                return ScaleOnTap(
                  onTap: () => notifier.setMacrosRatios(p['p'] as int, p['c'] as int, p['f'] as int),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCurrent ? const Color(0xFFFF8C00).withOpacity(0.2) : Colors.white.withOpacity(0.01),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isCurrent ? const Color(0xFFFF8C00).withOpacity(0.6) : borderDividerColor),
                    ),
                    child: Center(
                      child: Text(
                        p['title'] as String,
                        style: TextStyle(
                          color: isCurrent ? const Color(0xFFFF8C00) : (isDark ? Colors.white54 : Colors.black54),
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          _buildMacroVisualBar(isDark, proteinPercent, carbPercent, fatPercent),
          const SizedBox(height: 16),
          _buildMacroSliderRow(
            isDark: isDark,
            subTextColor: subTextColor,
            label: '🍗 蛋白质 (Protein %)',
            value: proteinPercent,
            color: const Color(0xFFFF8C00),
            onChanged: (v) => notifier.setMacrosRatios(v, carbPercent, fatPercent),
          ),
          _buildMacroSliderRow(
            isDark: isDark,
            subTextColor: subTextColor,
            label: '🍞 碳水化合物 (Carbs %)',
            value: carbPercent,
            color: const Color(0xFF00E5FF),
            onChanged: (v) => notifier.setMacrosRatios(proteinPercent, v, fatPercent),
          ),
          _buildMacroSliderRow(
            isDark: isDark,
            subTextColor: subTextColor,
            label: '🥑 脂肪 (Fats %)',
            value: fatPercent,
            color: const Color(0xFF00E676),
            onChanged: (v) => notifier.setMacrosRatios(proteinPercent, carbPercent, v),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('配比占比总和:', style: TextStyle(color: faintTextColor, fontSize: 12)),
              Text(
                '$total% / 100%',
                style: TextStyle(
                  color: isBalanced ? const Color(0xFF00E676) : const Color(0xFFFF5252),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroVisualBar(bool isDark, int protein, int carb, int fat) {
    final total = protein + carb + fat;
    if (total == 0) return const SizedBox.shrink();

    final pWeight = protein / total;
    final cWeight = carb / total;
    final fWeight = fat / total;

    return Container(
      height: 14,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          if (protein > 0)
            Expanded(
              flex: (pWeight * 100).toInt(),
              child: Container(
                color: const Color(0xFFFF8C00),
              ),
            ),
          if (carb > 0)
            Expanded(
              flex: (cWeight * 100).toInt(),
              child: Container(
                color: const Color(0xFF00E5FF),
              ),
            ),
          if (fat > 0)
            Expanded(
              flex: (fWeight * 100).toInt(),
              child: Container(
                color: const Color(0xFF00E676),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMacroSliderRow({
    required bool isDark,
    required Color subTextColor,
    required String label,
    required int value,
    required Color color,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: subTextColor, fontSize: 12)),
              Text('$value%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
              thumbColor: color,
              overlayColor: color.withOpacity(0.15),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: (v) => onChanged(v.toInt()),
            ),
          ),
        ],
      ),
    );
  }
}
