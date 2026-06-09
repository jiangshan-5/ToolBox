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

      // Premium borderless card guidelines
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
            width: 1.0,
          ),
        ),
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.02),
      ),

      // Premium Input Fields Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05), width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: preset.primary, width: 1.5),
        ),
        labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14),
        hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 14),
      ),

      // Beautiful Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: preset.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
            width: 1.2,
          ),
        ),
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),

      // Premium Floating SnackBar Toast Theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? const Color(0xFF140E20).withOpacity(0.92)
            : Colors.white.withOpacity(0.92),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: preset.primary.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        contentTextStyle: GoogleFonts.outfit(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        insetPadding: const EdgeInsets.fromLTRB(24, 0, 24, 60),
      ),
    );
  }

  // Fallback default theme for raw usage if needed
  static ThemeData get darkTheme {
    return buildTheme(
      const AppThemePreset(
        type: AppThemeType.cyberpunkDark,
        name: '赛博霓虹 (暗)',
        primary: Color(0xFF8B5CF6),
        secondary: Color(0xFF06B6D4),
        surface: Color(0xFF090710),
        surfaceContainer: Color(0xFF140E20),
        isDark: true,
      ),
    );
  }
}
