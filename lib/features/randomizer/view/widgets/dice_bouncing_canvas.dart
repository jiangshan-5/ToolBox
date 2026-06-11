import 'package:flutter/material.dart';
import '../../../../core/widgets/dynamic_effects.dart';

class DiceBouncingCanvas extends StatefulWidget {
  final bool isGenerating;
  final List<String> diceRollResults;
  final Future<void> Function() onRoll;

  const DiceBouncingCanvas({
    super.key,
    required this.isGenerating,
    required this.diceRollResults,
    required this.onRoll,
  });

  @override
  State<DiceBouncingCanvas> createState() => _DiceBouncingCanvasState();
}

class _DiceBouncingCanvasState extends State<DiceBouncingCanvas> {
  bool _isDiceBouncing = false;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get textColor => isDark ? Colors.white : Colors.black87;

  @override
  Widget build(BuildContext context) {
    return ScaleOnTap(
      onTap: widget.isGenerating || _isDiceBouncing
          ? null
          : () async {
              setState(() => _isDiceBouncing = true);
              await widget.onRoll();
              if (mounted) {
                setState(() => _isDiceBouncing = false);
              }
            },
      child: HoverGlowCard(
        glowColor: isDark ? Colors.orangeAccent : Colors.orange.shade800,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          height: 190,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF7B00), Color(0xFFFFC107)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.orangeAccent.withOpacity(
                  _isDiceBouncing ? 0.55 : 0.25,
                ),
                blurRadius: _isDiceBouncing ? 35 : 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_isDiceBouncing)
                Positioned(
                  top: 18,
                  child: Text(
                    '🎲 命运骰子飞速旋转中 ...',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0,
                      end: _isDiceBouncing ? 10 * 3.14159 : 0,
                    ),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.bounceOut,
                    builder: (context, value, child) {
                      return Transform.rotate(
                        angle: value,
                        child: Transform.scale(
                          scale: _isDiceBouncing ? 1.3 : 1.0,
                          child: Icon(
                            Icons.casino_rounded,
                            color: textColor,
                            size: 76,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.diceRollResults.isEmpty
                        ? '点击骰蛊投掷命运'
                        : '投掷结果: ${widget.diceRollResults.first}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
