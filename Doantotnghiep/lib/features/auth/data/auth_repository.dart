/// Authentication Repository
/// 
/// Handles all authentication-related operations:
/// - User login and registration
/// - Session management (save/restore)
/// - Password change
/// - Auth state stream for reactive UI updates
/// 
/// Uses SharedPreferences for local storage (NOTE: Should migrate to flutter_secure_storage for production)
library;

import 'dart:async';
import 'dart:convert';
import 'package:doantotnghiep/core/network/api_client.dart';
import 'package:doantotnghiep/core/network/api_constants.dart';
import 'package:doantotnghiep/core/exceptions/app_exceptions.dart';
import 'package:doantotnghiep/features/auth/domain/models/app_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart' as import_firebase_messaging;

/// Provider for AuthRepository singleton
/// 
/// Creates a single AuthRepository instance that manages authentication state
/// across the entire app.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});

/// Stream provider for auth state changes
/// 
/// Listens to authentication state changes and notifies UI when user logs in/out.
/// Returns `AppUser?` - null if not authenticated, AppUser if authenticated.
/// 
/// **Usage:**
/// ```dart
/// final authState = ref.watch(authStateChangesProvider);
/// authState.when(
///   data: (user) => user != null ? HomeScreen() : LoginScreen(),
///   loading: () => LoadingScreen(),
///   error: (err, stack) => ErrorScreen(),
/// );
/// ```
final authStateChangesProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Repository for authentication operations
/// 
/// Manages user authentication, session persistence, and auth state broadcasting.
/// Automatically restores session on initialization.
class AuthRepository {
  /// API client for making authentication requests
  final ApiClient _apiClient;
  
  /// Stream controller for broadcasting auth state changes
  /// Used to notify all listeners when user logs in/out
  final _authStateController = StreamController<AppUser?>.broadcast();
  
  /// Current authenticated user (null if not logged in)
  AppUser? _currentUser;

  /// Initialize AuthRepository and restore previous session
  /// 
  /// Automatically attempts to restore user session from SharedPreferences
  /// on app startup. If valid session exists, user is considered logged in.
  AuthRepository(this._apiClient) {
    _restoreSession();
  }

  /// Stream of authentication state changes
  /// 
  /// **Returns:**
  /// - `Stream<AppUser?>`: Stream that emits current user or null
  /// 
  /// **Usage:**
  /// - Emits current user immediately when subscribed
  /// - Emits new values when user logs in/out
  /// - Used by UI to reactively update based on auth state
  Stream<AppUser?> get authStateChanges async* {
    yield _currentUser;
    yield* _authStateController.stream;
  }
  
  /// Get current authenticated user
  /// 
  /// **Returns:**
  /// - `AppUser?`: Current user if authenticated, null otherwise
  AppUser? get currentUser => _currentUser;

  /// Restore user session from local storage
  /// 
  /// **Purpose:**
  /// - Called on app startup to restore previous login session
  /// - Reads token and user data from SharedPreferences
  /// - If valid data exists, sets current user and broadcasts auth state
  /// 
  /// **Error Handling:**
  /// - If data is corrupted or invalid, clears session and signs out
  /// 
  /// **NOTE:** This is a private method called automatically in constructor
  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userJson = prefs.getString('user_data');

