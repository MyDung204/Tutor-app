import 'package:doantotnghiep/features/chat/data/chat_provider.dart';
import 'package:doantotnghiep/features/chat/presentation/group_chat_screen.dart';
import 'package:doantotnghiep/features/group/domain/models/group_request.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsStreamProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
             return const Center(child: Text('Chưa có tin nhắn nào', style: TextStyle(color: Colors.grey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conv = conversations[index];
              return Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: conv.isGroup 
                        ? (conv.partnerId.startsWith('course_') ? Colors.purple[50] : Colors.blue[50]) 
                        : Colors.grey[200],
                    child: Icon(
                      conv.isGroup 
                          ? (conv.partnerId.startsWith('course_') ? Icons.school : Icons.people) 
                          : Icons.person, 
                      size: 28, 
                      color: conv.isGroup 
                          ? (conv.partnerId.startsWith('course_') ? Colors.purple : Colors.blue) 
                          : Colors.grey
                    ),
                  ),
                  title: Text(conv.partnerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                     "${conv.lastSenderId == 'you' ? 'Bạn: ' : ''}${conv.lastMessage}", 
                     maxLines: 1, 
                     overflow: TextOverflow.ellipsis
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                       Text(DateFormat('HH:mm').format(conv.lastMessageTime), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                       if (conv.unreadCount > 0)
                         Container(
                           margin: const EdgeInsets.only(top: 4),
                           padding: const EdgeInsets.all(6),
                           decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                           child: Text(conv.unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10)),
                         )
                    ],
                  ),
                  onTap: () {
                    if (conv.isGroup) {
                       // We need a GroupRequest object for GroupChatScreen.
                       // Ideally we passed full group object, but here we just have ID.
                       // Re-fetching or just creating partial object.
                       // For now creating partial object is fast, or we navigate to detail.
                       // BETTER: Navigate to GroupChatScreen with minimal info or fetch.
                       
                       // Hack for now: Construct minimal GroupRequest logic or fetch it?
                       // Actually GroupChatScreen is designed to take GroupRequest.
                       // Let's create a minimal one.
                       final minimalGroup = GroupRequest(
                          id: conv.partnerId, // group_id
                          topic: conv.partnerName, 
                          subject: '', 
                          gradeLevel: '',
                          pricePerSession: 0,
                          location: '',
                          description: '', 
                          creatorId: '', 
                          creatorName: '', 
                          currentMembers: 0, 
                          maxMembers: 0, 
                          createdAt: DateTime.now(),
                          startTime: DateTime.now(),
                       );
                       
                        Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(builder: (_) => GroupChatScreen(group: minimalGroup)),
                      );
                    } else {
                       context.push('/chat', extra: {
                          'conversation_id': conv.id,
                          'partner_id': conv.partnerId,
                          'partner_name': conv.partnerName,
                          'partner_avatar': conv.partnerAvatar
                      });
                    }
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
      ),
    );
  }
}
