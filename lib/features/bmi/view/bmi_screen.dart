import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/provider/tools_provider.dart';

class BmiScreen extends ConsumerStatefulWidget {
  const BmiScreen({super.key});

  @override
  ConsumerState<BmiScreen> createState() => _BmiScreenState();
}

class _BmiScreenState extends ConsumerState<BmiScreen> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  double? _bmi;
  String _message = "";
  bool _isCalculating = false;

  /// Perform physical calculator logic and log telemetry to PostgreSQL
  Future<void> _calculate() async {
    final double? h = double.tryParse(_heightController.text.trim());
    final double? w = double.tryParse(_weightController.text.trim());

    if (h == null || w == null || h <= 0 || w <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入合理的身高与体重数值'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() {
      _isCalculating = true;
    });

    final stopwatch = Stopwatch()..start();
    
    // Simulate quick calculation load
    await Future.delayed(const Duration(milliseconds: 200));

    final calculatedBmi = w / ((h / 100) * (h / 100));
    String msg = "";

    if (calculatedBmi < 18.5) {
      msg = "体重偏轻 - 营养摄入有些不足，吃点点心吧！🥗";
    } else if (calculatedBmi < 25) {
      msg = "健康体态 - 指标非常完美，继续保持！✨";
    } else if (calculatedBmi < 30) {
      msg = "超重范围 - 适当运动，少糖少油哦！🏃";
    } else {
      msg = "肥胖范围 - 为了健康，建议咨询专业医生！❤️";
    }
    stopwatch.stop();

    setState(() {
      _bmi = calculatedBmi;
      _message = msg;
      _isCalculating = false;
    });

    // Save telemetry to DB logs
    ref.read(toolsAnalyticsProvider).logUsage(
      toolKey: 'bmi_calculator',
      parameters: {
        'height': h,
        'weight': w,
        'bmi': double.parse(calculatedBmi.toStringAsFixed(2)),
        'outcome': msg,
      },
      status: 'success',
      durationMs: stopwatch.elapsedMilliseconds,
    );
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('健康 BMI 计算器', style: TextStyle(color: Colors.white)),
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
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildInputField(
                    controller: _heightController,
                    label: '身高 (cm)',
                    icon: Icons.height,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: _weightController,
                    label: '体重 (kg)',
                    icon: Icons.monitor_weight_outlined,
                  ),
                  const SizedBox(height: 40),
                  _buildCalculateButton(),
                  if (_bmi != null) ...[
                    const SizedBox(height: 40),
                    _buildResultCard(),
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

  Widget _buildCalculateButton() {
    return ElevatedButton(
      onPressed: _isCalculating ? null : _calculate,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
      child: _isCalculating
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : const Text('计 算  B M I', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.pinkAccent.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.pinkAccent.withOpacity(0.05),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('您的 BMI 指数', style: TextStyle(fontSize: 14, color: Colors.white60)),
          const SizedBox(height: 8),
          Text(
            _bmi!.toStringAsFixed(1),
            style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: Colors.pinkAccent),
          ),
          const SizedBox(height: 12),
          Text(
            _message, 
            textAlign: TextAlign.center, 
            style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String label, required IconData icon}) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: Colors.pinkAccent),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.pinkAccent),
        ),
      ),
    );
  }
}
