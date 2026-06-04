import 'package:flutter/material.dart';
import '../features/shell/presentation/shell_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String initial = '/';

  static Map<String, WidgetBuilder> get routes => {
        initial: (context) => const ShellScreen(),
      };
}
