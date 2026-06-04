import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/widgets/common/scale_button.dart';
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

  void _completeAuth() {
    if (widget.role == 'user') {
      final newUser = UserModel(
        id: 'user_new',
        name: _userNameController.text.isNotEmpty ? _userNameController.text : 'New User',
        email: _userEmailController.text.isNotEmpty ? _userEmailController.text : 'user@nearo.com',
        phone: _userPhoneController.text.isNotEmpty ? _userPhoneController.text : '+91 99999 88888',
        profileImage: _googleProfileImage ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
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
        phone: '+91 99887 76655',
        whatsapp: '9988776655',
        description: _shopDescController.text.isNotEmpty ? _shopDescController.text : 'A premium local establishment on Nearo.',
      );
      ref.read(databaseProvider.notifier).updateCurrentShop(newShop);
      ref.read(appRoleProvider.notifier).state = 'owner';
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showGoogleSignInDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.globe, size: 20, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sign in with Google', style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold)),
                      Text('to continue to Nearo', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Text('Choose an account', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              _buildGoogleAccountTile(
                name: 'Dikesh Sharma',
                email: 'dikesh.sharma@gmail.com',
                imageUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
                onTap: () => _handleSelectedGoogleAccount('Dikesh Sharma', 'dikesh.sharma@gmail.com', 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150'),
              ),
              _buildGoogleAccountTile(
                name: 'Sarah Chen',
                email: 'sarah.chen@gmail.com',
                imageUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
                onTap: () => _handleSelectedGoogleAccount('Sarah Chen', 'sarah.chen@gmail.com', 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150'),
              ),
              _buildGoogleAccountTile(
                name: 'Aman Verma',
                email: 'aman.verma@gmail.com',
                imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
                onTap: () => _handleSelectedGoogleAccount('Aman Verma', 'aman.verma@gmail.com', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150'),
              ),
              
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.userPlus, size: 18),
                ),
                title: Text('Use another account', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                onTap: () => _handleSelectedGoogleAccount('Guest User', 'guest@gmail.com', ''),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGoogleAccountTile({
    required String name,
    required String email,
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: NetworkImage(imageUrl),
      ),
      title: Text(name, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(email, style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11)),
      onTap: onTap,
    );
  }

  void _handleSelectedGoogleAccount(String name, String email, String imageUrl) {
    Navigator.pop(context); // Close bottom sheet
    setState(() {
      _isLoading = true;
    });
    
    // Simulate sign in loading
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _userNameController.text = name;
          _userEmailController.text = email;
          _googleProfileImage = imageUrl.isNotEmpty ? imageUrl : null;
          
          if (widget.role == 'owner') {
            _shopOwnerNameController.text = name;
            _shopNameController.text = '$name\'s Shop';
          }
        });
        
        // Go to next step
        _pageController.nextPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });
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
              onTap: _showGoogleSignInDialog,
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
            onPressed: _showGoogleSignInDialog,
          ),
          if (widget.role == 'user') ...[
            const SizedBox(height: AppSpacing.s16),
            Center(
              child: TextButton(
                onPressed: () {
                  final guestUser = UserModel(
                    id: 'guest_user',
                    name: 'Guest Explorer',
                    email: 'guest@nearo.com',
                    phone: '+91 99999 88888',
                    profileImage: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
                    location: 'Sector 62, Noida',
                    interests: [],
                    followingShops: [],
                    savedProducts: [],
                    createdAt: DateTime.now(),
                  );
                  ref.read(databaseProvider.notifier).updateCurrentUser(guestUser);
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

          ScaleButtonPressed(
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
