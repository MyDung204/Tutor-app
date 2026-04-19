import 'package:doantotnghiep/features/auth/data/auth_repository.dart';
import 'package:doantotnghiep/features/chat/data/firebase_chat_repository.dart';
import 'package:doantotnghiep/features/chat/domain/models/chat_message.dart';
import 'package:doantotnghiep/features/chat/domain/models/conversation.dart';
import 'package:doantotnghiep/features/chat/domain/models/course_offer.dart';
import 'package:doantotnghiep/core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Conversations Stream
final conversationsStreamProvider = StreamProvider.autoDispose<List<Conversation>>((ref) {
  final repo = ref.watch(firebaseChatRepositoryProvider);
  final authState = ref.watch(authStateChangesProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) {
        print("ConversationsProvider: User is null, returning empty stream");
        return Stream.value([]);
      }
      
      print("ConversationsProvider: Fetching conversations for user ${user.id}");
      return repo.getConversationsStream(user.id).map((snapshot) {
        print("ConversationsProvider: Got snapshot with ${snapshot.docs.length} docs");
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final bool isGroup = data['is_group'] == true;
          String name = 'User';
          String avatar = '';
          String pId = '';

          if (isGroup) {
             name = data['group_name'] ?? 'Nhóm';
             pId = data['group_id'] ?? '';
             // Use Default Group Avatar or custom logic
          } else {
             // Map to Conversation model
             final userData = data['user_data'] as Map<String, dynamic>? ?? {};
             final otherUserId = (data['users'] as List).firstWhere((u) => u != user.id, orElse: () => '');
             final otherUserMap = userData[otherUserId];
             
             name = otherUserMap?['name'] ?? 'User';
             avatar = otherUserMap?['avatar_url'] ?? '';
             pId = otherUserId.toString();
          }

          return Conversation(
            id: doc.id,
            partnerId: pId,
            partnerName: name,
            partnerAvatar: avatar,
            lastMessage: data['last_message'] ?? '',
            lastMessageTime: (data['updated_at'] != null) ? (data['updated_at']).toDate() : DateTime.now(),
            unreadCount: (data['unread_counts']?[user.id] ?? 0),
            lastSenderId: data['last_sender_id']?.toString() ?? '',
            isGroup: isGroup,
          );
        }).toList();
      });
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

final currentActivePartnerIdProvider = StateProvider<String?>((ref) => null);

// 2. Chat Messages Stream
final chatMessagesStreamProvider = StreamProvider.autoDispose.family<List<ChatMessage>, String>((ref, partnerId) {
  final repo = ref.watch(firebaseChatRepositoryProvider);
  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        print("ChatProvider: User is null, returning empty list");
        return Stream.value([]);
      }
      
      // Construct Doc ID: min_max
      final ids = [user.id, partnerId]..sort();
      final conversationId = '${ids[0]}_${ids[1]}';
      print("ChatProvider: Listening to messages for $conversationId");
      
      return repo.getMessagesStream(conversationId).map((snapshot) {
        print("ChatProvider: Got snapshot with ${snapshot.docs.length} docs");
        return snapshot.docs.map((doc) {
          return ChatMessage.fromFirestore(doc.data() as Map<String, dynamic>, doc.id, user.id);
        }).toList();
      });
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// 3. Chat Controller
final chatControllerProvider = Provider.autoDispose.family<ChatController, String>((ref, partnerId) {
  return ChatController(ref, partnerId);
});

class ChatController {
  final Ref ref;
  final String partnerId;

  ChatController(this.ref, this.partnerId);

  Future<void> sendMessage(String? text, {CourseOffer? offer, String? filePath, String? mimeType, String? partnerName, String? partnerAvatar}) async {
    final repo = ref.read(firebaseChatRepositoryProvider);
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    // Construct Doc ID
    final ids = [user.id, partnerId]..sort();
    final conversationId = '${ids[0]}_${ids[1]}';

    // 1. Ensure conversation exists (create if new)
    // Construct user data carefully. 
    // Always provide CURRENT USER data.
    // Only provide PARTNER data if we explicitly have it (not defaulting to 'User').
    
    final Map<String, dynamic> userData = {
      user.id: {'name': user.name, 'avatar_url': user.avatarUrl},
    };

    if (partnerName != null && partnerName.isNotEmpty && partnerName != 'User') {
      userData[partnerId] = {'name': partnerName, 'avatar_url': partnerAvatar ?? ''};
    }
    
    // Create/Update conversation doc
    // Note: createOrGetConversation now uses merge: true, so partial updates are safe.
    await repo.createOrGetConversation(user.id, partnerId, userData);

    // 2. Send Message
    await repo.sendMessage(
      conversationId: conversationId,
      senderId: user.id,
      receiverId: partnerId,
      content: text,
      attachmentPath: filePath,
      attachmentType: mimeType,
      offerData: offer?.toMap(),
    );
  }
  
  Future<void> markAsRead() async {
    final repo = ref.read(firebaseChatRepositoryProvider);
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;
    
    final ids = [user.id, partnerId]..sort();
    final conversationId = '${ids[0]}_${ids[1]}';
    
    await repo.markAsRead(conversationId, user.id);
  }

  Future<void> updateOfferStatus(String messageId, String status, {CourseOffer? offer}) async {
    final repo = ref.read(firebaseChatRepositoryProvider);
    final user = ref.read(authRepositoryProvider).currentUser;
    final apiClient = ref.read(apiClientProvider);

    if (user == null) return;
    
    // Nếu status là accepted và có dữ liệu offer, gọi API tạo lớp học
    if (status == 'accepted' && offer != null) {
      try {
        await apiClient.post('/chat/offer/accept', data: {
          'tutor_id': offer.tutorId, // This might be user_id or tutor_id depending on the App
          'subject': offer.subject,
          'schedule': offer.schedule,
          'price': offer.price,
        });
        print("Tạo lớp học từ đề xuất thành công trên DB");
      } catch (e) {
        print("Lỗi khi tạo lớp học từ đề xuất: $e");
        // Nếu API lỗi, có nên chặn cập nhật Firebase không?
        rethrow; // Ném lỗi ra màn hình cho người dùng UI xử lý
      }
    }

    final ids = [user.id, partnerId]..sort();
    final conversationId = '${ids[0]}_${ids[1]}';
    
    await repo.updateOfferStatus(conversationId, messageId, status);
  }
}

// 4. Total Unread Count Provider (For Notifications)
final totalUnreadChatCountProvider = Provider<AsyncValue<int>>((ref) {
  final conversationsAsync = ref.watch(conversationsStreamProvider);
  return conversationsAsync.whenData((conversations) {
    return conversations.fold(0, (sum, c) => sum + c.unreadCount);
  });
});
