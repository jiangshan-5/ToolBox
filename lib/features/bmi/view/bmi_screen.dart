import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/bmi_provider.dart';

/// Highly clinical, modern Body Health and Biometric Analyzer Screen
class BmiScreen extends ConsumerStatefulWidget {
  const BmiScreen({super.key});

  @override
  ConsumerState<BmiScreen> createState() => _BmiScreenState();
}

class _BmiScreenState extends ConsumerState<BmiScreen> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  Future<void> _handleAnalyze() async {
    final double? h = double.tryParse(_heightController.text.trim());
    final double? w = double.tryParse(_weightController.text.trim());

    if (h == null || w == null || h <= 0 || w <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入合理的数值'),
          backgroundColor: Colors.pinkAccent,
        ),
      );
      return;
    }

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bmiProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('体征与健康代谢分析中心', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  _buildUnitSystemToggle(state),
                  const SizedBox(height: 20),
                  _buildGenderSelector(state),
                  const SizedBox(height: 24),
                  _buildBiometricInputs(state),
                  const SizedBox(height: 24),
                  _buildActivitySelector(state),
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

  Widget _buildUnitSystemToggle(BmiState state) {
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
              onTap: () => ref.read(bmiProvider.notifier).toggleSystem(true),
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
              onTap: () => ref.read(bmiProvider.notifier).toggleSystem(false),
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

  Widget _buildGenderSelector(BmiState state) {
    final isMale = state.gender == 'male';
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => ref.read(bmiProvider.notifier).setGender('male'),
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
            onTap: () => ref.read(bmiProvider.notifier).setGender('female'),
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

  Widget _buildBiometricInputs(BmiState state) {
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
                  label: '输入身高 ($heightUnit)',
                  icon: Icons.height_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInputField(
                  controller: _weightController,
                  label: '输入体重 ($weightUnit)',
                  icon: Icons.monitor_weight_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '输入年龄: ${state.age} 岁',
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
          ),
          Slider(
            value: state.age.toDouble(),
            min: 5,
            max: 100,
            divisions: 95,
            activeColor: Colors.pinkAccent,
            inactiveColor: Colors.white10,
            onChanged: (v) => ref.read(bmiProvider.notifier).setAge(v.toInt()),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String label, required IconData icon}) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.pinkAccent, size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.pinkAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildActivitySelector(BmiState state) {
    final activities = ['久坐不动', '轻度活动', '中度运动', '高强度训练', '专业运动员'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '选择您的日常活跃程度',
          style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final act = activities[index];
              final isSel = state.activity == act;
              return GestureDetector(
                onTap: () => ref.read(bmiProvider.notifier).setActivity(act),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSel ? Colors.pinkAccent : Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSel ? Colors.transparent : Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      act,
                      style: TextStyle(
                        color: isSel ? Colors.white : Colors.white70,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
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
              '一 键 智 能 体 征 分 析',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
    );
  }

  // --- HEALTH DASHBOARD ---

  Widget _buildResultDashboard(BmiState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '人体健康数据体征仪',
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
              unit: state.isMetric ? 'kg' : 'lb',
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

        const SizedBox(height: 20),

        // TARGET CALORIC TARGET BANNER
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
                    '每日卡路里能量上限推荐',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(text: '根据您的日常活跃度 (', style: TextStyle(color: Colors.white60, fontSize: 13)),
                    TextSpan(text: state.activity, style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                    const TextSpan(text: ')，建议您每日的食物卡路里摄入维持在 ', style: TextStyle(color: Colors.white60, fontSize: 13)),
                    TextSpan(
                      text: '${state.dailyCalories!.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const TextSpan(text: ' 千卡 (kcal) 以内，以维持能量完美代谢平衡。', style: TextStyle(color: Colors.white60, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
