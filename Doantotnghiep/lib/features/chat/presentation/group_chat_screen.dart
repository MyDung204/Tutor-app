import 'package:doantotnghiep/core/theme/edu_theme.dart';
import 'package:doantotnghiep/features/chat/data/group_chat_provider.dart';
import 'package:doantotnghiep/features/chat/domain/models/chat_message.dart';
import 'package:doantotnghiep/features/chat/presentation/widgets/attachment_image.dart';
import 'package:doantotnghiep/features/group/domain/models/group_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class GroupChatScreen extends ConsumerStatefulWidget {
  final GroupRequest group;

  const GroupChatScreen({super.key, required this.group});

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
       ref.read(groupChatControllerProvider(widget.group.id)).markAsRead();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0, 
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        await ref.read(groupChatControllerProvider(widget.group.id)).sendMessage(
          '', 
          filePath: image.path,
        );
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    ref.read(groupChatControllerProvider(widget.group.id)).sendMessage(
      _controller.text, 
    );
    _controller.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(groupChatMessagesStreamProvider(widget.group.id));

    // Auto-mark read on new messages check could go here if needed
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.group.topic, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('${widget.group.currentMembers} thành viên', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
               // Maybe show members?
            },
          ),
        ],
      ),
      body: Container(
         color: Colors.grey[50],
         child: Column(
          children: [
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return const Center(child: Text("Bắt đầu cuộc trò chuyện nhóm...", style: TextStyle(color: Colors.grey)));
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      // Show Sender Name logic? 
                      // For now simpler bubble.
                      return _buildMessageItem(msg);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text("Lỗi: $err")),
              ),
            ),
             // Input Area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, -2))],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.image, color: Colors.blue),
                      onPressed: _pickImage,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Nhập tin nhắn...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: EduTheme.primary),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ),
          ],
         ),
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Only show sender name if NOT me
            if (!msg.isUser && msg.senderName != null)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      msg.senderName!,
                      style: const TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.black54
                      ),
                    ),
                    if (msg.senderId == widget.group.creatorId)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.star, color: Colors.amber, size: 14),
                      ),
                  ],
                ),
              ),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: msg.isUser ? EduTheme.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: msg.isUser ? const Radius.circular(16) : Radius.zero,
                  bottomRight: msg.isUser ? Radius.zero : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (msg.attachmentUrl != null)
                     Padding(
                       padding: const EdgeInsets.only(bottom: 8.0),
                       child: AttachmentImage(url: msg.attachmentUrl!),
                     ),
                  
                  if (msg.text.isNotEmpty)
                    Text(
                      msg.text,
                      style: TextStyle(color: msg.isUser ? Colors.white : Colors.black87),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 4),
              child: Text(
                "${msg.time.hour}:${msg.time.minute.toString().padLeft(2, '0')}",
                style: TextStyle(color: Colors.grey[600], fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
