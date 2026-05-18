import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/provider/tools_provider.dart';

class ConverterScreen extends ConsumerStatefulWidget {
  const ConverterScreen({super.key});

  @override
  ConsumerState<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends ConsumerState<ConverterScreen> {
  double _inputValue = 0;
  String _fromUnit = 'cm';
  String _toUnit = 'm';
  double _result = 0;
  bool _isConverting = false;

  final Map<String, double> _unitFactors = {
    'cm': 1.0,
    'm': 100.0,
    'inch': 2.54,
    'feet': 30.48,
  };

  /// Trigger conversion calculation and log telemetry to PostgreSQL
  Future<void> _convert() async {
    setState(() {
      _isConverting = true;
    });

    final stopwatch = Stopwatch()..start();

    // Quick delay simulating unit processing
    await Future.delayed(const Duration(milliseconds: 150));

    double valueInCm = _inputValue * _unitFactors[_fromUnit]!;
    double finalResult = valueInCm / _unitFactors[_toUnit]!;
    
    stopwatch.stop();

    setState(() {
      _result = finalResult;
      _isConverting = false;
    });

    // Fire off non-blocking telemetry logging to database
    ref.read(toolsAnalyticsProvider).logUsage(
      toolKey: 'converter',
      parameters: {
        'input_value': _inputValue,
        'from_unit': _fromUnit,
        'to_unit': _toUnit,
        'result': double.parse(finalResult.toStringAsFixed(4)),
      },
      status: 'success',
      durationMs: stopwatch.elapsedMilliseconds,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('标准单位转换器', style: TextStyle(color: Colors.white)),
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
                  _buildInputField(),
                  const SizedBox(height: 24),
                  _buildUnitSelectors(),
                  const SizedBox(height: 40),
                  _buildConvertButton(),
                  if (_result > 0 || _inputValue > 0) ...[
                    const SizedBox(height: 50),
                    _buildResultDisplay(),
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

  Widget _buildInputField() {
    return TextField(
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: '输入转换数值',
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: const Icon(Icons.edit, color: Colors.cyanAccent),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.cyanAccent),
        ),
      ),
      onChanged: (v) {
        final val = double.tryParse(v) ?? 0;
        setState(() {
          _inputValue = val;
        });
      },
    );
  }

  Widget _buildUnitSelectors() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildDropdown(_fromUnit, (v) => setState(() => _fromUnit = v!)),
          const Icon(Icons.arrow_forward_rounded, color: Colors.cyanAccent),
          _buildDropdown(_toUnit, (v) => setState(() => _toUnit = v!)),
        ],
      ),
    );
  }

  Widget _buildDropdown(String value, ValueChanged<String?> onChanged) {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: const Color(0xFF24243E),
      ),
      child: DropdownButton<String>(
        value: value,
        dropdownColor: const Color(0xFF24243E),
        iconEnabledColor: Colors.cyanAccent,
        underline: const SizedBox(),
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        items: _unitFactors.keys.map((u) {
          return DropdownMenuItem(
            value: u,
            child: Text(u.toUpperCase()),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildConvertButton() {
    return ElevatedButton(
      onPressed: _isConverting ? null : _convert,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black87,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
      child: _isConverting
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
            )
          : const Text('开 始 转换', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildResultDisplay() {
    return Column(
      children: [
        const Text('转换结果', style: TextStyle(fontSize: 14, color: Colors.white60)),
        const SizedBox(height: 8),
        Text(
          _result.toStringAsFixed(4),
          style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
        ),
        const SizedBox(height: 4),
        Text(
          _toUnit.toUpperCase(), 
          style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
