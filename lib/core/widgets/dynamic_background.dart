import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toolbox_app/features/settings/provider/settings_provider.dart';
import 'package:toolbox_app/core/providers/theme_provider.dart';
import 'package:toolbox_app/core/app_theme.dart';

class DynamicBackground extends ConsumerStatefulWidget {
  final Widget child;

  const DynamicBackground({super.key, required this.child});

  @override
  ConsumerState<DynamicBackground> createState() => _DynamicBackgroundState();
}

class _DynamicBackgroundState extends ConsumerState<DynamicBackground>
    with SingleTickerProviderStateMixin {
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

  Widget? _buildImageBackdrop(ThemeConfig themeConfig, Color surfaceColor, bool isDark) {
    final isCustomBg = themeConfig.type == AppThemeType.custom && themeConfig.customBgBase64 != null;
    if (!isCustomBg) return null;
    try {
      String base64Str = themeConfig.customBgBase64!;
      if (base64Str.contains(',')) {
        base64Str = base64Str.split(',')[1];
      }
      final bytes = base64.decode(base64Str);
      return Positioned.fill(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: MemoryImage(bytes),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  surfaceColor.withOpacity(isDark ? 0.78 : 0.82),
                  BlendMode.srcOver,
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error loading custom background image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLowPower = ref.watch(settingsProvider).isLowPowerMode;
    final themeConfig = ref.watch(themeProvider);
    final theme = Theme.of(context);
    final surfaceColor = theme.colorScheme.surface;
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;
    final isDark = theme.brightness == Brightness.dark;

    final double primaryOpacity = isDark ? 0.18 : 0.04;
    final double secondaryOpacity = isDark ? 0.15 : 0.03;
    final double primaryGlowOpacity = isDark ? 0.22 : 0.06;
    final double secondaryGlowOpacity = isDark ? 0.20 : 0.05;

    final imageBackdrop = _buildImageBackdrop(themeConfig, surfaceColor, isDark);

    if (isLowPower) {
      if (_controller.isAnimating) {
        _controller.stop();
      }
      return Stack(
        children: [
          // Solid Backdrop
          Container(color: surfaceColor),

          // Custom Background Image
          ?imageBackdrop,

          // Floating Mesh Gradients (Static positions)
          Positioned(
            top: -50,
            left: -100,
            child: Container(
              width: MediaQuery.of(context).size.width * 1.2,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(primaryOpacity),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(primaryGlowOpacity),
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
                color: secondaryColor.withOpacity(secondaryOpacity),
                boxShadow: [
                  BoxShadow(
                    color: secondaryColor.withOpacity(secondaryGlowOpacity),
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
          Container(color: surfaceColor),

          // Custom Background Image
          ?imageBackdrop,

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
                        color: primaryColor.withOpacity(primaryOpacity),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(primaryGlowOpacity),
                            blurRadius: 200,
                            spreadRadius: 150,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom:
                        -100 + math.cos(_controller.value * 2 * math.pi) * 80,
                    right: -50 + math.sin(_controller.value * 2 * math.pi) * 80,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 1.2,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: secondaryColor.withOpacity(secondaryOpacity),
                        boxShadow: [
                          BoxShadow(
                            color: secondaryColor.withOpacity(
                              secondaryGlowOpacity,
                            ),
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
