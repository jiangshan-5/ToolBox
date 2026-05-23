import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeType {
  cyberpunkDark,
  neonMidnight,
  volcanoCyber,
  forestMatrix,
  oceanCyber,
  sakuraDream,
  cyberpunkLight,
  neonMidnightLight,
  volcanoCyberLight,
  forestMatrixLight,
  oceanCyberLight,
  sakuraDreamLight,
  custom,
}

class AppThemePreset {
  final AppThemeType type;
  final String name;
  final Color primary;
  final Color secondary;
  final Color surface;
  final Color surfaceContainer;
  final bool isDark;

  const AppThemePreset({
    required this.type,
    required this.name,
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.surfaceContainer,
    required this.isDark,
  });
}

class AppTheme {
  static ThemeData buildTheme(AppThemePreset preset) {
    final brightness = preset.isDark ? Brightness.dark : Brightness.light;
    final textThemeBase = preset.isDark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    final isDark = preset.isDark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,

      // Cohesive Theme Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: preset.primary,
        brightness: brightness,
        surface: preset.surface,
        surfaceContainer: preset.surfaceContainer,
        primary: preset.primary,
        secondary: preset.secondary,
      ),

      // Outfit typography with explicit high contrast text colors for all themes
      textTheme: GoogleFonts.outfitTextTheme(
        textThemeBase.copyWith(
          bodyLarge: TextStyle(color: isDark ? Colors.white : Colors.black87),
          bodyMedium: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
          ),
          bodySmall: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
          titleLarge: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
          titleSmall: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
          ),
          labelLarge: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
          labelMedium: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          labelSmall: TextStyle(
            color: isDark ? Colors.white60 : Colors.black45,
          ),
        ),
      ),

      // Frosted card guidelines
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.03),
      ),

      // Dynamic Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: preset.primary,
        inactiveTrackColor: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.1),
        thumbColor: preset.secondary,
        overlayColor: preset.secondary.withOpacity(0.15),
        valueIndicatorColor: preset.primary,
        valueIndicatorTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
        trackHeight: 4.0,
      ),

      // Glowing Custom Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return preset.secondary;
          }
          return isDark ? Colors.grey.shade400 : Colors.grey.shade600;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return preset.primary.withOpacity(0.5);
          }
          return isDark ? Colors.white12 : Colors.black12;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // Interactive Button Theme Defaulting
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: preset.primary,
          foregroundColor: isDark ? Colors.white : Colors.black87,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // Fallback default theme for raw usage if needed
  static ThemeData get darkTheme {
    return buildTheme(
      const AppThemePreset(
        type: AppThemeType.cyberpunkDark,
        name: '赛博霓虹 (暗)',
        primary: Color(0xFF7C4DFF),
        secondary: Color(0xFF18FFFF),
        surface: Color(0xFF0E0B1E),
        surfaceContainer: Color(0xFF181335),
        isDark: true,
      ),
    );
  }
}
