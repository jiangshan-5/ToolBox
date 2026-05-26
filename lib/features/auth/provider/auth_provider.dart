import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/token_manager.dart';
import '../../../core/providers/api_config_provider.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? email;
  final String? nickname;
  final String? avatarUrl;
  final String? bio;
  final String? error;

  AuthState({
    required this.isAuthenticated,
    this.isLoading = false,
    this.email,
    this.nickname,
    this.avatarUrl,
    this.bio,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? email,
    String? nickname,
    String? avatarUrl,
    String? bio,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
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
        final avatarUrl = userProfile != null ? userProfile['avatar_url'] : null;
        final bio = userProfile != null ? userProfile['bio'] : null;
        state = AuthState(
          isAuthenticated: true,
          email: email,
          nickname: nickname,
          avatarUrl: avatarUrl,
          bio: bio,
        );
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
        data: {'email': email, 'password': password},
      );

      final token = response.data['access_token'] as String;
      final refreshToken = response.data['refresh_token'] as String;
      final responseEmail = response.data['user']['email'] as String;
      final userProfile = response.data['user']['profile'];
      final nickname = userProfile != null ? userProfile['nickname'] : null;
      final avatarUrl = userProfile != null ? userProfile['avatar_url'] : null;
      final bio = userProfile != null ? userProfile['bio'] : null;

      // Persist credentials securely
      await TokenManager.saveSession(
        accessToken: token,
        refreshToken: refreshToken,
        email: responseEmail,
      );

      state = AuthState(
        isAuthenticated: true,
        email: responseEmail,
        nickname: nickname,
        avatarUrl: avatarUrl,
        bio: bio,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.error?.toString() ?? "登录失败，请稍后重试",
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "系统异常: $e");
    }
  }

  /// Register endpoint caller with email verification code
  Future<void> register(String email, String password, String code) async {
    state = state.copyWith(isLoading: true, error: null);

    if (email.isEmpty || !email.contains('@')) {
      state = state.copyWith(isLoading: false, error: "邮箱格式不正确");
      return;
    }
    if (password.length < 6) {
      state = state.copyWith(isLoading: false, error: "密码长度不能少于 6 位");
      return;
    }
    if (code.isEmpty) {
      state = state.copyWith(isLoading: false, error: "请输入验证码");
      return;
    }

    try {
      final response = await _apiClient.instance.post(
        '/auth/register',
        data: {'email': email, 'password': password, 'code': code},
      );

      final token = response.data['access_token'] as String;
      final refreshToken = response.data['refresh_token'] as String;
      final responseEmail = response.data['user']['email'] as String;
      final userProfile = response.data['user']['profile'];
      final nickname = userProfile != null ? userProfile['nickname'] : null;
      final avatarUrl = userProfile != null ? userProfile['avatar_url'] : null;
      final bio = userProfile != null ? userProfile['bio'] : null;

      // Persist session
      await TokenManager.saveSession(
        accessToken: token,
        refreshToken: refreshToken,
        email: responseEmail,
      );

      state = AuthState(
        isAuthenticated: true,
        email: responseEmail,
        nickname: nickname,
        avatarUrl: avatarUrl,
        bio: bio,
      );
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
  Future<bool> updateProfile({String? nickname, String? avatarUrl, String? bio}) async {
    if (!state.isAuthenticated) return false;

    try {
      final payload = <String, dynamic>{};
      if (nickname != null) payload['nickname'] = nickname;
      if (avatarUrl != null) payload['avatar_url'] = avatarUrl;
      if (bio != null) payload['bio'] = bio;

      if (payload.isEmpty) return true;

      // Ensure API call succeeds
      await _apiClient.instance.put('/auth/profile', data: payload);

      // Update local state smoothly without full reload
      state = state.copyWith(
        nickname: nickname ?? state.nickname,
        avatarUrl: avatarUrl ?? state.avatarUrl,
        bio: bio ?? state.bio,
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data['detail'] ?? 'Failed to update profile',
      );
      return false;
    } catch (e) {
      state = state.copyWith(error: 'An unexpected error occurred.');
      return false;
    }
  }

  /// Send registration verification code email
  Future<String?> sendRegisterCode(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    if (email.isEmpty || !email.contains('@')) {
      state = state.copyWith(isLoading: false, error: "邮箱格式不正确");
      return null;
    }

    try {
      final response = await _apiClient.instance.post(
        '/auth/register/send-code',
        data: {'email': email},
      );
      state = state.copyWith(isLoading: false);
      return response.data['detail'] as String?;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.error?.toString() ?? "发送验证码失败，请稍后重试",
      );
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "系统异常: $e");
      return null;
    }
  }

  /// Change user password securely
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);

    if (oldPassword.isEmpty || newPassword.isEmpty) {
      state = state.copyWith(isLoading: false, error: "密码不能为空");
      return false;
    }
    if (newPassword.length < 6) {
      state = state.copyWith(isLoading: false, error: "新密码长度不能少于 6 位");
      return false;
    }
    if (oldPassword == newPassword) {
      state = state.copyWith(isLoading: false, error: "新密码不能与原密码相同");
      return false;
    }

    try {
      await _apiClient.instance.put(
        '/auth/change-password',
        data: {'old_password': oldPassword, 'new_password': newPassword},
      );
      state = state.copyWith(isLoading: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.error?.toString() ?? "修改密码失败，请稍后重试",
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "系统异常: $e");
      return false;
    }
  }

  /// Guest bypass session activation
  Future<void> loginAsGuest() async {
    // Clear old registered user sessions to prevent header pollution
    await TokenManager.clearSession();
    state = AuthState(isAuthenticated: true, email: null, nickname: "游客");
  }

  /// Admin bypass login shortcut
  Future<void> loginAsAdmin() async {
    await login("admin@toolbox.com", "admin123456");
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
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return ApiClient(baseUrl: baseUrl);
});

// 2. Auth State Provider linking to ApiClient
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(apiClient);
});
