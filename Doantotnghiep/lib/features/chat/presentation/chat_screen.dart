import 'dart:io';
import 'package:doantotnghiep/features/chat/presentation/widgets/attachment_image.dart';
import 'package:doantotnghiep/features/chat/data/chat_provider.dart';
import 'package:doantotnghiep/features/chat/domain/models/course_offer.dart';
import 'package:doantotnghiep/features/chat/domain/models/chat_message.dart';
import 'package:doantotnghiep/features/chat/presentation/widgets/offer_bubble.dart';
import 'package:doantotnghiep/features/chat/presentation/widgets/booking_request_bubble.dart';
import 'package:doantotnghiep/features/tutor/domain/models/tutor.dart';
import 'package:doantotnghiep/features/tutor_dashboard/domain/models/tutor_request.dart';
import 'package:doantotnghiep/features/tutor_dashboard/domain/models/tutor_request.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:uuid/uuid.dart';
import 'package:doantotnghiep/features/auth/data/auth_repository.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:doantotnghiep/features/admin/data/admin_system_provider.dart';


class ChatScreen extends ConsumerStatefulWidget {
  final Tutor tutor;
  final TutorRequest? initialRequest;

  const ChatScreen({super.key, required this.tutor, this.initialRequest});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
       ref.read(currentActivePartnerIdProvider.notifier).state = widget.tutor.userId;
       if (widget.initialRequest != null) {
          _sendContextMessage(widget.initialRequest!);
       }
       // Mark as read immediately on open
       ref.read(chatControllerProvider(widget.tutor.userId)).markAsRead();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    Future.delayed(Duration.zero, () {
      if (mounted) { 
          ref.read(currentActivePartnerIdProvider.notifier).state = null;
      }
    });
    super.deactivate();
  }

  void _sendContextMessage(TutorRequest req) {
    final text = "Chào bạn, mình thấy bài đăng tìm gia sư môn ${req.subject} (${req.gradeLevel}) của bạn.\nMình rất quan tâm và muốn nhận lớp này.";
    ref.read(chatControllerProvider(widget.tutor.userId)).sendMessage(
      text,
      partnerName: widget.tutor.name,
      partnerAvatar: widget.tutor.avatarUrl
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0, // For reverse: true, 0 is the bottom (newest message)
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
        await ref.read(chatControllerProvider(widget.tutor.userId)).sendMessage(
          null, 
          filePath: image.path, 
          mimeType: 'image',
          partnerName: widget.tutor.name,
          partnerAvatar: widget.tutor.avatarUrl
        );
        _scrollToBottom();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
         await ref.read(chatControllerProvider(widget.tutor.userId)).sendMessage(
          null, 
          filePath: result.files.single.path!, 
          mimeType: 'file',
          partnerName: widget.tutor.name,
          partnerAvatar: widget.tutor.avatarUrl
        );
        _scrollToBottom();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _sendLocation() async {
    try {
      final hasPermission = await _checkPermission();
      if (!hasPermission) return;

      final position = await Geolocator.getCurrentPosition();
      final locationString = "${position.latitude},${position.longitude}";
      
      await ref.read(chatControllerProvider(widget.tutor.userId)).sendMessage(
        locationString,
        mimeType: 'location',
        partnerName: widget.tutor.name,
        partnerAvatar: widget.tutor.avatarUrl
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi lấy vị trí: $e')));
    }
  }

  Future<bool> _checkPermission() async {
     LocationPermission permission = await Geolocator.checkPermission();
     if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return false;
     }
     if (permission == LocationPermission.deniedForever) return false;
     return true;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authRepositoryProvider).currentUser;
    print("ChatScreen: Build. UserID: ${currentUser?.id}, PartnerID: ${widget.tutor.userId}");
    final messagesAsync = ref.watch(chatMessagesStreamProvider(widget.tutor.userId));

    // Auto-scroll on new messages
    // Note: With reverse: true, new messages appear at top (index 0, scroll offset 0).
    // So we don't necessarily NEED to scroll unless user is scrolled up.
    // But forcing scroll to 0 ensures they see it.
    ref.listen<AsyncValue<List<ChatMessage>>>(chatMessagesStreamProvider(widget.tutor.userId), (prev, next) {
      if (next.hasValue && (prev?.value?.length ?? 0) != next.value!.length) {
         _scrollToBottom();
         // Mark as read when new messages arrive while screen is open
         ref.read(chatControllerProvider(widget.tutor.userId)).markAsRead();
      }
    });
    
    return Scaffold(
      extendBodyBehindAppBar: true, 
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        // ... (AppBar content skipped for brevity in replace, keep matching target to context)
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.withOpacity(0.1), Colors.blue.withOpacity(0.1)],
            ),
          ),
        ),
        title: Row(
          children: [ 
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              radius: 18,
              child: const Icon(Icons.person, size: 18, color: Colors.grey),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.tutor.name, style: const TextStyle(color: Colors.black87, fontSize: 16)),
              ],
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: const [],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFe0c3fc), Color(0xFF8ec5fc)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child:Builder(
                builder: (context) {
                  return messagesAsync.when(
                    data: (messages) {
                      print("ChatScreen: Loaded ${messages.length} messages");
                      if (messages.isEmpty) {
                        return const Center(child: Text("Bắt đầu cuộc trò chuyện...", style: TextStyle(color: Colors.white70)));
                      }
                      // Wrap in Scrollbar
                      return Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 120, 16, 16),
                          itemCount: messages.length,
                          reverse: true, // Firestore messages are ordered desc (newest first). List usually displays bottom-up.
                          itemBuilder: (context, index) {
                            // If reverse=true, index 0 is status bottom (newest).
                            // But our API/Firestore repo returns orderBy desc.
                            // So index 0 is newest. Perfect for reverse=true.
                            final msg = messages[index];
                            return _buildMessageItem(msg);
                          },
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text("Lỗi: $err")),
                  );
                },
              ),
            ),
            // Input Area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.orange, size: 30),
                    onPressed: _showActionSheet,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blueAccent),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage msg) {
    try {
      // print("ChatScreen: Building message. ID: ${msg.id}, Type: ${msg.attachmentType}, Text: ${msg.text}");
      if (msg.attachmentType != null) {
         print("ChatScreen: Message has attachment. Type: ${msg.attachmentType}, URL: ${msg.attachmentUrl}");
      }
      // System Message
      if (msg.isSystem) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
            child: Text(msg.text, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
        );
      }

    // Booking Request Message
    if (msg.bookingId != null) {
      return Align(
        alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: BookingRequestBubble(bookingId: msg.bookingId!, isUser: msg.isUser),
      );
    }

    // Offer Message
    if (msg.offer != null) {
      return Align(
        alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: OfferBubble(
          offer: msg.offer!, 
          isUser: msg.isUser,
          onStatusUpdate: (status) {
            ref.read(chatControllerProvider(widget.tutor.userId)).updateOfferStatus(msg.id, status, offer: msg.offer!);
          },
        ),
      );
    }

    // Attachment Message
    if (msg.attachmentType != null || msg.attachmentType == 'location') {
      return Align(
        alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          constraints: const BoxConstraints(maxWidth: 250),
          child: Column(
            crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (msg.attachmentType == 'image' && msg.attachmentUrl != null)
                AttachmentImage(url: msg.attachmentUrl!)
              else if (msg.attachmentType == 'location')
                GestureDetector(
                  onTap: () {
                     final parts = msg.text.split(',');
                     if (parts.length == 2) {
                        try {
                          final lat = double.parse(parts[0]);
                          final lng = double.parse(parts[1]);
                          context.push('/map', extra: LatLng(lat, lng));
                        } catch (e) {
                          print('Error parsing location: $e');
                        }
                     }
                  },
                  child: Container(
                    height: 150,
                    width: 250,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueAccent, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on, color: Colors.red, size: 40),
                        const SizedBox(height: 8),
                        const Text('Vị trí hiện tại', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        Text(msg.text, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else 
                Container( // File (keeping existing logic for 'file')
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: msg.isUser ? Colors.blue[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.attach_file, color: Colors.black54),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          msg.attachmentName ?? 'Tệp tin',
                          style: const TextStyle(color: Colors.black87, decoration: TextDecoration.underline),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                
              if (msg.text.isNotEmpty)
                Padding(
                   padding: const EdgeInsets.only(top: 4),
                   child: Container(
                     padding: const EdgeInsets.all(8),
                     decoration: BoxDecoration(
                       color: msg.isUser ? Colors.blueAccent : Colors.white,
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: Text(msg.text, style: TextStyle(color: msg.isUser ? Colors.white : Colors.black87)),
                   ),
                ),

              // Time & Status
               Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${msg.time.hour}:${msg.time.minute.toString().padLeft(2, '0')}",
                        style: TextStyle(color: Colors.black54, fontSize: 10),
                      ),
                      if (msg.isUser) ...[
                        const SizedBox(width: 4),
                        Icon(
                          msg.isRead ? Icons.done_all : Icons.check,
                          size: 14,
                          color: msg.isRead ? Colors.blue : Colors.grey,
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Normal Text Message
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: msg.isUser ? Colors.blueAccent : Colors.white,
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
             child: Text(
              msg.text,
              style: TextStyle(color: msg.isUser ? Colors.white : Colors.black87),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${msg.time.hour}:${msg.time.minute.toString().padLeft(2, '0')}",
                    style: TextStyle(color: Colors.black54, fontSize: 10),
                  ),
                  if (msg.isUser) ...[
                    const SizedBox(width: 4),
                    Icon(
                      msg.isRead ? Icons.done_all : Icons.check,
                      size: 14,
                      color: msg.isRead ? Colors.blue : Colors.grey,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
    } catch (e, stack) {
      print("ChatScreen: Error building message ${msg.id}: $e");
      return const SizedBox.shrink(); // Prevent crash
    }
  }

  void _showActionSheet() {
    final currentUser = ref.read(authRepositoryProvider).currentUser;
    final isTutor = currentUser?.role == 'tutor';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isTutor)
              ListTile(
                leading: const Icon(Icons.assignment_turned_in, color: Colors.green),
                title: const Text('Tạo đề xuất khóa học'),
                subtitle: const Text('Gửi báo giá và lịch học'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateOfferModal();
                },
              ),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.blue),
              title: const Text('Gửi ảnh'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file, color: Colors.orange),
              title: const Text('Gửi tập tin'),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
            ListTile(
               leading: const Icon(Icons.location_on, color: Colors.red),
               title: const Text('Gửi vị trí hiện tại'),
               onTap: () {
                 Navigator.pop(context);
                 _sendLocation();
               },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateOfferModal() {
    String? selectedSubject;
    String? selectedTime = "19:00"; 
    List<String> selectedDays = []; 
    final daysOfWeek = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    final priceCtrl = TextEditingController(); 
    final sessionsCtrl = TextEditingController(text: '0');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          
          return Consumer(
            builder: (context, ref, child) {
              final subjectsAsync = ref.watch(adminSubjectsProvider);
              List<String> subjects = ['Toán', 'Lý', 'Hóa', 'Tiếng Anh', 'Ngữ Văn', 'Lập trình']; // Default fallback
              
              if (subjectsAsync.hasValue && subjectsAsync.value!.isNotEmpty) {
                 subjects = subjectsAsync.value!.map((e) {
                   if (e is Map && e.containsKey('name')) {
                     return e['name'].toString();
                   }
                   return e.toString();
                 }).toList();
              }

              return Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tạo đề xuất khóa học', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    // Subject Dropdown
                    const Text('Môn học', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedSubject,
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                      hint: const Text('Chọn môn học'),
                      items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) {
                        setState(() {
                           selectedSubject = val;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    const Text('Lịch học', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
                    const SizedBox(height: 8),
                    
                    // Days Selector
                    Wrap(
                      spacing: 8,
                      children: daysOfWeek.map((day) {
                        final isSelected = selectedDays.contains(day);
                        return ChoiceChip(
                          label: Text(day),
                          selected: isSelected,
                          selectedColor: Colors.blueAccent.withValues(alpha: 0.2),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                selectedDays.add(day);
                              } else {
                                selectedDays.remove(day);
                              }
                              sessionsCtrl.text = selectedDays.length.toString();
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    
                    // Time Selector
                    Row(
                      children: [
                        const Text('Giờ học bắt đầu: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
                        TextButton.icon(
                          icon: const Icon(Icons.access_time),
                          label: Text(selectedTime ?? 'Chọn giờ', style: const TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context, 
                              initialTime: const TimeOfDay(hour: 19, minute: 0),
                            );
                            if (time != null && context.mounted) {
                              setState(() {
                                selectedTime = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
                              });
                            }
                          },
                        )
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Học phí/buổi (VNĐ)', border: OutlineInputBorder()))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: sessionsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Số buổi/tuần', border: OutlineInputBorder()))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (selectedSubject == null || priceCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn môn học và nhập học phí')));
                            return;
                          }
                          
                          final scheduleText = selectedDays.isEmpty 
                              ? (selectedTime ?? '') 
                              : "${selectedDays.join(', ')} - ${selectedTime ?? '19:00'}";

                          final offer = CourseOffer(
                            id: const Uuid().v4(),
                            tutorId: widget.tutor.id,
                            tutorName: widget.tutor.name,
                            subject: selectedSubject!,
                            schedule: scheduleText,
                            price: double.tryParse(priceCtrl.text) ?? 0,
                            sessionsPerWeek: int.tryParse(sessionsCtrl.text) ?? 2,
                          );

                          ref.read(chatControllerProvider(widget.tutor.userId)).sendMessage(
                            'Đã gửi đề xuất: ${offer.subject}',
                            offer: offer,
                            partnerName: widget.tutor.name,
                            partnerAvatar: widget.tutor.avatarUrl
                          );
                          Navigator.pop(context);
                          _scrollToBottom();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent, 
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Gửi đề xuất'),
                      ),
                    )
                  ],
                ),
              );
            }
          );
        }
      ),
    );
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    ref.read(chatControllerProvider(widget.tutor.userId)).sendMessage(
      _controller.text, 
      partnerName: widget.tutor.name, 
      partnerAvatar: widget.tutor.avatarUrl
    );
    _controller.clear();
    _scrollToBottom();
  }
}
