import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // Google Sign-In
  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    return await _auth.signInWithCredential(credential);
  }

  // Link Google Account
  Future<UserCredential> linkWithGoogle() async {
    final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    return await _auth.currentUser!.linkWithCredential(credential);
  }

  // Phone Sign-In
  Future<UserCredential> signInWithPhoneCredential(PhoneAuthCredential credential) async {
    return await _auth.signInWithCredential(credential);
  }

  // Link Phone Account
  Future<UserCredential> linkWithPhoneCredential(PhoneAuthCredential credential) async {
    return await _auth.currentUser!.linkWithCredential(credential);
  }

  // Anonymous Auth (Guest Mode)
  Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  // Sign Out
  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }

  // Delete Auth Account
  Future<void> deleteAuthAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }

  // Firestore operations
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDoc(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  Future<void> setUserDoc(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).set(data);
  }

  Future<void> updateUserDoc(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  Future<void> deleteUserDoc(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }

  // Check if a phone number is already verified by another account
  Future<bool> isPhoneNumberUsed(String phoneNumber) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('phone', isEqualTo: phoneNumber)
        .where('phoneVerified', isEqualTo: true)
        .limit(1)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  // Firebase Storage operations
  Future<String> uploadProfilePhoto(String uid, File file) async {
    final ref = _storage.ref().child('users').child(uid).child('profile.jpg');
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<String> uploadShopAsset(String shopId, String assetType, File file) async {
    // assetType is either 'logo' or 'banner'
    final ref = _storage.ref().child('shops').child(shopId).child('$assetType.jpg');
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> deleteProfilePhoto(String uid) async {
    try {
      final ref = _storage.ref().child('users').child(uid).child('profile.jpg');
      await ref.delete();
    } catch (_) {
      // Ignore if file doesn't exist
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});
