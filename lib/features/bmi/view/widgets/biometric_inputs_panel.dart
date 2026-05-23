import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/dynamic_effects.dart';
import '../../provider/bmi_provider.dart';

class BmiBiometricInputsPanel extends ConsumerStatefulWidget {
  final TextEditingController heightController;
  final TextEditingController weightController;
  final TextEditingController targetWeightController;

  const BmiBiometricInputsPanel({
    super.key,
    required this.heightController,
    required this.weightController,
    required this.targetWeightController,
  });

  @override
  ConsumerState<BmiBiometricInputsPanel> createState() =>
      _BmiBiometricInputsPanelState();
}

class _BmiBiometricInputsPanelState
    extends ConsumerState<BmiBiometricInputsPanel> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get textColor => isDark ? Colors.white : Colors.black87;
  Color get subTextColor => isDark ? Colors.white70 : Colors.black54;
  Color get faintTextColor => isDark ? Colors.white38 : Colors.black38;
  Color get borderDividerColor =>
      isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bmiProvider);
    final notifier = ref.read(bmiProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUnitSystemToggle(state.isMetric, notifier),
        const SizedBox(height: 16),
        _buildGenderSelector(state.gender, notifier),
        const SizedBox(height: 16),
        _buildBiometricInputs(
          state.isMetric,
          state.age,
          state.activity,
          notifier,
        ),
        const SizedBox(height: 16),
        _buildGoalSandboxConfig(state.isMetric, state.weeklyChange, notifier),
      ],
    );
  }

  Widget _buildUnitSystemToggle(bool isMetric, BmiNotifier notifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '体征测量单位制:',
          style: TextStyle(
            color: subTextColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.015)
                : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderDividerColor),
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            children: [
              _buildUnitTab('公制 (Metric)', isMetric, () {
                if (!isMetric) {
                  notifier.setUnitSystem(true);
                  widget.heightController.clear();
                  widget.weightController.clear();
                }
              }),
              _buildUnitTab('英制 (Imperial)', !isMetric, () {
                if (isMetric) {
                  notifier.setUnitSystem(false);
                  widget.heightController.clear();
                  widget.weightController.clear();
                }
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnitTab(String label, bool isSelected, VoidCallback onTap) {
    return ScaleOnTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? const Color(0xFFFF007F).withOpacity(0.12)
              : Colors.transparent,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFFFF007F)
                : (isDark ? Colors.white38 : Colors.black38),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildGenderSelector(String gender, BmiNotifier notifier) {
    final isMale = gender == 'male';

    return Row(
      children: [
        Expanded(
          child: ScaleOnTap(
            onTap: () => notifier.setGender('male'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: isMale
                    ? LinearGradient(
                        colors: [
                          const Color(0xFF00B0FF).withOpacity(0.12),
                          const Color(0xFF0077FF).withOpacity(0.04),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.01),
                          Colors.white.withOpacity(0.01),
                        ],
                      ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isMale
                      ? const Color(0xFF00B0FF).withOpacity(0.4)
                      : borderDividerColor,
                  width: 1.5,
                ),
                boxShadow: isMale
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00B0FF).withOpacity(0.08),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.male_rounded,
                    color: isMale
                        ? const Color(0xFF00B0FF)
                        : (isDark ? Colors.white38 : Colors.black38),
                    size: 34,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '男 性',
                    style: TextStyle(
                      color: isMale
                          ? const Color(0xFF00B0FF)
                          : (isDark ? Colors.white54 : Colors.black54),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: ScaleOnTap(
            onTap: () => notifier.setGender('female'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: !isMale
                    ? LinearGradient(
                        colors: [
                          const Color(0xFFFF007F).withOpacity(0.12),
                          const Color(0xFFFF5E62).withOpacity(0.04),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.01),
                          Colors.white.withOpacity(0.01),
                        ],
                      ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: !isMale
                      ? const Color(0xFFFF007F).withOpacity(0.4)
                      : borderDividerColor,
                  width: 1.5,
                ),
                boxShadow: !isMale
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF007F).withOpacity(0.08),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.female_rounded,
                    color: !isMale
                        ? const Color(0xFFFF007F)
                        : (isDark ? Colors.white38 : Colors.black38),
                    size: 34,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '女 性',
                    style: TextStyle(
                      color: !isMale
                          ? const Color(0xFFFF007F)
                          : (isDark ? Colors.white54 : Colors.black54),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBiometricInputs(
    bool isMetric,
    int age,
    String activity,
    BmiNotifier notifier,
  ) {
    final heightUnit = isMetric ? 'cm' : 'inch';
    final weightUnit = isMetric ? 'kg' : 'lb';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.02)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderDividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: widget.heightController,
                  label: '当前身高',
                  unit: heightUnit,
                  icon: Icons.height_rounded,
                  color: const Color(0xFFFF007F),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildInputField(
                  controller: widget.weightController,
                  label: '当前体重',
                  unit: weightUnit,
                  icon: Icons.monitor_weight_outlined,
                  color: const Color(0xFFFF007F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '基础新陈代谢年龄:',
                style: TextStyle(color: subTextColor, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF007F).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$age 岁',
                  style: const TextStyle(
                    color: Color(0xFFFF007F),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFFFF007F),
              inactiveTrackColor: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.06),
              thumbColor: const Color(0xFFFF007F),
              overlayColor: const Color(0xFFFF007F).withOpacity(0.15),
              valueIndicatorColor: const Color(0xFFFF007F),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: age.toDouble(),
              min: 5,
              max: 100,
              divisions: 95,
              onChanged: (v) => notifier.setAge(v.toInt()),
            ),
          ),
          const SizedBox(height: 12),
          _buildActivitySelector(activity, notifier),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.015)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderDividerColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          labelText: '$label ($unit)',
          labelStyle: TextStyle(color: faintTextColor, fontSize: 12),
          prefixIcon: Icon(icon, color: color.withOpacity(0.8), size: 18),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildActivitySelector(String activity, BmiNotifier notifier) {
    final activities = ['久坐不动', '轻度活动', '中度运动', '高强度训练', '专业运动员'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('日常活跃系数:', style: TextStyle(color: faintTextColor, fontSize: 12)),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final act = activities[index];
              final isSel = activity == act;
              return ScaleOnTap(
                onTap: () => notifier.setActivity(act),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isSel
                        ? const Color(0xFFFF007F).withOpacity(0.12)
                        : Colors.white.withOpacity(0.01),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSel
                          ? const Color(0xFFFF007F).withOpacity(0.4)
                          : borderDividerColor,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      act,
                      style: TextStyle(
                        color: isSel
                            ? const Color(0xFFFF007F)
                            : (isDark ? Colors.white54 : Colors.black54),
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGoalSandboxConfig(
    bool isMetric,
    double weeklyChange,
    BmiNotifier notifier,
  ) {
    final weightUnit = isMetric ? 'kg' : 'lb';
    final state = ref.watch(bmiProvider);
    final activeGoal = state.activeGoal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.02)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderDividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '健身目标规划:',
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                width: 100,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.015)
                      : Colors.black.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderDividerColor),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: TextFormField(
                  controller: widget.targetWeightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  decoration: InputDecoration(
                    labelText: '目标 ($weightUnit)',
                    labelStyle: TextStyle(color: faintTextColor, fontSize: 8),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildGoalChip(
                '减脂 (Cut)',
                activeGoal == 'cut',
                () => notifier.setGoal('cut'),
              ),
              const SizedBox(width: 8),
              _buildGoalChip(
                '维持 (Maintain)',
                activeGoal == 'maintain',
                () => notifier.setGoal('maintain'),
              ),
              const SizedBox(width: 8),
              _buildGoalChip(
                '增肌 (Bulk)',
                activeGoal == 'bulk',
                () => notifier.setGoal('bulk'),
              ),
            ],
          ),
          if (activeGoal != 'maintain') ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  activeGoal == 'cut' ? '每周减重目标:' : '每周增重目标:',
                  style: TextStyle(color: subTextColor, fontSize: 12),
                ),
                Text(
                  '${weeklyChange.toStringAsFixed(2)} $weightUnit/周',
                  style: const TextStyle(
                    color: Color(0xFFFF007F),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: const Color(0xFFFF007F),
                inactiveTrackColor: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.06),
                thumbColor: const Color(0xFFFF007F),
                overlayColor: const Color(0xFFFF007F).withOpacity(0.15),
                valueIndicatorColor: const Color(0xFFFF007F),
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: weeklyChange,
                min: isMetric ? 0.1 : 0.2,
                max: isMetric ? 1.0 : 2.2,
                onChanged: (v) => notifier.setWeeklyChange(v),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalChip(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: ScaleOnTap(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFF007F).withOpacity(0.12)
                : Colors.white.withOpacity(0.01),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFF007F).withOpacity(0.4)
                  : borderDividerColor,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFFFF007F)
                    : (isDark ? Colors.white54 : Colors.black54),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
