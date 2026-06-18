import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/widgets/dynamic_effects.dart';

/// Floating Glassmorphic Bottom Navigation Bar mimicking premium mainstream shells
class DashboardNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const DashboardNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final width = MediaQuery.of(context).size.width;

    // Constrain width on wide screens (BETA/Tablet/Web layout optimization)
    final horizontalMargin = width < 360 ? 12.0 : 24.0;
    final double navBarWidth = width > 600 ? 460 : width - horizontalMargin * 2;

    return Positioned(
      bottom: bottomPadding > 0 ? bottomPadding : 20,
      left: (width - navBarWidth) / 2,
      width: navBarWidth,
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: isDark
              ? colors.surface.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : colors.primary.withValues(alpha: 0.08),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Stack(
              children: [
                // Horizontal Animated Selection Slider block
                AnimatedAlign(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  alignment: Alignment(
                    currentIndex == 0
                        ? -0.926
                        : currentIndex == 1
                        ? 0.0
                        : 0.926,
                    0.0,
                  ),
                  child: FractionallySizedBox(
                    widthFactor: 0.28,
                    heightFactor: 0.72,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.15),
                          width: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
                // Navigation items
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(context, 0, Icons.grid_view_rounded, '工作台'),
                    _buildNavItem(context, 1, Icons.bar_chart_rounded, '分析站'),
                    _buildNavItem(
                      context,
                      2,
                      Icons.face_retouching_natural_rounded,
                      '个人中心',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = currentIndex == index;

    final Color color = isSelected
        ? primaryColor
        : (isDark ? Colors.white54 : Colors.black45);

    return Expanded(
      child: ScaleOnTap(
        onTap: () => onTabSelected(index),
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Icon(icon, color: color, size: isSelected ? 24 : 22),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  letterSpacing: 0,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
