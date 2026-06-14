import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import 'app_state_providers.dart';

class NotificationsNotifier extends Notifier<List<NotificationModel>> {
  StreamSubscription? _subscription;

  @override
  List<NotificationModel> build() {
    final userState = ref.watch(databaseProvider);
    final userUid = userState.currentUser.uid;

    _subscription?.cancel();

    if (userUid.isEmpty) {
      return [];
    }

    _subscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userUid)
        .snapshots()
        .listen((snapshot) {
          final dbNotifications = snapshot.docs.map((doc) => NotificationModel.fromMap(doc.data())).toList();
          // Sort descending (newest first)
          dbNotifications.sort((a, b) => b.id.compareTo(a.id));

          state = dbNotifications;
        });

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return [];
  }

  Future<void> markAllRead() async {
    final userState = ref.read(databaseProvider);
    final userUid = userState.currentUser.uid;
    
    // Toggle local state (mock ones)
    state = state.map((n) => n.copyWith(isRead: true)).toList();

    // Toggle database ones
    try {
      final query = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userUid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in query.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (_) {}
  }

  Future<void> toggleRead(String id) async {
    // Update in database
    try {
      final notif = state.where((n) => n.id == id).firstOrNull;
      if (notif == null) return;      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(id)
          .update({'isRead': !notif.isRead});
    } catch (_) {}
  }

  Future<void> deleteNotification(String id) async {
    try {
      // Optimistic delete locally
      state = state.where((n) => n.id != id).toList();
      
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(id)
          .delete();
    } catch (_) {}
  }
}

final notificationsProvider = NotifierProvider<NotificationsNotifier, List<NotificationModel>>(() {
  return NotificationsNotifier();
});
