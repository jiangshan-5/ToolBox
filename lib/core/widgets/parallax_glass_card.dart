import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'glass_card.dart';

class ParallaxGlassCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double tiltSensitivity;

  const ParallaxGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderColor,
    this.tiltSensitivity = 0.015,
  });

  @override
  State<ParallaxGlassCard> createState() => _ParallaxGlassCardState();
}

class _ParallaxGlassCardState extends State<ParallaxGlassCard> {
  double _pitch = 0.0;
  double _roll = 0.0;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  @override
  void initState() {
    super.initState();
    try {
      _accelerometerSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
        if (mounted) {
          setState(() {
            // Cap the max tilt to prevent extreme flips
            double clampedX = event.x.clamp(-10.0, 10.0);
            double clampedY = event.y.clamp(-10.0, 10.0);
            _roll = clampedX * widget.tiltSensitivity;
            _pitch = clampedY * widget.tiltSensitivity;
          });
        }
      });
    } catch (e) {
      // Fallback if device has no accelerometer
      debugPrint('Accelerometer not available: $e');
    }
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 3D Perspective Matrix
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.001) // perspective
      ..rotateX(-_pitch) // tilt up/down
      ..rotateY(-_roll);  // tilt left/right

    return TweenAnimationBuilder(
      tween: Matrix4Tween(begin: Matrix4.identity(), end: matrix),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutQuart,
      builder: (context, Matrix4 value, child) {
        return Transform(
          transform: value,
          alignment: FractionalOffset.center,
          child: child,
        );
      },
      child: GlassCard(
        onTap: () {
          HapticFeedback.lightImpact(); // Micro-interaction vibration
          if (widget.onTap != null) widget.onTap!();
        },
        borderColor: widget.borderColor,
        child: widget.child,
      ),
    );
  }
}
