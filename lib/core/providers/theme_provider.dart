import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbox_app/core/app_theme.dart';

final List<AppThemePreset> appThemePresets = [
  const AppThemePreset(
    type: AppThemeType.cyberpunkLight,
    name: '极简纯白 (明)',
    primary: Color(0xFF4F46E5), // Premium Indigo
    secondary: Color(0xFF06B6D4), // Premium Cyan
    surface: Color(0xFFFFFFFF),
    surfaceContainer: Color(0xFFF8FAFC), // Very soft slate
    isDark: false,
  ),
  const AppThemePreset(
    type: AppThemeType.neonMidnightLight,
    name: '午夜霓虹 (明)',
    primary: Color(0xFF6366F1),
    secondary: Color(0xFFEC4899), // Rose
    surface: Color(0xFFF8FAFC),
    surfaceContainer: Color(0xFFF1F5F9),
    isDark: false,
  ),
  const AppThemePreset(
    type: AppThemeType.volcanoCyberLight,
    name: '烈焰火山 (明)',
    primary: Color(0xFFE11D48), // Deep Rose Red
    secondary: Color(0xFFD97706), // Muted Amber
    surface: Color(0xFFFFF1F2),
    surfaceContainer: Color(0xFFFFE4E6),
    isDark: false,
  ),
  const AppThemePreset(
    type: AppThemeType.forestMatrixLight,
    name: '矩阵森林 (明)',
    primary: Color(0xFF059669), // Emerald Green
    secondary: Color(0xFF0D9488), // Teal
    surface: Color(0xFFECFDF5),
    surfaceContainer: Color(0xFFD1FAE5),
    isDark: false,
  ),
  const AppThemePreset(
    type: AppThemeType.oceanCyberLight,
    name: '赛博海洋 (明)',
    primary: Color(0xFF2563EB), // Premium Blue
    secondary: Color(0xFF0EA5E9), // Sky Blue
    surface: Color(0xFFF0F9FF),
    surfaceContainer: Color(0xFFE0F2FE),
    isDark: false,
  ),
  const AppThemePreset(
    type: AppThemeType.sakuraDreamLight,
    name: '樱花梦境 (明)',
    primary: Color(0xFFDB2777),
    secondary: Color(0xFF7C3AED), // Premium Purple
    surface: Color(0xFFFDF2F8),
    surfaceContainer: Color(0xFFFCE7F3),
    isDark: false,
  ),
  const AppThemePreset(
    type: AppThemeType.cyberpunkDark,
    name: '深邃极光 (暗)', // Renamed for elegance
    primary: Color(0xFF8B5CF6), // Premium Violet
    secondary: Color(0xFF06B6D4), // Cyan Glow
    surface: Color(0xFF090710), // Obsidian black
    surfaceContainer: Color(0xFF140E20),
    isDark: true,
  ),
  const AppThemePreset(
    type: AppThemeType.neonMidnight,
    name: '午夜霓虹 (暗)',
    primary: Color(0xFF6366F1),
    secondary: Color(0xFFEC4899),
    surface: Color(0xFF030712), // Pitch Black
    surfaceContainer: Color(0xFF0B0F19),
    isDark: true,
  ),
  const AppThemePreset(
    type: AppThemeType.volcanoCyber,
    name: '烈焰火山 (暗)',
    primary: Color(0xFFEF4444), // Coral Red
    secondary: Color(0xFFF59E0B), // Amber
    surface: Color(0xFF110909), // Volcano Ash
    surfaceContainer: Color(0xFF1A1010),
    isDark: true,
  ),
  const AppThemePreset(
    type: AppThemeType.forestMatrix,
    name: '矩阵森林 (暗)',
    primary: Color(0xFF10B981),
    secondary: Color(0xFF34D399),
    surface: Color(0xFF050C08),
    surfaceContainer: Color(0xFF0F1813),
    isDark: true,
  ),
  const AppThemePreset(
    type: AppThemeType.oceanCyber,
    name: '赛博海洋 (暗)',
    primary: Color(0xFF3B82F6),
    secondary: Color(0xFF06B6D4),
    surface: Color(0xFF050B14),
    surfaceContainer: Color(0xFF0D1624),
    isDark: true,
  ),
  const AppThemePreset(
    type: AppThemeType.sakuraDream,
    name: '樱花梦境 (暗)',
    primary: Color(0xFFEC4899),
    secondary: Color(0xFF8B5CF6),
    surface: Color(0xFF110512),
    surfaceContainer: Color(0xFF1E0C1F),
    isDark: true,
  ),
];

class ThemeConfig {
  final AppThemeType type;
  final Color customPrimary;
  final Color customSecondary;
  final Color customSurface;
  final Color customSurfaceContainer;
  final bool customIsDark;
  final String? customBgBase64;

  ThemeConfig({
    required this.type,
    required this.customPrimary,
    required this.customSecondary,
    required this.customSurface,
    required this.customSurfaceContainer,
    required this.customIsDark,
    this.customBgBase64,
  });

