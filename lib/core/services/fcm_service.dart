import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');
}

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  bool _isFlutterLocalNotificationsInitialized = false;
  GlobalKey<NavigatorState>? _navigatorKey;

  Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;

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

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      // Check if Android 13+ permission is denied forever
      final status = await Permission.notification.status;
      if (status.isPermanentlyDenied && _navigatorKey?.currentContext != null) {
        showDialog(
          context: _navigatorKey!.currentContext!,
          builder: (context) => AlertDialog(
            title: const Text('Notifications Disabled'),
            content: const Text('Please enable notifications in app settings to stay updated.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(context);
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    }

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // 2. Setup Local Notifications
      await _setupFlutterLocalNotifications();

      // 3. Sync Token
      await syncToken();

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        await _updateTokenInFirestore(newToken);
      });

      // 4. Setup message handlers
      _setupMessageHandlers();
    }
  }

  Future<void> syncToken() async {
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _updateTokenInFirestore(token);
    }
  }

  Future<void> _updateTokenInFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'fcmToken': token,
        });
        debugPrint('FCM Token synced to Firestore: $token');
      } catch (e) {
        debugPrint('Failed to sync FCM Token: $e');
      }
    }
  }

  Future<void> _setupFlutterLocalNotifications() async {
    if (_isFlutterLocalNotificationsInitialized) return;

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          debugPrint('Local Notification tapped with payload: ${response.payload}');
          try {
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            _handleDeepLink(data);
          } catch (_) {}
        }
      },
    );

    _isFlutterLocalNotificationsInitialized = true;
  }

  void _setupMessageHandlers() {
    // Terminated state to foreground tap
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App launched from terminated state via notification');
        _handleDeepLink(message.data);
      }
    });

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Message received in foreground: ${message.messageId}');
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

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
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    // Background to foreground tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('App opened from background via notification');
      _handleDeepLink(message.data);
    });
  }

  void _handleDeepLink(Map<String, dynamic> data) {
    if (_navigatorKey?.currentState == null) return;
    
    final type = data['type'] as String?;
    final referenceId = data['referenceId'] as String?;

    if (type == null || referenceId == null) return;

    // Based on the prompt's deep linking requirements
    // Normally we'd push a named route or material page route here.
    // For demonstration, we use pushNamed if those screens exist, or handle it via a router.
    // Assuming you have named routes or you can build simple dummy routes if they don't exist yet.
    
    // We will push a generic placeholder if the actual routes are not yet defined in AppRoutes.
    _navigatorKey!.currentState!.push(MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: Text('Deep Link: $type')),
        body: Center(child: Text('Navigating to $type with ID: $referenceId')),
      ),
    ));
  }

  // Topic Management
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  Future<void> updateTopicSubscriptions({
    required bool pushEnabled,
    required bool offersEnabled,
    required bool nearbyDealsEnabled,
    required bool marketingEnabled,
  }) async {
    if (!pushEnabled) {
      await unsubscribeFromTopic('offers');
      await unsubscribeFromTopic('nearbyDeals');
      await unsubscribeFromTopic('marketing');
      await unsubscribeFromTopic('all_users');
      return;
    }
    await subscribeToTopic('all_users');
    offersEnabled ? await subscribeToTopic('offers') : await unsubscribeFromTopic('offers');
    nearbyDealsEnabled ? await subscribeToTopic('nearbyDeals') : await unsubscribeFromTopic('nearbyDeals');
    marketingEnabled ? await subscribeToTopic('marketing') : await unsubscribeFromTopic('marketing');
  }
}

final fcmService = FCMService();
