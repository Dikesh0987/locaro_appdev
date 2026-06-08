import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'providers/app_state_providers.dart';
import 'core/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Set the background messaging handler early on, as a named top-level function
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Initialize FCM Service for foreground and permissions
  await fcmService.init();

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  try {
    await GoogleSignIn.instance.initialize();
  } catch (_) {
    // Ignore configuration errors on unsupported desktop/test platforms
  }
  runApp(const ProviderScope(child: LocaroApp()));
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
      initialRoute: AppRoutes.initial,
      routes: AppRoutes.routes,
    );
  }
}
