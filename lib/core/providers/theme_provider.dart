import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbox_app/core/app_theme.dart';

final List<AppThemePreset> appThemePresets = [
  const AppThemePreset(
    type: AppThemeType.cyberpunkDark,
    name: '赛博霓虹 (暗)',
    primary: Color(0xFF7C4DFF),
    secondary: Color(0xFF18FFFF),
    surface: Color(0xFF0E0B1E),
    surfaceContainer: Color(0xFF181335),
    isDark: true,
  ),
  const AppThemePreset(
    type: AppThemeType.neonMidnight,
    name: '午夜霓虹 (暗)',
    primary: Color(0xFF00E5FF),
    secondary: Color(0xFFFF007F),
    surface: Color(0xFF051124),
    surfaceContainer: Color(0xFF0E1E38),
    isDark: true,
  ),
  const AppThemePreset(
    type: AppThemeType.volcanoCyber,
    name: '烈焰火山 (暗)',
    primary: Color(0xFFFF3D00),
    secondary: Color(0xFFFFD600),
    surface: Color(0xFF1C0909),
    surfaceContainer: Color(0xFF2D1212),
    isDark: true,
  ),
  const AppThemePreset(
    type: AppThemeType.forestMatrix,
    name: '矩阵森林 (暗)',
    primary: Color(0xFF00E676),
    secondary: Color(0xFF1DE9B6),
    surface: Color(0xFF07140B),
    surfaceContainer: Color(0xFF122818),
    isDark: true,
  ),
  const AppThemePreset(
    type: AppThemeType.oceanCyber,
    name: '赛博海洋 (暗)',
    primary: Color(0xFF2979FF),
    secondary: Color(0xFF00E5FF),
    surface: Color(0xFF081524),
    surfaceContainer: Color(0xFF13253D),
    isDark: true,
  ),
  const AppThemePreset(
    type: AppThemeType.sakuraDream,
    name: '樱花梦境 (暗)',
    primary: Color(0xFFFF4081),
    secondary: Color(0xFFE040FB),
    surface: Color(0xFF1D091B),
    surfaceContainer: Color(0xFF32122F),
    isDark: true,
  ),
  const AppThemePreset(
    type: AppThemeType.cyberpunkLight,
    name: '赛博极客 (明)',
    primary: Color(0xFF6200EE),
    secondary: Color(0xFF03DAC6),
    surface: Color(0xFFF5F4FA),
    surfaceContainer: Color(0xFFEAE7F2),
    isDark: false,
  ),
  const AppThemePreset(
    type: AppThemeType.neonMidnightLight,
    name: '午夜霓虹 (明)',
    primary: Color(0xFF00ACC1),
    secondary: Color(0xFFD81B60),
    surface: Color(0xFFF1F5F9),
    surfaceContainer: Color(0xFFE2E8F0),
    isDark: false,
  ),
  const AppThemePreset(
    type: AppThemeType.volcanoCyberLight,
    name: '烈焰火山 (明)',
    primary: Color(0xFFE53935),
    secondary: Color(0xFFFFB300),
    surface: Color(0xFFFFF5F5),
    surfaceContainer: Color(0xFFFED7D7),
    isDark: false,
  ),
  const AppThemePreset(
    type: AppThemeType.forestMatrixLight,
    name: '矩阵森林 (明)',
    primary: Color(0xFF43A047),
    secondary: Color(0xFF00B0FF),
    surface: Color(0xFFF0FDF4),
    surfaceContainer: Color(0xFFDCFCE7),
    isDark: false,
  ),
  const AppThemePreset(
    type: AppThemeType.oceanCyberLight,
    name: '赛博海洋 (明)',
    primary: Color(0xFF1E88E5),
    secondary: Color(0xFF00E5FF),
    surface: Color(0xFFF0F9FF),
    surfaceContainer: Color(0xFFE0F2FE),
    isDark: false,
  ),
  const AppThemePreset(
    type: AppThemeType.sakuraDreamLight,
    name: '樱花梦境 (明)',
    primary: Color(0xFFD81B60),
    secondary: Color(0xFF8E24AA),
    surface: Color(0xFFFFF1F2),
    surfaceContainer: Color(0xFFFFE4E6),
    isDark: false,
  ),
];

