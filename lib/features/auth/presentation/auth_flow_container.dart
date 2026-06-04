import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/secondary_button.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../providers/app_state_providers.dart';
import '../../../models/user_model.dart';
import '../../../models/shop_model.dart';

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

  // Controllers for User flow
  final TextEditingController _userPhoneController = TextEditingController(text: '9876543210');
  final TextEditingController _userOtpController = TextEditingController(text: '123456');
  final TextEditingController _userNameController = TextEditingController();
  final List<String> _selectedInterests = [];

  // Controllers for Shop Owner flow
  final TextEditingController _ownerPhoneController = TextEditingController(text: '9988776655');
  final TextEditingController _ownerOtpController = TextEditingController(text: '654321');
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
    _userPhoneController.dispose();
    _userOtpController.dispose();
    _userNameController.dispose();
    _ownerPhoneController.dispose();
    _ownerOtpController.dispose();
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

  void _completeAuth() {
    if (widget.role == 'user') {
      final newUser = UserModel(
        id: 'user_new',
        name: _userNameController.text.isNotEmpty ? _userNameController.text : 'New User',
        phone: _userPhoneController.text,
        profileImage: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        location: 'Sector 62, Noida',
        interests: _selectedInterests,
        followingShops: [],
        savedProducts: [],
        createdAt: DateTime.now(),
      );
      ref.read(databaseProvider.notifier).updateCurrentUser(newUser);
      ref.read(appRoleProvider.notifier).state = 'user';
    } else {
      final newShop = ShopModel(
        id: 'shop_new',
        shopName: _shopNameController.text.isNotEmpty ? _shopNameController.text : 'My Business',
        ownerName: _shopOwnerNameController.text.isNotEmpty ? _shopOwnerNameController.text : 'Owner',
        logo: _logoUrl ?? 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=100',
        banner: _bannerUrl ?? 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=600',
        address: _shopAddressController.text.isNotEmpty ? _shopAddressController.text : 'Sector 62, Noida',
        latitude: 28.6273,
        longitude: 77.3725,
        rating: 5.0,
        followers: 0,
        category: _selectedCategory,
        isVerified: true,
        phone: _ownerPhoneController.text,
        whatsapp: _ownerPhoneController.text,
        description: _shopDescController.text.isNotEmpty ? _shopDescController.text : 'A premium local establishment on Nearo.',
      );
      ref.read(databaseProvider.notifier).updateCurrentShop(newShop);
      ref.read(appRoleProvider.notifier).state = 'owner';
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final int totalSteps = widget.role == 'user' ? 6 : 6;

    return Scaffold(
      appBar: AppBar(
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: _prevPage,
              )
            : null,
        title: Text(widget.role == 'user' ? 'User Account' : 'Shop Setup'),
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
            // Linear Progress Indicator matching Apple style
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
      // Page 1: Welcome Screen
      _buildWelcomeStep(),
      // Page 2: Phone Login
      _buildPhoneStep(_userPhoneController),
      // Page 3: OTP Verification
      _buildOtpStep(_userOtpController),
      // Page 4: Create Profile
      _buildProfileStep(),
      // Page 5: Select Interests
      _buildInterestsStep(),
      // Page 6: Permission Screen
      _buildPermissionStep(),
    ];
  }

  // --- SHOP FLOW PAGES ---
  List<Widget> _buildShopPages() {
    return [
      // Page 1: Phone Login
      _buildPhoneStep(_ownerPhoneController, title: 'Shop Owner Login', sub: 'Access your merchant dashboard'),
      // Page 2: OTP Verification
      _buildOtpStep(_ownerOtpController),
      // Page 3: Business Setup
      _buildBusinessSetupStep(),
      // Page 4: Shop Details
      _buildShopDetailsStep(),
      // Page 5: Media Upload
      _buildMediaUploadStep(),
      // Page 6: Permission Screen
      _buildPermissionStep(isShop: true),
    ];
  }

  // --- STEP BUILDERS ---

  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.mobilePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Center(
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
          const SizedBox(height: 32),
          Text('Discover your neighborhood', style: AppTypography.display),
          const SizedBox(height: AppSpacing.s12),
          Text(
            'Connect with local merchants, explore nearby fresh arrivals, and get custom discount updates in your locality.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const Spacer(),
          PrimaryButton(
            text: 'Continue with Phone',
            isLoading: _isLoading,
            onPressed: _nextPage,
          ),
          const SizedBox(height: AppSpacing.s12),
          SecondaryButton(
            text: 'Continue with Google',
            onPressed: _nextPage,
            icon: Icon(LucideIcons.globe, size: 20, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.s12),
          Center(
            child: TextButton(
              onPressed: () {
                ref.read(appRoleProvider.notifier).state = 'user';
              },
              child: Text(
                'Continue as Guest',
                style: AppTypography.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
        ],
      ),
    );
  }

  Widget _buildPhoneStep(TextEditingController controller, {String title = 'Enter Phone Number', String sub = 'Verify your phone to start searching'}) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.mobilePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.s24),
          Text(title, style: AppTypography.heading),
          const SizedBox(height: AppSpacing.s8),
          Text(sub, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.s32),
          Row(
            children: [
              // Mock Country Picker
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                  border: Border.all(color: AppColors.border),
                ),
                alignment: Alignment.center,
                child: Row(
                  children: [
                    Text('🇮🇳 +91', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: AppSpacing.s4),
                    const Icon(LucideIcons.chevronDown, size: 16),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: AppTextField(
                  controller: controller,
                  hintText: 'Phone number',
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
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

  Widget _buildOtpStep(TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.mobilePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.s24),
          Text('Verify OTP', style: AppTypography.heading),
          const SizedBox(height: AppSpacing.s8),
          Text('We sent a 6-digit code to your mobile number', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.s32),
          AppTextField(
            controller: controller,
            hintText: '6-digit OTP code',
            keyboardType: TextInputType.number,
            obscureText: false,
          ),
          const SizedBox(height: AppSpacing.s16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Didn't receive code?", style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
              TextButton(
                onPressed: () {},
                child: Text('Resend OTP', style: AppTypography.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const Spacer(),
          PrimaryButton(
            text: 'Verify & Continue',
            isLoading: _isLoading,
            onPressed: _nextPage,
          ),
          const SizedBox(height: AppSpacing.s16),
        ],
      ),
    );
  }

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
            Text('Tell us a bit about yourself', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.s32),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.border,
                    backgroundImage: _userNameController.text.isNotEmpty
                        ? const NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150')
                        : null,
                    child: _userNameController.text.isEmpty
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
                      child: const Icon(LucideIcons.camera, size: 16, color: AppColors.surface),
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
            const SizedBox(height: 120),
            PrimaryButton(
              text: 'Continue',
              isLoading: _isLoading,
              onPressed: () {
                if (_userNameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your name')),
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
              return GestureDetector(
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
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    interest,
                    style: AppTypography.caption.copyWith(
                      color: isSelected ? AppColors.surface : AppColors.textPrimary,
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

  // --- SHOP FLOW SPECIFIC STEPS ---

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
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: AppTypography.caption.copyWith(
                        color: isSelected ? AppColors.surface : AppColors.textPrimary,
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
          
          // Logo Upload Simulation
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() => _logoUrl = 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=100');
                },
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
                  _logoUrl != null ? 'Logo uploaded' : 'Tap to simulate uploading shop logo',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s24),

          // Banner Upload Simulation
          GestureDetector(
            onTap: () {
              setState(() => _bannerUrl = 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=600');
            },
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
                        Text('Tap to simulate uploading store banner image', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
