import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../data/auth_repository.dart';
import '../../../models/user_model.dart';
import '../../../providers/app_state_providers.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/services/fcm_service.dart';

class AuthService {
  final AuthRepository _repository;
  final Ref _ref;

  AuthService(this._repository, this._ref);

  // Sign In with Google
  Future<UserModel> handleGoogleSignIn(String selectedRole) async {
    final credential = await _repository.signInWithGoogle();
    final fbUser = credential.user;
    if (fbUser == null) {
      throw Exception("Failed to retrieve Google user credentials.");
    }

    final doc = await _repository.getUserDoc(fbUser.uid);

    if (doc.exists) {
      // Existing User
      final data = doc.data()!;
      final existingUser = UserModel.fromMap(data);

      bool roleChangedToShopOwner = existingUser.role == 'user' && selectedRole == 'shop_owner';
      bool newIsOnboardingCompleted = roleChangedToShopOwner ? false : existingUser.isOnboardingCompleted;
      String newRole = roleChangedToShopOwner ? 'shop_owner' : existingUser.role;

      // Update analytics fields in Firestore
      final int currentLoginCount = data['loginCount'] ?? 0;
      await _repository.updateUserDoc(fbUser.uid, {
        'lastLoginAt': Timestamp.fromDate(DateTime.now()),
        'loginCount': currentLoginCount + 1,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        if (roleChangedToShopOwner) 'role': newRole,
        if (roleChangedToShopOwner) 'isOnboardingCompleted': newIsOnboardingCompleted,
      });

      final updatedUser = existingUser.copyWith(
        lastLoginAt: DateTime.now(),
        updatedAt: DateTime.now(),
        role: newRole,
        isOnboardingCompleted: newIsOnboardingCompleted,
      );

      // Sync with Riverpod state
      _ref.read(databaseProvider.notifier).setCurrentUser(updatedUser);
      _ref.read(appRoleProvider.notifier).state = newIsOnboardingCompleted ? updatedUser.role : null;

      // Update local theme state
      _setThemeFromStr(updatedUser.themeMode);

      // Sync FCM topics
      fcmService.updateTopicSubscriptions(
        pushEnabled: updatedUser.notificationEnabled,
        offersEnabled: updatedUser.notificationSettings['offers'] ?? true,
        nearbyDealsEnabled:
            updatedUser.notificationSettings['nearbyDeals'] ?? true,
        marketingEnabled:
            updatedUser.notificationSettings['marketing'] ?? false,
      );

      // Sync FCM Token
      await fcmService.syncToken();

      return updatedUser;
    } else {
      // New User - Auto create account
      final newUser = UserModel(
        uid: fbUser.uid,
        name: fbUser.displayName ?? 'New Explorer',
        email: fbUser.email ?? '',
        phone: fbUser.phoneNumber ?? '',
        photoUrl: fbUser.photoURL ?? '',
        role: selectedRole,
        isGuest: false,
        interests: [],
        location: '',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isOnboardingCompleted: false,
        isProfileCompleted: false,
        notificationEnabled: true,
        language: 'English',
        themeMode: 'system',
        followingShops: [],
        savedProducts: [],
        notificationSettings: {
          'offers': true,
          'nearbyDeals': true,
          'comments': true,
          'followers': true,
          'announcements': true,
          'marketing': false,
        },
        likedProducts: [],
        likedPosts: [],
      );

      // Write user profile to Firestore
      final mapData = newUser.toMap();
      mapData['loginCount'] = 1;
      mapData['platform'] = Platform.isAndroid ? 'Android' : 'iOS';
      mapData['accountType'] = selectedRole;

      await _repository.setUserDoc(fbUser.uid, mapData);

      // Sync with Riverpod state
      _ref.read(databaseProvider.notifier).setCurrentUser(newUser);

      // Role is not set in shell until onboarding is finished!
      _ref.read(appRoleProvider.notifier).state = null;

      // Sync FCM topics
      fcmService.updateTopicSubscriptions(
        pushEnabled: newUser.notificationEnabled,
        offersEnabled: newUser.notificationSettings['offers'] ?? true,
        nearbyDealsEnabled: newUser.notificationSettings['nearbyDeals'] ?? true,
        marketingEnabled: newUser.notificationSettings['marketing'] ?? false,
      );

      // Sync FCM Token
      await fcmService.syncToken();

      return newUser;
    }
  }

