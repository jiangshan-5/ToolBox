import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/converter_provider.dart';

/// Clean ConsumerWidget representing the UI of the Physical Converter feature
class ConverterScreen extends ConsumerWidget {
  const ConverterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(converterProvider);
    final notifier = ref.read(converterProvider.notifier);

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
                  _buildInputField(notifier),
                  const SizedBox(height: 24),
                  _buildUnitSelectors(context, state, notifier),
                  const SizedBox(height: 40),
                  _buildConvertButton(state, notifier),
                  if (state.result > 0 || state.inputValue > 0) ...[
                    const SizedBox(height: 50),
                    _buildResultDisplay(state),
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

  Widget _buildInputField(ConverterNotifier notifier) {
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
        final val = double.tryParse(v) ?? 0.0;
        notifier.updateInputValue(val);
      },
    );
  }

  Widget _buildUnitSelectors(BuildContext context, ConverterState state, ConverterNotifier notifier) {
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
          _buildDropdown(context, state.fromUnit, notifier.unitFactors.keys.toList(), (v) => notifier.updateFromUnit(v!)),
          const Icon(Icons.arrow_forward_rounded, color: Colors.cyanAccent),
          _buildDropdown(context, state.toUnit, notifier.unitFactors.keys.toList(), (v) => notifier.updateToUnit(v!)),
        ],
      ),
    );
  }

  Widget _buildDropdown(BuildContext context, String value, List<String> units, ValueChanged<String?> onChanged) {
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
        items: units.map((u) {
          return DropdownMenuItem(
            value: u,
            child: Text(u.toUpperCase()),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildConvertButton(ConverterState state, ConverterNotifier notifier) {
    return ElevatedButton(
      onPressed: state.isConverting ? null : () => notifier.convert(),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black87,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
      child: state.isConverting
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
            )
          : const Text('开 始 转换', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildResultDisplay(ConverterState state) {
    return Column(
      children: [
        const Text('转换结果', style: TextStyle(fontSize: 14, color: Colors.white60)),
        const SizedBox(height: 8),
        Text(
          state.result.toStringAsFixed(4),
          style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
        ),
        const SizedBox(height: 4),
        Text(
          state.toUnit.toUpperCase(), 
          style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
