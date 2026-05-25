import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/message_provider.dart';
import '../services/cache_service.dart';
import '../utils/vibrant_theme.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _supabase = Supabase.instance.client;
  late final RealtimeChannel _presenceChannel;
  Map<String, dynamic>? _otherUserData;

  String get _currentUserId => _supabase.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _markAsRead();
    _initPresenceListener();
    // Initial fetch to ensure messages are loaded even if stream is slow
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessageProvider>().fetchMessages(_currentUserId, widget.otherUserId);
    });
  }

  void _initPresenceListener() async {
    try {
      final data = await _supabase
          .from('users')
          .select('name, last_seen_at, is_online')
          .eq('id', widget.otherUserId)
          .maybeSingle();
      if (mounted && data != null) {
        setState(() {
          _otherUserData = data;
        });
      }
    } catch (_) {}

    _presenceChannel = _supabase
        .channel('public:users_presence_${widget.otherUserId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'users',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.otherUserId,
          ),
          callback: (payload) {
            if (mounted) {
              setState(() {
                _otherUserData = payload.newRecord;
              });
            }
          },
        )
      ..subscribe();
  }

  Future<void> _markAsRead() async {
    try {
      await context.read<MessageProvider>().markAsRead(widget.otherUserId, _currentUserId);
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();

    try {
      await context.read<MessageProvider>().sendMessage(
        senderId: _currentUserId,
        receiverId: widget.otherUserId,
        content: content,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _deleteMessage(String id) async {
    try {
      await _supabase.from('messages').delete().eq('id', id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showEditDialog(String id, String currentContent) {
    final initialText = currentContent.replaceAll(' (edited)', '');
    final editController = TextEditingController(text: initialText);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(hintText: 'New message...'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final newText = editController.text.trim();
              if (newText.isNotEmpty && newText != initialText) {
                try {
                  await _supabase
                      .from('messages')
                      .update({'content': '$newText (edited)'}).eq('id', id);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to edit: $e'), backgroundColor: Colors.red));
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showOptions(String id, String content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit, color: VibrantTheme.primaryGreen),
              title: const Text('Edit Message'),
              onTap: () {
                Navigator.pop(ctx);
                _showEditDialog(id, content);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete / Unsend for Everyone', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteMessage(id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    try {
      _presenceChannel.unsubscribe();
    } catch (_) {}
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ageMessage = CacheService.getCacheAgeMessage('messages');

    final lastSeenStr = _otherUserData?['last_seen_at'];
    final isOnline = _otherUserData?['is_online'] ?? false;

    bool isActuallyOnline = false;
    if (isOnline && lastSeenStr != null) {
      final lastSeen = DateTime.parse(lastSeenStr);
      isActuallyOnline = DateTime.now().difference(lastSeen).inMinutes < 3;
    }

    String presenceSubtitle = 'Offline';
    if (isActuallyOnline) {
      presenceSubtitle = 'Online';
    } else if (lastSeenStr != null) {
      final lastSeen = DateTime.parse(lastSeenStr);
      final difference = DateTime.now().difference(lastSeen);
      if (difference.inMinutes < 60) {
        presenceSubtitle = 'Active ${difference.inMinutes} mins ago';
      } else if (difference.inHours < 24) {
        presenceSubtitle = 'Active ${difference.inHours} hrs ago';
      } else {
        presenceSubtitle = 'Active ${difference.inDays} days ago';
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F0),
      appBar: AppBar(
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: VibrantTheme.primaryGradient)),
        elevation: 2,
        title: Row(
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'avatar_${widget.otherUserId}',
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    child: Text(
                      widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (isActuallyOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.otherUserName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  presenceSubtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isActuallyOnline ? Colors.lightGreenAccent[100] : Colors.white70,
                    fontWeight: isActuallyOnline ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (ageMessage.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.amber[50],
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 16, color: Colors.amber[800]),
                  const SizedBox(width: 8),
                  Text(
                    'Viewing offline messages ($ageMessage)',
                    style: TextStyle(
                      color: Colors.amber[900],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: context.read<MessageProvider>().streamMessages(_currentUserId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Connection error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                }
                
                // Use data from stream if available, otherwise fallback to provider data (initial fetch)
                final List<Map<String, dynamic>> rawMessages = snapshot.data ?? [];
                
                final messages = rawMessages.where((msg) {
                  return (msg['sender_id'] == _currentUserId &&
                          msg['receiver_id'] == widget.otherUserId) ||
                      (msg['sender_id'] == widget.otherUserId &&
                          msg['receiver_id'] == _currentUserId);
                }).toList();

                if (messages.isEmpty && !snapshot.hasData) {
                  // If stream hasn't returned yet, check if provider has cached messages
                  final cached = context.watch<MessageProvider>().messages;
                  if (cached.isNotEmpty) {
                    return _buildMessageList(cached.map((m) => {
                      'id': m.id,
                      'sender_id': m.senderId,
                      'receiver_id': m.receiverId,
                      'content': m.content,
                      'created_at': m.createdAt.toIso8601String(),
                    }).toList());
                  }
                  return const Center(child: CircularProgressIndicator());
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('No messages yet', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                      ],
                    ),
                  );
                }

                _scrollToBottom();
                return _buildMessageList(messages);
              },
            ),
          ),
          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: VibrantTheme.primaryGreen,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<Map<String, dynamic>> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final isMine = msg['sender_id'] == _currentUserId;
        final time = DateTime.parse(msg['created_at'] ?? DateTime.now().toIso8601String());

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Align(
            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
            child: GestureDetector(
              onLongPress: isMine ? () => _showOptions(msg['id'], msg['content'] ?? '') : null,
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isMine ? VibrantTheme.primaryGradient : null,
                  color: isMine ? null : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: isMine ? const Radius.circular(20) : Radius.zero,
                    bottomRight: isMine ? Radius.zero : const Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg['content'] ?? '',
                      style: TextStyle(color: isMine ? Colors.white : Colors.black87, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isMine ? Colors.white70 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
