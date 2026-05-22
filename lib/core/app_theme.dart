import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Cohesive Cyberpunk Dark Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurpleAccent,
        brightness: Brightness.dark,
        surface: const Color(0xFF0A0714), // Perfect dark backdrop matching DynamicBackground
        surfaceContainer: const Color(0xFF130F24), // Sleek secondary container
        primary: Colors.deepPurpleAccent,
        secondary: Colors.cyanAccent,
      ),
      
      // Outfit typography as the primary typeface
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      
      // Frosted card guidelines
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: Colors.white.withOpacity(0.04),
      ),
      
      // Elite Cyberpunk Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: Colors.deepPurpleAccent,
        inactiveTrackColor: Colors.white.withOpacity(0.1),
        thumbColor: Colors.cyanAccent,
        overlayColor: Colors.cyanAccent.withOpacity(0.15),
        valueIndicatorColor: Colors.deepPurpleAccent,
        valueIndicatorTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
        trackHeight: 4.0,
      ),
      
      // Glowing Custom Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.cyanAccent;
          }
          return Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.deepPurpleAccent.withOpacity(0.5);
          }
          return Colors.white12;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      
      // Interactive Button Theme Defaulting
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurpleAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
