import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/randomizer_provider.dart';

/// Fully-featured, high-end Multi-Mode Randomizer Screen
class RandomizerScreen extends ConsumerWidget {
  const RandomizerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(randomizerProvider);
    final notifier = ref.read(randomizerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('多维极客随机选派中心', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (state.mode == RandomizerMode.number) _buildNumberModeConfig(context, state, notifier),
                        if (state.mode == RandomizerMode.list) _buildListModeConfig(state, notifier),
                        if (state.mode == RandomizerMode.dice) _buildDiceModeConfig(state, notifier),
                        
                        const SizedBox(height: 32),
                        _buildActionAndResults(context, state, notifier),
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
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          _buildTabButton('数字随机', RandomizerMode.number, state.mode, () => notifier.setMode(RandomizerMode.number)),
          _buildTabButton('选项抽签', RandomizerMode.list, state.mode, () => notifier.setMode(RandomizerMode.list)),
          _buildTabButton('掷骰中心', RandomizerMode.dice, state.mode, () => notifier.setMode(RandomizerMode.dice)),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, RandomizerMode targetMode, RandomizerMode currentMode, VoidCallback onTap) {
    final isSelected = targetMode == currentMode;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orangeAccent.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? Colors.orangeAccent.withOpacity(0.3) : Colors.transparent),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.orangeAccent : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- MODE CONFIGS ---

  Widget _buildNumberModeConfig(BuildContext context, RandomizerState state, RandomizerNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('区间参数配置', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildNumberInput('最小值', state.min.toString(), (v) {
                  final parsed = int.tryParse(v) ?? 1;
                  notifier.setMin(parsed);
                }),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildNumberInput('最大值', state.max.toString(), (v) {
                  final parsed = int.tryParse(v) ?? 100;
                  notifier.setMax(parsed);
                }),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '生成个数: ${state.count} 个',
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
          ),
          Slider(
            value: state.count.toDouble(),
            min: 1,
            max: 20,
            divisions: 19,
            activeColor: Colors.orangeAccent,
            inactiveColor: Colors.white10,
            onChanged: (v) => notifier.setCount(v.toInt()),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('允许生成重复数字', style: TextStyle(color: Colors.white70)),
              Switch(
                value: state.allowDuplicates,
                activeColor: Colors.orangeAccent,
                onChanged: notifier.setAllowDuplicates,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberInput(String label, String initialValue, ValueChanged<String> onChanged) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.orangeAccent, width: 1.5),
        ),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildListModeConfig(RandomizerState state, RandomizerNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('抽签池配置', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: state.listInput,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: '输入候选项，用中文/英文逗号或回车换行分隔',
              hintStyle: const TextStyle(color: Colors.white30),
              filled: true,
              fillColor: Colors.white.withOpacity(0.04),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.orangeAccent, width: 1.5),
              ),
            ),
            onChanged: notifier.setListInput,
          ),
          const SizedBox(height: 20),
          Text(
            '抽取候选项个数: ${state.listDrawCount} 项',
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
          ),
          Slider(
            value: state.listDrawCount.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: Colors.orangeAccent,
            inactiveColor: Colors.white10,
            onChanged: (v) => notifier.setListDrawCount(v.toInt()),
          ),
        ],
      ),
    );
  }

  Widget _buildDiceModeConfig(RandomizerState state, RandomizerNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('骰子个数选择', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              final val = index + 1;
              final isSel = state.diceCount == val;
              return GestureDetector(
                onTap: () => notifier.setDiceCount(val),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSel ? Colors.orangeAccent : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSel ? Colors.transparent : Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$val',
                      style: TextStyle(
                        color: isSel ? Colors.black87 : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // --- ACTION BUTTON & OUTPUT VIEWS ---

  Widget _buildActionAndResults(BuildContext context, RandomizerState state, RandomizerNotifier notifier) {
    VoidCallback? action;
    String btnText = '';

    if (state.mode == RandomizerMode.number) {
      action = notifier.generateNumbers;
      btnText = '生成随机数字';
    } else if (state.mode == RandomizerMode.list) {
      action = notifier.drawFromList;
      btnText = '从抽签池抽取';
    } else if (state.mode == RandomizerMode.dice) {
      action = notifier.rollDice;
      btnText = '掷出所有骰子';
    }

    return Column(
      children: [
        ElevatedButton(
          onPressed: state.isGenerating ? null : action,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            foregroundColor: Colors.black87,
            minimumSize: const Size(double.infinity, 58),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 8,
          ),
          child: state.isGenerating
              ? const CircularProgressIndicator(color: Colors.black87)
              : Text(
                  btnText,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
        ),
        const SizedBox(height: 40),
        
        // Output Panels
        if (state.mode == RandomizerMode.number && state.numberResults.isNotEmpty)
          _buildNumberResults(context, state.numberResults),
        if (state.mode == RandomizerMode.list && state.listResults.isNotEmpty)
          _buildListResults(context, state.listResults),
        if (state.mode == RandomizerMode.dice && state.diceResults.isNotEmpty)
          _buildDiceResults(state.diceResults),
      ],
    );
  }

  Widget _buildNumberResults(BuildContext context, List<int> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('随机生成数字结果', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
            IconButton(
              icon: const Icon(Icons.copy_rounded, color: Colors.orangeAccent, size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: results.join(', ')));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已复制结果至剪贴板'), duration: Duration(seconds: 1)),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: results.map((val) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9900), Color(0xFFFF5500)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.orangeAccent.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Text(
                '$val',
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildListResults(BuildContext context, List<String> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('抽签中签结果', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
            IconButton(
              icon: const Icon(Icons.copy_rounded, color: Colors.orangeAccent, size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: results.join(', ')));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已复制中签项至剪贴板'), duration: Duration(seconds: 1)),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: results.map((val) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orangeAccent.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.orangeAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      val,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDiceResults(List<int> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('骰子投掷结果', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: results.map((dots) {
            return Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Center(
                child: _buildDiceFace(dots),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            '点数总和: ${results.reduce((a, b) => a + b)} 点',
            style: const TextStyle(color: Colors.orangeAccent, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  /// Draw classic dots pattern for dice face
  Widget _buildDiceFace(int dots) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
      ),
      itemCount: 9,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final Map<int, List<int>> dotPositions = {
          1: [4],
          2: [0, 8],
          3: [0, 4, 8],
          4: [0, 2, 6, 8],
          5: [0, 2, 4, 6, 8],
          6: [0, 2, 3, 5, 6, 8],
        };

        bool hasDot = dotPositions[dots]!.contains(index);
        return Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: hasDot ? const Color(0xFFC30000) : Colors.transparent,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
