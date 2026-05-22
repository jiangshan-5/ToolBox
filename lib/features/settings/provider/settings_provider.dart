import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final bool isDarkMode;
  final bool isHapticsEnabled;
  final bool isBiometricsEnabled;
  final bool isLowPowerMode;

  SettingsState({
    required this.isDarkMode,
    required this.isHapticsEnabled,
    required this.isBiometricsEnabled,
    required this.isLowPowerMode,
  });

  SettingsState copyWith({
    bool? isDarkMode,
    bool? isHapticsEnabled,
    bool? isBiometricsEnabled,
    bool? isLowPowerMode,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isHapticsEnabled: isHapticsEnabled ?? this.isHapticsEnabled,
      isBiometricsEnabled: isBiometricsEnabled ?? this.isBiometricsEnabled,
      isLowPowerMode: isLowPowerMode ?? this.isLowPowerMode,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier()
      : super(SettingsState(
          isDarkMode: true,
          isHapticsEnabled: true,
          isBiometricsEnabled: false,
          isLowPowerMode: false,
        )) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      isDarkMode: prefs.getBool('isDarkMode') ?? true,
      isHapticsEnabled: prefs.getBool('isHapticsEnabled') ?? true,
      isBiometricsEnabled: prefs.getBool('isBiometricsEnabled') ?? false,
      isLowPowerMode: prefs.getBool('isLowPowerMode') ?? false,
    );
  }

  Future<void> toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    state = state.copyWith(isDarkMode: value);
  }

  Future<void> toggleHaptics(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isHapticsEnabled', value);
    state = state.copyWith(isHapticsEnabled: value);
  }

  Future<void> toggleBiometrics(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isBiometricsEnabled', value);
    state = state.copyWith(isBiometricsEnabled: value);
  }

  Future<void> toggleLowPowerMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLowPowerMode', value);
    state = state.copyWith(isLowPowerMode: value);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
