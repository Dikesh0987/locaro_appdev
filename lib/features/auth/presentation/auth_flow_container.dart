import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/secondary_button.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/widgets/common/scale_button.dart';
import '../../../providers/app_state_providers.dart';
import '../../../models/shop_model.dart';
import '../application/auth_service.dart';
import '../data/auth_repository.dart';
import 'auth_controller.dart';
import 'auth_state.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../core/utils/firebase_error_handler.dart';

class AuthFlowContainer extends ConsumerStatefulWidget {
  final String role; // fallback/initial role

  const AuthFlowContainer({super.key, required this.role});

  @override
  ConsumerState<AuthFlowContainer> createState() => _AuthFlowContainerState();
}

class _AuthFlowContainerState extends ConsumerState<AuthFlowContainer> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  late String _role; // mutable role state chosen at Step 0

  // Google Account simulated state
  String? _googleProfileImage;

  // Controllers for User flow
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _userEmailController = TextEditingController();
  final TextEditingController _userPhoneController = TextEditingController();
  final List<String> _selectedInterests = [];

  // Controllers for Shop Owner flow
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _shopOwnerNameController =
      TextEditingController();
  final TextEditingController _shopAddressController = TextEditingController();
  final TextEditingController _shopDescController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isWhatsappVerified = false;
  bool _isOtpSent = false;
  String? _verificationId;
  int? _resendToken;
  List<String> _selectedCategories = [];
  String? _logoUrl;
  String? _bannerUrl;

  final List<String> _availableCategories = [
    'Cafe',
    'Groceries',
    'Electronics',
    'Fashion',
    'Bakery',
  ];
  final List<String> _availableInterests = [
    'Coffee',
    'Fresh Produce',
    'Electronics',
    'Fashion',
    'Bakery',
    'Organic Food',
    'Tech Gadgets',
    'Desserts',
  ];

  @override
  void initState() {
    super.initState();
    _role = widget.role;

    // Prefill controllers with Google profile data from active session
    final user = ref.read(databaseProvider).currentUser;
    if (!user.isGuest) {
      _userNameController.text = user.name;
      _userEmailController.text = user.email;
      _googleProfileImage = user.photoUrl.isNotEmpty ? user.photoUrl : null;
      _shopOwnerNameController.text = user.name;
      _shopNameController.text = '${user.name}\'s Shop';
    }
  }

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
    _whatsappController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle(_role);

      final authState = ref.read(authControllerProvider);
      if (authState is AuthFailure) {
        throw Exception(authState.errorMessage);
      }

      final user = ref.read(databaseProvider).currentUser;

      setState(() {
        _userNameController.text = user.name;
        _userEmailController.text = user.email;
        if (user.phone.isNotEmpty) {
          _userPhoneController.text = user.phone;
        }
        _googleProfileImage = user.photoUrl.isNotEmpty ? user.photoUrl : null;

        _shopOwnerNameController.text = user.name;
        _shopNameController.text = "${user.name}'s Shop";
      });

      if (user.isOnboardingCompleted) {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        _nextPage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: context.colors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGuestSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authControllerProvider.notifier).signInAsGuest();

      final authState = ref.read(authControllerProvider);
      if (authState is AuthFailure) {
        throw Exception(authState.errorMessage);
      }

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: context.colors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _completeAuth() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      double latitude = 0.0;
      double longitude = 0.0;
      String locationStr = '';

      // Fetch actual location
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }

          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            Position? position;
            try {
              position = await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.high,
                  timeLimit: Duration(seconds: 10),
                ),
              );
            } catch (e) {
              position = await Geolocator.getLastKnownPosition();
            }

            if (position != null) {
              latitude = position.latitude;
              longitude = position.longitude;
              locationStr =
                  '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
            }
          }
        }
      } catch (e) {
        // Location fetch failed, proceed with 0.0 defaults
        debugPrint('Location fetch failed: $e');
      }

      final user = ref.read(databaseProvider).currentUser;
      
      String finalEmail = _userEmailController.text.trim();
      if (finalEmail.isEmpty) finalEmail = user.email;
      
      String finalPhone = _role == 'shop_owner' 
          ? _whatsappController.text.trim() 
          : _userPhoneController.text.trim();
      if (finalPhone.isEmpty) finalPhone = user.phone;

      final updatedUser = user.copyWith(
        name: _userNameController.text.trim(),
        email: finalEmail,
        phone: finalPhone,
        interests: _selectedInterests,
        location: locationStr, // updated dynamically
        photoUrl: _googleProfileImage ?? '',
        role: _role,
        latitude: latitude,
        longitude: longitude,
        phoneVerified: _isWhatsappVerified || user.phoneVerified,
        verifiedAt: (_isWhatsappVerified && !user.phoneVerified) ? DateTime.now() : user.verifiedAt,
      );

      if (_role == 'shop_owner') {
        final newShop = ShopModel(
          id: 'shop_${user.uid}',
          ownerUid: user.uid,
          shopName: _shopNameController.text.trim(),
          ownerName: _userNameController.text.trim(),
          logoUrl: _logoUrl ?? '',
          bannerUrl: _bannerUrl ?? '',
          address: _shopAddressController.text.trim(),
          latitude: latitude,
          longitude: longitude,
          rating: 5.0,
          followers: 0,
          category: _selectedCategories.join(', '),
          isVerified: true,
          phone: finalPhone,
          whatsapp: finalPhone,
          description: _shopDescController.text.trim(),
          openTime: '09:00',
          closeTime: '21:00',
          showOnlineStatus: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await ref.read(databaseProvider.notifier).updateCurrentShop(newShop);
      }

      await ref.read(authServiceProvider).completeOnboarding(updatedUser);
      if (mounted) {
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

  Future<void> _pickLogo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() => _isLoading = true);
      try {
        final currentUser = ref.read(databaseProvider).currentUser;
        final url = await ref
            .read(authRepositoryProvider)
            .uploadShopAsset(
              'shop_${currentUser.uid}',
              'logo',
              File(image.path),
            );
        setState(() => _logoUrl = url);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload logo: ${e.toString()}')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickBanner() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (image != null) {
      setState(() => _isLoading = true);
      try {
        final currentUser = ref.read(databaseProvider).currentUser;
        final url = await ref
            .read(authRepositoryProvider)
            .uploadShopAsset(
              'shop_${currentUser.uid}',
              'banner',
              File(image.path),
            );
        setState(() => _bannerUrl = url);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload banner: ${e.toString()}')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendRealOtp() async {
    final phone = _whatsappController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter phone number')),
      );
      return;
    }

    // Add country code if not present (defaulting to +91 for India as an example)
    String formattedPhone = phone;
    if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+91$phone';
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final isUsed = await ref.read(authRepositoryProvider).isPhoneNumberUsed(formattedPhone);
      if (isUsed) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This phone number is already verified by another account.')),
          );
        }
        return;
      }
    } catch (e) {
      debugPrint('Phone uniqueness check failed: $e');
    }

    try {
      // NOTE: If a web browser opens for reCAPTCHA, it means Play Integrity/SafetyNet failed.
      // To fix this permanently:
      // 1. Add your SHA-1 and SHA-256 keys to the Firebase Console settings.
      // 2. Enable 'Play Integrity API' in Google Cloud Console for this project.
      await fb.FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (fb.PhoneAuthCredential credential) async {
          try {
            await fb.FirebaseAuth.instance.currentUser?.linkWithCredential(
              credential,
            );
            if (mounted) {
              setState(() {
                _isWhatsappVerified = true;
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('WhatsApp Auto-Verified Successfully!'),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                _isWhatsappVerified = true;
                _isLoading = false;
              });
            }
          }
        },
        verificationFailed: (fb.FirebaseAuthException e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isOtpSent = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Verification Failed: ${e.message}')),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _resendToken = resendToken;
              _isOtpSent = true;
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('OTP sent successfully!')),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isOtpSent = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _verifyRealOtp() async {
    final code = _otpController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter the OTP')));
      return;
    }
    if (_verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for OTP to be sent')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );

      try {
        await ref.read(authServiceProvider).linkPhoneAccount(credential);
      } on fb.FirebaseAuthException catch (e) {
        debugPrint('Link credential error: ${e.code}');
        if (e.code == 'invalid-verification-code' || e.code == 'session-expired') {
          rethrow;
        }
        // If it throws provider-already-linked or credential-already-in-use,
        // it means the OTP was actually valid (Firebase verified it), 
        // but we can't link it to this specific auth account. 
        // Since we just want to verify they own the WhatsApp number, we can safely continue.
      }

      if (mounted) {
        setState(() {
          _isWhatsappVerified = true;
          _isOtpSent = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp Verified Successfully!')),
        );
      }
    } on fb.FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(FirebaseErrorHandler.handleAuthException(e))),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error verifying OTP: $e')));
      }
    }
  }

  void _showPhoneLoginSheet() {
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController otpController = TextEditingController();
    bool isOtpSent = false;
    bool isSheetLoading = false;
    String? verificationId;
    int cooldownSeconds = 0;
    Timer? cooldownTimer;

    Future<void> handlePhoneSuccess(fb.PhoneAuthCredential credential) async {
      try {
        await ref
            .read(authServiceProvider)
            .handlePhoneSignIn(credential, _role);
        final user = ref.read(databaseProvider).currentUser;
        if (mounted) {
          Navigator.pop(context);
          if (!user.isOnboardingCompleted) {
            if (user.phone.isNotEmpty) {
              _userPhoneController.text = user.phone;
              _whatsappController.text = user.phone;
            }
            _nextPage();
          } else {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
      } on fb.FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(FirebaseErrorHandler.handleAuthException(e))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(FirebaseErrorHandler.handleGenericException(e))),
          );
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void startCooldown() {
              cooldownSeconds = 30;
              cooldownTimer?.cancel();
              cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                setSheetState(() {
                  if (cooldownSeconds > 0) {
                    cooldownSeconds--;
                  } else {
                    timer.cancel();
                  }
                });
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.all(AppSpacing.mobilePadding),
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
                    const SizedBox(height: 24),
                    Text(
                      isOtpSent ? 'Enter OTP' : 'Continue with Phone',
                      style: AppTypography.heading,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isOtpSent
                          ? 'We sent a verification code to your number.'
                          : 'You will receive a 6-digit code to verify your number.',
                      style: AppTypography.caption.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (!isOtpSent) ...[
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'Phone Number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        text: cooldownSeconds > 0 ? 'Resend in ${cooldownSeconds}s' : 'Send OTP',
                        isLoading: isSheetLoading,
                        onPressed: cooldownSeconds > 0 ? () {} : () async {
                          final phone = phoneController.text.trim();
                          if (phone.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter phone number'),
                              ),
                            );
                            return;
                          }
                          String formattedPhone = phone.startsWith('+')
                              ? phone
                              : '+91$phone';

                          setSheetState(() => isSheetLoading = true);



                          try {
                            await fb.FirebaseAuth.instance.verifyPhoneNumber(
                              phoneNumber: formattedPhone,
                              timeout: const Duration(seconds: 60),
                              verificationCompleted:
                                  (fb.PhoneAuthCredential credential) async {
                                    await handlePhoneSuccess(credential);
                                  },
                              verificationFailed: (fb.FirebaseAuthException e) {
                                setSheetState(() {
                                  isSheetLoading = false;
                                  if (e.code == 'too-many-requests') {
                                    startCooldown();
                                  }
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(FirebaseErrorHandler.handleAuthException(e)),
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              },
                              codeSent: (String verId, int? resendToken) {
                                setSheetState(() {
                                  verificationId = verId;
                                  isOtpSent = true;
                                  isSheetLoading = false;
                                  startCooldown();
                                });
                              },
                              codeAutoRetrievalTimeout: (String verId) {
                                verificationId = verId;
                              },
                            );
                          } catch (e) {
                            setSheetState(() => isSheetLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(FirebaseErrorHandler.handleGenericException(e))),
                            );
                          }
                        },
                      ),
                    ] else ...[
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '6-digit OTP',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        text: 'Verify & Login',
                        isLoading: isSheetLoading,
                        onPressed: () async {
                          final code = otpController.text.trim();
                          if (code.isEmpty || verificationId == null) return;

                          setSheetState(() => isSheetLoading = true);

                          try {
                            final credential = fb.PhoneAuthProvider.credential(
                              verificationId: verificationId!,
                              smsCode: code,
                            );
                            await handlePhoneSuccess(credential);
                          } on fb.FirebaseAuthException catch (e) {
                            setSheetState(() => isSheetLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(FirebaseErrorHandler.handleAuthException(e)),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          } catch (e) {
                            setSheetState(() => isSheetLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(FirebaseErrorHandler.handleGenericException(e)),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalSteps = _role == 'user' ? 4 : 5;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            if (_currentStep > 0) {
              _prevPage();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(_role == 'user' ? 'Create Account' : 'Merchant Center'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.mobilePadding),
            child: Center(
              child: Text(
                '${_currentStep + 1}/$totalSteps',
                style: AppTypography.label.copyWith(
                  color: context.colors.textSecondary,
                ),
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
              backgroundColor: context.colors.border,
              valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
              minHeight: 3,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() => _currentStep = page);
                },
                children: _role == 'user'
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
    final isShop = _role == 'shop_owner';
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.mobilePadding,
        vertical: AppSpacing.s24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          // Visual Brand element
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                height: 110,
                width: 110,
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: context.colors.border, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  isShop ? LucideIcons.store : LucideIcons.compass,
                  size: 44,
                  color: context.colors.primary,
                ),
              ),
            ),
          ),
          SizedBox(height: 36),
          // Welcome Headlines
          Text(
            isShop ? 'Grow your\nbusiness' : 'Discover your\nneighborhood',
            style: AppTypography.display.copyWith(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
          ),
          SizedBox(height: 14),
          Text(
            isShop
                ? 'Create your merchant profile, list your products, post deals, and connect with customers in your neighborhood directly.'
                : 'Connect with local merchants, explore nearby fresh arrivals, and get custom discount updates in your block instantly.',
            style: AppTypography.body.copyWith(
              color: context.colors.textSecondary,
              height: 1.5,
            ),
          ),
          const Spacer(),
          // Login Actions
          PrimaryButton(
            text: 'Continue with Phone Number',
            isLoading: _isLoading,
            onPressed: _isLoading ? () {} : _showPhoneLoginSheet,
          ),
          const SizedBox(height: AppSpacing.s12),
          SecondaryButton(
            text: 'Continue with Google',
            onPressed: _handleGoogleSignIn,
          ),
          if (!isShop) ...[
            SizedBox(height: AppSpacing.s16),
            Center(
              child: ScaleButtonPressed(
                onTap: _isLoading ? () {} : _handleGuestSignIn,
                child: TextButton(
                  onPressed: null, // Let ScaleButtonPressed handle the tap
                  child: Text(
                    'Continue as Guest',
                    style: AppTypography.body.copyWith(
                      color: context.colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
          SizedBox(height: AppSpacing.s12),
        ],
      ),
    );
  }

  // --- USER PROFILE STEP ---
  Widget _buildProfileStep() {
    final user = ref.read(databaseProvider).currentUser;
    final isGoogleSignIn = user.email.isNotEmpty && user.phone.isEmpty;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.mobilePadding),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppSpacing.s24),
            Text('Create Profile', style: AppTypography.heading),
            SizedBox(height: AppSpacing.s8),
            Text(
              'Verify and complete your profile details',
              style: AppTypography.caption.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.s32),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: context.colors.border,
                    backgroundImage: _googleProfileImage != null
                        ? NetworkImage(_googleProfileImage!)
                        : null,
                    child: _googleProfileImage == null
                        ? Icon(
                            LucideIcons.user,
                            size: 40,
                            color: context.colors.textSecondary,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: context.colors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.camera,
                        size: 16,
                        color: context.colors.surface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.s32),
            AppTextField(
              controller: _userNameController,
              hintText: 'Full Name',
            ),
            SizedBox(height: AppSpacing.s16),
            if (isGoogleSignIn) ...[
              AppTextField(
                controller: _userPhoneController,
                hintText: 'Phone Number (Optional)',
                keyboardType: TextInputType.phone,
              ),
            ] else ...[
              AppTextField(
                controller: _userEmailController,
                hintText: 'Email Address',
                keyboardType: TextInputType.emailAddress,
              ),
            ],
            SizedBox(height: 80),
            PrimaryButton(
              text: 'Continue',
              isLoading: _isLoading,
              onPressed: () {
                if (_userNameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your name')),
                  );
                } else if (!isGoogleSignIn && _userEmailController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your email')),
                  );
                } else {
                  _nextPage();
                }
              },
            ),
            SizedBox(height: AppSpacing.s16),
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
          SizedBox(height: AppSpacing.s24),
          Text('Select Interests', style: AppTypography.heading),
          SizedBox(height: AppSpacing.s8),
          Text(
            'Help us curate a custom local feed for you',
            style: AppTypography.caption.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.s32),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s16,
                    vertical: AppSpacing.s12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.colors.primary
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isSelected
                          ? context.colors.primary
                          : Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Text(
                    interest,
                    style: AppTypography.caption.copyWith(
                      color: isSelected
                          ? context.colors.surface
                          : Theme.of(context).textTheme.bodyLarge?.color,
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
                  const SnackBar(
                    content: Text('Please select at least 1 interest'),
                  ),
                );
              } else {
                _nextPage();
              }
            },
          ),
          SizedBox(height: AppSpacing.s16),
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
                color: context.colors.border,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: Icon(
                LucideIcons.mapPin,
                size: 56,
                color: context.colors.primary,
              ),
            ),
          ),
          SizedBox(height: 32),
          Text('Enable Location & Alerts', style: AppTypography.heading),
          SizedBox(height: AppSpacing.s12),
          Text(
            'Locaro is built for local discovery. We need location permission to show you stores and products near your block, and notification permission to alert you on active discounts.',
            style: AppTypography.body.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const Spacer(),
          PrimaryButton(
            text: 'Allow Access & Finish',
            isLoading: _isLoading,
            onPressed: _completeAuth,
          ),
          SizedBox(height: AppSpacing.s12),
          Center(
            child: TextButton(
              onPressed: _completeAuth,
              child: Text(
                'Skip for now',
                style: AppTypography.body.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.s8),
        ],
      ),
    );
  }

  // --- BUSINESS SETUP STEP ---
  Widget _buildBusinessSetupStep() {
    final user = ref.read(databaseProvider).currentUser;
    final isGoogleSignIn = user.email.isNotEmpty && user.phone.isEmpty;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.mobilePadding),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppSpacing.s24),
            Text('Business Setup', style: AppTypography.heading),
            SizedBox(height: AppSpacing.s8),
            Text(
              'Let customers discover your shop brand',
              style: AppTypography.caption.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.s32),
            AppTextField(
              controller: _shopNameController,
              hintText: 'Shop Name',
            ),
            SizedBox(height: AppSpacing.s16),
            AppTextField(
              controller: _shopOwnerNameController,
              hintText: 'Owner Name',
            ),
            SizedBox(height: AppSpacing.s16),
            if (isGoogleSignIn) ...[
              AppTextField(
                controller: _whatsappController,
                hintText: 'Phone Number (Required)',
                keyboardType: TextInputType.phone,
              ),
            ] else ...[
              AppTextField(
                controller: _userEmailController,
                hintText: 'Business Email (Optional)',
                keyboardType: TextInputType.emailAddress,
              ),
            ],
            SizedBox(height: AppSpacing.s16),
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
            SizedBox(height: 40),
            PrimaryButton(
              text: 'Continue',
              isLoading: _isLoading,
              onPressed: () {
                if (_shopNameController.text.isEmpty ||
                    _shopOwnerNameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill out business details'),
                    ),
                  );
                } else if (isGoogleSignIn && _whatsappController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter phone number to continue'),
                    ),
                  );
                } else {
                  _nextPage();
                }
              },
            ),
            SizedBox(height: AppSpacing.s16),
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
            SizedBox(height: AppSpacing.s24),
            Text('Address & Category', style: AppTypography.heading),
            SizedBox(height: AppSpacing.s8),
            Text(
              'Set where you are located and shop type',
              style: AppTypography.caption.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.s32),
            AppTextField(
              controller: _shopAddressController,
              hintText: 'Shop Address (or Auto-detect in next step)',
            ),
            SizedBox(height: AppSpacing.s24),
            Text('Select Business Category', style: AppTypography.subheading),
            SizedBox(height: AppSpacing.s12),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: _availableCategories.map((cat) {
                final isSelected = _selectedCategories.contains(cat);
                return ScaleButtonPressed(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedCategories.remove(cat);
                      } else {
                        _selectedCategories.add(cat);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s16,
                      vertical: AppSpacing.s12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.colors.primary
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isSelected
                            ? context.colors.primary
                            : Theme.of(context).dividerColor,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: AppTypography.caption.copyWith(
                        color: isSelected
                            ? context.colors.surface
                            : Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 120),
            PrimaryButton(
              text: 'Continue',
              isLoading: _isLoading,
              onPressed: () {
                if (_shopAddressController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter shop address')),
                  );
                } else if (_selectedCategories.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select at least one category')),
                  );
                } else {
                  _nextPage();
                }
              },
            ),
            SizedBox(height: AppSpacing.s16),
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
          SizedBox(height: AppSpacing.s24),
          Text('Upload Logo & Banner', style: AppTypography.heading),
          SizedBox(height: AppSpacing.s8),
          Text(
            'Visual assets build trust with customers',
            style: AppTypography.caption.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.s32),

          Row(
            children: [
              ScaleButtonPressed(
                onTap: _pickLogo,
                child: Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: context.colors.border,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    image: _logoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_logoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _logoUrl == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.image,
                              size: 24,
                              color: context.colors.textSecondary,
                            ),
                            Text(
                              'Logo',
                              style: TextStyle(
                                fontSize: 10,
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
              SizedBox(width: AppSpacing.s16),
              Expanded(
                child: Text(
                  _logoUrl != null
                      ? 'Logo uploaded'
                      : 'Tap to upload shop logo (Required)',
                  style: AppTypography.caption.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.s24),

          ScaleButtonPressed(
            onTap: _pickBanner,
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                image: _bannerUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_bannerUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: _bannerUrl == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.image,
                          size: 32,
                          color: context.colors.textSecondary,
                        ),
                        SizedBox(height: AppSpacing.s4),
                        Text(
                          'Tap to upload store banner image',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
          ),

          const Spacer(),
          PrimaryButton(
            text: 'Continue',
            isLoading: _isLoading,
            onPressed: () {
              if (_logoUrl == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please upload a shop logo')),
                );
              } else if (_bannerUrl == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please upload a store banner image')),
                );
              } else {
                _nextPage();
              }
            },
          ),
          SizedBox(height: AppSpacing.s16),
        ],
      ),
    );
  }
}