  ThemeConfig copyWith({
    AppThemeType? type,
    Color? customPrimary,
    Color? customSecondary,
    Color? customSurface,
    Color? customSurfaceContainer,
    bool? customIsDark,
    String? customBgBase64,
    bool clearBg = false,
  }) {
    return ThemeConfig(
      type: type ?? this.type,
      customPrimary: customPrimary ?? this.customPrimary,
      customSecondary: customSecondary ?? this.customSecondary,
      customSurface: customSurface ?? this.customSurface,
      customSurfaceContainer:
          customSurfaceContainer ?? this.customSurfaceContainer,
      customIsDark: customIsDark ?? this.customIsDark,
      customBgBase64: clearBg ? null : (customBgBase64 ?? this.customBgBase64),
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeConfig> {
  ThemeNotifier()
    : super(
        ThemeConfig(
          type: AppThemeType.cyberpunkLight,
          customPrimary: const Color(0xFF6200EE),
          customSecondary: const Color(0xFF03DAC6),
          customSurface: const Color(0xFFF5F4FA),
          customSurfaceContainer: const Color(0xFFEAE7F2),
          customIsDark: false,
          customBgBase64: null,
        ),
      ) {
    _loadThemeSettings();
  }

  Future<void> _loadThemeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final typeIndex = prefs.getInt('theme_type_index');
      final customPrimaryVal = prefs.getInt('theme_custom_primary');
      final customSecondaryVal = prefs.getInt('theme_custom_secondary');
      final customSurfaceVal = prefs.getInt('theme_custom_surface');
      final customSurfaceContainerVal = prefs.getInt(
        'theme_custom_surface_container',
      );
      final customIsDarkVal = prefs.getBool('theme_custom_is_dark');
      final customBgBase64Val = prefs.getString('theme_custom_bg_base64');

      state = ThemeConfig(
        type: typeIndex != null
            ? AppThemeType.values[typeIndex]
            : AppThemeType.cyberpunkLight,
        customPrimary: customPrimaryVal != null
            ? Color(customPrimaryVal)
            : const Color(0xFF6200EE),
        customSecondary: customSecondaryVal != null
            ? Color(customSecondaryVal)
            : const Color(0xFF03DAC6),
        customSurface: customSurfaceVal != null
            ? Color(customSurfaceVal)
            : const Color(0xFFF5F4FA),
        customSurfaceContainer: customSurfaceContainerVal != null
            ? Color(customSurfaceContainerVal)
            : const Color(0xFFEAE7F2),
        customIsDark: customIsDarkVal ?? false,
        customBgBase64: customBgBase64Val,
      );
    } catch (_) {}
  }

  Future<void> setThemeType(AppThemeType type) async {
    state = state.copyWith(type: type);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_type_index', type.index);
  }

  Future<void> updateCustomTheme({
    Color? primary,
    Color? secondary,
    Color? surface,
    Color? surfaceContainer,
    bool? isDark,
    String? bgBase64,
    bool clearBg = false,
  }) async {
    final newPrimary = primary ?? state.customPrimary;
    final newSecondary = secondary ?? state.customSecondary;
    final newSurface = surface ?? state.customSurface;
    final newIsDark = isDark ?? state.customIsDark;

    // Derive surface container if not provided
    final Color newSurfaceContainer;
    if (surfaceContainer != null) {
      newSurfaceContainer = surfaceContainer;
    } else {
      if (newIsDark) {
        newSurfaceContainer = Color.alphaBlend(
          Colors.white.withOpacity(0.06),
          newSurface,
        );
      } else {
        newSurfaceContainer = Color.alphaBlend(
          Colors.black.withOpacity(0.06),
          newSurface,
        );
      }
    }

    state = state.copyWith(
      type: AppThemeType.custom,
      customPrimary: newPrimary,
      customSecondary: newSecondary,
      customSurface: newSurface,
      customSurfaceContainer: newSurfaceContainer,
      customIsDark: newIsDark,
      customBgBase64: bgBase64,
      clearBg: clearBg,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_type_index', AppThemeType.custom.index);
    await prefs.setInt('theme_custom_primary', newPrimary.value);
    await prefs.setInt('theme_custom_secondary', newSecondary.value);
    await prefs.setInt('theme_custom_surface', newSurface.value);
    await prefs.setInt(
      'theme_custom_surface_container',
      newSurfaceContainer.value,
    );
    await prefs.setBool('theme_custom_is_dark', newIsDark);

    if (clearBg) {
      await prefs.remove('theme_custom_bg_base64');
    } else if (bgBase64 != null) {
      await prefs.setString('theme_custom_bg_base64', bgBase64);
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeConfig>((ref) {
  return ThemeNotifier();
});

final themePresetProvider = Provider<AppThemePreset>((ref) {
  final config = ref.watch(themeProvider);
  if (config.type == AppThemeType.custom) {
    return AppThemePreset(
      type: AppThemeType.custom,
      name: '自定义主题',
      primary: config.customPrimary,
      secondary: config.customSecondary,
      surface: config.customSurface,
      surfaceContainer: config.customSurfaceContainer,
      isDark: config.customIsDark,
    );
  }
  return appThemePresets.firstWhere((preset) => preset.type == config.type);
});

final themeDataProvider = Provider<ThemeData>((ref) {
  final preset = ref.watch(themePresetProvider);
  return AppTheme.buildTheme(preset);
});