  // Sign In with Phone
  Future<UserModel> handlePhoneSignIn(
    fb.PhoneAuthCredential credential,
    String selectedRole,
  ) async {
    final userCredential = await _repository.signInWithPhoneCredential(
      credential,
    );
    final fbUser = userCredential.user;
    if (fbUser == null) {
      throw Exception("Failed to retrieve Phone user credentials.");
    }

    final doc = await _repository.getUserDoc(fbUser.uid);

    if (doc.exists) {
      // Existing User
      final data = doc.data()!;
      final existingUser = UserModel.fromMap(data);

      bool roleChangedToShopOwner = existingUser.role == 'user' && selectedRole == 'shop_owner';
      bool newIsOnboardingCompleted = roleChangedToShopOwner ? false : existingUser.isOnboardingCompleted;
      String newRole = roleChangedToShopOwner ? 'shop_owner' : existingUser.role;

      final int currentLoginCount = data['loginCount'] ?? 0;
      await _repository.updateUserDoc(fbUser.uid, {
        'lastLoginAt': Timestamp.fromDate(DateTime.now()),
        'loginCount': currentLoginCount + 1,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        if (roleChangedToShopOwner) 'role': newRole,
        if (roleChangedToShopOwner) 'isOnboardingCompleted': newIsOnboardingCompleted,
      });

      final updatedUser = existingUser.copyWith(
        lastLoginAt: DateTime.now(),
        updatedAt: DateTime.now(),
        role: newRole,
        isOnboardingCompleted: newIsOnboardingCompleted,
      );

      _ref.read(databaseProvider.notifier).setCurrentUser(updatedUser);
      _ref.read(appRoleProvider.notifier).state = newIsOnboardingCompleted ? updatedUser.role : null;

      _setThemeFromStr(updatedUser.themeMode);

      fcmService.updateTopicSubscriptions(
        pushEnabled: updatedUser.notificationEnabled,
        offersEnabled: updatedUser.notificationSettings['offers'] ?? true,
        nearbyDealsEnabled:
            updatedUser.notificationSettings['nearbyDeals'] ?? true,
        marketingEnabled:
            updatedUser.notificationSettings['marketing'] ?? false,
      );

      await fcmService.syncToken();

      return updatedUser;
    } else {
      // New User - Auto create account
      final newUser = UserModel(
        uid: fbUser.uid,
        name: 'New Explorer',
        email: '',
        phone: fbUser.phoneNumber ?? '',
        photoUrl: '',
        role: selectedRole,
        isGuest: false,
        interests: [],
        location: '',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isOnboardingCompleted: false,
        isProfileCompleted: false,
        notificationEnabled: true,
        language: 'English',
        themeMode: 'system',
        followingShops: [],
        savedProducts: [],
        notificationSettings: {
          'offers': true,
          'nearbyDeals': true,
          'comments': true,
          'followers': true,
          'announcements': true,
          'marketing': false,
        },
        likedProducts: [],
        likedPosts: [],
        phoneVerified: true,
        verifiedAt: DateTime.now(),
      );

      final mapData = newUser.toMap();
      mapData['loginCount'] = 1;
      mapData['platform'] = Platform.isAndroid ? 'Android' : 'iOS';
      mapData['accountType'] = 'phone';

      await _repository.setUserDoc(fbUser.uid, mapData);

      _ref.read(databaseProvider.notifier).setCurrentUser(newUser);
      _ref.read(appRoleProvider.notifier).state = null;

      fcmService.updateTopicSubscriptions(
        pushEnabled: newUser.notificationEnabled,
        offersEnabled: newUser.notificationSettings['offers'] ?? true,
        nearbyDealsEnabled: newUser.notificationSettings['nearbyDeals'] ?? true,
        marketingEnabled: newUser.notificationSettings['marketing'] ?? false,
      );

      await fcmService.syncToken();

      return newUser;
    }
  }

  // Link Google Account
  Future<void> linkGoogleAccount() async {
    final userCredential = await _repository.linkWithGoogle();
    final fbUser = userCredential.user;
    if (fbUser != null && fbUser.email != null) {
      final doc = await _repository.getUserDoc(fbUser.uid);
      if (doc.exists) {
        final existingUser = UserModel.fromMap(doc.data()!);
        final updatedUser = existingUser.copyWith(
          email: fbUser.email,
        );
        await _repository.updateUserDoc(fbUser.uid, {'email': fbUser.email});
        _ref.read(databaseProvider.notifier).setCurrentUser(updatedUser);
      }
    }
  }

  // Link Phone Account
  Future<void> linkPhoneAccount(fb.PhoneAuthCredential credential) async {
    final userCredential = await _repository.linkWithPhoneCredential(credential);
    final fbUser = userCredential.user;
    if (fbUser != null && fbUser.phoneNumber != null) {
      final doc = await _repository.getUserDoc(fbUser.uid);
      if (doc.exists) {
        final existingUser = UserModel.fromMap(doc.data()!);
        final updatedUser = existingUser.copyWith(
          phone: fbUser.phoneNumber,
          phoneVerified: true,
          verifiedAt: DateTime.now(),
        );
        await _repository.updateUserDoc(fbUser.uid, {
          'phone': fbUser.phoneNumber,
          'phoneVerified': true,
          'verifiedAt': Timestamp.fromDate(DateTime.now()),
        });
        _ref.read(databaseProvider.notifier).setCurrentUser(updatedUser);
      }
    }
  }

