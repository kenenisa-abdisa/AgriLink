import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import 'package:intl/intl.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>>? _messages;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final messages = await _adminService.fetchAllMessages();
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Moderation'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(onPressed: _loadMessages, icon: const Icon(Icons.refresh)),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: ListView.separated(
                  itemCount: _messages?.length ?? 0,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final msg = _messages![index];
                    final bool isReported = msg['reported'] ?? false;
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isReported ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                        child: Icon(
                          isReported ? Icons.report_problem : Icons.chat_bubble_outline,
                          color: isReported ? Colors.red : Colors.green,
                          size: 20,
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            '${msg['sender']?['name'] ?? 'Unknown'} ➔ ${msg['receiver']?['name'] ?? 'Unknown'}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          if (isReported)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Chip(
                                label: Text('REPORTED', style: TextStyle(color: Colors.white, fontSize: 10)),
                                backgroundColor: Colors.red,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(msg['content'] ?? ''),
                      ),
                      trailing: Text(
                        DateFormat('MMM dd, HH:mm').format(DateTime.parse(msg['created_at'])),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      onTap: () {
                        // Could expand to see full conversation thread
                      },
                    );
                  },
                ),
              ),
            ),
    );
  }
}
