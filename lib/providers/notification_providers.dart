import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';

class NotificationsNotifier extends Notifier<List<NotificationModel>> {
  @override
  List<NotificationModel> build() {
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

  void markAllRead() {
    state = state.map((n) => n.copyWith(isUnread: false)).toList();
  }

  void toggleUnread(String id) {
    state = state.map((n) {
      if (n.id == id) {
        return n.copyWith(isUnread: !n.isUnread);
      }
      return n;
    }).toList();
  }
}

final notificationsProvider = NotifierProvider<NotificationsNotifier, List<NotificationModel>>(() {
  return NotificationsNotifier();
});
