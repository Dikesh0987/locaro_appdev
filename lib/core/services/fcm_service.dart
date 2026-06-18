import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../features/products/presentation/product_details_screen.dart';
import '../../features/shop/presentation/shop_profile_screen.dart';
import '../../providers/app_state_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<String> _downloadAndSaveFile(String url, String fileName) async {
  final Directory directory = Directory.systemTemp;
  final String filePath = '${directory.path}/$fileName';
  final File file = File(filePath);
  
  if (await file.exists()) return filePath;

  final HttpClient client = HttpClient();
  try {
    final HttpClientRequest request = await client.getUrl(Uri.parse(url));
    final HttpClientResponse response = await request.close();
    if (response.statusCode == 200) {
      final List<int> bytes = [];
      await for (var chunk in response) {
        bytes.addAll(chunk);
      }
      await file.writeAsBytes(bytes);
      return filePath;
    }
  } catch (e) {
    debugPrint('Error downloading image: $e');
  } finally {
    client.close();
  }
  return '';
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('================ BACKGROUND NOTIFICATION ================');
  debugPrint('Message ID: ${message.messageId}');
  
  // Extract title and body from notification or data
  final String? title = message.notification?.title ?? message.data['title'];
  final String? body = message.notification?.body ?? message.data['body'];
  final String? imageUrl = message.notification?.android?.imageUrl ?? message.data['image'] ?? message.data['imageUrl'];

  // If the message is data-only (notification block is null), the OS will NOT show it.
  // We must show it manually using flutter_local_notifications.
  if (message.notification == null && title != null && body != null) {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    await flutterLocalNotificationsPlugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
      ),
    );

    BigPictureStyleInformation? bigPictureStyleInformation;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final String largeIconPath = await _downloadAndSaveFile(imageUrl, 'largeIcon_${message.messageId ?? DateTime.now().millisecondsSinceEpoch}');
      if (largeIconPath.isNotEmpty) {
        bigPictureStyleInformation = BigPictureStyleInformation(
          FilePathAndroidBitmap(largeIconPath),
          hideExpandedLargeIcon: true,
          contentTitle: title,
          summaryText: body,
        );
      }
    }

    await flutterLocalNotificationsPlugin.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'locaro_high_importance_v1',
          'High Importance Notifications',
          channelDescription: 'This channel is used for important notifications.',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          icon: '@drawable/ic_notification',
          styleInformation: bigPictureStyleInformation,
        ),
      ),
      payload: jsonEncode(message.data),
    );
    debugPrint('Manually displayed notification for data-only message');
  }

  debugPrint('=======================================================');
}

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'locaro_high_importance_v1', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
    enableLights: true,
    enableVibration: true,
    showBadge: true,
    playSound: true,
  );

  final AndroidNotificationChannel _defaultChannel = const AndroidNotificationChannel(
    'default_importance_channel', // id
    'Default Notifications', // title
    description: 'This channel is used for general notifications.',
    importance: Importance.defaultImportance,
  );

  bool _isFlutterLocalNotificationsInitialized = false;
  GlobalKey<NavigatorState>? _navigatorKey;
  ProviderContainer? _container;

  Future<void> init(GlobalKey<NavigatorState> navigatorKey, ProviderContainer container) async {
    _navigatorKey = navigatorKey;
    _container = container;

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
      
      // 5. Sync token on auth state changes
      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) {
          syncToken();
          _attemptPendingDeepLinkNavigation();
        }
      });
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

    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.createNotificationChannel(_channel);
    await androidPlugin?.createNotificationChannel(_defaultChannel);

    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_notification');
        
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
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('================ FOREGROUND NOTIFICATION ================');
      debugPrint('Notification State: Foreground');
      debugPrint('Message ID: ${message.messageId}');
      debugPrint('Message Payload (Data): ${message.data}');
      if (message.notification != null) {
        debugPrint('Notification Title: ${message.notification?.title}');
        debugPrint('Notification Body: ${message.notification?.body}');
      }
      debugPrint('=======================================================');

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null && !kIsWeb) {
        BigPictureStyleInformation? bigPictureStyleInformation;
        final String? imageUrl = android.imageUrl ?? message.data['image'] ?? message.data['imageUrl'];
        
        if (imageUrl != null && imageUrl.isNotEmpty) {
          final String largeIconPath = await _downloadAndSaveFile(imageUrl, 'largeIcon_${message.messageId ?? DateTime.now().millisecondsSinceEpoch}');
          if (largeIconPath.isNotEmpty) {
            bigPictureStyleInformation = BigPictureStyleInformation(
              FilePathAndroidBitmap(largeIconPath),
              hideExpandedLargeIcon: true,
              contentTitle: notification.title,
              summaryText: notification.body,
            );
          }
        }

        _flutterLocalNotificationsPlugin.show(
          id: DateTime.now().millisecond,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: '@drawable/ic_notification',
              importance: Importance.high,
              priority: Priority.high,
              styleInformation: bigPictureStyleInformation,
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
    if (_container == null) return;
    
    final type = data['type'] as String?;
    final referenceId = data['referenceId'] as String?;

    if (type == null || referenceId == null) return;

    // Save deep link state
    _container!.read(pendingDeepLinkProvider.notifier).state = data;
    
    // Attempt navigation if context is ready and user is logged in
    _attemptPendingDeepLinkNavigation();
  }

  void _attemptPendingDeepLinkNavigation() {
    if (_navigatorKey?.currentState?.context == null || _container == null) return;
    
    final pendingLink = _container!.read(pendingDeepLinkProvider);
    if (pendingLink == null) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Wait for login

    final type = pendingLink['type'] as String;
    final referenceId = pendingLink['referenceId'] as String;

    // Clear pending link
    _container!.read(pendingDeepLinkProvider.notifier).state = null;

    if (type.toLowerCase() == 'product' || type.toLowerCase() == 'offers') {
      _navigatorKey!.currentState!.push(MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(productId: referenceId),
      ));
    } else if (type.toLowerCase() == 'shop' || type.toLowerCase() == 'followers') {
      _navigatorKey!.currentState!.push(MaterialPageRoute(
        builder: (context) => ShopProfileScreen(shopId: referenceId),
      ));
    } else {
      _navigatorKey!.currentState!.push(MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text('Deep Link: $type')),
          body: Center(child: Text('Navigating to $type with ID: $referenceId')),
        ),
      ));
    }
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
