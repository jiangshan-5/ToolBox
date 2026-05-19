import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'token_manager.dart';

class ApiClient {
  late final Dio _dio;
  late final Dio _refreshDio;
  bool _isRefreshing = false;

  /// Callback triggered when authorization fails permanently
  VoidCallback? onAuthFailure;

  /// The live production cloud server URL (Alibaba Cloud Shenzhen)
  static const String liveServerUrl = 'http://47.106.119.62:1234/api/v1';

  /// Set to [true] to connect to the live server, or [false] to debug with local FastAPI server!
  static const bool useLiveServer = true;

  /// Dynamic Base URL detection for seamless emulator/simulator local debugging
  static String get baseUrl {
    if (useLiveServer) {
      return liveServerUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:8000/api/v1';
    }
    // Android Emulator bridges to local host loopback via 10.0.2.2
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    // iOS Simulator, Windows, macOS, Linux desktop
    return 'http://127.0.0.1:8000/api/v1';
  }

  ApiClient() {
    _refreshDio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        contentType: Headers.jsonContentType,
      ),
    );
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        contentType: Headers.jsonContentType,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Read secure storage JWT and automatically inject Bearer auth header
          final token = await TokenManager.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Intercept 401 Unauthorized for silent automatic token refresh
          final requestPath = error.requestOptions.path;
          if (error.response?.statusCode == 401 &&
              !requestPath.contains('/auth/login') &&
              !requestPath.contains('/auth/register') &&
              !requestPath.contains('/auth/refresh')) {
            
            final refreshToken = await TokenManager.getRefreshToken();
            final email = await TokenManager.getEmail();
            
            if (refreshToken != null && email != null) {
              if (!_isRefreshing) {
                _isRefreshing = true;
                try {
                  // Call refresh endpoint with the separate refresh Dio instance
                  final refreshResponse = await _refreshDio.post(
                    '/auth/refresh',
                    data: {'refresh_token': refreshToken},
                  );
                  
                  final newAccessToken = refreshResponse.data['access_token'] as String;
                  final newRefreshToken = refreshResponse.data['refresh_token'] as String;
                  
                  // Save newly rotated tokens
                  await TokenManager.saveSession(
                    accessToken: newAccessToken,
                    refreshToken: newRefreshToken,
                    email: email,
                  );
                  
                  _isRefreshing = false;
                  
                  // Replay the original failed request with the new access token
                  final options = error.requestOptions;
                  options.headers['Authorization'] = 'Bearer $newAccessToken';
                  
                  final response = await _dio.fetch(options);
                  return handler.resolve(response);
                } catch (refreshError) {
                  _isRefreshing = false;
                  
                  // Token refresh failed (e.g. revoked or expired) -> Wipe session
                  await TokenManager.clearSession();
                  
                  // Trigger global authentication failure callback
                  onAuthFailure?.call();
                  
                  final customException = DioException(
                    requestOptions: error.requestOptions,
                    response: error.response,
                    type: error.type,
                    error: "登录已失效，请重新登录",
                  );
                  return handler.next(customException);
                }
              } else {
                // Another request is currently refreshing the token, wait for it to complete
                int retries = 0;
                while (_isRefreshing && retries < 10) {
                  await Future.delayed(const Duration(milliseconds: 500));
                  retries++;
                }
                
                final newAccessToken = await TokenManager.getToken();
                if (newAccessToken != null) {
                  final options = error.requestOptions;
                  options.headers['Authorization'] = 'Bearer $newAccessToken';
                  
                  final response = await _dio.fetch(options);
                  return handler.resolve(response);
                }
              }
            }
          }

          // Cleanly extract custom error messages set by FastAPI detail fields
          String message = "网络连接失败，请检查网络设置并稍后重试";
          
          if (error.response != null) {
            final data = error.response?.data;
            if (data is Map && data.containsKey('detail')) {
              message = data['detail'].toString();
            } else if (error.response?.statusCode == 401) {
              message = "身份认证失效，请重新登录";
            } else {
              message = "服务器处理出错 (状态码: ${error.response?.statusCode})";
            }
          } else if (error.type == DioExceptionType.connectionTimeout || 
                     error.type == DioExceptionType.receiveTimeout) {
            message = "请求连接超时，请检查网络连接";
          }
          
          // Inject friendly description directly into error entity
          final customException = DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: message,
          );
          
          return handler.next(customException);
        },
      ),
    );
  }

  /// Get the configured Dio HTTP instance
  Dio get instance => _dio;
}
