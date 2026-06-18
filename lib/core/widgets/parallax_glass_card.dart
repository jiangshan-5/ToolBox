import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'glass_card.dart';

class ParallaxGlassCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? glowColor;
  final double tiltSensitivity;

  const ParallaxGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderColor,
    this.glowColor,
    this.tiltSensitivity = 0.015,
  });

  @override
  State<ParallaxGlassCard> createState() => _ParallaxGlassCardState();
}

class _ParallaxGlassCardState extends State<ParallaxGlassCard> {
  static final ValueNotifier<Offset> _globalTilt = ValueNotifier(Offset.zero);
  static StreamSubscription<AccelerometerEvent>?
  _globalAccelerometerSubscription;
  static DateTime _lastTiltUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  static int _activeTiltCards = 0;

  static const Duration _tiltFrameInterval = Duration(milliseconds: 66);
  static const double _minimumTiltDelta = 0.15;

  double _pitch = 0.0;
  double _roll = 0.0;
  double _scale = 1.0;
  VoidCallback? _tiltListener;

  bool get _usesMotionTilt => widget.tiltSensitivity > 0;

  @override
  void initState() {
    super.initState();
    if (!_usesMotionTilt) return;

    _tiltListener = () {
      if (!mounted) return;
      final tilt = _globalTilt.value;
      final nextRoll = tilt.dx * widget.tiltSensitivity;
      final nextPitch = tilt.dy * widget.tiltSensitivity;
      if ((nextRoll - _roll).abs() < 0.002 &&
          (nextPitch - _pitch).abs() < 0.002) {
        return;
      }
      setState(() {
        _roll = nextRoll;
        _pitch = nextPitch;
      });
    };
    _globalTilt.addListener(_tiltListener!);
    _activeTiltCards++;
    _ensureAccelerometerSubscription();
  }

  static void _ensureAccelerometerSubscription() {
    if (_globalAccelerometerSubscription != null) return;
    try {
      _globalAccelerometerSubscription = accelerometerEventStream().listen(
        (AccelerometerEvent event) {
          final now = DateTime.now();
          if (now.difference(_lastTiltUpdate) < _tiltFrameInterval) return;
          _lastTiltUpdate = now;

          // Cap the max tilt to prevent extreme flips.
          final nextTilt = Offset(
            event.x.clamp(-10.0, 10.0).toDouble(),
            event.y.clamp(-10.0, 10.0).toDouble(),
          );
          if ((nextTilt - _globalTilt.value).distance < _minimumTiltDelta) {
            return;
          }
          _globalTilt.value = nextTilt;
        },
        onError: (Object error) {
          debugPrint('Accelerometer not available: $error');
        },
      );
    } catch (e) {
      // Fallback if device has no accelerometer
      debugPrint('Accelerometer not available: $e');
    }
  }

  @override
  void dispose() {
    final listener = _tiltListener;
    if (listener != null) {
      _globalTilt.removeListener(listener);
      _activeTiltCards = _activeTiltCards > 0 ? _activeTiltCards - 1 : 0;
      if (_activeTiltCards == 0) {
        _globalAccelerometerSubscription?.cancel();
        _globalAccelerometerSubscription = null;
        _globalTilt.value = Offset.zero;
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 3D Perspective Matrix combined with scale down for tap feedback
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.001) // perspective
      ..rotateX(-_pitch) // tilt up/down
      ..rotateY(-_roll) // tilt left/right
      ..scaleByDouble(_scale, _scale, 1, 1); // dynamic scale feedback

    return Listener(
      onPointerDown: (_) {
        if (widget.onTap != null && mounted) {
          setState(() => _scale = 0.96);
        }
      },
      onPointerUp: (_) {
        if (widget.onTap != null && mounted) {
          setState(() => _scale = 1.0);
        }
      },
      onPointerCancel: (_) {
        if (widget.onTap != null && mounted) {
          setState(() => _scale = 1.0);
        }
      },
      child: TweenAnimationBuilder(
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
          onTap: widget.onTap == null
              ? null
              : () {
                  HapticFeedback.lightImpact(); // Micro-interaction vibration
                  widget.onTap!();
                },
          borderColor: widget.borderColor,
          glowColor: widget.glowColor,
          child: widget.child,
        ),
      ),
    );
  }
}
