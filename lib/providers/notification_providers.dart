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
      return _getMockNotifications();
    }

    _subscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userUid)
        .snapshots()
        .listen((snapshot) {
          final dbNotifications = snapshot.docs.map((doc) => NotificationModel.fromMap(doc.data())).toList();
          // Sort descending (newest first)
          dbNotifications.sort((a, b) => b.id.compareTo(a.id));

          // Prepend database notifications to the mock notifications list to have a full feed
          state = [...dbNotifications, ..._getMockNotifications()];
        });

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return _getMockNotifications();
  }

  List<NotificationModel> _getMockNotifications() {
    return [
      NotificationModel(
        id: 'n1',
        title: 'Cafe Aroma',
        body: 'Your morning brew is ready! Flash this notification for 10% off your next purchase.',
        time: '2m ago',
        logoUrl: 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=100',
        isUnread: true,
        category: 'Offers',
      ),
      NotificationModel(
        id: 'n2',
        title: 'The Daily Catch',
        body: 'Fresh King Salmon just arrived. Limited stock available this weekend!',
        time: '1h ago',
        logoUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=100',
        isUnread: true,
        category: 'Offers',
      ),
      NotificationModel(
        id: 'n3',
        title: 'Sarah Jenkins',
        body: 'Sarah Jenkins started following your shop updates.',
        time: '3h ago',
        logoUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100',
        isUnread: false,
        category: 'Followers',
      ),
      NotificationModel(
        id: 'n4',
        title: 'Alex Miller',
        body: 'Alex Miller commented: "Are these organic? Can I visit today?"',
        time: 'Yesterday',
        logoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100',
        isUnread: false,
        category: 'Comments',
      ),
      NotificationModel(
        id: 'n5',
        title: 'Nearo System',
        body: 'You\'ve reached level 3 local explorer! Check out your new badge in settings.',
        time: 'Tue',
        logoUrl: '',
        isUnread: false,
        category: 'System',
      ),
    ];
  }

  Future<void> markAllRead() async {
    final userState = ref.read(databaseProvider);
    final userUid = userState.currentUser.uid;
    
    // Toggle local state (mock ones)
    state = state.map((n) => n.copyWith(isUnread: false)).toList();

    // Toggle database ones
    try {
      final query = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userUid)
          .where('isUnread', isEqualTo: true)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in query.docs) {
        batch.update(doc.reference, {'isUnread': false});
      }
      await batch.commit();
    } catch (_) {}
  }

  Future<void> toggleUnread(String id) async {
    // Check if it's a mock notification
    if (id.startsWith('n') && id.length <= 2) {
      state = state.map((n) {
        if (n.id == id) {
          return n.copyWith(isUnread: !n.isUnread);
        }
        return n;
      }).toList();
      return;
    }

    // Otherwise, update in database
    try {
      final notif = state.firstWhere((n) => n.id == id);
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(id)
          .update({'isUnread': !notif.isUnread});
    } catch (_) {}
  }
}

final notificationsProvider = NotifierProvider<NotificationsNotifier, List<NotificationModel>>(() {
  return NotificationsNotifier();
});
