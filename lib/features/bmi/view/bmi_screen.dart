import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/dynamic_effects.dart';
import '../../../core/widgets/dynamic_background.dart';
import '../../../core/storage/local_storage.dart';
import '../provider/bmi_provider.dart';
import '../../utilities/provider/markdown_editor_provider.dart';
import '../../utilities/view/markdown_editor_screen.dart';

/// Sandboxed clinical Body Fitness and Macronutrient Analyzer Screen with premium visual assets
class BmiScreen extends ConsumerStatefulWidget {
  const BmiScreen({super.key});

  @override
  ConsumerState<BmiScreen> createState() => _BmiScreenState();
}

class _BmiScreenState extends ConsumerState<BmiScreen> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _targetWeightController = TextEditingController(text: '70.0');

  Future<void> _handleAnalyze() async {
    final double? h = double.tryParse(_heightController.text.trim());
    final double? w = double.tryParse(_weightController.text.trim());
    final double? tw = double.tryParse(_targetWeightController.text.trim());

    if (h == null || w == null || tw == null || h <= 0 || w <= 0 || tw <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入合理的体征数值（身高、当前体重及目标体重）'),
          backgroundColor: Colors.pinkAccent,
        ),
      );
      return;
    }

    // Set Target Weight dynamically in provider before running analysis
    ref.read(bmiProvider.notifier).setTargetWeight(tw);

    final success = await ref.read(bmiProvider.notifier).runBiometricAnalysis(
      heightInput: h,
      weightInput: w,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('体征分析失败，请检查输入'),
          backgroundColor: Colors.pinkAccent,
        ),
      );
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(bmiProvider.notifier);
    final isCalculating = ref.watch(bmiProvider.select((s) => s.isCalculating));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0714),
      appBar: AppBar(
        title: const Text(
          '体征与宏量营养沙盒',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.8),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF0A0714).withOpacity(0.8), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // Unit System selector
                  Consumer(
                    builder: (context, ref, child) {
                      final isMetric = ref.watch(bmiProvider.select((s) => s.isMetric));
                      return _buildUnitSystemToggle(isMetric, notifier);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Gender selector
                  Consumer(
                    builder: (context, ref, child) {
                      final gender = ref.watch(bmiProvider.select((s) => s.gender));
                      return _buildGenderSelector(gender, notifier);
                    },
                  ),
                  const SizedBox(height: 20),
                  // CARD 1: INPUTS (Isolates biometric slider & inputs changes)
                  HoverGlowCard(
                    glowColor: const Color(0xFFFF007F),
                    child: Consumer(
                      builder: (context, ref, child) {
                        final isMetric = ref.watch(bmiProvider.select((s) => s.isMetric));
                        final age = ref.watch(bmiProvider.select((s) => s.age));
                        final activity = ref.watch(bmiProvider.select((s) => s.activity));
                        return _buildBiometricInputs(isMetric, age, activity, notifier);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // CARD 2: WEIGHT GOALS SANDBOX
                  HoverGlowCard(
                    glowColor: const Color(0xFF00E5FF),
                    child: Consumer(
                      builder: (context, ref, child) {
                        final isMetric = ref.watch(bmiProvider.select((s) => s.isMetric));
                        final weeklyChange = ref.watch(bmiProvider.select((s) => s.weeklyChange));
                        return _buildGoalSandboxConfig(isMetric, weeklyChange, notifier);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // CARD 3: MACRONUTRIENT RATIOS
                  HoverGlowCard(
                    glowColor: const Color(0xFFFF8C00),
                    child: Consumer(
                      builder: (context, ref, child) {
                        final proteinPercent = ref.watch(bmiProvider.select((s) => s.proteinPercent));
                        final carbPercent = ref.watch(bmiProvider.select((s) => s.carbPercent));
                        final fatPercent = ref.watch(bmiProvider.select((s) => s.fatPercent));
                        return _buildMacroSplitsSandbox(proteinPercent, carbPercent, fatPercent, notifier);
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  // RUN SUBMIT BUTTON
                  ScaleOnTap(
                    onTap: isCalculating ? null : _handleAnalyze,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF007F), Color(0xFFFF5E62)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF007F).withOpacity(0.35),
                            blurRadius: 16,
                            spreadRadius: 1,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: Center(
                        child: isCalculating
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text(
                                '开 始 体 征 诊 断',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 3.0,
                                ),
                              ),
                      ),
                    ),
                  ),
                  // RESULTS VIEW (Only rebuilds when target analytical results are computed)
                  Consumer(
                    builder: (context, ref, child) {
                      final state = ref.watch(bmiProvider);
                      if (state.bmi == null) return const SizedBox.shrink();
                      return _buildResultDashboard(state);
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return const DynamicBackground(
      child: SizedBox.expand(),
    );
  }

  Widget _buildUnitSystemToggle(bool isMetric, BmiNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ScaleOnTap(
              onTap: () {
                notifier.toggleSystem(true);
                _targetWeightController.text = '70.0';
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  gradient: isMetric
                      ? LinearGradient(
                          colors: [const Color(0xFFFF007F).withOpacity(0.2), const Color(0xFFFF5E62).withOpacity(0.1)],
                        )
                      : null,
                  color: isMetric ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isMetric ? const Color(0xFFFF007F).withOpacity(0.4) : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Text(
                    '公制系统 (cm / kg)',
                    style: TextStyle(
                      color: isMetric ? const Color(0xFFFF5E62) : Colors.white60,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ScaleOnTap(
              onTap: () {
                notifier.toggleSystem(false);
                _targetWeightController.text = '154.0';
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  gradient: !isMetric
                      ? LinearGradient(
                          colors: [const Color(0xFFFF007F).withOpacity(0.2), const Color(0xFFFF5E62).withOpacity(0.1)],
                        )
                      : null,
                  color: !isMetric ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: !isMetric ? const Color(0xFFFF007F).withOpacity(0.4) : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Text(
                    '英制系统 (inch / lb)',
                    style: TextStyle(
                      color: !isMetric ? const Color(0xFFFF5E62) : Colors.white60,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
                        colors: [const Color(0xFF00B0FF).withOpacity(0.12), const Color(0xFF0077FF).withOpacity(0.04)],
                      )
                    : LinearGradient(
                        colors: [Colors.white.withOpacity(0.01), Colors.white.withOpacity(0.01)],
                      ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isMale ? const Color(0xFF00B0FF).withOpacity(0.4) : Colors.white.withOpacity(0.04),
                  width: 1.5,
                ),
                boxShadow: isMale
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00B0FF).withOpacity(0.08),
                          blurRadius: 10,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Icon(Icons.male_rounded, color: isMale ? const Color(0xFF00B0FF) : Colors.white38, size: 34),
                  const SizedBox(height: 6),
                  Text(
                    '男 性',
                    style: TextStyle(
                      color: isMale ? const Color(0xFF00B0FF) : Colors.white54,
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
                        colors: [const Color(0xFFFF007F).withOpacity(0.12), const Color(0xFFFF5E62).withOpacity(0.04)],
                      )
                    : LinearGradient(
                        colors: [Colors.white.withOpacity(0.01), Colors.white.withOpacity(0.01)],
                      ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: !isMale ? const Color(0xFFFF007F).withOpacity(0.4) : Colors.white.withOpacity(0.04),
                  width: 1.5,
                ),
                boxShadow: !isMale
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF007F).withOpacity(0.08),
                          blurRadius: 10,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Icon(Icons.female_rounded, color: !isMale ? const Color(0xFFFF007F) : Colors.white38, size: 34),
                  const SizedBox(height: 6),
                  Text(
                    '女 性',
                    style: TextStyle(
                      color: !isMale ? const Color(0xFFFF007F) : Colors.white54,
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

  Widget _buildBiometricInputs(bool isMetric, int age, String activity, BmiNotifier notifier) {
    final heightUnit = isMetric ? 'cm' : 'inch';
    final weightUnit = isMetric ? 'kg' : 'lb';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _heightController,
                  label: '当前身高',
                  unit: heightUnit,
                  icon: Icons.height_rounded,
                  color: const Color(0xFFFF007F),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildInputField(
                  controller: _weightController,
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
              const Text('基础新陈代谢年龄:', style: TextStyle(color: Colors.white54, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF007F).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$age 岁',
                  style: const TextStyle(color: Color(0xFFFF007F), fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFFFF007F),
              inactiveTrackColor: Colors.white.withOpacity(0.06),
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
        color: Colors.white.withOpacity(0.015),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        decoration: InputDecoration(
          labelText: '$label ($unit)',
          labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
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
        const Text('日常活跃系数:', style: TextStyle(color: Colors.white38, fontSize: 12)),
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
                    color: isSel ? const Color(0xFFFF007F).withOpacity(0.12) : Colors.white.withOpacity(0.01),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSel ? const Color(0xFFFF007F).withOpacity(0.4) : Colors.white.withOpacity(0.04),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      act,
                      style: TextStyle(
                        color: isSel ? const Color(0xFFFF007F) : Colors.white54,
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

  Widget _buildGoalSandboxConfig(bool isMetric, double weeklyChange, BmiNotifier notifier) {
    final weightUnit = isMetric ? 'kg' : 'lb';
    final changeText = weeklyChange < 0
        ? '📉 每周减重 ${weeklyChange.abs().toStringAsFixed(2)} $weightUnit'
        : '📈 每周增重 ${weeklyChange.toStringAsFixed(2)} $weightUnit';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.track_changes_rounded, color: Color(0xFF00E5FF), size: 18),
              SizedBox(width: 8),
              Text(
                '体重管理目标沙盒',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _targetWeightController,
            label: '终极目标体重',
            unit: weightUnit,
            icon: Icons.flag_rounded,
            color: const Color(0xFF00E5FF),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('每周健康变动期望:', style: TextStyle(color: Colors.white54, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  changeText,
                  style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFF00E5FF),
              inactiveTrackColor: Colors.white.withOpacity(0.06),
              thumbColor: const Color(0xFF00E5FF),
              overlayColor: const Color(0xFF00E5FF).withOpacity(0.15),
              valueIndicatorColor: const Color(0xFF00E5FF),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: weeklyChange,
              min: isMetric ? -1.5 : -3.3,
              max: isMetric ? 1.5 : 3.3,
              divisions: 60,
              onChanged: (v) => notifier.setWeeklyChange(v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroSplitsSandbox(int proteinPercent, int carbPercent, int fatPercent, BmiNotifier notifier) {
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
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.restaurant_menu_rounded, color: Color(0xFFFF8C00), size: 18),
              SizedBox(width: 8),
              Text(
                '三大营养素分配比重沙盒',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14),
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
                      border: Border.all(color: isCurrent ? const Color(0xFFFF8C00).withOpacity(0.6) : Colors.white.withOpacity(0.04)),
                    ),
                    child: Center(
                      child: Text(
                        p['title'] as String,
                        style: TextStyle(
                          color: isCurrent ? const Color(0xFFFF8C00) : Colors.white54,
                          fontSize: 11,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          _buildMacroVisualBar(proteinPercent, carbPercent, fatPercent),
          const SizedBox(height: 16),
          _buildMacroSliderRow(
            label: '🥚 蛋白质 (Protein %)',
            value: proteinPercent,
            color: const Color(0xFFFF8C00),
            onChanged: (v) => notifier.setMacrosRatios(v, carbPercent, fatPercent),
          ),
          _buildMacroSliderRow(
            label: '🍞 碳水化合物 (Carbs %)',
            value: carbPercent,
            color: const Color(0xFF00E5FF),
            onChanged: (v) => notifier.setMacrosRatios(proteinPercent, v, fatPercent),
          ),
          _buildMacroSliderRow(
            label: '🥑 脂肪 (Fats %)',
            value: fatPercent,
            color: const Color(0xFF00E676),
            onChanged: (v) => notifier.setMacrosRatios(proteinPercent, carbPercent, v),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('配比占比总和:', style: TextStyle(color: Colors.white38, fontSize: 12)),
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
          if (!isBalanced) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5252).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFF5252).withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: Color(0xFFFF5252), size: 14),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '营养素能量比重总和必须等于 100% 才能解锁计算。',
                      style: TextStyle(color: Color(0xFFFF5252), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildMacroVisualBar(int protein, int carb, int fat) {
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
        color: Colors.white.withOpacity(0.05),
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
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              Text('$value%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: Colors.white.withOpacity(0.06),
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

  Widget _buildResultDashboard(BmiState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        const Row(
          children: [
            Icon(Icons.dashboard_customize_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              '体征目标与健康诊断仪',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.5),
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
                  const Text('BMI 身体质量指数', style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text(
                    state.bmi!.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 68, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -1),
                  ),
                  const SizedBox(height: 14),
                  _buildBmiGauge(state.bmi!),
                  const SizedBox(height: 14),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (state.weeksToTarget != null && state.weeksToTarget! > 0)
          StaggerEntrance(
            index: 1,
            child: HoverGlowCard(
              glowColor: const Color(0xFF00E5FF),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.015),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.hourglass_empty_rounded, color: Color(0xFF00E5FF), size: 18),
                        SizedBox(width: 8),
                        Text('目标身材预计达成沙盒倒计时', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${state.weeksToTarget!.toStringAsFixed(1)} 周',
                      style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 34, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '约等于 ${(state.weeksToTarget! * 7).toStringAsFixed(0)} 天  •  日摄入偏离值：${state.caloricOffset.toStringAsFixed(0)} kcal',
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        StaggerEntrance(
          index: 2,
          child: HoverGlowCard(
            glowColor: const Color(0xFF00E676),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.015),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.restaurant_rounded, color: Color(0xFFFF007F), size: 18),
                      SizedBox(width: 8),
                      Text(
                        '每日卡路里摄入目标',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${state.finalCalorieGoal!.toStringAsFixed(0)} 千卡 / 天',
                    style: const TextStyle(color: Color(0xFF00E676), fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '结合了您的基础新陈代谢和增肌减脂期望，此目标已自动限制在临床健康红线底限以上。',
                    style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        StaggerEntrance(
          index: 3,
          child: HoverGlowCard(
            glowColor: const Color(0xFFFF8C00),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.015),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.analytics_rounded, color: Color(0xFFFF8C00), size: 18),
                      SizedBox(width: 8),
                      Text('三大宏量营养重量指标', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNutritionGramCard(
                          label: '🥚 蛋白质',
                          value: '${state.proteinGrams!.toStringAsFixed(1)} g',
                          color: const Color(0xFFFF8C00),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildNutritionGramCard(
                          label: '🍞 碳水化合物',
                          value: '${state.carbGrams!.toStringAsFixed(1)} g',
                          color: const Color(0xFF00E5FF),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildNutritionGramCard(
                          label: '🥑 脂肪',
                          value: '${state.fatGrams!.toStringAsFixed(1)} g',
                          color: const Color(0xFF00E676),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // ✨ Export to Markdown Notes (cross-tool linkage)
        GestureDetector(
          onTap: () {
            try {
              final storage = ref.read(localStorageServiceProvider);
              final ts = DateTime.now().toString().substring(0, 16);
              final report = '''
## 🏥 健康报告 ($ts)

| 指标 | 数据 |
|------|------|
| **BMI 身体质量指数** | ${state.bmi!.toStringAsFixed(2)} |
| **BMR 基础新陈代谢** | ${state.bmr!.toStringAsFixed(0)} kcal |
| **每日卡路里目标** | ${state.finalCalorieGoal!.toStringAsFixed(0)} kcal |
| **理想体重** | ${state.idealWeight!.toStringAsFixed(1)} ${state.isMetric ? 'kg' : 'lb'} |
| **预计达标周数** | ${state.weeksToTarget!.toStringAsFixed(1)} 周 |

### 宏量营养素分配
- 🥚 蛋白质：${state.proteinGrams!.toStringAsFixed(1)} g / 天
- 🍞 碳水化合物：${state.carbGrams!.toStringAsFixed(1)} g / 天
- 🥑 脂肪：${state.fatGrams!.toStringAsFixed(1)} g / 天

> ${state.message}
''';
              ref.read(markdownEditorCacheProvider.notifier).appendText(report);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('📝 健康报告已导出到 Markdown 笔记本'),
                  backgroundColor: const Color(0xFF1E1B3A),
                  action: SnackBarAction(
                    label: '去看看',
                    textColor: Colors.purpleAccent,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MarkdownEditorScreen()),
                      );
                    },
                  ),
                ),
              );
            } catch (_) {}
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF00E5FF).withValues(alpha: 0.15), const Color(0xFF00E676).withValues(alpha: 0.1)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_note_rounded, color: Color(0xFF00E5FF), size: 18),
                SizedBox(width: 8),
                Text(
                  '📊 导出健康报告到 Markdown 笔记本',
                  style: TextStyle(color: Color(0xFF00E5FF), fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBmiGauge(double bmi) {
    // Clamp BMI for display between 15.0 and 35.0
    final double displayBmi = bmi.clamp(15.0, 35.0);
    final double percentage = (displayBmi - 15.0) / (35.0 - 15.0);

    return Column(
      children: [
        Stack(
          children: [
            // Gauge Track with gorgeous neon gradient segments
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF00E5FF), // Underweight
                    Color(0xFF00E676), // Normal
                    Color(0xFFFFB300), // Overweight
                    Color(0xFFFF1744), // Obese
                  ],
                  stops: [0.175, 0.495, 0.745, 1.0],
                ),
              ),
            ),
            // Floating Indicator Pointer
            LayoutBuilder(
              builder: (context, constraints) {
                final double pointerOffset = (constraints.maxWidth - 16) * percentage;
                return Positioned(
                  left: pointerOffset.clamp(0.0, constraints.maxWidth - 16),
                  top: 0,
                  child: Container(
                    width: 16,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF007F),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('15.0 (偏瘦)', style: TextStyle(color: Colors.white30, fontSize: 10)),
            Text('22.0 (完美范围)', style: TextStyle(color: Color(0xFF00E676), fontSize: 10, fontWeight: FontWeight.bold)),
            Text('35.0 (肥胖)', style: TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _buildNutritionGramCard({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