    if (token != null && userJson != null) {
      try {
        _currentUser = AppUser.fromJson(jsonDecode(userJson));
        _authStateController.add(_currentUser);
        // Set token in ApiClient immediately
        _apiClient.setToken(token);
        // Sync FCM Token on restore
        syncFCMToken();
      } catch (e) {
        await signOut();
      }
    } else {
       _authStateController.add(null);
    }
  }



  /// Sign in user with email and password
  /// 
  /// **Parameters:**
  /// - `email`: User's email address
  /// - `password`: User's password (plain text, will be hashed by backend)
  /// 
  /// **Returns:**
  /// - `AppUser?`: Authenticated user object if successful
  /// 
  /// **Throws:**
  /// - `String`: Error message if login fails (should be ApiException in future)
  /// 
  /// **Process:**
  /// 1. Sends credentials to backend API
  /// 2. Receives authentication token and user data
  /// 3. Saves token and user data to local storage
  /// 4. Updates current user and broadcasts auth state change
  /// 
  /// **Example:**
  /// ```dart
  /// try {
  ///   final user = await authRepo.signInWithEmailAndPassword('user@example.com', 'password123');
  ///   // User is now logged in
  /// } catch (e) {
  ///   // Handle error
  /// }
  /// ```
  /// 
  /// **TODO:** Replace String throw with ApiException for better error handling
  Future<AppUser?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final response = await _apiClient.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
      });

      // Extract token and user data from response
      // Backend returns: { 'token': '...', 'user': {...} }
      final token = response['token'];
      final user = AppUser.fromJson(response['user']);

      // Save session to local storage and update state
      await _saveSession(token, user);
      return user;
    } catch (e) {
      // TODO: Replace with ApiException for better error handling
      // Current implementation throws String for backward compatibility
      if (e is ApiException) {
        throw e.userMessage;
      }
      throw 'Đăng nhập thất bại: ${e.toString()}';
    }
  }

  /// Register new user account
  /// 
  /// **Parameters:**
  /// - `name`: User's full name
  /// - `email`: User's email address (must be unique)
  /// - `password`: User's password (will be hashed by backend)
  /// - `role`: User role ('student', 'tutor', or 'admin')
  /// 
  /// **Returns:**
  /// - `AppUser?`: Newly created user object if successful
  /// 
  /// **Throws:**
  /// - `String`: Error message if registration fails
  /// 
  /// **Process:**
  /// 1. Sends registration data to backend
  /// 2. Backend creates user account and returns token
  /// 3. Saves session and automatically logs user in
  /// 
  /// **Example:**
  /// ```dart
  /// final user = await authRepo.signUpWithEmailAndPassword(
  ///   'John Doe',
  ///   'john@example.com',
  ///   'password123',
  ///   'student'
  /// );
  /// ```
  /// 
  /// **TODO:** Replace String throw with ApiException
  Future<AppUser?> signUpWithEmailAndPassword(String name, String email, String password, String role) async {
    try {
      final response = await _apiClient.post(ApiConstants.register, data: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      });

      // Backend returns token and user data on successful registration
      final token = response['token'];
      final user = AppUser.fromJson(response['user']);

      // Auto-login after registration
      await _saveSession(token, user);
      return user;
    } catch (e) {
      // TODO: Replace with ApiException
      if (e is ApiException) {
        throw e.userMessage;
      }
      throw 'Đăng ký thất bại: ${e.toString()}';
    }
  }

  /// Sign out current user
  /// 
  /// **Purpose:**
  /// - Clears current user session
  /// - Removes all stored authentication data
  /// - Broadcasts auth state change (user becomes null)
  /// 
  /// **Process:**
  /// 1. Clears current user from memory
  /// 2. Removes token, user data, and role from SharedPreferences
  /// 3. Notifies all listeners that user is logged out
  /// 
  /// **Note:** Does not call backend logout endpoint (token remains valid on server)
  /// This is acceptable for mobile apps where token expiration handles security.
  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
    _apiClient.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    await prefs.remove('user_role');
  }

  /// Save user session to local storage
  /// 
  /// **Parameters:**
  /// - `token`: Authentication token from backend
  /// - `user`: User object with profile information
  /// 
  /// **Purpose:**
  /// - Persists authentication state to SharedPreferences
  /// - Updates current user in memory
  /// - Broadcasts auth state change to all listeners
  /// 
  /// **Storage:**
  /// - `auth_token`: Bearer token for API requests
  /// - `user_data`: JSON-encoded user object
  /// - `user_role`: User role for quick access
  /// 
  /// **NOTE:** This is a private method. Use signIn/signUp to save session.
  /// 
  /// **SECURITY WARNING:** SharedPreferences is not encrypted.
  /// Should migrate to flutter_secure_storage for production.
  Future<void> _saveSession(String token, AppUser user) async {
    _currentUser = user;
    _authStateController.add(user);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_data', jsonEncode(user.toJson()));
    await prefs.setString('user_role', user.role);

    // Set token in ApiClient immediately
    _apiClient.setToken(token);
    
    // Sync FCM Token after saving session
    syncFCMToken();
  }

  /// Sync FCM Token to Backend
  Future<void> syncFCMToken() async {
    try {
      // Import this lazily or at top level if possible, but assuming firebase_messaging is available
      // We need to add import 'package:firebase_messaging/firebase_messaging.dart'; at the top
      final token = await import_firebase_messaging.FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _apiClient.post('/device-token', data: {'token': token});
        print("FCM Token Synced: $token");
      }
    } catch (e) {
      // Ignore token sync errors (e.g. no internet or no firebase)
      print('FCM Sync Error: $e');
    }
  }

  /// Get user role for current user
  /// 
  /// **Parameters:**
  /// - `uid`: User ID (currently unused, kept for backward compatibility)
  /// 
  /// **Returns:**
  /// - `String?`: User role ('student', 'tutor', 'admin') or null if not logged in
  /// 
  /// **Note:** This method exists for backward compatibility with old code.
  /// Prefer using `currentUser?.role` directly.
  Future<String?> getUserRole(String uid) async {
    return _currentUser?.role;
  }
  
  /// Change user password
  /// 
  /// **Parameters:**
  /// - `currentPassword`: User's current password (for verification)
  /// - `newPassword`: New password to set
  /// - `confirmPassword`: Confirmation of new password (must match newPassword)
  /// 
  /// **Throws:**
  /// - `String`: Error message if password change fails
  /// 
  /// **Process:**
  /// 1. Validates current password
  /// 2. Checks new password matches confirmation
  /// 3. Updates password on backend
  /// 
  /// **Example:**
  /// ```dart
  /// try {
  ///   await authRepo.changePassword('oldPass', 'newPass123', 'newPass123');
  ///   // Password changed successfully
  /// } catch (e) {
  ///   // Handle error (wrong current password, etc.)
  /// }
  /// ```
  /// 
  /// **TODO:** Replace String throw with ApiException
  Future<void> changePassword(String currentPassword, String newPassword, String confirmPassword) async {
    try {
      await _apiClient.post('/change-password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': confirmPassword,
      });
    } catch (e) {
      // TODO: Replace with ApiException
      if (e is ApiException) {
        throw e.userMessage;
      }
      throw e.toString();
    }
  }

  /// Save user role (deprecated - no-op)
  /// 
  /// **Purpose:**
  /// - Exists for backward compatibility with old Firebase-based code
  /// - User role is managed by backend, not client
  /// 
  /// **Note:** This method does nothing. Role is set during registration
  /// and managed by backend. Do not use this method.
  Future<void> saveUserRole(String uid, String role) async {
     // No-op: Role is managed by backend, not client
     // This method exists only for backward compatibility
  }
}
