import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? glowColor;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderColor,
    this.glowColor,
    this.borderRadius = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = BorderRadius.circular(borderRadius);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: effectiveBorderRadius,
          boxShadow: [
            if (glowColor != null) ...[
              // Vibrant Cyberpunk Breathing Glow
              BoxShadow(
                color: glowColor!.withOpacity(isDark ? 0.12 : 0.08),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: glowColor!.withOpacity(isDark ? 0.06 : 0.04),
                blurRadius: 40,
                spreadRadius: -4,
                offset: const Offset(0, 16),
              ),
            ] else ...[
              // Premium ambient dark drop shadow for maximum physical depth
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: isDark ? Colors.deepPurpleAccent.withOpacity(0.03) : Colors.black.withOpacity(0.01),
                blurRadius: 30,
                spreadRadius: 1,
              ),
            ],
          ],
        ),
        child: ClipRRect(
          borderRadius: effectiveBorderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16), // Increased blur for a premium frosted look
            child: Container(
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withOpacity(0.04) 
                    : Colors.white.withOpacity(0.65), // Standard frosted glass look for light mode
                borderRadius: effectiveBorderRadius,
                border: Border.all(
                  color: borderColor ?? 
                      (glowColor != null 
                          ? glowColor!.withOpacity(isDark ? 0.25 : 0.18) 
                          : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06))),
                  width: 1.2,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
