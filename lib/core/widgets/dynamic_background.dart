import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toolbox_app/features/settings/provider/settings_provider.dart';

class DynamicBackground extends ConsumerStatefulWidget {
  final Widget child;

  const DynamicBackground({super.key, required this.child});

  @override
  ConsumerState<DynamicBackground> createState() => _DynamicBackgroundState();
}

class _DynamicBackgroundState extends ConsumerState<DynamicBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLowPower = ref.watch(settingsProvider).isLowPowerMode;
    final theme = Theme.of(context);
    final surfaceColor = theme.colorScheme.surface;
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;

    if (isLowPower) {
      if (_controller.isAnimating) {
        _controller.stop();
      }
      return Stack(
        children: [
          // Solid Backdrop
          Container(
            color: surfaceColor,
          ),
          
          // Floating Mesh Gradients (Static positions)
          Positioned(
            top: -50,
            left: -100,
            child: Container(
              width: MediaQuery.of(context).size.width * 1.2,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.08),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.12),
                    blurRadius: 200,
                    spreadRadius: 150,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -50,
            child: Container(
              width: MediaQuery.of(context).size.width * 1.2,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: secondaryColor.withOpacity(0.08),
                boxShadow: [
                  BoxShadow(
                    color: secondaryColor.withOpacity(0.12),
                    blurRadius: 200,
                    spreadRadius: 150,
                  ),
                ],
              ),
            ),
          ),
          
          // Foreground Content
          widget.child,
        ],
      );
    } else {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
      return Stack(
        children: [
          // Solid Backdrop
          Container(
            color: surfaceColor,
          ),
          
          // Floating Mesh Gradients
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -50 + math.sin(_controller.value * 2 * math.pi) * 80,
                    left: -100 + math.cos(_controller.value * 2 * math.pi) * 80,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 1.2,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withOpacity(0.08),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.12),
                            blurRadius: 200,
                            spreadRadius: 150,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -100 + math.cos(_controller.value * 2 * math.pi) * 80,
                    right: -50 + math.sin(_controller.value * 2 * math.pi) * 80,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 1.2,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: secondaryColor.withOpacity(0.08),
                        boxShadow: [
                          BoxShadow(
                            color: secondaryColor.withOpacity(0.12),
                            blurRadius: 200,
                            spreadRadius: 150,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          // Foreground Content
          widget.child,
        ],
      );
    }
  }
}
