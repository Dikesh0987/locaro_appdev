import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';

void main() {
  runApp(
    const ProviderScope(
      child: NearoApp(),
    ),
  );
}

class NearoApp extends StatelessWidget {
  const NearoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nearo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.initial,
      routes: AppRoutes.routes,
    );
  }
}
