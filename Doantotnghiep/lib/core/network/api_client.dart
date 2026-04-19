/// API Client for handling HTTP requests to Laravel backend
/// 
/// This class provides a centralized way to make API calls with:
/// - Automatic authentication token injection
/// - Error handling with custom exceptions
/// - Request/response logging
/// - Configurable timeouts
/// 
/// Usage:
/// ```dart
/// final apiClient = ref.read(apiClientProvider);
/// final response = await apiClient.get('/tutors');
/// ```
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_constants.dart';
import 'api_config.dart';
import '../exceptions/app_exceptions.dart';

/// Provider for ApiClient singleton instance
/// 
/// This provider creates a single ApiClient instance that is shared across the app.
/// The instance is created lazily when first accessed.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// HTTP client wrapper using Dio for API communication
/// 
/// Handles all HTTP requests to the Laravel backend API with:
/// - Automatic Bearer token authentication
/// - Request/response logging for debugging
/// - Custom exception handling for better error messages
/// - Configurable timeouts (30 seconds default)
class ApiClient {
  /// Dio instance for HTTP requests
  late final Dio _dio;

  /// Initialize API client with interceptors and configuration
  /// 
  /// Sets up:
  /// - Base URL from ApiConfig (supports emulator/physical device)
  /// - Timeout configuration (30s connect, 30s receive)
  /// - Request/response logging interceptor
  /// - Authentication token interceptor (reads from SharedPreferences)
  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: ApiConfig.connectTimeout),
      receiveTimeout: const Duration(seconds: ApiConfig.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // Log interceptor: Logs all requests and responses for debugging
    // NOTE: Disable in production for security
    _dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
    
    // Auth Token Interceptor: Automatically adds Bearer token to all requests
    // Reads token from SharedPreferences and injects into Authorization header
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  /// Perform GET request to API endpoint
  /// 
  /// **Parameters:**
  /// - `path`: API endpoint path (e.g., '/tutors', '/bookings')
  /// - `queryParameters`: Optional query parameters as key-value map
  /// 
  /// **Returns:**
  /// - `dynamic`: Response data (usually Map or List)
  /// 
  /// **Throws:**
  /// - `ApiException`: If request fails (with user-friendly message)
  /// 
  /// **Example:**
  /// ```dart
  /// final tutors = await apiClient.get('/tutors', queryParameters: {'featured': 1});
  /// ```
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(
        userMessage: 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.',
        technicalMessage: e.toString(),
        originalError: e,
      );
    }
  }

  /// Perform POST request to API endpoint
  /// 
  /// **Parameters:**
  /// - `path`: API endpoint path (e.g., '/login', '/bookings/lock')
  /// - `data`: Request body data (Map, List, or other serializable object)
  /// 
  /// **Returns:**
  /// - `dynamic`: Response data from server
  /// 
  /// **Throws:**
  /// - `ApiException`: If request fails (with user-friendly message)
  /// 
  /// **Example:**
  /// ```dart
  /// final response = await apiClient.post('/login', data: {
  ///   'email': 'user@example.com',
  ///   'password': 'password123'
  /// });
  /// ```
  Future<dynamic> post(String path, {dynamic data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(
        userMessage: 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.',
        technicalMessage: e.toString(),
        originalError: e,
      );
    }
  }

  /// Perform PUT request to API endpoint (for updates)
  /// 
  /// **Parameters:**
  /// - `path`: API endpoint path (e.g., '/profile/123')
  /// - `data`: Request body data to update
  /// 
  /// **Returns:**
  /// - `dynamic`: Response data from server
  /// 
  /// **Throws:**
  /// - `ApiException`: If request fails (with user-friendly message)
  /// 
  /// **Example:**
  /// ```dart
  /// await apiClient.put('/profile/123', data: {'name': 'New Name'});
  /// ```
  Future<dynamic> put(String path, {dynamic data}) async {
    try {
      final response = await _dio.put(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(
        userMessage: 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.',
        technicalMessage: e.toString(),
        originalError: e,
      );
    }
  }

  /// Perform DELETE request to API endpoint
  /// 
  /// **Parameters:**
  /// - `path`: API endpoint path (e.g., '/bookings/123')
  /// 
  /// **Returns:**
  /// - `dynamic`: Response data from server (usually success message)
  /// 
  /// **Throws:**
  /// - `ApiException`: If request fails (with user-friendly message)
  /// 
  /// **Example:**
  /// ```dart
  /// await apiClient.delete('/bookings/123');
  /// ```
  Future<dynamic> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(
        userMessage: 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.',
        technicalMessage: e.toString(),
        originalError: e,
      );
    }
  }
  /// Manually set auth token (updates headers immediately)
  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Manually clear auth token
  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }
}