  // Guest Mode Sign-In
  Future<UserModel> handleGuestSignIn() async {
    final credential = await _repository.signInAnonymously();
    final fbUser = credential.user;
    if (fbUser == null) {
      throw Exception("Failed to start anonymous guest session.");
    }

    final guestUser = UserModel(
      uid: fbUser.uid,
      name: 'Guest Explorer',
      email: 'guest@Locaro.com',
      phone: '',
      photoUrl: '',
      role: 'user',
      isGuest: true,
      interests: [],
      location: 'Default Location',
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isOnboardingCompleted: true, // Guest skips onboarding
      isProfileCompleted: false,
      notificationEnabled: false,
      language: 'English',
      themeMode: 'light',
      followingShops: [],
      savedProducts: [],
      notificationSettings: {
        'offers': false,
        'nearbyDeals': false,
        'comments': false,
        'followers': false,
        'announcements': false,
        'marketing': false,
      },
      likedProducts: [],
      likedPosts: [],
    );

    // Save Guest user to Firestore
    final mapData = guestUser.toMap();
    mapData['loginCount'] = 1;
    mapData['platform'] = Platform.isAndroid ? 'Android' : 'iOS';
    mapData['accountType'] = 'guest';

    await _repository.setUserDoc(fbUser.uid, mapData);

    // Sync with Riverpod
    _ref.read(databaseProvider.notifier).setCurrentUser(guestUser);
    _ref.read(appRoleProvider.notifier).state = 'user';
    _setThemeFromStr('light');

    return guestUser;
  }

