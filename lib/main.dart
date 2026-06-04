import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'providers/app_state_providers.dart';


void main() {
  runApp(
    const ProviderScope(
      child: NearoApp(),
    ),
  );
}

class NearoApp extends ConsumerWidget {
  const NearoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeModeProvider);

    return MaterialApp(
      title: 'Nearo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      initialRoute: AppRoutes.initial,
      routes: AppRoutes.routes,
    );
  }
}
