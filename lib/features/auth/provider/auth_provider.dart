import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? email;
  final String? error;

  AuthState({
    required this.isAuthenticated,
    this.isLoading = false,
    this.email,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? email,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      email: email ?? this.email,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState(isAuthenticated: false)) {
    _init();
  }

  // Check if user was previously logged in
  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('user_email');
    if (savedEmail != null) {
      state = AuthState(isAuthenticated: true, email: savedEmail);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    // Formal validation
    if (email.isEmpty || !email.contains('@')) {
      state = state.copyWith(isLoading: false, error: "Invalid email format");
      return;
    }
    if (password.length < 6) {
      state = state.copyWith(isLoading: false, error: "Password too short (min 6)");
      return;
    }

    try {
      await Future.delayed(const Duration(seconds: 1.5)); // Simulate API
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', email);
      
      state = AuthState(isAuthenticated: true, email: email);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Connection failed");
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
    state = AuthState(isAuthenticated: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
