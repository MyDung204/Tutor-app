import 'api_config.dart';

class ApiConstants {
  /// Base URL cho API (tự động detect platform)
  static String get baseUrl => ApiConfig.baseUrl;
  
  // Endpoints
  static const String login = '/login';
  static const String register = '/register';
  static const String tutors = '/tutors';
  static const String questions = '/questions';
  static const String bookings = '/bookings';
  static const String transactions = '/transactions';
  static const String classes = '/classes';
  static const String groups = '/groups';
}
