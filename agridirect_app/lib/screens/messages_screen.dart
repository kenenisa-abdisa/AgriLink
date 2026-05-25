import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/message_provider.dart';
import 'chat_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:supabase_flutter/supabase_flutter.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = context.read<AuthProvider>().currentUserId;
      context.read<MessageProvider>().fetchConversations(currentUserId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.currentUserId;
    final messageProvider = context.watch<MessageProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: const Color(0xFF1B6B3A),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => messageProvider.fetchConversations(currentUserId),
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),

            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: messageProvider.streamMessages(currentUserId),
                builder: (context, snapshot) {
                  // Group messages by conversation partner
                  final List<Map<String, dynamic>> rawMessages = snapshot.data ?? [];
                  
                  // Filter for current user's messages if stream doesn't do it
                  final allMessages = rawMessages.where((msg) => 
                    msg['sender_id'] == currentUserId || msg['receiver_id'] == currentUserId
                  ).toList();

                  final Map<String, Map<String, dynamic>> conversations = {};

                  for (final msg in allMessages) {
                    final isSender = msg['sender_id'] == currentUserId;
                    final partnerId = isSender ? msg['receiver_id'] : msg['sender_id'];

                    if (!conversations.containsKey(partnerId)) {
                      conversations[partnerId] = msg;
                    } else {
                      // Keep the latest message
                      final currentMsgDate = DateTime.parse(msg['created_at']);
                      final existingMsgDate = DateTime.parse(conversations[partnerId]!['created_at']);
                      if (currentMsgDate.isAfter(existingMsgDate)) {
                        conversations[partnerId] = msg;
                      }
                    }
                  }

                  if (conversations.isEmpty) {
                    if (messageProvider.isLoading && !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    // Fallback to provider conversations if stream is empty but provider has data
                    if (messageProvider.conversations.isNotEmpty) {
                       return _buildConversationList(messageProvider.conversations, currentUserId);
                    }

                    return ListView( // Use ListView for RefreshIndicator to work
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.message_outlined, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('No messages yet', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                              const SizedBox(height: 8),
                              const Text('Start a conversation from a product or farmer page', textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  final entries = conversations.entries.map((e) => {
                    'partner_id': e.key,
                    'last_message': e.value['content'],
                    'created_at': e.value['created_at'],
                    'is_read': e.value['is_read'],
                    'receiver_id': e.value['receiver_id'],
                  }).toList();
                  
                  // Sort by date
                  entries.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));

                  return _buildConversationList(entries, currentUserId);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationList(List<Map<String, dynamic>> conversations, String currentUserId) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conv = conversations[index];
        final partnerId = conv['partner_id'];
        final isUnread = conv['is_read'] == false && conv['receiver_id'] == currentUserId;

        return FutureBuilder<Map<String, dynamic>?>(
          future: _fetchUserName(partnerId),
          builder: (context, userSnap) {
            final name = userSnap.data?['name'] ?? 'User';
            final lastSeenStr = userSnap.data?['last_seen_at'];
            final isOnline = userSnap.data?['is_online'] ?? false;

            bool isActuallyOnline = false;
            if (isOnline && lastSeenStr != null) {
              final lastSeen = DateTime.parse(lastSeenStr);
              isActuallyOnline = DateTime.now().difference(lastSeen).inMinutes < 3;
            }

            if (_searchQuery.isNotEmpty && !name.toLowerCase().contains(_searchQuery.toLowerCase())) {
              return const SizedBox.shrink();
            }

            return ListTile(
              leading: Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF1B6B3A),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (isActuallyOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(name, style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.normal)),
              subtitle: Text(
                conv['last_message'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: isUnread ? Colors.black87 : Colors.grey[600], fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    timeago.format(DateTime.parse(conv['created_at'])),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  if (isUnread) ...[
                    const SizedBox(height: 4),
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF1B6B3A), shape: BoxShape.circle)),
                  ],
                ],
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(otherUserId: partnerId, otherUserName: name)));
              },
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _fetchUserName(String userId) async {
    try {
      return await Supabase.instance.client
          .from('users')
          .select('name, last_seen_at, is_online')
          .eq('id', userId)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }
}
