import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/dynamic_effects.dart';
import '../../../core/widgets/dynamic_background.dart';
import '../provider/bmi_provider.dart';
import 'widgets/biometric_inputs_panel.dart';
import 'widgets/macros_sandbox_panel.dart';
import 'widgets/result_dashboard_panel.dart';

/// Sandboxed clinical Body Fitness and Macronutrient Analyzer Screen with premium visual assets
class BmiScreen extends ConsumerStatefulWidget {
  const BmiScreen({super.key});

  @override
  ConsumerState<BmiScreen> createState() => _BmiScreenState();
}

class _BmiScreenState extends ConsumerState<BmiScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get textColor => isDark ? Colors.white : Colors.black87;
  Color get subTextColor => isDark ? Colors.white70 : Colors.black54;
  Color get faintTextColor => isDark ? Colors.white38 : Colors.black38;
  Color get borderDividerColor =>
      isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _targetWeightController = TextEditingController(text: '70.0');

  Future<void> _handleAnalyze() async {
    final double? h = double.tryParse(_heightController.text.trim());
    final double? w = double.tryParse(_weightController.text.trim());
    final double? tw = double.tryParse(_targetWeightController.text.trim());

    if (h == null || w == null || tw == null || h <= 0 || w <= 0 || tw <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请输入合理的体征数值（身高、当前体重及目标体重）'),
          backgroundColor: Colors.pinkAccent,
        ),
      );
      return;
    }

    ref.read(bmiProvider.notifier).setTargetWeight(tw);
    final success = await ref
        .read(bmiProvider.notifier)
        .runBiometricAnalysis(heightInput: h, weightInput: w);

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
    final isCalculating = state.isCalculating;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          '体征与宏量营养沙盒',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.8,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surface.withOpacity(0.8),
                Colors.transparent,
              ],
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
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  BmiBiometricInputsPanel(
                    heightController: _heightController,
                    weightController: _weightController,
                    targetWeightController: _targetWeightController,
                  ),
                  const SizedBox(height: 24),
                  ScaleOnTap(
                    onTap: isCalculating ? null : _handleAnalyze,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF007F), Color(0xFFE040FB)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF007F).withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: isCalculating
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: textColor,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                '立即唤起体征诊断引擎',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const BmiMacrosSandboxPanel(),
                  if (state.bmi != null &&
                      state.bmr != null &&
                      state.tdee != null) ...[
                    const BmiResultDashboardPanel(),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return const DynamicBackground(child: SizedBox.expand());
  }
}