  // Restore session
  Future<void> restoreSession(fb.User fbUser) async {
    final doc = await _repository.getUserDoc(fbUser.uid);
    if (doc.exists) {
      final user = UserModel.fromMap(doc.data()!);

      // Update lastLoginAt
      await _repository.updateUserDoc(fbUser.uid, {
        'lastLoginAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      final updatedUser = user.copyWith(
        lastLoginAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Sync state
      _ref.read(databaseProvider.notifier).setCurrentUser(updatedUser);
      _setThemeFromStr(updatedUser.themeMode);

      // Sync FCM topics
      fcmService.updateTopicSubscriptions(
        pushEnabled: updatedUser.notificationEnabled,
        offersEnabled: updatedUser.notificationSettings['offers'] ?? true,
        nearbyDealsEnabled:
            updatedUser.notificationSettings['nearbyDeals'] ?? true,
        marketingEnabled:
            updatedUser.notificationSettings['marketing'] ?? false,
      );

      if (updatedUser.isOnboardingCompleted) {
        _ref.read(appRoleProvider.notifier).state = updatedUser.role;
      } else {
        _ref.read(appRoleProvider.notifier).state = null; // show onboarding
      }
    }
  }

  // Complete Onboarding Flow
  Future<void> completeOnboarding(UserModel updatedUser) async {
    final finalUser = updatedUser.copyWith(
      isOnboardingCompleted: true,
      isProfileCompleted: true,
      updatedAt: DateTime.now(),
    );

    // Write to Firestore
    await _repository.updateUserDoc(finalUser.uid, {
      'name': finalUser.name,
      'email': finalUser.email,
      'phone': finalUser.phone,
      'photoUrl': finalUser.photoUrl,
      'role': finalUser.role,
      'interests': finalUser.interests,
      'location': finalUser.location,
      'latitude': finalUser.latitude,
      'longitude': finalUser.longitude,
      'phoneVerified': finalUser.phoneVerified,
      'verifiedAt': finalUser.verifiedAt != null ? Timestamp.fromDate(finalUser.verifiedAt!) : null,
      'isOnboardingCompleted': true,
      'isProfileCompleted': true,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    // Update state
    _ref.read(databaseProvider.notifier).setCurrentUser(finalUser);
    _ref.read(appRoleProvider.notifier).state = finalUser.role;
    _ref.read(authUserProvider.notifier).refresh();
  }

  // Save Theme Preference
  Future<void> updateThemeMode(String themeStr) async {
    final user = _ref.read(databaseProvider).currentUser;
    if (!user.isGuest) {
      await _repository.updateUserDoc(user.uid, {
        'themeMode': themeStr,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
    _setThemeFromStr(themeStr);
  }

  // Save Notification Preference
  Future<void> updateNotificationSettings(
    bool enabled,
    Map<String, bool> settings,
  ) async {
    final user = _ref.read(databaseProvider).currentUser;
    if (!user.isGuest) {
      await _repository.updateUserDoc(user.uid, {
        'notificationEnabled': enabled,
        'notificationSettings': settings,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      final updatedUser = user.copyWith(
        notificationEnabled: enabled,
        notificationSettings: settings,
      );
      _ref.read(databaseProvider.notifier).setCurrentUser(updatedUser);
    }
  }

  // Upload Custom Photo & Save to storage
  Future<String> changeProfilePhoto(File imageFile) async {
    final user = _ref.read(databaseProvider).currentUser;
    final downloadUrl = await _repository.uploadProfilePhoto(
      user.uid,
      imageFile,
    );

    // Update Firestore user document
    await _repository.updateUserDoc(user.uid, {
      'photoUrl': downloadUrl,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    final updatedUser = user.copyWith(
      photoUrl: downloadUrl,
      updatedAt: DateTime.now(),
    );
    _ref.read(databaseProvider.notifier).setCurrentUser(updatedUser);

    return downloadUrl;
  }

  // Update Phone Number
  Future<void> updatePhoneNumber(String newPhone) async {
    final user = _ref.read(databaseProvider).currentUser;
    if (!user.isGuest) {
      await _repository.updateUserDoc(user.uid, {
        'phone': newPhone,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      final updatedUser = user.copyWith(
        phone: newPhone,
        updatedAt: DateTime.now(),
      );
      _ref.read(databaseProvider.notifier).setCurrentUser(updatedUser);
    }
  }

  // Send Email Verification Link
  Future<void> sendEmailVerification(String email) async {
    final fbUser = fb.FirebaseAuth.instance.currentUser;
    if (fbUser != null) {
      // This sends a verification email to the new address and, upon verification, updates the email on the Firebase account.
      await fbUser.verifyBeforeUpdateEmail(email);
    } else {
      throw Exception('User is not signed in.');
    }
  }

  // Refresh Email Verification Status
  Future<void> refreshUserEmailVerificationStatus() async {
    final fbUser = fb.FirebaseAuth.instance.currentUser;
    if (fbUser != null) {
      await fbUser.reload();
      if (fbUser.emailVerified) {
        // Update Firestore if the email was successfully verified in Firebase Auth
        final user = _ref.read(databaseProvider).currentUser;
        if (user.email != fbUser.email) {
          await _repository.updateUserDoc(user.uid, {
            'email': fbUser.email,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
          final updatedUser = user.copyWith(
            email: fbUser.email ?? '',
            updatedAt: DateTime.now(),
          );
          _ref.read(databaseProvider.notifier).setCurrentUser(updatedUser);
        }
      }
    }
  }

  // Sign Out
  Future<void> handleSignOut() async {
    await _repository.signOut();
    _clearLocalProviders();
    // Unsubscribe from all topics on sign out
    fcmService.updateTopicSubscriptions(
      pushEnabled: false,
      offersEnabled: false,
      nearbyDealsEnabled: false,
      marketingEnabled: false,
    );
  }

  // Delete User Account Completely
  Future<void> handleDeleteAccount() async {
    final user = _ref.read(databaseProvider).currentUser;
    // 1. Delete Firestore User Document
    await _repository.deleteUserDoc(user.uid);

    // 2. Delete Storage Profile photo
    await _repository.deleteProfilePhoto(user.uid);

    // 3. Delete Firebase Auth account
    await _repository.deleteAuthAccount();
    _clearLocalProviders();
  }

  // Guest Action Check Guard
  bool checkGuest(BuildContext context, {required VoidCallback onAllowed}) {
    final currentUser = _ref.read(databaseProvider).currentUser;
    if (currentUser.isGuest) {
      _showGuestLoginBottomSheet(context);
      return false;
    }
    onAllowed();
    return true;
  }

  void _clearLocalProviders() {
    _ref.read(appRoleProvider.notifier).state = null;
    _ref.read(bottomNavIndexProvider.notifier).state = 0;
  }

  void _setThemeFromStr(String themeModeStr) {
    ThemeMode mode;
    switch (themeModeStr) {
      case 'light':
        mode = ThemeMode.light;
        break;
      case 'dark':
        mode = ThemeMode.dark;
        break;
      case 'system':
      default:
        mode = ThemeMode.system;
        break;
    }
    _ref.read(appThemeModeProvider.notifier).setThemeMode(mode);
  }

  // Premium Sign-in popup for Guest Mode Restrictions
  void _showGuestLoginBottomSheet(BuildContext context) {
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.border,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.lock,
                  size: 32,
                  color: context.colors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Sign in required',
                style: AppTypography.heading.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'To like, save products, write reviews, and follow shops, you need to sign in with your Google account.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: context.colors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                text: 'Continue with Google',
                onPressed: () async {
                  Navigator.pop(context); // Close bottom sheet
                  // Sign out current anonymous guest session and go to welcome
                  await handleSignOut();
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Maybe Later',
                  style: AppTypography.body.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthService(repository, ref);
});
