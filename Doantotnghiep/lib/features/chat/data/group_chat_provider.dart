import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doantotnghiep/features/auth/data/auth_repository.dart';
import 'package:doantotnghiep/features/chat/data/firebase_chat_repository.dart';
import 'package:doantotnghiep/features/chat/domain/models/chat_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Direct Stream from Repo logic (Group Version)
final groupChatMessagesStreamProvider = StreamProvider.family<List<ChatMessage>, String>((ref, groupId) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return Stream.value([]); // Return empty stream if no user

  // Create a stream that listens to the MESSAGES subcollection of the group
  final collection = FirebaseFirestore.instance
      .collection('conversations')
      .doc('group_$groupId')
      .collection('messages')
      .orderBy('created_at', descending: true);

  return collection.snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc.data(), doc.id, user.id.toString())).toList();
  });
});

final groupChatControllerProvider = Provider.family<GroupChatController, String>((ref, groupId) {
  return GroupChatController(
    ref.watch(firebaseChatRepositoryProvider), 
    ref.watch(authRepositoryProvider),
    groupId
  );
});

class GroupChatController {
  final FirebaseChatRepository _repo;
  final AuthRepository _authRepo;
  final String groupId;

  GroupChatController(this._repo, this._authRepo, this.groupId);

  Future<void> sendMessage(String text, {String? filePath}) async {
    final user = _authRepo.currentUser;
    if (user == null) return;

    await _repo.sendGroupMessage(
      groupId: groupId, 
      senderId: user.id.toString(), 
      content: text,
      attachmentPath: filePath,
      senderName: user.name,
    );
  }

  Future<void> markAsRead() async {
    final user = _authRepo.currentUser;
    if (user == null) return;
    
    await _repo.markAsRead('group_$groupId', user.id.toString());
  }

  Future<void> joinChat({String? groupName, String? initialMessage}) async {
    final user = _authRepo.currentUser;
    if (user == null) return;

    await _repo.addMemberToGroupConversation(groupId, user.id.toString(), groupName: groupName, initialMessage: initialMessage);
  }
}
