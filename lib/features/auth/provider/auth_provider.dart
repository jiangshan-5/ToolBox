import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/token_manager.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? email;
  final String? nickname;
  final String? error;

  AuthState({
    required this.isAuthenticated,
    this.isLoading = false,
    this.email,
    this.nickname,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? email,
    String? nickname,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;

  AuthNotifier(this._apiClient) : super(AuthState(isAuthenticated: false)) {
    _apiClient.onAuthFailure = () {
      state = AuthState(isAuthenticated: false);
    };
    _init();
  }

  /// Cold start session validator: Automatically logins user if dynamic token is valid
  Future<void> _init() async {
    final token = await TokenManager.getToken();
    final email = await TokenManager.getEmail();

    if (token != null && email != null) {
      try {
        // Ping /auth/me to verify token validity and get profile
        final response = await _apiClient.instance.get('/auth/me');
        final userProfile = response.data['profile'];
        final nickname = userProfile != null ? userProfile['nickname'] : null;
        state = AuthState(isAuthenticated: true, email: email, nickname: nickname);
      } catch (e) {
        // If expired or network error fails auth checks, wipe session
        await TokenManager.clearSession();
        state = AuthState(isAuthenticated: false);
      }
    }
  }

  /// Login endpoint caller
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    // Simple client side checks
    if (email.isEmpty || !email.contains('@')) {
      state = state.copyWith(isLoading: false, error: "邮箱格式不正确");
      return;
    }
    if (password.length < 6) {
      state = state.copyWith(isLoading: false, error: "密码长度不能少于 6 位");
      return;
    }

    try {
      final response = await _apiClient.instance.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final token = response.data['access_token'] as String;
      final refreshToken = response.data['refresh_token'] as String;
      final responseEmail = response.data['user']['email'] as String;
      final userProfile = response.data['user']['profile'];
      final nickname = userProfile != null ? userProfile['nickname'] : null;

      // Persist credentials securely
      await TokenManager.saveSession(accessToken: token, refreshToken: refreshToken, email: responseEmail);

      state = AuthState(isAuthenticated: true, email: responseEmail, nickname: nickname);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.error?.toString() ?? "登录失败，请稍后重试",
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "系统异常: $e");
    }
  }

  /// Register endpoint caller
  Future<void> register(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    if (email.isEmpty || !email.contains('@')) {
      state = state.copyWith(isLoading: false, error: "邮箱格式不正确");
      return;
    }
    if (password.length < 6) {
      state = state.copyWith(isLoading: false, error: "密码长度不能少于 6 位");
      return;
    }

    try {
      final response = await _apiClient.instance.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
        },
      );

      final token = response.data['access_token'] as String;
      final refreshToken = response.data['refresh_token'] as String;
      final responseEmail = response.data['user']['email'] as String;
      final userProfile = response.data['user']['profile'];
      final nickname = userProfile != null ? userProfile['nickname'] : null;

      // Persist session
      await TokenManager.saveSession(accessToken: token, refreshToken: refreshToken, email: responseEmail);

      state = AuthState(isAuthenticated: true, email: responseEmail, nickname: nickname);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.error?.toString() ?? "注册失败，请稍后重试",
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "系统异常: $e");
    }
  }

  /// Update user profile attributes securely via the backend API
  Future<bool> updateProfile({String? nickname}) async {
    if (!state.isAuthenticated) return false;

    try {
      final payload = <String, dynamic>{};
      if (nickname != null) payload['nickname'] = nickname;

      if (payload.isEmpty) return true;

      // Ensure API call succeeds
      await _apiClient.instance.put('/auth/profile', data: payload);

      // Update local state smoothly without full reload
      state = state.copyWith(nickname: nickname ?? state.nickname);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: e.response?.data['detail'] ?? 'Failed to update profile');
      return false;
    } catch (e) {
      state = state.copyWith(error: 'An unexpected error occurred.');
      return false;
    }
  }

  /// Guest bypass session activation
  Future<void> loginAsGuest() async {
    // Clear old registered user sessions to prevent header pollution
    await TokenManager.clearSession();
    state = AuthState(
      isAuthenticated: true,
      email: null,
      nickname: "游客",
    );
  }

  /// Session teardown
  Future<void> logout() async {
    // Clear state and storage immediately for instant UI feedback
    await TokenManager.clearSession();
    state = AuthState(isAuthenticated: false);
    
    try {
      // Fire backend logout in background without awaiting or blocking UI
      _apiClient.instance.post('/auth/logout').ignore();
    } catch (e) {
      // Silent catch
    }
  }
}

// 1. Register API Client provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// 2. Auth State Provider linking to ApiClient
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(apiClient);
});
