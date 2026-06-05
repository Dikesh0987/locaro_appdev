import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/navigation/bottom_nav_bar.dart';
import '../../../providers/app_state_providers.dart';
import '../../home/presentation/home_screen.dart';
import '../../discover/presentation/discover_screen.dart';
import '../../map/presentation/map_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../products/presentation/product_management_screen.dart';
import '../../posts/presentation/post_management_screen.dart';
import '../../leads/presentation/leads_screen.dart';
import '../../auth/presentation/splash_screen.dart';

class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(appRoleProvider);
    final currentIndex = ref.watch(bottomNavIndexProvider);

    // Guard if role hasn't synced yet
    if (role == null) {
      return const SplashScreen();
    }

    final List<Widget> screens = role == 'user'
        ? const [
            HomeScreen(),
            DiscoverScreen(),
            MapScreen(),
            NotificationsScreen(),
            ProfileScreen(),
          ]
        : const [
            DashboardScreen(),
            ProductManagementScreen(),
            PostManagementScreen(),
            LeadsScreen(),
            ProfileScreen(),
          ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavBar(
        role: role,
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(bottomNavIndexProvider.notifier).state = index;
        },
      ),
    );
  }
}
