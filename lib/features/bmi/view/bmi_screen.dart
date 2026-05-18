import 'package:flutter/material.dart';

class BmiScreen extends StatefulWidget {
  const BmiScreen({super.key});

  @override
  State<BmiScreen> createState() => _BmiScreenState();
}

class _BmiScreenState extends State<BmiScreen> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  double? _bmi;
  String _message = "";

  void _calculate() {
    final double? h = double.tryParse(_heightController.text);
    final double? w = double.tryParse(_weightController.text);

    if (h != null && w != null && h > 0) {
      setState(() {
        _bmi = w / ((h / 100) * (h / 100));
        if (_bmi! < 18.5) {
          _message = "Underweight - Time for a snack! 🥗";
        } else if (_bmi! < 25) {
          _message = "Healthy - You are doing great! ✨";
        } else if (_bmi! < 30) {
          _message = "Overweight - Let's stay active! 🏃";
        } else {
          _message = "Obese - Health is wealth! ❤️";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BMI Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildInputField(
              controller: _heightController,
              label: 'Height (cm)',
              icon: Icons.height,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _weightController,
              label: 'Weight (kg)',
              icon: Icons.monitor_weight_outlined,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('CALCULATE BMI'),
            ),
            if (_bmi != null) ...[
              const SizedBox(height: 40),
              _buildResultCard(),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.pinkAccent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text('YOUR BMI', style: TextStyle(fontSize: 14, color: Colors.white70)),
          Text(
            _bmi!.toStringAsFixed(1),
            style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.pinkAccent),
          ),
          const SizedBox(height: 8),
          Text(_message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String label, required IconData icon}) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.pinkAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
      ),
    );
  }
}
