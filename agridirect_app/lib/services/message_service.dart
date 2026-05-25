import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';
import 'email_service.dart';
import 'notification_service.dart';

class MessageService {
  final _supabase = Supabase.instance.client;

  /// Fetch all conversations for the current user (grouped by partner)
  Future<List<Map<String, dynamic>>> fetchConversations(String userId) async {
    try {
      // Get all messages where user is sender or receiver
      final sent = await _supabase
          .from('messages')
          .select()
          .eq('sender_id', userId)
          .order('created_at', ascending: false);

      final received = await _supabase
          .from('messages')
          .select()
          .eq('receiver_id', userId)
          .order('created_at', ascending: false);

      // Combine and group by conversation partner
      final allMessages = <Map<String, dynamic>>[];
      allMessages.addAll(sent);
      allMessages.addAll(received);

      // Group by partner ID
      final Map<String, Map<String, dynamic>> conversations = {};
      for (final msg in allMessages) {
        final partnerId = msg['sender_id'] == userId
            ? msg['receiver_id']
            : msg['sender_id'];
        if (!conversations.containsKey(partnerId) ||
            DateTime.parse(msg['created_at']).isAfter(
              DateTime.parse(conversations[partnerId]!['created_at']),
            )) {
          conversations[partnerId] = msg;
        }
      }

      return conversations.entries.map((e) {
        final msg = e.value;
        return {
          'partner_id': e.key,
          'last_message': msg['content'],
          'created_at': msg['created_at'],
          'is_read': msg['is_read'],
          'sender_id': msg['sender_id'],
        };
      }).toList()
        ..sort((a, b) => DateTime.parse(b['created_at'])
            .compareTo(DateTime.parse(a['created_at'])));
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch messages between two users
  Future<List<MessageModel>> fetchMessages(
      String userId, String otherUserId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .or('and(sender_id.eq.$userId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$userId)')
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => MessageModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Stream messages between two users for real-time updates
  Stream<List<Map<String, dynamic>>> streamMessages(String userId) {
    // We stream all messages for the user and filter in memory 
    // because Supabase streams don't support complex OR filters easily.
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true);
  }

  /// Send a message
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    try {
      final response = await _supabase.from('messages').insert({
        'sender_id': senderId,
        'receiver_id': receiverId,
        'content': content,
        'is_read': false,
      }).select().single();

      if (response.isEmpty) {
        throw Exception('Failed to insert message record.');
      }

      // Get sender name for the notification
      try {
        final senderData = await _supabase.from('users').select('name').eq('id', senderId).maybeSingle();
        final senderName = senderData?['name'] ?? 'Someone';

        // Notify Receiver via database notifications
        await _supabase.from('notifications').insert({
          'user_id': receiverId,
          'title': 'New Message from $senderName 💬',
          'body': content.length > 50 ? '${content.substring(0, 47)}...' : content,
          'data': {'sender_id': senderId, 'type': 'new_message'}
        });

        // Send New Message Email (Fire and forget or catch errors)
        try {
          final receiverData = await _supabase.from('users').select('email').eq('id', receiverId).maybeSingle();
          if (receiverData != null && receiverData['email'] != null) {
            await EmailService().sendNewMessageEmail(
              email: receiverData['email'],
              senderName: senderName,
              content: content,
            );
          }
        } catch (e) {
          // Email failure shouldn't stop the message flow
          debugPrint('Email service error: $e');
        }

        // Send Background FCM Push Notification
        try {
          await NotificationService().sendPushNotification(
            receiverId: receiverId,
            title: 'New Message from $senderName 💬',
            body: content.length > 50 ? '${content.substring(0, 47)}...' : content,
            data: {'type': 'new_message', 'sender_id': senderId},
          );
        } catch (e) {
          debugPrint('FCM push error: $e');
        }
      } catch (e) {
        // Notification failure shouldn't stop the message flow
        debugPrint('Notification service error: $e');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Mark messages from a sender as read
  Future<void> markAsRead(String senderId, String receiverId) async {
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('sender_id', senderId)
          .eq('receiver_id', receiverId);
    } catch (e) {
      rethrow;
    }
  }

  /// Get unread message count
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .eq('receiver_id', userId)
          .eq('is_read', false);
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Update (Edit) a message
  Future<void> updateMessage(String messageId, String newContent) async {
    try {
      await _supabase
          .from('messages')
          .update({'content': '$newContent (edited)'})
          .eq('id', messageId);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete (Unsend) a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _supabase.from('messages').delete().eq('id', messageId);
    } catch (e) {
      rethrow;
    }
  }
}
