import 'package:flutter/material.dart';

/// Satisfying physics-based bounce feedback when tapped.
class ScaleOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;

  const ScaleOnTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.93,
  });

  @override
  State<ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<ScaleOnTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
      ),
    );
  }
}

/// Dynamic card adding smooth floating lift and neon glow breathing when hovered on web
class HoverGlowCard extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double liftOffset;
  final BorderRadius borderRadius;

  const HoverGlowCard({
    super.key,
    required this.child,
    required this.glowColor,
    this.liftOffset = -6.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
  });

  @override
  State<HoverGlowCard> createState() => _HoverGlowCardState();
}

class _HoverGlowCardState extends State<HoverGlowCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(
          0.0,
          _isHovered ? widget.liftOffset : 0.0,
          0.0,
        ),
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? widget.glowColor.withOpacity(0.25)
                  : widget.glowColor.withOpacity(0.02),
              blurRadius: _isHovered ? 25 : 10,
              spreadRadius: _isHovered ? 4 : 0,
              offset: Offset(0, _isHovered ? 12 : 4),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

/// Multi-unit / Multi-option staggered slide up and fade entrance animation
class StaggerEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delayStep;

  const StaggerEntrance({
    super.key,
    required this.child,
    required this.index,
    this.delayStep = const Duration(milliseconds: 60),
  });

  @override
  State<StaggerEntrance> createState() => _StaggerEntranceState();
}

class _StaggerEntranceState extends State<StaggerEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slide = Tween<Offset>(
      begin: const Offset(0.0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    Future.delayed(widget.delayStep * widget.index, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Slowly breathing background shadow pulse indicating high priority outcomes (e.g. BMI status card)
class PulseGlow extends StatefulWidget {
  final Widget child;
  final Color color;

  const PulseGlow({super.key, required this.child, required this.color});

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowRadius;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowRadius = Tween<double>(
      begin: 8.0,
      end: 24.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowRadius,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.2),
                blurRadius: _glowRadius.value,
                spreadRadius: _glowRadius.value / 4.0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}
