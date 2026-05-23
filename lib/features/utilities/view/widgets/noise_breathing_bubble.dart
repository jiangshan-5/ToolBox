import 'package:flutter/material.dart';
import '../../../../core/widgets/glass_card.dart';

class NoiseBreathingBubble extends StatelessWidget {
  final bool isBreathingActive;
  final Color glowColor;
  final double bubbleScale;
  final double elapsedFraction;
  final int breathingSecondsRemaining;
  final int completedCycles;
  final String breathingPhase;
  final VoidCallback onToggle;

  const NoiseBreathingBubble({
    super.key,
    required this.isBreathingActive,
    required this.glowColor,
    required this.bubbleScale,
    required this.elapsedFraction,
    required this.breathingSecondsRemaining,
    required this.completedCycles,
    required this.breathingPhase,
    required this.onToggle,
  });

  String _getBreathingPhaseEmoji() {
    if (!isBreathingActive) return '🧘';
    switch (breathingPhase) {
      case 'inhale':
        return '🌬️';
      case 'hold':
      case 'hold2':
        return '⚓';
      case 'exhale':
        return '💨';
      default:
        return '🧘';
    }
  }

  String _getBreathingPhaseText() {
    if (!isBreathingActive) return '开始吸气放松调息';
    switch (breathingPhase) {
      case 'inhale':
        return '💨 缓慢吸气...';
      case 'hold':
        return '🧘 屏住呼吸，专注静止...';
      case 'exhale':
        return '🌬️ 吐出焦虑，全身放松...';
      case 'hold2':
        return '🔒 保持空肺，安宁凝神...';
      default:
        return '平静放松中...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color faintTextColor = isDark ? Colors.white38 : Colors.black38;

    return GlassCard(
      glowColor: isBreathingActive
          ? glowColor
          : (isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.black.withOpacity(0.04)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        child: Column(
          children: [
            Center(
              child: SizedBox(
                height: 220,
                width: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isBreathingActive)
                      ...List.generate(2, (idx) {
                        final delayOffset = (idx + 1) / 3.0;
                        final currentScale = bubbleScale + (delayOffset * 0.15);
                        return Transform.scale(
                          scale: currentScale.clamp(1.0, 2.5),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: glowColor.withOpacity(
                                  (0.15 - (idx * 0.05)) *
                                      (1.0 - elapsedFraction),
                                ),
                                width: 1.5,
                              ),
                            ),
                          ),
                        );
                      }),
                    Transform.scale(
                      scale: bubbleScale,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              isBreathingActive
                                  ? glowColor.withOpacity(0.25)
                                  : (isDark
                                        ? Colors.white.withOpacity(0.02)
                                        : Colors.black.withOpacity(0.03)),
                              isBreathingActive
                                  ? glowColor.withOpacity(0.08)
                                  : Colors.white.withOpacity(0.005),
                            ],
                          ),
                          border: Border.all(
                            color: isBreathingActive
                                ? glowColor
                                : Colors.white30,
                            width: isBreathingActive ? 2.5 : 1.5,
                          ),
                          boxShadow: [
                            if (isBreathingActive)
                              BoxShadow(
                                color: glowColor.withOpacity(0.35),
                                blurRadius: 18,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _getBreathingPhaseEmoji(),
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _getBreathingPhaseText(),
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isBreathingActive
                  ? '当前周期倒计时：$breathingSecondsRemaining 秒'
                  : '选择模式开启科学吐纳',
              style: TextStyle(color: faintTextColor, fontSize: 11.5),
            ),
            if (isBreathingActive && completedCycles > 0) ...[
              const SizedBox(height: 6),
              Text(
                '已成功调息：$completedCycles 次循环',
                style: TextStyle(
                  color: glowColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onToggle,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isBreathingActive
                        ? [Colors.redAccent, Colors.deepOrangeAccent]
                        : [glowColor.withOpacity(0.8), glowColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (isBreathingActive ? Colors.redAccent : glowColor)
                          .withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isBreathingActive
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_arrow_rounded,
                      color: textColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isBreathingActive ? '停止呼吸向导' : '开始放松调息',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
