import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../../../core/widgets/glass_card.dart';

class NoiseVisualizer extends StatefulWidget {
  final bool isMixerPlaying;
  final VoidCallback onToggleMixerPlay;
  final double maxWaveHeight;

  const NoiseVisualizer({
    super.key,
    required this.isMixerPlaying,
    required this.onToggleMixerPlay,
    this.maxWaveHeight = 42.0,
  });

  @override
  State<NoiseVisualizer> createState() => _NoiseVisualizerState();
}

class _NoiseVisualizerState extends State<NoiseVisualizer> {
  Timer? _visualizerTimer;
  final List<double> _visualizerHeights = List.generate(24, (_) => 4.0);
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    if (widget.isMixerPlaying) {
      _startVisualizerAnimation();
    }
  }

  @override
  void didUpdateWidget(NoiseVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMixerPlaying != oldWidget.isMixerPlaying) {
      if (widget.isMixerPlaying) {
        _startVisualizerAnimation();
      } else {
        _visualizerTimer?.cancel();
        setState(() {
          _visualizerHeights.fillRange(0, _visualizerHeights.length, 4.0);
        });
      }
    }
  }

  @override
  void dispose() {
    _visualizerTimer?.cancel();
    super.dispose();
  }

  void _startVisualizerAnimation() {
    _visualizerTimer?.cancel();
    _visualizerTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted || !widget.isMixerPlaying) {
        timer.cancel();
        return;
      }
      setState(() {
        for (var i = 0; i < _visualizerHeights.length; i++) {
          _visualizerHeights[i] = 3.0 + _random.nextDouble() * widget.maxWaveHeight;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color faintTextColor = isDark ? Colors.white38 : Colors.black54;

    return GlassCard(
      glowColor: widget.isMixerPlaying
          ? Colors.cyanAccent
          : (isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.04)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _visualizerHeights.map((h) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: 5,
                    height: widget.isMixerPlaying ? h : 4.0,
                    decoration: BoxDecoration(
                      color: widget.isMixerPlaying
                          ? Colors.cyanAccent.withValues(alpha: 0.8)
                          : (isDark ? Colors.white12 : Colors.black12),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        if (widget.isMixerPlaying)
                          BoxShadow(
                            color: Colors.cyanAccent.withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isMixerPlaying ? '大自然环绕声效混音中' : '声景播放已静音',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '支持开启多声道声效，混合出独属您的冥想空间',
                      style: TextStyle(color: faintTextColor, fontSize: 10),
                    ),
                  ],
                ),
                IconButton(
                  iconSize: 42,
                  icon: Icon(
                    widget.isMixerPlaying
                        ? Icons.stop_circle_rounded
                        : Icons.play_circle_fill_rounded,
                    color: Colors.cyanAccent,
                  ),
                  onPressed: widget.onToggleMixerPlay,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
