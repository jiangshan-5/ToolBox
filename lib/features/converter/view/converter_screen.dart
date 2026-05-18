import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/converter_provider.dart';

/// Highly interactive, modern universal Multi-Category Converter Screen
class ConverterScreen extends ConsumerWidget {
  const ConverterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(converterProvider);
    final notifier = ref.read(converterProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('全能多物理量转换站', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildCategorySelector(state, notifier),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        _buildConversionCard(context, state, notifier),
                        const SizedBox(height: 32),
                        _buildDetailsAndGuides(state),
                      ],
                    ),
                  ),
                ),
              ],
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

  Widget _buildCategorySelector(ConverterState state, ConverterNotifier notifier) {
    final categories = [
      {'title': '长度', 'cat': ConverterCategory.length, 'icon': Icons.linear_scale_rounded, 'color': Colors.cyanAccent},
      {'title': '质量', 'cat': ConverterCategory.mass, 'icon': Icons.monitor_weight_rounded, 'color': Colors.pinkAccent},
      {'title': '温度', 'cat': ConverterCategory.temperature, 'icon': Icons.thermostat_rounded, 'color': Colors.orangeAccent},
      {'title': '面积', 'cat': ConverterCategory.area, 'icon': Icons.grid_view_rounded, 'color': Colors.greenAccent},
    ];

    return Container(
      height: 90,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final item = categories[index];
          final cat = item['cat'] as ConverterCategory;
          final isSel = state.category == cat;
          final color = item['color'] as Color;

          return GestureDetector(
            onTap: () => notifier.setCategory(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 90,
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: isSel ? color.withOpacity(0.12) : Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSel ? color.withOpacity(0.4) : Colors.white.withOpacity(0.08),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item['icon'] as IconData, color: isSel ? color : Colors.white60, size: 24),
                  const SizedBox(height: 6),
                  Text(
                    item['title'] as String,
                    style: TextStyle(
                      color: isSel ? color : Colors.white70,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- CONVERSION DUAL CARD PANELS ---

  Widget _buildConversionCard(BuildContext context, ConverterState state, ConverterNotifier notifier) {
    final activeColor = _getCategoryColor(state.category);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          // SOURCE PANEL
          _buildUnitPanel(
            context: context,
            label: '原始数值与单位',
            valueText: state.inputValue == 0 ? '' : state.inputValue.toString(),
            activeUnit: state.fromUnit,
            units: notifier.getUnitsForCategory(state.category),
            color: activeColor,
            isReadOnly: false,
            onValueChanged: (v) {
              final parsed = double.tryParse(v) ?? 0.0;
              notifier.updateInputValue(parsed);
            },
            onUnitChanged: (u) => notifier.updateFromUnit(u!),
          ),
          
          const SizedBox(height: 12),
          
          // SWAP BUTTON
          GestureDetector(
            onTap: notifier.reverseUnits,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: activeColor.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: activeColor.withOpacity(0.3), width: 1.5),
              ),
              child: Icon(Icons.swap_vert_rounded, color: activeColor, size: 24),
            ),
          ),

          const SizedBox(height: 12),

          // TARGET PANEL
          _buildUnitPanel(
            context: context,
            label: '转换结果',
            valueText: state.result.toStringAsFixed(5),
            activeUnit: state.toUnit,
            units: notifier.getUnitsForCategory(state.category),
            color: activeColor,
            isReadOnly: true,
            onValueChanged: (_) {},
            onUnitChanged: (u) => notifier.updateToUnit(u!),
          ),
          
          const SizedBox(height: 24),


          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: '${state.inputValue} ${state.fromUnit.toUpperCase()} = ${state.result.toStringAsFixed(5)} ${state.toUnit.toUpperCase()}'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('完整计算公式已复制'), duration: Duration(seconds: 1)),
              );
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: activeColor.withOpacity(0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            icon: Icon(Icons.copy_all_rounded, color: activeColor, size: 18),
            label: Text('复制转换公式', style: TextStyle(color: activeColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitPanel({
    required BuildContext context,
    required String label,
    required String valueText,
    required String activeUnit,
    required List<String> units,
    required Color color,
    required bool isReadOnly,
    required ValueChanged<String> onValueChanged,
    required ValueChanged<String?> onUnitChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: isReadOnly
                    ? SelectableText(
                        valueText == '0.00000' ? '0' : valueText,
                        style: TextStyle(
                          color: color,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    : TextFormField(
                        initialValue: valueText,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(color: Colors.white24),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: onValueChanged,
                      ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(canvasColor: const Color(0xFF24243E)),
                  child: DropdownButton<String>(
                    value: activeUnit,
                    dropdownColor: const Color(0xFF24243E),
                    iconEnabledColor: color,
                    underline: const SizedBox(),
                    style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
                    items: units.map((u) {
                      return DropdownMenuItem(
                        value: u,
                        child: Text(u.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: onUnitChanged,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsAndGuides(ConverterState state) {
    String desc = '';
    if (state.category == ConverterCategory.length) {
      desc = '长度常识：1 英寸(inch) 等于 2.54 厘米(cm)，1 英尺(feet) 等于 30.48 厘米(cm)；公里与英里为地理常用距离。';
    } else if (state.category == ConverterCategory.mass) {
      desc = '质量常识：1 磅(lb) 约等于 0.4536 千克(kg)，1 盎司(oz) 约等于 28.35 克(g)；1 市斤刚好为 0.5 千克。';
    } else if (state.category == ConverterCategory.temperature) {
      desc = '温度常识：摄氏度与开氏度为等温距单位，0°C 对应 273.15K；华氏度广泛应用于北美地区。';
    } else if (state.category == ConverterCategory.area) {
      desc = '面积常识：1 公顷(ha) 等于 10,000 平方米，中国传统市亩 (mu) 刚好约为 666.67 平方米。';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: _getCategoryColor(state.category), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              desc,
              style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(ConverterCategory cat) {
    switch (cat) {
      case ConverterCategory.length:
        return Colors.cyanAccent;
      case ConverterCategory.mass:
        return Colors.pinkAccent;
      case ConverterCategory.temperature:
        return Colors.orangeAccent;
      case ConverterCategory.area:
        return Colors.greenAccent;
    }
  }
}
