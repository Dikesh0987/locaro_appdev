import 'package:flutter/material.dart';
import '../features/auth/presentation/auth_guard.dart';

class AppRoutes {
  AppRoutes._();

  static const String initial = '/';

  static Map<String, WidgetBuilder> get routes => {
        initial: (context) => const AuthGuard(),
      };
}
