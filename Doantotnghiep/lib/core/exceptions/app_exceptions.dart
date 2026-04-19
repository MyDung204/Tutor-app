import 'package:dio/dio.dart';

/// Custom Exception classes for better error handling
/// Provides user-friendly error messages and error types

/// Base exception class for app-specific errors
abstract class AppException implements Exception {
  final String userMessage;
  final String? technicalMessage;
  final dynamic originalError;

  AppException({
    required this.userMessage,
    this.technicalMessage,
    this.originalError,
  });

  @override
  String toString() => userMessage;
}

/// API-related exceptions
class ApiException extends AppException {
  final int? statusCode;
  final String? responseMessage;

  ApiException({
    required super.userMessage,
    this.statusCode,
    this.responseMessage,
    super.technicalMessage,
    super.originalError,
  });

  factory ApiException.fromDioException(dynamic error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final responseMessage = error.response?.data?['message'] as String?;

      // Map status codes to user-friendly messages
      String userMessage;
      switch (statusCode) {
        case 400:
          userMessage = responseMessage ?? 'Yêu cầu không hợp lệ. Vui lòng kiểm tra lại thông tin.';
          break;
        case 401:
          userMessage = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
          break;
        case 403:
          userMessage = 'Bạn không có quyền thực hiện thao tác này.';
          break;
        case 404:
          userMessage = 'Không tìm thấy dữ liệu.';
          break;
        case 409:
          userMessage = responseMessage ?? 'Dữ liệu đã bị thay đổi. Vui lòng thử lại.';
          break;
        case 422:
          userMessage = responseMessage ?? 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.';
          break;
        case 500:
        case 502:
        case 503:
          userMessage = 'Lỗi máy chủ. Vui lòng thử lại sau.';
          break;
        default:
          userMessage = responseMessage ?? 
              'Lỗi kết nối: ${error.message ?? "Vui lòng kiểm tra kết nối mạng của bạn."}';
      }

      return ApiException(
        userMessage: userMessage,
        statusCode: statusCode,
        responseMessage: responseMessage,
        technicalMessage: error.message,
        originalError: error,
      );
    }

    return ApiException(
      userMessage: 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.',
      technicalMessage: error.toString(),
      originalError: error,
    );
  }
}

/// Booking-related exceptions
class BookingException extends AppException {
  final BookingErrorType type;

  BookingException({
    required this.type,
    required super.userMessage,
    super.technicalMessage,
    super.originalError,
  });

  factory BookingException.slotAlreadyBooked() {
    return BookingException(
      type: BookingErrorType.slotAlreadyBooked,
      userMessage: 'Khung giờ này đã được đặt. Vui lòng chọn khung giờ khác.',
    );
  }

  factory BookingException.paymentFailed(String? reason) {
    return BookingException(
      type: BookingErrorType.paymentFailed,
      userMessage: reason ?? 'Thanh toán thất bại. Vui lòng thử lại hoặc chọn phương thức thanh toán khác.',
      technicalMessage: reason,
    );
  }

  factory BookingException.networkError() {
    return BookingException(
      type: BookingErrorType.networkError,
      userMessage: 'Lỗi kết nối. Vui lòng kiểm tra mạng và thử lại.',
    );
  }

  factory BookingException.tutorUnavailable() {
    return BookingException(
      type: BookingErrorType.tutorUnavailable,
      userMessage: 'Gia sư hiện không khả dụng. Vui lòng chọn gia sư khác.',
    );
  }

  factory BookingException.invalidTimeSlot() {
    return BookingException(
      type: BookingErrorType.invalidTimeSlot,
      userMessage: 'Khung giờ không hợp lệ. Vui lòng chọn lại.',
    );
  }
}

enum BookingErrorType {
  slotAlreadyBooked,
  paymentFailed,
  networkError,
  tutorUnavailable,
  invalidTimeSlot,
  unknown,
}

/// Search-related exceptions
class SearchException extends AppException {
  SearchException({
    required super.userMessage,
    super.technicalMessage,
    super.originalError,
  });

  factory SearchException.networkError() {
    return SearchException(
      userMessage: 'Không thể tìm kiếm. Vui lòng kiểm tra kết nối mạng.',
    );
  }

  factory SearchException.serverError() {
    return SearchException(
      userMessage: 'Lỗi máy chủ. Vui lòng thử lại sau.',
    );
  }
}

/// Network-related exceptions
class NetworkException extends AppException {
  NetworkException({
    required super.userMessage,
    super.technicalMessage,
    super.originalError,
  });

  factory NetworkException.noConnection() {
    return NetworkException(
      userMessage: 'Không có kết nối mạng. Vui lòng kiểm tra kết nối và thử lại.',
    );
  }

  factory NetworkException.timeout() {
    return NetworkException(
      userMessage: 'Kết nối quá lâu. Vui lòng thử lại.',
    );
  }
}