class ThemeConfig {
  final AppThemeType type;
  final Color customPrimary;
  final Color customSecondary;
  final Color customSurface;
  final Color customSurfaceContainer;
  final bool customIsDark;

  ThemeConfig({
    required this.type,
    required this.customPrimary,
    required this.customSecondary,
    required this.customSurface,
    required this.customSurfaceContainer,
    required this.customIsDark,
  });

  ThemeConfig copyWith({
    AppThemeType? type,
    Color? customPrimary,
    Color? customSecondary,
    Color? customSurface,
    Color? customSurfaceContainer,
    bool? customIsDark,
  }) {
    return ThemeConfig(
      type: type ?? this.type,
      customPrimary: customPrimary ?? this.customPrimary,
      customSecondary: customSecondary ?? this.customSecondary,
      customSurface: customSurface ?? this.customSurface,
      customSurfaceContainer: customSurfaceContainer ?? this.customSurfaceContainer,
      customIsDark: customIsDark ?? this.customIsDark,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeConfig> {
  ThemeNotifier()
      : super(ThemeConfig(
          type: AppThemeType.cyberpunkDark,
          customPrimary: const Color(0xFF7C4DFF),
          customSecondary: const Color(0xFF18FFFF),
          customSurface: const Color(0xFF0A0714),
          customSurfaceContainer: const Color(0xFF130F24),
          customIsDark: true,
        )) {
    _loadThemeSettings();
  }

  Future<void> _loadThemeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final typeIndex = prefs.getInt('theme_type_index');
      final customPrimaryVal = prefs.getInt('theme_custom_primary');
      final customSecondaryVal = prefs.getInt('theme_custom_secondary');
      final customSurfaceVal = prefs.getInt('theme_custom_surface');
      final customSurfaceContainerVal = prefs.getInt('theme_custom_surface_container');
      final customIsDarkVal = prefs.getBool('theme_custom_is_dark');

      state = ThemeConfig(
        type: typeIndex != null ? AppThemeType.values[typeIndex] : AppThemeType.cyberpunkDark,
        customPrimary: customPrimaryVal != null ? Color(customPrimaryVal) : const Color(0xFF7C4DFF),
        customSecondary: customSecondaryVal != null ? Color(customSecondaryVal) : const Color(0xFF18FFFF),
        customSurface: customSurfaceVal != null ? Color(customSurfaceVal) : const Color(0xFF0A0714),
        customSurfaceContainer: customSurfaceContainerVal != null ? Color(customSurfaceContainerVal) : const Color(0xFF130F24),
        customIsDark: customIsDarkVal ?? true,
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
        newSurfaceContainer = Color.alphaBlend(Colors.white.withOpacity(0.06), newSurface);
      } else {
        newSurfaceContainer = Color.alphaBlend(Colors.black.withOpacity(0.06), newSurface);
      }
    }

    state = state.copyWith(
      type: AppThemeType.custom,
      customPrimary: newPrimary,
      customSecondary: newSecondary,
      customSurface: newSurface,
      customSurfaceContainer: newSurfaceContainer,
      customIsDark: newIsDark,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_type_index', AppThemeType.custom.index);
    await prefs.setInt('theme_custom_primary', newPrimary.value);
    await prefs.setInt('theme_custom_secondary', newSecondary.value);
    await prefs.setInt('theme_custom_surface', newSurface.value);
    await prefs.setInt('theme_custom_surface_container', newSurfaceContainer.value);
    await prefs.setBool('theme_custom_is_dark', newIsDark);
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
