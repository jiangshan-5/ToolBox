import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:confetti/confetti.dart';

import '../../../core/widgets/dynamic_effects.dart';

import '../../../core/widgets/dynamic_background.dart';

import '../provider/randomizer_provider.dart';
import 'widgets/random_range_row.dart';
import 'widgets/random_option_row.dart';
import 'widgets/dice_bouncing_canvas.dart';

/// Sandboxed, highly-customizable Decision & Combinatorial Randomizer Screen with dynamic micro-interactions
class RandomizerScreen extends ConsumerStatefulWidget {
  const RandomizerScreen({super.key});

  @override
  ConsumerState<RandomizerScreen> createState() => _RandomizerScreenState();
}

class _RandomizerScreenState extends ConsumerState<RandomizerScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get textColor => isDark ? Colors.white : Colors.black87;
  Color get subTextColor => isDark ? Colors.white70 : Colors.black54;
  Color get faintTextColor => isDark ? Colors.white38 : Colors.black38;

  final _addOptionController = TextEditingController();
  final _prefixController = TextEditingController(text: 'ID-');
  final _suffixController = TextEditingController();
  final _diceLabelsController = TextEditingController(text: '大吉, 中吉, 小吉, 平, 凶, 大凶');
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _addOptionController.dispose();
    _prefixController.dispose();
    _suffixController.dispose();
    _diceLabelsController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(randomizerProvider.notifier);
    final mode = ref.watch(randomizerProvider.select((s) => s.mode));
    ref.listen(randomizerProvider.select((s) => s.isGenerating), (previous, next) {
      if (previous == true && next == false) {
        final state = ref.read(randomizerProvider);
        if (state.formattedResults.isNotEmpty) {
          _confettiController.play();
          HapticFeedback.heavyImpact();
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          '高自由度决策随机沙盒',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.8),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Theme.of(context).colorScheme.surface.withOpacity(0.8), Colors.transparent],
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
                _buildModeSelector(mode, notifier),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeInOutCubic,
                      switchOutCurve: Curves.easeInOutCubic,
                      child: _buildActiveSandbox(mode, notifier),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14159 / 2, // down
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              maxBlastForce: 20,
              minBlastForce: 5,
              gravity: 0.2,
              colors: const [Colors.cyanAccent, Colors.pinkAccent, Colors.orangeAccent, Colors.white],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return const DynamicBackground(
      child: SizedBox.expand(),
    );
  }

  Widget _buildModeSelector(RandomizerMode activeMode, RandomizerNotifier notifier) {
    final modes = [
      {'title': '区间随机', 'mode': RandomizerMode.number, 'icon': Icons.tune_rounded, 'color': Colors.cyanAccent},
      {'title': '权重决策', 'mode': RandomizerMode.list, 'icon': Icons.analytics_outlined, 'color': Colors.pinkAccent},
      {'title': '命运面骰', 'mode': RandomizerMode.dice, 'icon': Icons.casino_rounded, 'color': Colors.orangeAccent},
    ];

    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.015) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: modes.map((m) {
          final isSel = activeMode == m['mode'] as RandomizerMode;
          final color = m['color'] as Color;
          return Expanded(
            child: ScaleOnTap(
              onTap: () => notifier.setMode(m['mode'] as RandomizerMode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: isSel
                      ? LinearGradient(
                          colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSel ? color.withOpacity(0.4) : Colors.transparent),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(m['icon'] as IconData, color: isSel ? color : Colors.white38, size: 16),
                    const SizedBox(width: 5),
                    Text(
                      m['title'] as String,
                      style: TextStyle(
                        color: isSel ? color : Colors.white60,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        fontSize: 11,
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

  Widget _buildActiveSandbox(RandomizerMode activeMode, RandomizerNotifier notifier) {
    switch (activeMode) {
      case RandomizerMode.number:
        return _buildNumberSandbox(context, notifier);
      case RandomizerMode.list:
        return _buildWeightedSandbox(context, notifier);
      case RandomizerMode.dice:
        return _buildDiceSandbox(context, notifier);
    }
  }

  // ==================== 1. NUMBER SANDBOX UI ====================
  Widget _buildNumberSandbox(BuildContext context, RandomizerNotifier notifier) {
    return Column(
      key: const ValueKey('number_sandbox'),
      children: [
        // RANGES CARD
        HoverGlowCard(
          glowColor: Colors.cyanAccent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.015) : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune_rounded, color: Colors.cyanAccent, size: 16),
                    const SizedBox(width: 6),
                    Text('配置多区间生成器 (支持并行区间)', style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, child) {
                    final ranges = ref.watch(randomizerProvider.select((s) => s.customRanges));
                    return Column(
                      children: List.generate(ranges.length, (index) {
                        final range = ranges[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: RandomRangeRow(
                            index: index,
                            min: range.min,
                            max: range.max,
                            active: range.active,
                            notifier: notifier,
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        // FORMATTING CARD
        HoverGlowCard(
          glowColor: Colors.cyanAccent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.015) : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.style_rounded, color: Colors.cyanAccent, size: 16),
                    const SizedBox(width: 6),
                    Text('定制生成数字排版与约束', style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSmallTextInput(
                        controller: _prefixController,
                        label: '添加前缀 (如: ID-)',
                        onChanged: notifier.setPrefix,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSmallTextInput(
                        controller: _suffixController,
                        label: '添加后缀 (如: 号)',
                        onChanged: notifier.setSuffix,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Consumer(
                  builder: (context, ref, child) {
                    final padLeft = ref.watch(randomizerProvider.select((s) => s.padLeft));
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('零对齐填充长度:', style: TextStyle(color: subTextColor, fontSize: 12)),
                            Text('$padLeft 位 (如: 007)', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: Colors.cyanAccent,
                            inactiveTrackColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                            thumbColor: Colors.cyanAccent,
                            overlayColor: Colors.cyanAccent.withOpacity(0.15),
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            value: padLeft.toDouble(),
                            min: 1,
                            max: 8,
                            divisions: 7,
                            onChanged: (v) => notifier.setPadLeft(v.toInt()),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final generateCount = ref.watch(randomizerProvider.select((s) => s.generateCount));
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('一次抽取总项数:', style: TextStyle(color: subTextColor, fontSize: 12)),
                            Text('$generateCount 项', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: Colors.cyanAccent,
                            inactiveTrackColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                            thumbColor: Colors.cyanAccent,
                            overlayColor: Colors.cyanAccent.withOpacity(0.15),
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            value: generateCount.toDouble(),
                            min: 1,
                            max: 30,
                            divisions: 29,
                            onChanged: (v) => notifier.setGenerateCount(v.toInt()),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final allowDuplicates = ref.watch(randomizerProvider.select((s) => s.allowDuplicates));
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('允许结果出现重复项:', style: TextStyle(color: subTextColor, fontSize: 12)),
                        Switch(
                          value: allowDuplicates,
                          activeThumbColor: Colors.cyanAccent,
                          activeTrackColor: Colors.cyanAccent.withOpacity(0.2),
                          onChanged: notifier.setAllowDuplicates,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // RUN BUTTON & RESULTS
        Consumer(
          builder: (context, ref, child) {
            final isGenerating = ref.watch(randomizerProvider.select((s) => s.isGenerating));
            return ScaleOnTap(
              onTap: isGenerating ? null : notifier.runCombinatorialGenerate,
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.cyanAccent, Color(0xFF00B0FF)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
                  ],
                ),
                child: Center(
                  child: isGenerating
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2.5),
                        )
                      : const Text(
                          '一 键 沙 盒 区 间 抽 选',
                          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 2.0),
                        ),
                ),
              ),
            );
          },
        ),
        Consumer(
          builder: (context, ref, child) {
            final formattedResults = ref.watch(randomizerProvider.select((s) => s.formattedResults));
            if (formattedResults.isEmpty) return const SizedBox.shrink();
            return Column(
              children: [
                const SizedBox(height: 24),
                _buildResultsDisplay(formattedResults, Colors.cyanAccent),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSmallTextInput({required TextEditingController controller, required String label, required ValueChanged<String> onChanged}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: textColor, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: faintTextColor, fontSize: 11),
          filled: true,
          fillColor: isDark ? Colors.white.withOpacity(0.015) : Colors.black.withOpacity(0.02),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        onChanged: onChanged,
      ),
    );
  }

  // ==================== 2. WEIGHTED DECISION SANDBOX UI ====================
  Widget _buildWeightedSandbox(BuildContext context, RandomizerNotifier notifier) {
    return Column(
      key: const ValueKey('weighted_sandbox'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.01),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextFormField(
                  controller: _addOptionController,
                  style: TextStyle(color: textColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '输入想要抽选的决策选项 (如: 吃火锅, 敲代码)',
                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.015) : Colors.black.withOpacity(0.02),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ScaleOnTap(
              onTap: () {
                final txt = _addOptionController.text.trim();
                if (txt.isNotEmpty) {
                  notifier.addWeightedOption(txt);
                  _addOptionController.clear();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.pinkAccent, Color(0xFFFF4081)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.pinkAccent.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Icon(Icons.add, color: textColor, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Consumer(
          builder: (context, ref, child) {
            final weightedOptions = ref.watch(randomizerProvider.select((s) => s.weightedOptions));
            if (weightedOptions.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.01),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.edit_note_rounded, color: Colors.white24, size: 38),
                    const SizedBox(height: 8),
                    Text('目前还没有配置选项，快添加几个吧！✏️', style: TextStyle(color: faintTextColor, fontSize: 12)),
                  ],
                ),
              );
            }
            return HoverGlowCard(
              glowColor: Colors.pinkAccent,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.015) : Colors.black.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('决策权重与中签概率实时雷达', style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('共 ${weightedOptions.length} 个选择', style: const TextStyle(color: Colors.pinkAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: List.generate(weightedOptions.length, (idx) {
                        final item = weightedOptions[idx];
                        final prob = notifier.getProbabilityOfOption(item.id);
                        return RandomOptionRow(
                          key: ValueKey(item.id),
                          id: item.id,
                          text: item.text,
                          weight: item.weight,
                          probability: prob,
                          notifier: notifier,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Consumer(
          builder: (context, ref, child) {
            final weightedOptions = ref.watch(randomizerProvider.select((s) => s.weightedOptions));
            if (weightedOptions.isEmpty) return const SizedBox.shrink();
            final drawCount = ref.watch(randomizerProvider.select((s) => s.drawCount));
            final isGenerating = ref.watch(randomizerProvider.select((s) => s.isGenerating));
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('本次决策最终抽取数:', style: TextStyle(color: subTextColor, fontSize: 12)),
                    Text('$drawCount 项', style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Colors.pinkAccent,
                    inactiveTrackColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                    thumbColor: Colors.pinkAccent,
                    overlayColor: Colors.pinkAccent.withOpacity(0.15),
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: drawCount.clamp(1, weightedOptions.length).toDouble(),
                    min: 1,
                    max: weightedOptions.length.toDouble(),
                    divisions: (weightedOptions.length - 1).clamp(1, 100),
                    onChanged: (v) => notifier.setDrawCount(v.toInt()),
                  ),
                ),
                const SizedBox(height: 20),
                ScaleOnTap(
                  onTap: isGenerating ? null : notifier.runWeightedDecision,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.pinkAccent, Color(0xFFFF5E62)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(color: Colors.pinkAccent.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
                      ],
                    ),
                    child: Center(
                      child: isGenerating
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: textColor, strokeWidth: 2.5),
                            )
                          : Text(
                              '注 入 权 重 并 抽 选',
                              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 2.0),
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        Consumer(
          builder: (context, ref, child) {
            final drawnOptions = ref.watch(randomizerProvider.select((s) => s.drawnOptions));
            if (drawnOptions.isEmpty) return const SizedBox.shrink();
            return Column(
              children: [
                const SizedBox(height: 24),
                _buildResultsDisplay(drawnOptions, Colors.pinkAccent),
              ],
            );
          },
        ),
      ],
    );
  }

  // ==================== 3. DICE SANDBOX UI ====================
  Widget _buildDiceSandbox(BuildContext context, RandomizerNotifier notifier) {
    return Column(
      key: const ValueKey('dice_sandbox'),
      children: [
        HoverGlowCard(
          glowColor: Colors.orangeAccent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.015) : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.dashboard_customize_outlined, color: Colors.orangeAccent, size: 16),
                    const SizedBox(width: 6),
                    Text('自由定制命运骰子表面刻印', style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _diceLabelsController,
                  style: TextStyle(color: textColor, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: '输入逗号分割的项 (如: 是, 否, 弃权)',
                    labelStyle: const TextStyle(color: Colors.white24, fontSize: 11),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.015) : Colors.black.withOpacity(0.02),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                  onChanged: notifier.setCustomDiceLabels,
                ),
                const SizedBox(height: 20),
                Consumer(
                  builder: (context, ref, child) {
                    final diceSides = ref.watch(randomizerProvider.select((s) => s.diceSides));
                    return ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _diceLabelsController,
                      builder: (context, value, child) {
                        if (value.text.trim().isNotEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text('💡 已成功解锁“全息自由文本骰”！将从文字列表中均等概率抛出。', style: TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.w600)),
                            ),
                          );
                        }
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('使用标准多面数值骰:', style: TextStyle(color: subTextColor, fontSize: 12)),
                                Text('$diceSides 面骰', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: Colors.orangeAccent,
                                inactiveTrackColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                                thumbColor: Colors.orangeAccent,
                                overlayColor: Colors.orangeAccent.withOpacity(0.15),
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              ),
                              child: Slider(
                                value: diceSides.toDouble(),
                                min: 4,
                                max: 120,
                                divisions: 58,
                                onChanged: (v) => notifier.setDiceSides(v.toInt()),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        Consumer(
          builder: (context, ref, child) {
            final isGenerating = ref.watch(randomizerProvider.select((s) => s.isGenerating));
            final diceRollResults = ref.watch(randomizerProvider.select((s) => s.diceRollResults));
            return DiceBouncingCanvas(
              isGenerating: isGenerating,
              diceRollResults: diceRollResults,
              onRoll: () => notifier.rollCustomDice(),
            );
          },
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
        color: isDark ? Colors.white.withOpacity(0.015) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('🎉 随机沙盒抽选结果清单:', style: TextStyle(color: subTextColor, fontSize: 12)),
              ScaleOnTap(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: results.join('\n')));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚡ 全部抽取结果已成功复制'),
                      backgroundColor: Colors.white10,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.35)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.copy_rounded, color: color, size: 14),
                      const SizedBox(width: 4),
                      Text('一键复制', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(results.length, (idx) {
              final e = results[idx];
              return StaggerEntrance(
                index: idx,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.35)),
                  ),
                  child: Text(
                    e,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
