import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/widgets/common/scale_button.dart';
import '../../../providers/app_state_providers.dart';
import '../../../models/shop_model.dart';
import '../application/auth_service.dart';
import '../data/auth_repository.dart';


class AuthFlowContainer extends ConsumerStatefulWidget {
  final String role; // 'user' or 'owner'

  const AuthFlowContainer({super.key, required this.role});

  @override
  ConsumerState<AuthFlowContainer> createState() => _AuthFlowContainerState();
}

class _AuthFlowContainerState extends ConsumerState<AuthFlowContainer> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Google Account simulated state
  String? _googleProfileImage;


  // Controllers for User flow
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _userEmailController = TextEditingController();
  final TextEditingController _userPhoneController = TextEditingController();
  final List<String> _selectedInterests = [];

  // Controllers for Shop Owner flow
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _shopOwnerNameController = TextEditingController();
  final TextEditingController _shopAddressController = TextEditingController();
  final TextEditingController _shopDescController = TextEditingController();
  String _selectedCategory = 'Cafe';
  String? _logoUrl;
  String? _bannerUrl;

  final List<String> _availableCategories = ['Cafe', 'Groceries', 'Electronics', 'Fashion', 'Bakery'];
  final List<String> _availableInterests = ['Coffee', 'Fresh Produce', 'Electronics', 'Fashion', 'Bakery', 'Organic Food', 'Tech Gadgets', 'Desserts'];

  @override
  void dispose() {
    _pageController.dispose();
    _userNameController.dispose();
    _userEmailController.dispose();
    _userPhoneController.dispose();
    _shopNameController.dispose();
    _shopOwnerNameController.dispose();
    _shopAddressController.dispose();
    _shopDescController.dispose();
    super.dispose();
  }

  void _nextPage() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isLoading = false);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeAuth() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(databaseProvider).currentUser;
      final updatedUser = user.copyWith(
        name: _userNameController.text.trim(),
        email: _userEmailController.text.trim(),
        phone: _userPhoneController.text.trim(),
        interests: _selectedInterests,
        location: 'Sector 62, Noida', // default block
        photoUrl: _googleProfileImage ?? '',
      );

      if (widget.role == 'owner') {
        final newShop = ShopModel(
          id: 'shop_${user.uid}',
          ownerUid: user.uid,
          shopName: _shopNameController.text.trim(),
          ownerName: _userNameController.text.trim(),
          logoUrl: _logoUrl ?? 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=100',
          bannerUrl: _bannerUrl ?? 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=600',
          address: _shopAddressController.text.trim(),
          latitude: 28.6273,
          longitude: 77.3725,
          rating: 5.0,
          followers: 0,
          category: _selectedCategory,
          isVerified: true,
          phone: _userPhoneController.text.trim(),
          whatsapp: _userPhoneController.text.trim(),
          description: _shopDescController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await ref.read(databaseProvider.notifier).updateCurrentShop(newShop);
      }

      await ref.read(authServiceProvider).completeOnboarding(updatedUser);
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Onboarding setup failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final user = await ref.read(authServiceProvider).handleGoogleSignIn(widget.role);
      if (mounted) {
        setState(() => _isLoading = false);
        if (user.isOnboardingCompleted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          // New User: Populate controllers with Google data
          _userNameController.text = user.name;
          _userEmailController.text = user.email;
          _googleProfileImage = user.photoUrl.isNotEmpty ? user.photoUrl : null;
          
          if (widget.role == 'owner') {
            _shopOwnerNameController.text = user.name;
            _shopNameController.text = '${user.name}\'s Shop';
          }
          
          _nextPage();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleGuestSignIn() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).handleGuestSignIn();
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Guest login failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _pickLogo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _isLoading = true);
      try {
        final currentUser = ref.read(databaseProvider).currentUser;
        final url = await ref.read(authRepositoryProvider).uploadShopAsset(
          'shop_${currentUser.uid}',
          'logo',
          File(image.path)
        );
        setState(() => _logoUrl = url);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload logo: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickBanner() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (image != null) {
      setState(() => _isLoading = true);
      try {
        final currentUser = ref.read(databaseProvider).currentUser;
        final url = await ref.read(authRepositoryProvider).uploadShopAsset(
          'shop_${currentUser.uid}',
          'banner',
          File(image.path)
        );
        setState(() => _bannerUrl = url);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload banner: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalSteps = widget.role == 'user' ? 4 : 5;

    return Scaffold(
      appBar: AppBar(
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: _prevPage,
              )
            : null,
        title: Text(widget.role == 'user' ? 'Create Account' : 'Merchant Center'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.mobilePadding),
            child: Center(
              child: Text(
                '${_currentStep + 1}/$totalSteps',
                style: AppTypography.label.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentStep + 1) / totalSteps,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 3,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() => _currentStep = page);
                },
                children: widget.role == 'user'
                    ? _buildUserPages()
                    : _buildShopPages(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- USER FLOW PAGES ---
  List<Widget> _buildUserPages() {
    return [
      _buildWelcomeStep(),
      _buildProfileStep(),
      _buildInterestsStep(),
      _buildPermissionStep(),
    ];
  }

  // --- SHOP FLOW PAGES ---
  List<Widget> _buildShopPages() {
    return [
      _buildWelcomeStep(),
      _buildBusinessSetupStep(),
      _buildShopDetailsStep(),
      _buildMediaUploadStep(),
      _buildPermissionStep(isShop: true),
    ];
  }

  // --- WELCOME STEP ---
  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.mobilePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Center(
            child: ScaleButtonPressed(
              onTap: _handleGoogleSignIn,
              child: Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: const Icon(LucideIcons.compass, size: 48, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            widget.role == 'user' ? 'Discover your neighborhood' : 'Grow your local business',
            style: AppTypography.display,
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            widget.role == 'user'
                ? 'Connect with local merchants, explore nearby fresh arrivals, and get custom discount updates in your locality.'
                : 'Publish updates, manage your product catalog, chat directly with interested buyers, and grow followers in your block.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const Spacer(),
          PrimaryButton(
            text: 'Continue with Google',
            isLoading: _isLoading,
            onPressed: _handleGoogleSignIn,
          ),
          if (widget.role == 'user') ...[
            const SizedBox(height: AppSpacing.s16),
            Center(
              child: TextButton(
                onPressed: _handleGuestSignIn,
                child: Text(
                  'Continue as Guest',
                  style: AppTypography.body.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.s8),
        ],
      ),
    );
  }

  // --- USER PROFILE STEP ---
  Widget _buildProfileStep() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.mobilePadding),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.s24),
            Text('Create Profile', style: AppTypography.heading),
            const SizedBox(height: AppSpacing.s8),
            Text('Verify and complete your profile details', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.s32),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.border,
                    backgroundImage: _googleProfileImage != null
                        ? NetworkImage(_googleProfileImage!)
                        : null,
                    child: _googleProfileImage == null
                        ? const Icon(LucideIcons.user, size: 40, color: AppColors.textSecondary)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.camera, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s32),
            AppTextField(
              controller: _userNameController,
              hintText: 'Full Name',
            ),
            const SizedBox(height: AppSpacing.s16),
            AppTextField(
              controller: _userEmailController,
              hintText: 'Email Address',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppSpacing.s16),
            AppTextField(
              controller: _userPhoneController,
              hintText: 'Phone Number (Optional)',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 80),
            PrimaryButton(
              text: 'Continue',
              isLoading: _isLoading,
              onPressed: () {
                if (_userNameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your name')),
                  );
                } else if (_userEmailController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your email')),
                  );
                } else {
                  _nextPage();
                }
              },
            ),
            const SizedBox(height: AppSpacing.s16),
          ],
        ),
      ),
    );
  }

  // --- INTERESTS STEP ---
  Widget _buildInterestsStep() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.mobilePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.s24),
          Text('Select Interests', style: AppTypography.heading),
          const SizedBox(height: AppSpacing.s8),
          Text('Help us curate a custom local feed for you', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.s32),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: _availableInterests.map((interest) {
              final isSelected = _selectedInterests.contains(interest);
              return ScaleButtonPressed(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedInterests.remove(interest);
                    } else {
                      _selectedInterests.add(interest);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Text(
                    interest,
                    style: AppTypography.caption.copyWith(
                      color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const Spacer(),
          PrimaryButton(
            text: 'Continue',
            isLoading: _isLoading,
            onPressed: () {
              if (_selectedInterests.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select at least 1 interest')),
                );
              } else {
                _nextPage();
              }
            },
          ),
          const SizedBox(height: AppSpacing.s16),
        ],
      ),
    );
  }

  // --- PERMISSION STEP ---
  Widget _buildPermissionStep({bool isShop = false}) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.mobilePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Center(
            child: Container(
              height: 140,
              width: 140,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: const Icon(LucideIcons.mapPin, size: 56, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 32),
          Text('Enable Location & Alerts', style: AppTypography.heading),
          const SizedBox(height: AppSpacing.s12),
          Text(
            'Nearo is built for local discovery. We need location permission to show you stores and products near your block, and notification permission to alert you on active discounts.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const Spacer(),
          PrimaryButton(
            text: 'Allow Access & Finish',
            isLoading: _isLoading,
            onPressed: _completeAuth,
          ),
          const SizedBox(height: AppSpacing.s12),
          Center(
            child: TextButton(
              onPressed: _completeAuth,
              child: Text(
                'Skip for now',
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
        ],
      ),
    );
  }

  // --- BUSINESS SETUP STEP ---
  Widget _buildBusinessSetupStep() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.mobilePadding),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.s24),
            Text('Business Setup', style: AppTypography.heading),
            const SizedBox(height: AppSpacing.s8),
            Text('Let customers discover your shop brand', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.s32),
            AppTextField(
              controller: _shopNameController,
              hintText: 'Shop Name',
            ),
            const SizedBox(height: AppSpacing.s16),
            AppTextField(
              controller: _shopOwnerNameController,
              hintText: 'Owner Name',
            ),
            const SizedBox(height: AppSpacing.s16),
            SizedBox(
              height: 100,
              child: TextFormField(
                controller: _shopDescController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Tell customers about your shop...',
                ),
              ),
            ),
            const SizedBox(height: 80),
            PrimaryButton(
              text: 'Continue',
              isLoading: _isLoading,
              onPressed: () {
                if (_shopNameController.text.isEmpty || _shopOwnerNameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill out business details')),
                  );
                } else {
                  _nextPage();
                }
              },
            ),
            const SizedBox(height: AppSpacing.s16),
          ],
        ),
      ),
    );
  }

  // --- SHOP DETAILS STEP ---
  Widget _buildShopDetailsStep() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.mobilePadding),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.s24),
            Text('Address & Category', style: AppTypography.heading),
            const SizedBox(height: AppSpacing.s8),
            Text('Set where you are located and shop type', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.s32),
            AppTextField(
              controller: _shopAddressController,
              hintText: 'Shop Address (e.g. Sector 62, Noida)',
            ),
            const SizedBox(height: AppSpacing.s24),
            Text('Select Business Category', style: AppTypography.subheading),
            const SizedBox(height: AppSpacing.s12),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: _availableCategories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ScaleButtonPressed(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Theme.of(context).dividerColor,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: AppTypography.caption.copyWith(
                        color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 120),
            PrimaryButton(
              text: 'Continue',
              isLoading: _isLoading,
              onPressed: () {
                if (_shopAddressController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter shop address')),
                  );
                } else {
                  _nextPage();
                }
              },
            ),
            const SizedBox(height: AppSpacing.s16),
          ],
        ),
      ),
    );
  }

  // --- MEDIA UPLOAD STEP ---
  Widget _buildMediaUploadStep() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.mobilePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.s24),
          Text('Upload Logo & Banner', style: AppTypography.heading),
          const SizedBox(height: AppSpacing.s8),
          Text('Visual assets build trust with customers', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.s32),
          
          Row(
            children: [
              ScaleButtonPressed(
                onTap: _pickLogo,
                child: Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    image: _logoUrl != null ? DecorationImage(image: NetworkImage(_logoUrl!), fit: BoxFit.cover) : null,
                  ),
                  child: _logoUrl == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.image, size: 24, color: AppColors.textSecondary),
                            Text('Logo', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(width: AppSpacing.s16),
              Expanded(
                child: Text(
                  _logoUrl != null ? 'Logo uploaded' : 'Tap to upload shop logo',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s24),

          ScaleButtonPressed(
            onTap: _pickBanner,
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                image: _bannerUrl != null ? DecorationImage(image: NetworkImage(_bannerUrl!), fit: BoxFit.cover) : null,
              ),
              alignment: Alignment.center,
              child: _bannerUrl == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.image, size: 32, color: AppColors.textSecondary),
                        SizedBox(height: AppSpacing.s4),
                        Text('Tap to upload store banner image', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    )
                  : null,
            ),
          ),
          
          const Spacer(),
          PrimaryButton(
            text: 'Continue',
            isLoading: _isLoading,
            onPressed: _nextPage,
          ),
          const SizedBox(height: AppSpacing.s16),
        ],
      ),
    );
  }
}
