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
    final List<_NavItem> items = role == 'user'
        ? const [
            _NavItem(icon: LucideIcons.home, label: 'Home'),
            _NavItem(icon: LucideIcons.compass, label: 'Discover'),
            _NavItem(icon: LucideIcons.heart, label: 'Following'),
            _NavItem(icon: LucideIcons.user, label: 'Profile'),
          ]
        : const [
            _NavItem(icon: LucideIcons.layoutDashboard, label: 'Dashboard'),
            _NavItem(icon: LucideIcons.shoppingBag, label: 'Products'),
            _NavItem(icon: LucideIcons.plusCircle, label: 'Post'),
            _NavItem(icon: LucideIcons.messageCircle, label: 'Queries'),
            _NavItem(icon: LucideIcons.user, label: 'Profile'),
          ];

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == currentIndex;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedScale(
                          scale: isSelected ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            item.icon,
                            size: 22,
                            color: isSelected
                                ? context.colors.primary
                                : context.colors.secondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: AppTypography.label.copyWith(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? context.colors.primary
                                : context.colors.secondary,
                          ),
                          child: Text(item.label),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
