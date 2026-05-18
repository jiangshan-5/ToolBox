import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'token_manager.dart';

class ApiClient {
  late final Dio _dio;

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
        onError: (DioException error, handler) {
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
