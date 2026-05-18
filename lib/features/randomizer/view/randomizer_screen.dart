import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/randomizer_provider.dart';

/// Sandboxed, highly-customizable Decision & Combinatorial Randomizer Screen
class RandomizerScreen extends ConsumerStatefulWidget {
  const RandomizerScreen({super.key});

  @override
  ConsumerState<RandomizerScreen> createState() => _RandomizerScreenState();
}

class _BouncingDiceState {
  bool isBouncing = false;
}

class _RandomizerScreenState extends ConsumerState<RandomizerScreen> {
  final _addOptionController = TextEditingController();
  final _prefixController = TextEditingController(text: 'ID-');
  final _suffixController = TextEditingController();
  final _diceLabelsController = TextEditingController(text: '大吉, 中吉, 小吉, 平, 凶, 大凶');
  
  bool _isDiceBouncing = false;

  @override
  void dispose() {
    _addOptionController.dispose();
    _prefixController.dispose();
    _suffixController.dispose();
    _diceLabelsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(randomizerProvider);
    final notifier = ref.read(randomizerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('高自由度决策与随机沙盒', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                _buildModeSelector(state, notifier),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        if (state.mode == RandomizerMode.number) _buildNumberSandbox(state, notifier),
                        if (state.mode == RandomizerMode.list) _buildWeightedSandbox(state, notifier),
                        if (state.mode == RandomizerMode.dice) _buildDiceSandbox(state, notifier),
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

  Widget _buildModeSelector(RandomizerState state, RandomizerNotifier notifier) {
    final modes = [
      {'title': '组合区间数', 'mode': RandomizerMode.number, 'icon': Icons.tune_rounded, 'color': Colors.cyanAccent},
      {'title': '权重决策沙盒', 'mode': RandomizerMode.list, 'icon': Icons.analytics_outlined, 'color': Colors.pinkAccent},
      {'title': '命运面骰', 'mode': RandomizerMode.dice, 'icon': Icons.casino_rounded, 'color': Colors.orangeAccent},
    ];

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: modes.map((m) {
          final isSel = state.mode == m['mode'] as RandomizerMode;
          final color = m['color'] as Color;

          return Expanded(
            child: GestureDetector(
              onTap: () => notifier.setMode(m['mode'] as RandomizerMode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSel ? color.withOpacity(0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSel ? color.withOpacity(0.3) : Colors.transparent),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(m['icon'] as IconData, color: isSel ? color : Colors.white60, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      m['title'] as String,
                      style: TextStyle(
                        color: isSel ? color : Colors.white70,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==================== 1. NUMBER SANDBOX UI ====================

  Widget _buildNumberSandbox(RandomizerState state, RandomizerNotifier notifier) {
    return Column(
      children: [
        // RANGES CARD
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('配置多区间生成器 (支持并行区间)', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 16),
              ...List.generate(state.customRanges.length, (index) {
                final range = state.customRanges[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Checkbox(
                        value: range.active,
                        activeColor: Colors.cyanAccent,
                        checkColor: Colors.black87,
                        onChanged: (v) => notifier.toggleRangeActive(index, v!),
                      ),
                      Text('区间 ${index + 1}: ', style: const TextStyle(color: Colors.white70)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSmallNumberInput(
                          hint: 'Min',
                          initialVal: range.min.toString(),
                          onChanged: (v) => notifier.updateRangeMin(index, int.tryParse(v) ?? 0),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('~', style: TextStyle(color: Colors.white38)),
                      ),
                      Expanded(
                        child: _buildSmallNumberInput(
                          hint: 'Max',
                          initialVal: range.max.toString(),
                          onChanged: (v) => notifier.updateRangeMax(index, int.tryParse(v) ?? 0),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // FORMATTER PARAMETERS CARD
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('自由定制格式化输出 (Zero Padding & Delimiters)', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSmallTextInput(
                      controller: _prefixController,
                      label: '前缀字符 (Prefix)',
                      onChanged: notifier.setPrefix,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSmallTextInput(
                      controller: _suffixController,
                      label: '后缀字符 (Suffix)',
                      onChanged: notifier.setSuffix,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.between,
                children: [
                  const Text('零对齐填充长度:', style: TextStyle(color: Colors.white60, fontSize: 13)),
                  Text('${state.padLeft} 位 (如: 007)', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: state.padLeft.toDouble(),
                min: 1,
                max: 8,
                divisions: 7,
                activeColor: Colors.cyanAccent,
                inactiveColor: Colors.white10,
                onChanged: (v) => notifier.setPadLeft(v.toInt()),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.between,
                children: [
                  const Text('生成总项数:', style: TextStyle(color: Colors.white60, fontSize: 13)),
                  Text('${state.generateCount} 项', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: state.generateCount.toDouble(),
                min: 1,
                max: 30,
                divisions: 29,
                activeColor: Colors.cyanAccent,
                inactiveColor: Colors.white10,
                onChanged: (v) => notifier.setGenerateCount(v.toInt()),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.between,
                children: [
                  const Text('允许结果出现重复项:', style: TextStyle(color: Colors.white60, fontSize: 13)),
                  Switch(
                    value: state.allowDuplicates,
                    activeColor: Colors.cyanAccent,
                    onChanged: notifier.setAllowDuplicates,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // RUN BUTTON & RESULTS
        ElevatedButton(
          onPressed: state.isGenerating ? null : notifier.runCombinatorialGenerate,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black87,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: state.isGenerating
              ? const CircularProgressIndicator(color: Colors.black87)
              : const Text('一 键 沙 盒 区 间 抽 选', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),

        if (state.formattedResults.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildResultsDisplay(state.formattedResults, Colors.cyanAccent),
        ],
      ],
    );
  }

  Widget _buildSmallNumberInput({required String hint, required String initialVal, required ValueChanged<String> onChanged}) {
    return TextFormField(
      initialValue: initialVal,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildSmallTextInput({required TextEditingController controller, required String label, required ValueChanged<String> onChanged}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white30, fontSize: 11),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      onChanged: onChanged,
    );
  }

  // ==================== 2. WEIGHTED DECISION SANDBOX UI ====================

  Widget _buildWeightedSandbox(RandomizerState state, RandomizerNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ADD OPTION INPUT ROW
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _addOptionController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '添加自定义选项 (例如: 吃火锅, 敲代码)',
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.04),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                final txt = _addOptionController.text.trim();
                if (txt.isNotEmpty) {
                  notifier.addWeightedOption(txt);
                  _addOptionController.clear();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.pinkAccent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // WEIGHT SLIDERS CONTAINER
        if (state.weightedOptions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.01),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.03)),
            ),
            child: const Center(
              child: Text('目前还没有配置选项，快添加几个吧！✏️', style: TextStyle(color: Colors.white30, fontSize: 13)),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.between,
                  children: [
                    const Text('配置选项与相对权重占比', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('共 ${state.weightedOptions.length} 个选项', style: const TextStyle(color: Colors.pinkAccent, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.weightedOptions.length,
                  itemBuilder: (context, idx) {
                    final item = state.weightedOptions[idx];
                    final prob = notifier.getProbabilityOfOption(item.id);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: item.text,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  decoration: const InputDecoration(border: InputBorder.none),
                                  onChanged: (v) => notifier.updateOptionText(item.id, v),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.pinkAccent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '中签率 🎯 ${prob.toStringAsFixed(1)}%',
                                  style: const TextStyle(color: Colors.pinkAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white30, size: 18),
                                onPressed: () => notifier.removeWeightedOption(item.id),
                              ),
                            ],
                          ),
                          Slider(
                            value: item.weight,
                            min: 0.1,
                            max: 10.0,
                            divisions: 99,
                            activeColor: Colors.pinkAccent,
                            inactiveColor: Colors.white10,
                            onChanged: (v) => notifier.updateOptionWeight(item.id, v),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

        const SizedBox(height: 20),

        if (state.weightedOptions.isNotEmpty) ...[
          // DRAW COUNT CONFIG
          Row(
            mainAxisAlignment: MainAxisAlignment.between,
            children: [
              const Text('本次抽取目标项数:', style: TextStyle(color: Colors.white60, fontSize: 13)),
              Text('${state.drawCount} 项', style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: state.drawCount.clamp(1, state.weightedOptions.length).toDouble(),
            min: 1,
            max: state.weightedOptions.length.toDouble(),
            divisions: (state.weightedOptions.length - 1).clamp(1, 100),
            activeColor: Colors.pinkAccent,
            inactiveColor: Colors.white10,
            onChanged: (v) => notifier.setDrawCount(v.toInt()),
          ),
          const SizedBox(height: 16),
          // HIT BUTTON
          ElevatedButton(
            onPressed: state.isGenerating ? null : notifier.runWeightedDecision,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: state.isGenerating
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('一 键 权 重 精 准 决 策', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],

        if (state.drawnOptions.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildResultsDisplay(state.drawnOptions, Colors.pinkAccent),
        ],
      ],
    );
  }

  // ==================== 3. CUSTOM SIDES DICE SANDBOX UI ====================

  Widget _buildDiceSandbox(RandomizerState state, RandomizerNotifier notifier) {
    final isTextDice = _diceLabelsController.text.trim().isNotEmpty;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('定制命运骰面模式', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _diceLabelsController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: '输入自定义文本骰子面 (用逗号分隔)',
                  labelStyle: const TextStyle(color: Colors.orangeAccent, fontSize: 11),
                  hintText: '如: 是, 否, 也许, 明天, 大吉, 凶',
                  hintStyle: const TextStyle(color: Colors.white10),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.04),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
                onChanged: notifier.setCustomDiceLabels,
              ),
              const SizedBox(height: 20),
              if (_diceLabelsController.text.trim().isEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.between,
                  children: [
                    const Text('使用标准数字多面骰:', style: TextStyle(color: Colors.white60, fontSize: 13)),
                    Text('${state.diceSides} 面骰子', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: state.diceSides.toDouble(),
                  min: 4,
                  max: 120,
                  divisions: 58,
                  activeColor: Colors.orangeAccent,
                  inactiveColor: Colors.white10,
                  onChanged: (v) => notifier.setDiceSides(v.toInt()),
                ),
              ] else ...[
                const Center(
                  child: Text('💡 已开启“自由文本骰子”模式！将从输入选项中均等随机投掷。', style: TextStyle(color: Colors.white38, fontSize: 11)),
                )
              ]
            ],
          ),
        ),

        const SizedBox(height: 32),

        // VIRTUAL ROLLING DICE CARD
        GestureDetector(
          onTap: state.isGenerating ? null : () async {
            setState(() => _isDiceBouncing = true);
            await notifier.rollCustomDice();
            setState(() => _isDiceBouncing = false);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFE65C00), Color(0xFFF9D423)]),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.orangeAccent.withOpacity(_isDiceBouncing ? 0.5 : 0.25),
                  blurRadius: _isDiceBouncing ? 30 : 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isDiceBouncing)
                  const Positioned(
                    top: 16,
                    child: Text('摇 晃 骰 盅 中 ... 🎲', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedScale(
                      scale: _isDiceBouncing ? 1.25 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: const Icon(Icons.casino_rounded, color: Colors.white, size: 72),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.diceRollResults.isEmpty
                          ? '点击进行投掷'
                          : '投掷结果: ${state.diceRollResults.first}',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- REUSABLE RESULTS PANEL ---

  Widget _buildResultsDisplay(List<String> results, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.between,
            children: [
              const Text('🎉 随机产生结果清单:', style: TextStyle(color: Colors.white60, fontSize: 13)),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: results.join('\n')));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('全部结果已成功复制'), duration: Duration(seconds: 1)),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: color.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                icon: Icon(Icons.copy_rounded, color: color, size: 14),
                label: Text('一键复制', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: results.map((e) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  e,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
