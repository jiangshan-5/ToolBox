import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/bmi_provider.dart';

/// Sandboxed clinical Body Fitness and Macronutrient Analyzer Screen
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
    final state = ref.watch(bmiProvider);
    final notifier = ref.read(bmiProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('体征目标与宏量营养沙盒', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUnitSystemToggle(state, notifier),
                  const SizedBox(height: 20),
                  _buildGenderSelector(state, notifier),
                  const SizedBox(height: 24),
                  _buildBiometricInputs(state, notifier),
                  const SizedBox(height: 24),
                  _buildGoalSandboxConfig(state, notifier),
                  const SizedBox(height: 24),
                  _buildMacroSplitsSandbox(state, notifier),
                  const SizedBox(height: 32),
                  _buildSubmitButton(state),
                  if (state.bmi != null) ...[
                    const SizedBox(height: 40),
                    _buildResultDashboard(state),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildUnitSystemToggle(BmiState state, BmiNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                notifier.toggleSystem(true);
                _targetWeightController.text = '70.0';
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: state.isMetric ? Colors.pinkAccent.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: state.isMetric ? Colors.pinkAccent.withOpacity(0.3) : Colors.transparent),
                ),
                child: Center(
                  child: Text(
                    '公制系统 (cm / kg)',
                    style: TextStyle(
                      color: state.isMetric ? Colors.pinkAccent : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                notifier.toggleSystem(false);
                _targetWeightController.text = '154.0';
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !state.isMetric ? Colors.pinkAccent.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: !state.isMetric ? Colors.pinkAccent.withOpacity(0.3) : Colors.transparent),
                ),
                child: Center(
                  child: Text(
                    '英制系统 (inch / lb)',
                    style: TextStyle(
                      color: !state.isMetric ? Colors.pinkAccent : Colors.white70,
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

  Widget _buildGenderSelector(BmiState state, BmiNotifier notifier) {
    final isMale = state.gender == 'male';
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => notifier.setGender('male'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: isMale ? Colors.blueAccent.withOpacity(0.12) : Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isMale ? Colors.blueAccent.withOpacity(0.5) : Colors.white.withOpacity(0.06),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.male_rounded, color: isMale ? Colors.blueAccent : Colors.white54, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    '男 性',
                    style: TextStyle(
                      color: isMale ? Colors.blueAccent : Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () => notifier.setGender('female'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: !isMale ? Colors.pinkAccent.withOpacity(0.12) : Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: !isMale ? Colors.pinkAccent.withOpacity(0.5) : Colors.white.withOpacity(0.06),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.female_rounded, color: !isMale ? Colors.pinkAccent : Colors.white54, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    '女 性',
                    style: TextStyle(
                      color: !isMale ? Colors.pinkAccent : Colors.white70,
                      fontWeight: FontWeight.bold,
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

  Widget _buildBiometricInputs(BmiState state, BmiNotifier notifier) {
    final heightUnit = state.isMetric ? 'cm' : 'inch';
    final weightUnit = state.isMetric ? 'kg' : 'lb';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _heightController,
                  label: '输入当前身高 ($heightUnit)',
                  icon: Icons.height_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInputField(
                  controller: _weightController,
                  label: '输入当前体重 ($weightUnit)',
                  icon: Icons.monitor_weight_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('基础新陈代谢年龄:', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text('${state.age} 岁', style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: state.age.toDouble(),
            min: 5,
            max: 100,
            divisions: 95,
            activeColor: Colors.pinkAccent,
            inactiveColor: Colors.white10,
            onChanged: (v) => notifier.setAge(v.toInt()),
          ),
          const SizedBox(height: 8),
          _buildActivitySelector(state, notifier),
        ],
      ),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String label, required IconData icon}) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.pinkAccent, size: 18),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildActivitySelector(BmiState state, BmiNotifier notifier) {
    final activities = ['久坐不动', '轻度活动', '中度运动', '高强度训练', '专业运动员'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('日常活跃系数:', style: TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final act = activities[index];
              final isSel = state.activity == act;
              return GestureDetector(
                onTap: () => notifier.setActivity(act),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isSel ? Colors.pinkAccent.withOpacity(0.15) : Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSel ? Colors.pinkAccent.withOpacity(0.4) : Colors.white.withOpacity(0.06),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      act,
                      style: TextStyle(
                        color: isSel ? Colors.pinkAccent : Colors.white70,
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

  // ==================== 1. WEIGHT GOAL SANDBOX PANEL ====================

  Widget _buildGoalSandboxConfig(BmiState state, BmiNotifier notifier) {
    final weightUnit = state.isMetric ? 'kg' : 'lb';
    final changeText = state.weeklyChange < 0
        ? '📉 每周减重 ${state.weeklyChange.abs().toStringAsFixed(2)} $weightUnit'
        : '📈 每周增重 ${state.weeklyChange.toStringAsFixed(2)} $weightUnit';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.track_changes_rounded, color: Colors.pinkAccent, size: 18),
              SizedBox(width: 8),
              Text('增肌减脂体重目标沙盒', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _targetWeightController,
            label: '设定终极目标体重 ($weightUnit)',
            icon: Icons.flag_rounded,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('每周健康体重变动期望:', style: TextStyle(color: Colors.white60, fontSize: 13)),
              Text(changeText, style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: state.weeklyChange,
            min: state.isMetric ? -1.5 : -3.3,
            max: state.isMetric ? 1.5 : 3.3,
            divisions: 60,
            activeColor: Colors.pinkAccent,
            inactiveColor: Colors.white10,
            onChanged: (v) => notifier.setWeeklyChange(v),
          ),
        ],
      ),
    );
  }

  // ==================== 2. MACROS RATIO SANDBOX ====================

  Widget _buildMacroSplitsSandbox(BmiState state, BmiNotifier notifier) {
    final total = state.proteinPercent + state.carbPercent + state.fatPercent;
    final isBalanced = total == 100;

    final presets = [
      {'title': '均衡饮食流', 'p': 30, 'c': 40, 'f': 30},
      {'title': '极低碳生酮流', 'p': 20, 'c': 5, 'f': 75},
      {'title': '高蛋白增肌流', 'p': 40, 'c': 40, 'f': 20},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.restaurant_menu_rounded, color: Colors.pinkAccent, size: 18),
              SizedBox(width: 8),
              Text('三大宏量营养分配比重沙盒', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          // Presets row
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: presets.map((p) {
                final isCurrent = state.proteinPercent == p['p'] &&
                    state.carbPercent == p['c'] &&
                    state.fatPercent == p['f'];
                return GestureDetector(
                  onTap: () => notifier.setMacrosRatios(p['p'] as int, p['c'] as int, p['f'] as int),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCurrent ? Colors.pinkAccent : Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isCurrent ? Colors.transparent : Colors.white.withOpacity(0.06)),
                    ),
                    child: Text(
                      p['title'] as String,
                      style: TextStyle(
                        color: isCurrent ? Colors.white : Colors.white70,
                        fontSize: 11,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 20),

          // Protein Slider (Orange)
          _buildMacroSliderRow(
            label: '🥚 蛋白质 (Protein %)',
            value: state.proteinPercent,
            color: Colors.orangeAccent,
            onChanged: (v) => notifier.setMacrosRatios(v, state.carbPercent, state.fatPercent),
          ),

          // Carb Slider (Cyan)
          _buildMacroSliderRow(
            label: '🍞 碳水化合物 (Carbs %)',
            value: state.carbPercent,
            color: Colors.cyanAccent,
            onChanged: (v) => notifier.setMacrosRatios(state.proteinPercent, v, state.fatPercent),
          ),

          // Fat Slider (Green)
          _buildMacroSliderRow(
            label: '🥑 脂肪 (Fats %)',
            value: state.fatPercent,
            color: Colors.greenAccent,
            onChanged: (v) => notifier.setMacrosRatios(state.proteinPercent, state.carbPercent, v),
          ),

          const SizedBox(height: 12),

          // Ratio Sum Warning check
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('沙盒配比占比总和:', style: TextStyle(color: Colors.white38, fontSize: 12)),
              Text(
                '$total% / 100%',
                style: TextStyle(
                  color: isBalanced ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (!isBalanced) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  '⚠️ 营养素能量占比总和必须等于 100%，以保证克数正确。',
                  style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ]
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
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text('$value%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            activeColor: color,
            inactiveColor: Colors.white10,
            onChanged: (v) => onChanged(v.toInt()),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BmiState state) {
    return ElevatedButton(
      onPressed: state.isCalculating ? null : _handleAnalyze,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 58),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 8,
      ),
      child: state.isCalculating
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
              '注 入 配 置 并 诊 断',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
    );
  }

  // ==================== RESULT DASHBOARDS ====================

  Widget _buildResultDashboard(BmiState state) {
    final isBalanced = (state.proteinPercent + state.carbPercent + state.fatPercent) == 100;
    final weightUnit = state.isMetric ? 'kg' : 'lb';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '体征目标与营养诊断仪',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // BMI MAIN CARD
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF2E0854), Color(0xFF5E0B75)]),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: Colors.pinkAccent.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            children: [
              const Text('BMI 身体质量指数', style: TextStyle(color: Colors.white60, fontSize: 13)),
              const SizedBox(height: 8),
              Text(
                state.bmi!.toStringAsFixed(1),
                style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: Colors.pinkAccent),
              ),
              const SizedBox(height: 12),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // WEIGHT SANDBOX PROJECTIONS SUMMARY CARD
        if (state.weeksToTarget != null && state.weeksToTarget! > 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.hourglass_empty_rounded, color: Colors.cyanAccent, size: 20),
                    SizedBox(width: 8),
                    Text('目标身材预计达成沙盒倒计时', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${state.weeksToTarget!.toStringAsFixed(1)} 周',
                  style: const TextStyle(color: Colors.cyanAccent, fontSize: 36, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '约等于 ${(state.weeksToTarget! * 7).toStringAsFixed(0)} 天，日摄入偏离值：${state.caloricOffset.toStringAsFixed(0)} kcal',
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),

        const SizedBox(height: 20),

        // DAILY TARGET FOOD ENERGY CAP
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.restaurant_rounded, color: Colors.pinkAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '沙盒量身定制每日卡路里摄入目标',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${state.finalCalorieGoal!.toStringAsFixed(0)} 千卡 / 天',
                style: const TextStyle(color: Colors.greenAccent, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '根据您配置的体重目标热量偏离（已对齐临床健康红线底限），这是您每天的完美能量目标。',
                style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // DYNAMIC MACROS PILLS DASHBOARD (Only visible if 100% split is balanced)
        if (isBalanced && state.proteinGrams != null) ...[
          const Text('沙盒每日蛋白质 / 碳水 / 脂肪精确吃法 (克数):', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMacroPillBox(
                label: '蛋 白 质',
                value: '${state.proteinGrams!.toStringAsFixed(1)}g',
                percent: '${state.proteinPercent}%',
                color: Colors.orangeAccent,
              ),
              const SizedBox(width: 10),
              _buildMacroPillBox(
                label: '碳水化合物',
                value: '${state.carbGrams!.toStringAsFixed(1)}g',
                percent: '${state.carbPercent}%',
                color: Colors.cyanAccent,
              ),
              const SizedBox(width: 10),
              _buildMacroPillBox(
                label: '脂 肪',
                value: '${state.fatGrams!.toStringAsFixed(1)}g',
                percent: '${state.fatPercent}%',
                color: Colors.greenAccent,
              ),
            ],
          ),
        ],

        const SizedBox(height: 20),

        // CLINICAL DETAILS GRID
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
          children: [
            _buildGridMetricCard(
              title: '基础代谢率 (BMR)',
              value: '${state.bmr!.toStringAsFixed(0)}',
              unit: 'kcal / 天',
              color: Colors.orangeAccent,
              icon: Icons.flash_on_rounded,
            ),
            _buildGridMetricCard(
              title: '理想标准体重',
              value: '${state.idealWeight!.toStringAsFixed(1)}',
              unit: weightUnit,
              color: Colors.cyanAccent,
              icon: Icons.check_circle_rounded,
            ),
            _buildGridMetricCard(
              title: '体表面积 (BSA)',
              value: '${state.bsa!.toStringAsFixed(2)}',
              unit: '㎡',
              color: Colors.greenAccent,
              icon: Icons.aspect_ratio_rounded,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMacroPillBox({
    required String label,
    required String value,
    required String percent,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(percent, style: TextStyle(color: color.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildGridMetricCard({
    required String title,
    required String value,
    required String unit,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            unit,
            style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.white30, fontSize: 9),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
