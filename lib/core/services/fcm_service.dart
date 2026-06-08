import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

// Top level function to handle background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  debugPrint('Handling a background message: ${message.messageId}');
}

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Android notification channel setup
  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.', // description
    importance: Importance.high,
  );

  bool _isFlutterLocalNotificationsInitialized = false;

  Future<void> init() async {
    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // 2. Setup Flutter Local Notifications for Foreground Messages
      await _setupFlutterLocalNotifications();

      // 3. Setup message handlers
      _setupMessageHandlers();
    }
  }

  Future<void> _setupFlutterLocalNotifications() async {
    if (_isFlutterLocalNotificationsInitialized) {
      return;
    }

    // Android Setup
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Update iOS foreground notification presentation options
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize the plugin for Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    // For iOS we might need DarwinInitializationSettings later
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tapped logic here
        if (response.payload != null) {
          debugPrint('Notification payload: ${response.payload}');
        }
      },
    );

    _isFlutterLocalNotificationsInitialized = true;
  }

  void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // If `onMessage` is triggered with a notification, construct our own
      // local notification to show to users using the created channel.
      if (notification != null && android != null && !kIsWeb) {
        _flutterLocalNotificationsPlugin.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: '@mipmap/ic_launcher',
              // other properties...
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    // Handle when app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      // Navigate to required screen based on message.data
    });
  }

  // Topic Management
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }

  Future<void> updateTopicSubscriptions({
    required bool pushEnabled,
    required bool offersEnabled,
    required bool nearbyDealsEnabled,
    required bool marketingEnabled,
  }) async {
    if (!pushEnabled) {
      // If master push is disabled, unsubscribe from all specific topics
      await unsubscribeFromTopic('offers');
      await unsubscribeFromTopic('nearbyDeals');
      await unsubscribeFromTopic('marketing');
      await unsubscribeFromTopic('all_users'); // General topic
      return;
    }

    // Subscribe to general topic if push is enabled
    await subscribeToTopic('all_users');

    // Handle individual topics
    if (offersEnabled) {
      await subscribeToTopic('offers');
    } else {
      await unsubscribeFromTopic('offers');
    }

    if (nearbyDealsEnabled) {
      await subscribeToTopic('nearbyDeals');
    } else {
      await unsubscribeFromTopic('nearbyDeals');
    }

    if (marketingEnabled) {
      await subscribeToTopic('marketing');
    } else {
      await unsubscribeFromTopic('marketing');
    }
  }

  // Get token (optional, useful for user-specific targeting instead of topics)
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}

// Global instance for easy access
final fcmService = FCMService();
