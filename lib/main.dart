import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'providers/app_state_providers.dart';
import 'core/services/fcm_service.dart';
import 'core/widgets/common/network_overlay_wrapper.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Set the background messaging handler early on, as a named top-level function
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  final container = ProviderContainer();
  // Initialize FCM Service for foreground and permissions
  await fcmService.init(navigatorKey, container);

  // Removed appVerificationDisabledForTesting so Play Integrity works for real numbers in debug mode
  // if (kDebugMode) {
  //   FirebaseAuth.instance.setSettings(appVerificationDisabledForTesting: true);
  // }

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  try {
    await GoogleSignIn.instance.initialize();
  } catch (_) {
    // Ignore configuration errors on unsupported desktop/test platforms
  }
  runApp(UncontrolledProviderScope(
    container: container,
    child: const LocaroApp(),
  ));
}

class LocaroApp extends ConsumerWidget {
  const LocaroApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeModeProvider);

    return MaterialApp(
      title: 'Locaro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      navigatorKey: navigatorKey,
      initialRoute: AppRoutes.initial,
      routes: AppRoutes.routes,
      builder: (context, child) {
        return NetworkOverlayWrapper(
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}
