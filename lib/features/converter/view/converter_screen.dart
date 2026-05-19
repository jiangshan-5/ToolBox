import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/dynamic_effects.dart';
import '../provider/converter_provider.dart';

/// Highly customizable universal Unit Converter Sandbox Screen with premium isolated dynamic micro-interactions
class ConverterScreen extends ConsumerStatefulWidget {
  const ConverterScreen({super.key});

  @override
  ConsumerState<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends ConsumerState<ConverterScreen> {
  final _customNameController = TextEditingController();
  final _customFromController = TextEditingController();
  final _customToController = TextEditingController();
  final _customFactorController = TextEditingController();
  final _customOffsetController = TextEditingController();
  final _inputValueController = TextEditingController();

  bool _isCreatingCustom = false;
  double _swapRotationTurns = 0.0;

  @override
  void initState() {
    super.initState();
    _inputValueController.text = '0';
  }

  @override
  void dispose() {
    _customNameController.dispose();
    _customFromController.dispose();
    _customToController.dispose();
    _customFactorController.dispose();
    _customOffsetController.dispose();
    _inputValueController.dispose();
    super.dispose();
  }

  void _handleCreateCustom(ConverterNotifier notifier) {
    final name = _customNameController.text.trim();
    final from = _customFromController.text.trim();
    final to = _customToController.text.trim();
    final factor = double.tryParse(_customFactorController.text.trim()) ?? 1.0;
    final offset = double.tryParse(_customOffsetController.text.trim()) ?? 0.0;

    if (name.isEmpty || from.isEmpty || to.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('所有公式字段均为必填项'), backgroundColor: Colors.purpleAccent),
      );
      return;
    }

    notifier.addCustomConverter(
      name: name,
      fromUnit: from,
      toUnit: to,
      factor: factor,
      offset: offset,
    );

    // Reset controllers and slide down form
    _customNameController.clear();
    _customFromController.clear();
    _customToController.clear();
    _customFactorController.clear();
    _customOffsetController.clear();

