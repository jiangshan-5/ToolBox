import 'package:flutter/material.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  double _inputValue = 0;
  String _fromUnit = 'cm';
  String _toUnit = 'm';
  double _result = 0;

  final Map<String, double> _unitFactors = {
    'cm': 1.0,
    'm': 100.0,
    'inch': 2.54,
    'feet': 30.48,
  };

  void _convert() {
    setState(() {
      double valueInCm = _inputValue * _unitFactors[_fromUnit]!;
      _result = valueInCm / _unitFactors[_toUnit]!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Length Converter')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Enter value', border: OutlineInputBorder()),
              onChanged: (v) => _inputValue = double.tryParse(v) ?? 0,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDropdown(_fromUnit, (v) => setState(() => _fromUnit = v!)),
                const Icon(Icons.arrow_forward),
                _buildDropdown(_toUnit, (v) => setState(() => _toUnit = v!)),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _convert,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('CONVERT'),
            ),
            const SizedBox(height: 40),
            Text(
              _result.toStringAsFixed(4),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
            ),
            Text(_toUnit, style: const TextStyle(fontSize: 18, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String value, ValueChanged<String?> onChanged) {
    return DropdownButton<String>(
      value: value,
      items: _unitFactors.keys.map((u) => DropdownMenuItem(value: u, child: Text(u.toUpperCase()))).toList(),
      onChanged: onChanged,
    );
  }
}
