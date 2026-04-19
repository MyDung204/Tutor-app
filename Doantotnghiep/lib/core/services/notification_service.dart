import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

import 'package:doantotnghiep/core/router/app_router.dart';

/// Notification Service
/// 
/// Handles Firebase Cloud Messaging (FCM) and Local Notifications.
class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// Initialize Notification Service
  Future<void> initialize() async {
    // 1. Request Permission
    await _requestPermission();

    // 2. Initialize Local Notifications
    await _initLocalNotifications();

    // 3. Handle Background Messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(message);
        // Broadcast event to listeners (e.g. to refresh providers)
        _notificationStreamController.add(message);
      }
    });
  }

  // Stream for listening to incoming notifications
  final _notificationStreamController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onMessageReceived => _notificationStreamController.stream;

  /// Request Notification Permission
  Future<void> _requestPermission() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) debugPrint('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      if (kDebugMode) debugPrint('User granted provisional permission');
    } else {
      if (kDebugMode) debugPrint('User declined or has not accepted permission');
    }
  }

  /// Initialize Local Notifications
  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          if (kDebugMode) print('Notification tapped with payload: $payload');
          // Navigate
          try {
             // Handle specific paths or generic push
             if (payload.startsWith('/')) {
                AppRouter.router.push(payload);
             }
          } catch (e) { print('Nav Error: $e'); }
        }
      },
    );

    // EXPLICITLY CREATE CHANNEL (Fix for missing Sound/Heads-up on Android 8+)
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    await androidImplementation?.createNotificationChannel(const AndroidNotificationChannel(
      'high_importance_channel_v2', // Changed ID to force update settings
      'Thông báo quan trọng', // Localized title
      description: 'Kênh thông báo cho các sự kiện quan trọng.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    ));
  }

  /// Show Local Notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel_v2', // Match new ID
            'Thông báo quan trọng',
            channelDescription: 'Kênh thông báo cho các sự kiện quan trọng.',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  /// Show Local Notification (Public for Manual Trigger)
  Future<void> showNotification({required String title, required String body, String? payload}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel_v2',
      'Thông báo quan trọng',
      channelDescription: 'Kênh thông báo cho các sự kiện quan trọng.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      DateTime.now().millisecond, // Unique ID
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  /// Get FCM Token
  Future<String?> getToken() async {
    return await _fcm.getToken();
  }
}

/// Helper for background messages (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // await Firebase.initializeApp(); // Uncomment if using Firebase services in background
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }
}


