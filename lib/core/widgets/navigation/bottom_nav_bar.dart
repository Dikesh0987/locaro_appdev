import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String role; // 'user' or 'owner'

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final List<BottomNavigationBarItem> items = role == 'user'
        ? const [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.home),
              activeIcon: Icon(LucideIcons.home, fill: 1.0),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.compass),
              activeIcon: Icon(LucideIcons.compass, fill: 1.0),
              label: 'Discover',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.mapPin),
              activeIcon: Icon(LucideIcons.mapPin, fill: 1.0),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.bell),
              activeIcon: Icon(LucideIcons.bell, fill: 1.0),
              label: 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.user),
              activeIcon: Icon(LucideIcons.user, fill: 1.0),
              label: 'Profile',
            ),
          ]
        : const [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.layoutDashboard),
              activeIcon: Icon(LucideIcons.layoutDashboard, fill: 1.0),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.shoppingBag),
              activeIcon: Icon(LucideIcons.shoppingBag, fill: 1.0),
              label: 'Products',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.plusCircle),
              activeIcon: Icon(LucideIcons.plusCircle, fill: 1.0),
              label: 'Posts',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.users),
              activeIcon: Icon(LucideIcons.users, fill: 1.0),
              label: 'Leads',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.user),
              activeIcon: Icon(LucideIcons.user, fill: 1.0),
              label: 'Profile',
            ),
          ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.secondary,
        selectedLabelStyle: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTypography.label,
        elevation: 0,
        items: items,
      ),
    );
  }
}