    setState(() => _isCreatingCustom = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚡ 自定义物理换算卡片注入成功！'),
        backgroundColor: Colors.purpleAccent,
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
      case ConverterCategory.sandbox:
        return Colors.purpleAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(converterProvider.notifier);
    final category = ref.watch(converterProvider.select((s) => s.category));
    final activeColor = _getCategoryColor(category);

    return Scaffold(
      backgroundColor: const Color(0xFF090714),
      appBar: AppBar(
        title: const Text(
          '物理量公式沙盒转换站',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.8),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF090714).withOpacity(0.8), Colors.transparent],
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
            child: Column(
              children: [
                _buildCategorySelector(category, notifier),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: Column(
                      children: [
                        if (category == ConverterCategory.sandbox) ...[
                          Consumer(
                            builder: (context, ref, child) {
                              final activeCustomId = ref.watch(converterProvider.select((s) => s.activeCustomId));
                              final customConverters = ref.watch(converterProvider.select((s) => s.customConverters));
                              return _buildSandboxSelectorPanel(activeCustomId, customConverters, notifier);
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                        // MAIN CONVERSION CARD (Highly optimized input isolate card)
                        HoverGlowCard(
                          glowColor: activeColor,
                          child: _buildConversionCard(context, notifier, activeColor),
                        ),
                        // ALL MATRIX RESULT GRID
                        Consumer(
                          builder: (context, ref, child) {
                            final allConversionsMatrix = ref.watch(converterProvider.select((s) => s.allConversionsMatrix));
                            if (allConversionsMatrix.isEmpty) return const SizedBox.shrink();
                            return Column(
                              children: [
                                const SizedBox(height: 24),
                                _buildAllUnitsMatrixGrid(allConversionsMatrix, activeColor),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildDetailsAndGuides(category, activeColor),
                        const SizedBox(height: 30),
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
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0C091F),
              Color(0xFF140F2D),
              Color(0xFF06050C),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(ConverterCategory activeCat, ConverterNotifier notifier) {
    final categories = [
      {'title': '长度', 'cat': ConverterCategory.length, 'icon': Icons.linear_scale_rounded, 'color': Colors.cyanAccent},
      {'title': '质量', 'cat': ConverterCategory.mass, 'icon': Icons.monitor_weight_rounded, 'color': Colors.pinkAccent},
      {'title': '温度', 'cat': ConverterCategory.temperature, 'icon': Icons.thermostat_rounded, 'color': Colors.orangeAccent},
      {'title': '面积', 'cat': ConverterCategory.area, 'icon': Icons.grid_view_rounded, 'color': Colors.greenAccent},
      {'title': '公式沙盒', 'cat': ConverterCategory.sandbox, 'icon': Icons.dashboard_customize_rounded, 'color': Colors.purpleAccent},
    ];

    return Container(
      height: 76,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final item = categories[index];
          final cat = item['cat'] as ConverterCategory;
          final isSel = activeCat == cat;
          final color = item['color'] as Color;

          return ScaleOnTap(
            onTap: () {
              notifier.setCategory(cat);
              _inputValueController.text = '0';
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 82,
              margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              decoration: BoxDecoration(
                color: isSel ? color.withOpacity(0.12) : Colors.white.withOpacity(0.015),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSel ? color.withOpacity(0.5) : Colors.white.withOpacity(0.05),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item['icon'] as IconData, color: isSel ? color : Colors.white38, size: 20),
                  const SizedBox(height: 5),
                  Text(
                    item['title'] as String,
                    style: TextStyle(
                      color: isSel ? color : Colors.white60,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      fontSize: 11,
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

  Widget _buildSandboxSelectorPanel(String? activeCustomId, List<CustomConverter> customConverters, ConverterNotifier notifier) {
    return Column(
      children: [
        if (_isCreatingCustom)
          HoverGlowCard(
            glowColor: Colors.purpleAccent,
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.purpleAccent.withOpacity(0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.purpleAccent.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('设计自定义公式转换卡片', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ScaleOnTap(
                        onTap: () => setState(() => _isCreatingCustom = false),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.close, color: Colors.white60, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSmallFormInput(controller: _customNameController, label: '转换器标题 (如: 汇率、游戏点数换算)'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildSmallFormInput(controller: _customFromController, label: '原始单位 (如: 金币)')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildSmallFormInput(controller: _customToController, label: '目标单位 (如: 钻石)')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildSmallFormInput(controller: _customFactorController, label: '换算比例系数 (Multiplier)')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildSmallFormInput(controller: _customOffsetController, label: '加减法偏移量 (Offset)', hint: '0.0')),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ScaleOnTap(
                    onTap: () => _handleCreateCustom(notifier),
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF8A2387), Color(0xFFE94057)]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: Colors.purpleAccent.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: const Center(
                        child: Text('一 键 注 入 并 启 用', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.015),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(canvasColor: const Color(0xFF140F2D)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: activeCustomId,
                        iconEnabledColor: Colors.purpleAccent,
                        dropdownColor: const Color(0xFF140F2D),
                        style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 14),
                        items: customConverters.map((c) {
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            notifier.setActiveCustomId(v);
                            _inputValueController.text = '0';
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ScaleOnTap(
                onTap: () => setState(() => _isCreatingCustom = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add, color: Colors.purpleAccent, size: 16),
                      SizedBox(width: 6),
                      Text('添加新公式', style: TextStyle(color: Colors.purpleAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSmallFormInput({required TextEditingController controller, required String label, String hint = ''}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white30, fontSize: 11),
          hintText: hint.isEmpty ? null : hint,
          hintStyle: const TextStyle(color: Colors.white10),
          filled: true,
          fillColor: Colors.white.withOpacity(0.015),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildConversionCard(BuildContext context, ConverterNotifier notifier, Color activeColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.015),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        children: [
          // SOURCE PANEL (Decoupled input text field from top-level rebuild)
          Consumer(
            builder: (context, ref, child) {
              final fromUnit = ref.watch(converterProvider.select((s) => s.fromUnit));
              final category = ref.watch(converterProvider.select((s) => s.category));
              return _buildUnitPanel(
                context: context,
                label: '原始数值与单位',
                valueText: '',
                controller: _inputValueController,
                activeUnit: fromUnit,
                units: notifier.getUnitsForCategory(category),
                color: activeColor,
                isReadOnly: false,
                onValueChanged: (v) {
                  final parsed = double.tryParse(v) ?? 0.0;
                  notifier.updateInputValue(parsed);
                },
                onUnitChanged: (u) => notifier.updateFromUnit(u!),
              );
            },
          ),
          
          const SizedBox(height: 14),
          
          // SWAP BUTTON WITH SPRING ROTATION ANIMATION
          ScaleOnTap(
            onTap: () {
              setState(() {
                _swapRotationTurns += 0.5; // Spins 180 degrees smoothly on tap!
              });
              notifier.reverseUnits();
            },
            child: AnimatedRotation(
              turns: _swapRotationTurns,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutBack,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: activeColor.withOpacity(0.35), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: Icon(Icons.swap_vert_rounded, color: activeColor, size: 22),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // TARGET PANEL (Only rebuilds output conversion value changes)
          Consumer(
            builder: (context, ref, child) {
              final result = ref.watch(converterProvider.select((s) => s.result));
              final toUnit = ref.watch(converterProvider.select((s) => s.toUnit));
              final category = ref.watch(converterProvider.select((s) => s.category));
              return _buildUnitPanel(
                context: context,
                label: '转换结果',
                valueText: result.toStringAsFixed(5),
                activeUnit: toUnit,
                units: notifier.getUnitsForCategory(category),
                color: activeColor,
                isReadOnly: true,
                onValueChanged: (_) {},
                onUnitChanged: (u) => notifier.updateToUnit(u!),
              );
            },
          ),
          
          const SizedBox(height: 24),

          // CLIPBOARD COPY BUTTON
          Consumer(
            builder: (context, ref, child) {
              final inputValue = ref.watch(converterProvider.select((s) => s.inputValue));
              final fromUnit = ref.watch(converterProvider.select((s) => s.fromUnit));
              final result = ref.watch(converterProvider.select((s) => s.result));
              final toUnit = ref.watch(converterProvider.select((s) => s.toUnit));

              return ScaleOnTap(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: '$inputValue ${fromUnit.toUpperCase()} = ${result.toStringAsFixed(5)} ${toUnit.toUpperCase()}'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚡ 完整物理换算公式已复制到剪贴板'),
                      backgroundColor: Colors.white10,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: activeColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: activeColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.copy_all_rounded, color: activeColor, size: 18),
                      const SizedBox(width: 8),
                      Text('复制完整换算公式', style: TextStyle(color: activeColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUnitPanel({
    required BuildContext context,
    required String label,
    required String valueText,
    TextEditingController? controller,
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
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: isReadOnly
                    ? SelectableText(
                        valueText == '0.00000' ? '0' : valueText,
                        style: TextStyle(
                          color: color,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      )
                    : TextFormField(
                        controller: controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                        decoration: const InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(color: Colors.white12),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: onValueChanged,
                      ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(canvasColor: const Color(0xFF140F2D)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: activeUnit,
                      dropdownColor: const Color(0xFF140F2D),
                      iconEnabledColor: color,
                      style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllUnitsMatrixGrid(List<MatrixUnitItem> matrix, Color color) {
    return Container(
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
          Row(
            children: [
              Icon(Icons.dashboard_outlined, color: color, size: 18),
              const SizedBox(width: 8),
              const Text(
                '多维度同物理量极速对照矩阵',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              int cols = constraints.maxWidth > 550 ? 3 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.3,
                ),
                itemCount: matrix.length,
                itemBuilder: (context, idx) {
                  final e = matrix[idx];
                  return StaggerEntrance(
                    index: idx,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withOpacity(0.12)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            e.unit.toUpperCase(),
                            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            e.value.toStringAsFixed(3),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsAndGuides(ConverterCategory category, Color color) {
    String title = '';
    String desc = '';

    switch (category) {
      case ConverterCategory.length:
        title = '📏 物理量解析：长度 (Length)';
        desc = '长度是一维空间的度量，为数值点到点之间的距离。国际标准单位为米 (m)。本换算站同时涵盖了天文学单位和英美传统制单位对照。';
        break;
      case ConverterCategory.mass:
        title = '⚖️ 物理量解析：质量 (Mass)';
        desc = '质量是物体所含物质的量，是度量物体惯性大小的物理量。国际标准单位为千克 (kg)。本站亦对齐了市制金衡及磅盎司单位。';
        break;
      case ConverterCategory.temperature:
        title = '🌡️ 物理量解析：温度 (Temperature)';
        desc = '温度是度量物体冷热程度的物理量，微观上是分子热运动剧烈程度的表现。本站完美对齐了摄氏度 (°C)、华氏度 (°F) 及热力学开尔文 (K) 转换方程式。';
        break;
      case ConverterCategory.area:
        title = '📐 物理量解析：面积 (Area)';
        desc = '面积是二维平面图形占有空间维度的量度。标准单位为平方米 (㎡)。本站同时支持传统公顷、市亩与西方英亩的精密转换。';
        break;
      case ConverterCategory.sandbox:
        title = '🧪 极客探索：公式沙盒 (Sandbox)';
        desc = '您可以在此自主设计多重物理参数及兑换因子！输入自定义兑换率系数 (Multiplier) 和数学常数偏移量 (Offset)，本站将实时为您的自定义项目生成整套高精度沙盒对照。';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.006),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.02)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(color: Colors.white38, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}
