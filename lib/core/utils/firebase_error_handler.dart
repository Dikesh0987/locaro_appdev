import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseErrorHandler {
  /// Maps a [FirebaseAuthException] to a user-friendly error message string.
  /// Also logs the raw exception to the console in debug mode.
  static String handleAuthException(FirebaseAuthException e) {
    if (kDebugMode) {
      debugPrint('🔥 FirebaseAuthException: [${e.code}] ${e.message}');
    }

    switch (e.code) {
      case 'too-many-requests':
        return '⚠️ Too Many Verification Attempts\n\nYou\'ve requested verification codes too many times in a short period.\n\nPlease wait a while before trying again, or use a different device.';
      
      case 'quota-exceeded':
        return '⚠️ Verification Service Busy\n\nWe\'re currently unable to send verification codes.\n\nPlease try again later.';
      
      case 'network-request-failed':
        return '📶 No Internet Connection\n\nPlease check your internet connection and try again.';
      
      case 'app-not-authorized':
        return '⚠️ Verification Service Unavailable\n\nWe\'re unable to verify phone numbers right now.\n\nPlease try again later.';
      
      case 'invalid-phone-number':
        return '📱 Invalid Mobile Number\n\nPlease enter a valid mobile number.';
      
      case 'session-expired':
        return '⌛ Verification Code Expired\n\nPlease request a new verification code.';
      
      case 'invalid-verification-code':
        return '❌ Incorrect Verification Code\n\nPlease check the code and try again.';
        
      default:
        // A generic fallback message that doesn't expose underlying mechanics
        return '⚠️ Verification Failed\n\nSomething went wrong while verifying your request. Please try again later.';
    }
  }

  /// Maps generic exceptions (that aren't FirebaseAuthException)
  static String handleGenericException(Object e) {
    if (kDebugMode) {
      debugPrint('🔥 Generic Exception: $e');
    }
    return '⚠️ Unexpected Error\n\nSomething went wrong. Please try again.';
  }
}
