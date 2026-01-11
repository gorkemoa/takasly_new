import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'navigation_service.dart';

/// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log('📬 Background message received', name: 'FCM');
  developer.log('Message ID: ${message.messageId}', name: 'FCM');
}

/// Firebase Cloud Messaging service for handling push notifications
class FirebaseMessagingService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel_v2', // Updated channel ID to refresh settings
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static int? activeTicketId;

  /// Check if the notification should be suppressed (e.g. user is in the chat)
  static bool _shouldSuppressNotification(Map<String, dynamic> data) {
    if (activeTicketId == null) return false;

    // Same parsing logic as _processNavigation
    Map<String, dynamic> finalData = Map.from(data);
    if (finalData.containsKey('keysandvalues')) {
      try {
        String jsonStr = finalData['keysandvalues'].toString();
        if (jsonStr.contains(': }') ||
            jsonStr.contains(':, }') ||
            jsonStr.contains(': }')) {
          jsonStr = jsonStr.replaceAll(RegExp(r':\s*}'), ': null}');
        }
        final nested = jsonDecode(jsonStr);
        if (nested is Map) {
          finalData.addAll(Map<String, dynamic>.from(nested));
        }
      } catch (_) {}
    }

    final type = finalData['type'] as String? ?? '';
    final idValue = finalData['id'] ?? finalData['type_id'] ?? '0';
    final typeId = int.tryParse(idValue.toString()) ?? 0;

    if (type == 'new_ticket_message' && typeId == activeTicketId) {
      developer.log(
        '🔕 Suppressing notification for active ticket: $activeTicketId',
        name: 'FCM',
      );
      return true;
    }
    return false;
  }

  /// Initialize Firebase Messaging and Local Notifications
  static Future<void> initialize() async {
    try {
      developer.log('🚀 Initializing Firebase Messaging', name: 'FCM');

      // 1. Request notification permissions (iOS & Android 13+)
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      developer.log(
        '📱 Permission status: ${settings.authorizationStatus}',
        name: 'FCM',
      );

      // 2. Initialize Flutter Local Notifications (Android & iOS)
      const AndroidInitializationSettings androidInitialize =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const DarwinInitializationSettings iosInitialize =
          DarwinInitializationSettings(
            requestSoundPermission: true,
            requestBadgePermission: true,
            requestAlertPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: androidInitialize,
            iOS: iosInitialize,
          );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Foreground notification tap logic
          if (response.payload != null) {
            try {
              final Map<String, dynamic> data = jsonDecode(response.payload!);
              _processNavigation(data, null);
            } catch (e) {
              developer.log('❌ Error parsing payload: $e', name: 'FCM');
            }
          }
        },
      );

      if (Platform.isAndroid) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(_channel);

        developer.log('✅ Android Notification Channel Created', name: 'FCM');
      }

      // 3. iOS: Disable native foreground presentation to avoid duplicates
      // We will use Local Notifications for both Android and iOS in foreground
      if (Platform.isIOS) {
        await _firebaseMessaging.setForegroundNotificationPresentationOptions(
          alert: false,
          badge: true,
          sound: false,
        );
      }

      // 4. Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        developer.log('📨 Foreground message received', name: 'FCM');

        // Check suppression
        if (_shouldSuppressNotification(message.data)) {
          return;
        }

        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        // Show local notification for both Android and iOS
        if (notification != null) {
          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
                icon: android?.smallIcon ?? '@mipmap/launcher_icon',
                importance: Importance.max,
                priority: Priority.high,
                ticker: 'ticker',
                playSound: true,
              ),
              iOS: const DarwinNotificationDetails(
                presentSound: true,
                presentAlert: true,
                presentBadge: true,
              ),
            ),
            payload: jsonEncode(message.data),
          );
        }
      });

      // 5. Handle notification taps (Background / Terminated)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageNavigation);

      RemoteMessage? initialMessage = await _firebaseMessaging
          .getInitialMessage();
      if (initialMessage != null) {
        developer.log(
          '🔔 App opened from terminated state via FCM',
          name: 'FCM',
        );
        Future.delayed(const Duration(milliseconds: 1000), () {
          _handleMessageNavigation(initialMessage);
        });
      }

      // 6. Token refresh and Token Log
      try {
        final token = await getToken();
        if (token != null) developer.log('🔑 FCM Token: $token', name: 'FCM');
      } catch (e) {
        developer.log('⚠️ Could not get initial FCM token: $e', name: 'FCM');
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        developer.log('🔄 FCM Token refreshed: $newToken', name: 'FCM');
      });

      developer.log(
        '✅ Firebase Messaging initialization complete',
        name: 'FCM',
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error initializing FCM',
        name: 'FCM',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Subscribe to a topic using userId (String)
  static Future<void> subscribeToUserTopic(String userId) async {
    try {
      if (Platform.isIOS) {
        final apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken == null) {
          developer.log(
            '⚠️ APNS token not ready, skipping subscription: $userId',
            name: 'FCM',
          );
          return;
        }
      }
      // Backend expects topic to be just the user ID string
      await _firebaseMessaging.subscribeToTopic(userId);
      developer.log('📌 Subscribed to topic: $userId', name: 'FCM');
    } catch (e) {
      developer.log('❌ Error subscribing to topic: $userId: $e', name: 'FCM');
    }
  }

  /// Unsubscribe from a topic
  static Future<void> unsubscribeFromUserTopic(String userId) async {
    try {
      if (Platform.isIOS) {
        final apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken == null) return;
      }
      await _firebaseMessaging.unsubscribeFromTopic(userId);
      developer.log('📌 Unsubscribed from topic: $userId', name: 'FCM');
    } catch (e) {
      developer.log(
        '❌ Error unsubscribing from topic: $userId: $e',
        name: 'FCM',
      );
    }
  }

  static Future<String?> getToken() async {
    try {
      if (Platform.isIOS) {
        final apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken == null) {
          developer.log(
            '⚠️ APNS token has not been received yet. FCM token cannot be retrieved.',
            name: 'FCM',
          );
          return null;
        }
      }
      return await _firebaseMessaging.getToken();
    } catch (e) {
      developer.log('❌ Error getting FCM token: $e', name: 'FCM');
      return null;
    }
  }

  static void _handleMessageNavigation(RemoteMessage message) {
    _processNavigation(message.data, message.notification?.title);
  }

  static void _processNavigation(
    Map<String, dynamic> data,
    String? notificationTitle,
  ) {
    if (data.isEmpty) return;

    Map<String, dynamic> finalData = Map.from(data);

    // Parse nested keysandvalues if exists (as requested by user)
    if (finalData.containsKey('keysandvalues')) {
      try {
        String jsonStr = finalData['keysandvalues'].toString();

        // Malformed JSON sanitization: handles cases like "url": } by making it "url": null }
        // Also targets common trailing comma or missing value issues
        if (jsonStr.contains(': }') ||
            jsonStr.contains(':, }') ||
            jsonStr.contains(': }')) {
          jsonStr = jsonStr.replaceAll(RegExp(r':\s*}'), ': null}');
        }

        final nested = jsonDecode(jsonStr);
        if (nested is Map) {
          finalData.addAll(Map<String, dynamic>.from(nested));
        }
      } catch (e) {
        developer.log('❌ Error parsing keysandvalues JSON: $e', name: 'FCM');
        developer.log(
          '📦 Raw keysandvalues: ${finalData['keysandvalues']}',
          name: 'FCM',
        );
      }
    }

    final type = finalData['type'] as String? ?? '';
    // Use 'id' or 'type_id'
    final idValue = finalData['id'] ?? finalData['type_id'] ?? '0';
    final typeId = int.tryParse(idValue.toString()) ?? 0;
    final url = finalData['url'] as String?;
    final title = notificationTitle ?? finalData['title'] as String?;

    if (type.isNotEmpty || (url != null && url.isNotEmpty)) {
      developer.log(
        '🚀 FCM Navigating: $type (ID: $typeId, URL: $url)',
        name: 'FCM',
      );
      NavigationService().handleDeepLink(
        type: type,
        typeId: typeId,
        url: url,
        title: title,
      );
    }
  }
}
