import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../../../core/widgets/glass_card.dart';

class NoiseBreathingBubble extends StatefulWidget {
  final bool isBreathingActive;
  final Color glowColor;
  final int breathingSecondsRemaining;
  final int completedCycles;
  final String breathingPhase;
  final VoidCallback onToggle;
  final int phaseDuration;

  const NoiseBreathingBubble({
    super.key,
    required this.isBreathingActive,
    required this.glowColor,
    required this.breathingSecondsRemaining,
    required this.completedCycles,
    required this.breathingPhase,
    required this.onToggle,
    required this.phaseDuration,
  });

  @override
  State<NoiseBreathingBubble> createState() => _NoiseBreathingBubbleState();
}

class _NoiseBreathingBubbleState extends State<NoiseBreathingBubble> {
  Timer? _bubbleSmoothTimer;
  double _bubbleScale = 1.0;
  double _elapsedFraction = 0.0;
  int _elapsedMs = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isBreathingActive) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(NoiseBreathingBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBreathingActive != oldWidget.isBreathingActive ||
        widget.breathingPhase != oldWidget.breathingPhase ||
        widget.phaseDuration != oldWidget.phaseDuration ||
        widget.breathingSecondsRemaining != oldWidget.breathingSecondsRemaining) {
      
      // If phase changes or seconds remaining changes, align the smooth animation
      if (widget.breathingPhase != oldWidget.breathingPhase) {
        _elapsedMs = 0;
      }
      
      if (widget.isBreathingActive) {
        _startTimer();
      } else {
        _stopTimer();
      }
    }
  }

  @override
  void dispose() {
    _bubbleSmoothTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _bubbleSmoothTimer?.cancel();
    const int updatePeriodMs = 40;
    
    _bubbleSmoothTimer = Timer.periodic(
      const Duration(milliseconds: updatePeriodMs),
      (timer) {
        if (!mounted || !widget.isBreathingActive) {
          timer.cancel();
          return;
        }

        _elapsedMs += updatePeriodMs;
        final currentSecondsElapsed = widget.phaseDuration - widget.breathingSecondsRemaining;

        setState(() {
          final double ratio = (currentSecondsElapsed + (_elapsedMs % 1000) / 1000.0) / widget.phaseDuration;
          _elapsedFraction = ratio.clamp(0.0, 1.0);
          
          switch (widget.breathingPhase) {
            case 'inhale':
              _bubbleScale = 1.0 + (0.8 * _elapsedFraction);
              break;
            case 'hold':
              _bubbleScale = 1.8 + sin(DateTime.now().millisecondsSinceEpoch / 250.0) * 0.03;
              break;
            case 'exhale':
              _bubbleScale = 1.8 - (0.8 * _elapsedFraction);
              break;
            case 'hold2':
              _bubbleScale = 1.0 + sin(DateTime.now().millisecondsSinceEpoch / 250.0) * 0.01;
              break;
          }
        });
      },
    );
  }

  void _stopTimer() {
    _bubbleSmoothTimer?.cancel();
    _bubbleSmoothTimer = null;
    setState(() {
      _bubbleScale = 1.0;
      _elapsedFraction = 0.0;
      _elapsedMs = 0;
    });
  }

  String _getBreathingPhaseEmoji() {
    if (!widget.isBreathingActive) return '🧘';
    switch (widget.breathingPhase) {
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
    if (!widget.isBreathingActive) return '开始吸气放松调息';
    switch (widget.breathingPhase) {
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
    final Color faintTextColor = isDark ? Colors.white38 : Colors.black54;

    return GlassCard(
      glowColor: widget.isBreathingActive
          ? widget.glowColor
          : (isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.04)),
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
                    if (widget.isBreathingActive)
                      ...List.generate(2, (idx) {
                        final delayOffset = (idx + 1) / 3.0;
                        final currentScale = _bubbleScale + (delayOffset * 0.15);
                        return Transform.scale(
                          scale: currentScale.clamp(1.0, 2.5),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: widget.glowColor.withValues(
                                  alpha: ((0.15 - (idx * 0.05)) * (1.0 - _elapsedFraction)).clamp(0.0, 1.0),
                                ),
                                width: 1.5,
                              ),
                            ),
                          ),
                        );
                      }),
                    Transform.scale(
                      scale: _bubbleScale,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              widget.isBreathingActive
                                  ? widget.glowColor.withValues(alpha: 0.25)
                                  : (isDark
                                        ? Colors.white.withValues(alpha: 0.02)
                                        : Colors.black.withValues(alpha: 0.03)),
                              widget.isBreathingActive
                                  ? widget.glowColor.withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.005),
                            ],
                          ),
                          border: Border.all(
                            color: widget.isBreathingActive
                                ? widget.glowColor
                                : (isDark ? Colors.white30 : Colors.black26),
                            width: widget.isBreathingActive ? 2.5 : 1.5,
                          ),
                          boxShadow: [
                            if (widget.isBreathingActive)
                              BoxShadow(
                                color: widget.glowColor.withValues(alpha: 0.35),
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
              widget.isBreathingActive
                  ? '当前周期倒计时：${widget.breathingSecondsRemaining} 秒'
                  : '选择模式开启科学吐纳',
              style: TextStyle(color: faintTextColor, fontSize: 11.5),
            ),
            if (widget.isBreathingActive && widget.completedCycles > 0) ...[
              const SizedBox(height: 6),
              Text(
                '已成功调息：${widget.completedCycles} 次循环',
                style: TextStyle(
                  color: widget.glowColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 20),
            GestureDetector(
              onTap: widget.onToggle,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.isBreathingActive
                        ? [Colors.redAccent, Colors.deepOrangeAccent]
                        : [widget.glowColor.withValues(alpha: 0.8), widget.glowColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.isBreathingActive ? Colors.redAccent : widget.glowColor)
                          .withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isBreathingActive
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isBreathingActive ? '停止呼吸向导' : '开始放松调息',
                      style: const TextStyle(
                        color: Colors.white,
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
