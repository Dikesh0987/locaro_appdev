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
import 'core/widgets/common/network_overlay_wrapper.dart';
import 'features/auth/presentation/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set the background messaging handler early on, as a named top-level function
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final container = ProviderContainer();

  // Render UI immediately — don't block on FCM/Google/Firebase init
  runApp(UncontrolledProviderScope(
    container: container,
    child: LocaroApp(container: container),
  ));
}

class LocaroApp extends ConsumerStatefulWidget {
  final ProviderContainer container;
  
  const LocaroApp({super.key, required this.container});

  @override
  ConsumerState<LocaroApp> createState() => _LocaroAppState();
}

class _LocaroAppState extends ConsumerState<LocaroApp> {
  Future<void>? _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeServices();
  }

  Future<void> _initializeServices() async {
    await Firebase.initializeApp();
    
    // Firestore persistence — synchronous, no await needed
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );

    await fcmService.init(navigatorKey, widget.container);
    try {
      await GoogleSignIn.instance.initialize();
    } catch (_) {
      // Ignore configuration errors on unsupported desktop/test platforms
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          // Show the splash screen while Firebase initializes
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: const SplashScreen(),
          );
        }

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
      },
    );
  }
}
