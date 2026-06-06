import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/navigation/bottom_nav_bar.dart';
import '../../../core/widgets/common/fallback_image.dart';
import '../../../providers/app_state_providers.dart';
import '../../home/presentation/home_screen.dart';
import '../../discover/presentation/discover_screen.dart';
import '../../map/presentation/map_screen.dart';
import '../../following/presentation/following_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../products/presentation/product_management_screen.dart';
import '../../posts/presentation/post_management_screen.dart';
import '../../leads/presentation/leads_screen.dart';
import '../../auth/presentation/splash_screen.dart';
import '../../auth/application/auth_service.dart';

class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(appRoleProvider);
    final currentIndex = ref.watch(bottomNavIndexProvider);
    final dbState = ref.watch(databaseProvider);
    final activeThemeMode = ref.watch(appThemeModeProvider);

    // Guard if role hasn't synced yet
    if (role == null) {
      return const SplashScreen();
    }

    final List<Widget> screens = role == 'user'
        ? const [
            HomeScreen(),
            DiscoverScreen(),
            MapScreen(),
            FollowingScreen(),
            ProfileScreen(),
          ]
        : const [
            DashboardScreen(),
            ProductManagementScreen(),
            PostManagementScreen(),
            LeadsScreen(),
            ProfileScreen(),
          ];

    final user = dbState.currentUser;
    final shop = dbState.currentShop;

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
      drawer: Drawer(
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            children: [
              // Drawer Header
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                ),
                currentAccountPicture: FallbackAvatar(
                  imageUrl: role == 'user' ? user.photoUrl : shop.logo,
                  radius: 32,
                  fallbackIcon: role == 'user' ? LucideIcons.user : LucideIcons.store,
                ),
                accountName: Text(
                  role == 'user' ? user.name : shop.shopName,
                  style: AppTypography.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                accountEmail: Text(
                  role == 'user' ? user.email : 'Owner: ${shop.ownerName}',
                  style: AppTypography.caption.copyWith(color: Colors.white70),
                ),
              ),
              
              // Menu Items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ListTile(
                      leading: const Icon(LucideIcons.home, color: AppColors.primary),
                      title: Text('Home Feed', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                      onTap: () {
                        Navigator.pop(context);
                        ref.read(bottomNavIndexProvider.notifier).state = 0;
                      },
                    ),
                    ListTile(
                      leading: const Icon(LucideIcons.compass, color: AppColors.primary),
                      title: Text('Discover', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                      onTap: () {
                        Navigator.pop(context);
                        ref.read(bottomNavIndexProvider.notifier).state = 1;
                      },
                    ),
                    ListTile(
                      leading: const Icon(LucideIcons.mapPin, color: AppColors.primary),
                      title: Text('Map View', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                      onTap: () {
                        Navigator.pop(context);
                        ref.read(bottomNavIndexProvider.notifier).state = 2;
                      },
                    ),
                    if (role == 'user')
                      ListTile(
                        leading: const Icon(LucideIcons.heart, color: AppColors.primary),
                        title: Text('Following Updates', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                        onTap: () {
                          Navigator.pop(context);
                          ref.read(bottomNavIndexProvider.notifier).state = 3;
                        },
                      ),
                    ListTile(
                      leading: const Icon(LucideIcons.user, color: AppColors.primary),
                      title: Text('My Profile', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                      onTap: () {
                        Navigator.pop(context);
                        ref.read(bottomNavIndexProvider.notifier).state = role == 'user' ? 4 : 4;
                      },
                    ),
                    const Divider(),
                    
                    // Quick Theme Control in Drawer
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Appearance',
                            style: AppTypography.label.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _ThemeOptionPill(
                                label: 'Light',
                                isSelected: activeThemeMode == ThemeMode.light,
                                icon: LucideIcons.sun,
                                onTap: () => ref.read(authServiceProvider).updateThemeMode('light'),
                              ),
                              const SizedBox(width: 8),
                              _ThemeOptionPill(
                                label: 'Dark',
                                isSelected: activeThemeMode == ThemeMode.dark,
                                icon: LucideIcons.moon,
                                onTap: () => ref.read(authServiceProvider).updateThemeMode('dark'),
                              ),
                              const SizedBox(width: 8),
                              _ThemeOptionPill(
                                label: 'Auto',
                                isSelected: activeThemeMode == ThemeMode.system,
                                icon: LucideIcons.laptop,
                                onTap: () => ref.read(authServiceProvider).updateThemeMode('system'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Drawer Footer
              const Divider(),
              ListTile(
                leading: const Icon(LucideIcons.logOut, color: AppColors.error),
                title: Text(
                  'Log Out',
                  style: AppTypography.body.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await ref.read(authServiceProvider).handleSignOut();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Sign out failed: ${e.toString()}')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeOptionPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  const _ThemeOptionPill({
    required this.label,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 12,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTypography.label.copyWith(
                  fontSize: 10,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
