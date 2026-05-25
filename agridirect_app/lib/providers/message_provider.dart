import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';
import '../services/cache_service.dart';

class MessageProvider extends ChangeNotifier {
  final MessageService _messageService = MessageService();

  List<Map<String, dynamic>> _conversations = [];
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  int _unreadCount = 0;

  List<Map<String, dynamic>> get conversations => _conversations;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  /// Fetch all conversations
  Future<void> fetchConversations(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _conversations = await _messageService.fetchConversations(userId);
      _unreadCount = await _messageService.getUnreadCount(userId);
    } catch (e) {
      _conversations = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Fetch messages with a specific user
  Future<void> fetchMessages(String userId, String otherUserId) async {
    if (_messages.isEmpty) {
      _messages = CacheService.getCachedMessages();
    }
    _isLoading = true;
    notifyListeners();
    try {
      final fresh = await _messageService.fetchMessages(userId, otherUserId);
      _messages = fresh;
      await CacheService.cacheMessages(_messages);
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      if (_messages.isEmpty) {
        _messages = CacheService.getCachedMessages();
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Send a message
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    try {
      await _messageService.sendMessage(
        senderId: senderId,
        receiverId: receiverId,
        content: content,
      );
      // Add message locally for instant feedback
      final newMsg = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        createdAt: DateTime.now(),
      );
      _messages.add(newMsg);
      await CacheService.cacheMessages(_messages);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Mark messages as read
  Future<void> markAsRead(String senderId, String receiverId) async {
    try {
      await _messageService.markAsRead(senderId, receiverId);
      for (var i = 0; i < _messages.length; i++) {
        if (_messages[i].senderId == senderId) {
          _messages[i] = MessageModel(
            id: _messages[i].id,
            senderId: _messages[i].senderId,
            receiverId: _messages[i].receiverId,
            content: _messages[i].content,
            isRead: true,
            createdAt: _messages[i].createdAt,
          );
        }
      }
      await CacheService.cacheMessages(_messages);
      notifyListeners();
    } catch (e) {
      // Ignore mark-as-read errors
    }
  }

  /// Stream for real-time message updates
  Stream<List<Map<String, dynamic>>> streamMessages(String userId) {
    return _messageService.streamMessages(userId);
  }
}
