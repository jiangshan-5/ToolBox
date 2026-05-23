import 'package:flutter/material.dart';

class LedMarqueeWidget extends StatefulWidget {
  final String text;
  final double fontSize;
  final double speedMultiplier;
  final Color glowColor;
  final List<Color> neonGradient;
  final double glowRadius;

  const LedMarqueeWidget({
    super.key,
    required this.text,
    required this.fontSize,
    required this.speedMultiplier,
    required this.glowColor,
    required this.neonGradient,
    required this.glowRadius,
  });

  @override
  State<LedMarqueeWidget> createState() => _LedMarqueeWidgetState();
}

class _LedMarqueeWidgetState extends State<LedMarqueeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _containerWidth = 0;
  double _textWidth = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _controller.addListener(() {
      setState(() {});
    });
    _updateSpeedAndDuration();
  }

  @override
  void didUpdateWidget(covariant LedMarqueeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _calculateTextWidth();
    _updateSpeedAndDuration();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _calculateTextWidth() {
    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.text,
        style: TextStyle(
          fontSize: widget.fontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    setState(() {
      _textWidth = textPainter.width;
    });
  }

  void _updateSpeedAndDuration() {
    if (_textWidth <= 0 || _containerWidth <= 0) return;
    final distance = _containerWidth + _textWidth;
    final pixelsPerSecond = widget.speedMultiplier * 70.0;
    final seconds = distance / pixelsPerSecond;
    _controller.duration = Duration(milliseconds: (seconds * 1000).round());
    if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (_containerWidth != constraints.maxWidth) {
          _containerWidth = constraints.maxWidth;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _calculateTextWidth();
              _updateSpeedAndDuration();
            }
          });
        }
        final xOffset =
            _containerWidth -
            (_containerWidth + _textWidth) * _controller.value;
        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            Transform.translate(
              offset: Offset(xOffset, 0),
              child: ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    colors: widget.neonGradient,
                  ).createShader(Offset.zero & bounds.size);
                },
                child: Text(
                  widget.text,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: textColor,
                    shadows: widget.glowRadius > 0
                        ? [
                            Shadow(
                              color: widget.glowColor.withOpacity(0.8),
                              blurRadius: widget.glowRadius,
                            ),
                            Shadow(
                              color: widget.glowColor.withOpacity(0.5),
                              blurRadius: widget.glowRadius * 1.5,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
