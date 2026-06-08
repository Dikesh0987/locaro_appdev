import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/base_card.dart';
import 'auth_flow_container.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  String? _selectedRole; // 'user' or 'shop_owner'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.mobilePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Center(
                child: Text(
                  'Locaro',
                  style: AppTypography.display.copyWith(
                    fontSize: 40,
                    letterSpacing: -1.2,
                    fontWeight: FontWeight.w900,
                    color: context.colors.primary,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.s12),
              Center(
                child: Text(
                  'Hyperlocal Discovery Platform',
                  style: AppTypography.caption.copyWith(
                    color: context.colors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Choose account type',
                style: AppTypography.heading.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: AppSpacing.s16),
              
              // User Card
              BaseCard(
                onTap: () => setState(() => _selectedRole = 'user'),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.s20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(
                      color: _selectedRole == 'user' ? context.colors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.s12),
                        decoration: BoxDecoration(
                          color: context.colors.border,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(LucideIcons.user, color: context.colors.primary),
                      ),
                      SizedBox(width: AppSpacing.s16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('User', style: AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
                            SizedBox(height: AppSpacing.s4),
                            Text(
                              'Discover products and offers around you',
                              style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.s12),
              
              // Owner Card
              BaseCard(
                onTap: () => setState(() => _selectedRole = 'shop_owner'),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.s20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(
                      color: _selectedRole == 'shop_owner' ? context.colors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.s12),
                        decoration: BoxDecoration(
                          color: context.colors.border,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(LucideIcons.store, color: context.colors.primary),
                      ),
                      SizedBox(width: AppSpacing.s16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Shop Owner', style: AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
                            SizedBox(height: AppSpacing.s4),
                            Text(
                              'Promote products and grow followers',
                              style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              PrimaryButton(
                text: 'Continue',
                onPressed: () {
                  if (_selectedRole == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select an account type to continue'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AuthFlowContainer(role: _selectedRole!),
                      ),
                    );
                  }
                },
              ),
              SizedBox(height: AppSpacing.s8),
            ],
          ),
        ),
      ),
    );
  }
}
