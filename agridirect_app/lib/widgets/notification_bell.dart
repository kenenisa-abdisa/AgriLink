import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/notifications_screen.dart';

class NotificationBell extends StatelessWidget {
  final Color color;
  const NotificationBell({super.key, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return IconButton(
        icon: Icon(Icons.notifications_outlined, color: color),
        onPressed: () {},
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId),
      builder: (context, snapshot) {
        int unreadCount = 0;
        if (snapshot.hasData) {
          // Some DBs store false as null, so anything not true is unread
          unreadCount = snapshot.data!.where((n) => n['read'] != true).length;
        }

        return IconButton(
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            label: Text(unreadCount > 99 ? '99+' : unreadCount.toString()),
            child: Icon(Icons.notifications_outlined, color: color),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
        );
      },
    );
  }
}
