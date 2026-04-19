import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import 'package:doantotnghiep/core/network/api_client.dart';

final firebaseChatRepositoryProvider = Provider<FirebaseChatRepository>((ref) {
  return FirebaseChatRepository(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
    ref.read(apiClientProvider),
  );
});

class FirebaseChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final ApiClient _apiClient;

  FirebaseChatRepository(this._firestore, this._storage, this._apiClient);

  // Get stream of conversations for a user
  Stream<QuerySnapshot> getConversationsStream(String userId) {
    return _firestore
        .collection('conversations')
        .where('users', arrayContains: userId)
        .orderBy('updated_at', descending: true)
        .snapshots();
  }

  // Get stream of messages for a conversation
  Stream<QuerySnapshot> getMessagesStream(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  // Send a message
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    String? content,
    String? attachmentPath,
    String? attachmentType, // 'image' or 'file'
    Map<String, dynamic>? offerData,
  }) async {
    String? attachmentUrl;
    String? attachmentName;

    // Upload attachment if exists
    if (attachmentPath != null) {
      final uploadResult = await _uploadAttachment(attachmentPath);
      attachmentUrl = uploadResult['url'];
      attachmentName = uploadResult['name'];
    }

    final messageData = {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content ?? '',
      'type': attachmentUrl != null ? attachmentType : 'text',
      'attachment_url': attachmentUrl,
      'attachment_name': attachmentName,
      'created_at': FieldValue.serverTimestamp(),
      'is_read': false,
      if (offerData != null) 'offer': offerData,
    };

    // Add message to subcollection
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add(messageData);

    // Update conversation last message
    String lastMessageText = content ?? '';
    if (attachmentType == 'image') {
      lastMessageText = '[Hình ảnh]';
    } else if (attachmentType == 'file') {
      lastMessageText = '[Tệp tin]';
    }

    await _firestore.collection('conversations').doc(conversationId).update({
      'last_message': lastMessageText,
      'last_sender_id': senderId,
      'updated_at': FieldValue.serverTimestamp(),
      // Increment unread count for receiver
      'unread_counts.$receiverId': FieldValue.increment(1),
    });
  }

  // Create or Get Conversation
  Future<String> createOrGetConversation(String user1, String user2, Map<String, dynamic> userData) async {
    final sortedIds = [user1, user2]..sort();
    final docId = '${sortedIds[0]}_${sortedIds[1]}';
    
    final docRef = _firestore.collection('conversations').doc(docId);
    final docSnap = await docRef.get();

    if (!docSnap.exists) {
      await docRef.set({
        'users': [user1, user2],
        'user_data': userData, // Cache names/avatars
        'last_message': '',
        'last_sender_id': '',
        'updated_at': FieldValue.serverTimestamp(),
        'unread_counts': {user1: 0, user2: 0},
      });
    } else {
      // Update user data to ensure latest names/avatars
      await docRef.set({
        'user_data': userData
      }, SetOptions(merge: true));
    }
    
    return docId;
  }

  Future<void> markAsRead(String conversationId, String userId) async {
    try {
      // 1. Reset unread count for this user
      await _firestore.collection('conversations').doc(conversationId).update({
        'unread_counts.$userId': 0,
      });

      // 2. Mark individual messages AS READ
      final unreadSnapshot = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('is_read', isEqualTo: false)
          .limit(50) // Safety limit
          .get();

      final batch = _firestore.batch();
      int updateCount = 0;

      for (var doc in unreadSnapshot.docs) {
        final data = doc.data();
        final senderId = data['sender_id']?.toString();
        
        // Only mark if sender is NOT me (i.e. it's an incoming message)
        if (senderId != userId) {
           batch.update(doc.reference, {'is_read': true});
           updateCount++;
        }
      }

      if (updateCount > 0) {
        await batch.commit();
      }
    } catch (e) {
      // Error logging could go here if needed
    }
  }

  Future<void> updateOfferStatus(String conversationId, String messageId, String status) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({
      'offer.status': status,
    });
  }

  // ============ GROUP CHAT SUPPORT ============

  // Get stream for a specific group conversation
  Stream<DocumentSnapshot> getGroupConversationStream(String groupId) {
    return _firestore
        .collection('conversations')
        .doc('group_$groupId')
        .snapshots();
  }

  // Ensure Group Doc Exists & Update Members
  Future<void> createOrUpdateGroupConversation(String groupId, List<String> memberIds, String groupName) async {
    final docRef = _firestore.collection('conversations').doc('group_$groupId');
    
    // Check if exists to preserve existing unread counts
    final docSnap = await docRef.get();
    
    if (!docSnap.exists) {
      // Initialize unread counts for all members
      final unreadCounts = {for (var id in memberIds) id: 0};
      
      await docRef.set({
        'is_group': true,
        'group_id': groupId,
        'group_name': groupName,
        'users': memberIds,
        'last_message': 'Nhóm mới được tạo',
        'last_sender_id': '',
        'updated_at': FieldValue.serverTimestamp(),
        'unread_counts': unreadCounts,
      });
    } else {
      final currentData = docSnap.data() as Map<String, dynamic>;
      final currentUnread = Map<String, dynamic>.from(currentData['unread_counts'] ?? {});
      
      for (var id in memberIds) {
        if (!currentUnread.containsKey(id)) {
          currentUnread[id] = 0;
        }
      }

      await docRef.update({
         'users': memberIds,
         'group_name': groupName,
         'unread_counts': currentUnread,
      });
    }
  }

  // Send Group Message
  Future<void> sendGroupMessage({
    required String groupId,
    required String senderId,
    required String content,
    String? attachmentPath,
    String? senderName,
    String? attachmentType = 'image',
  }) async {
    final conversationId = 'group_$groupId';
    
    String? attachmentUrl;
    String? attachmentName;
    
    // Upload attachment if exists
    if (attachmentPath != null) {
      final uploadResult = await _uploadAttachment(attachmentPath);
      attachmentUrl = uploadResult['url'];
      attachmentName = uploadResult['name'];
    }

    final messageData = {
      'sender_id': senderId,
      'sender_name': senderName ?? 'Thành viên',
      'content': content,
      'type': attachmentUrl != null ? attachmentType : 'text',
      'attachment_url': attachmentUrl,
      'attachment_name': attachmentName,
      'created_at': FieldValue.serverTimestamp(),
      'is_read': false,
    };

    // Add to subcollection
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add(messageData);
    
    // Get current members to update unread counts
    final docSnap = await _firestore.collection('conversations').doc(conversationId).get();
    final userIds = List<String>.from(docSnap['users'] ?? []);
    
    // Build update map for unread counts
    final updateMap = <String, dynamic>{
       'last_message': attachmentUrl != null ? (attachmentType == 'image' ? '[Hình ảnh]' : '[Tệp tin]') : content,
       'last_sender_id': senderId,
       'updated_at': FieldValue.serverTimestamp(),
    };
    
    for (var userId in userIds) {
      if (userId != senderId) {
        updateMap['unread_counts.$userId'] = FieldValue.increment(1);
      }
    }

    await _firestore.collection('conversations').doc(conversationId).update(updateMap);
  }

  // Add member to group conversation (safe join)
  Future<void> addMemberToGroupConversation(String groupId, String userId, {String? groupName, String? initialMessage}) async {
    final docRef = _firestore.collection('conversations').doc('group_$groupId');
    
    final docSnap = await docRef.get();
    
    if (!docSnap.exists) {
      // Create if not exists (with just this user)
      final unreadCounts = {userId: 0};
      
      await docRef.set({
        'is_group': true,
        'group_id': groupId,
        'group_name': groupName ?? 'Nhóm $groupId',
        'users': [userId],
        'last_message': initialMessage ?? 'Nhóm mới được tạo',
        'last_sender_id': '',
        'updated_at': FieldValue.serverTimestamp(),
        'unread_counts': unreadCounts,
      });
    } else {
      // Add to users array
      await docRef.update({
        'users': FieldValue.arrayUnion([userId]),
      });

      final data = docSnap.data() as Map<String, dynamic>;
      final unreadCounts = Map<String, dynamic>.from(data['unread_counts'] ?? {});
      
      if (!unreadCounts.containsKey(userId)) {
        await docRef.update({
          'unread_counts.$userId': 0,
        });
      }
      
      if (groupName != null && data['group_name'] == null) {
         await docRef.update({'group_name': groupName});
      }
    }
  }

  // Remove member from group chat (kick or leave)
  Future<void> removeMemberFromGroupConversation(String groupId, String userId) async {
    final docRef = _firestore.collection('conversations').doc('group_$groupId');
    
    // 1. Remove from users array
    await docRef.update({
      'users': FieldValue.arrayRemove([userId]),
    });

    // 2. Remove from unread_counts map
    await docRef.update({
       'unread_counts.$userId': FieldValue.delete(),
    });
  }

  // Shared attachment upload logic
  Future<Map<String, String?>> _uploadAttachment(String path) async {
    final file = File(path);
    final fileName = '${const Uuid().v4()}_${file.uri.pathSegments.last}';
    
    // 1. Try Firebase Storage first
    try {
      final ref = _storage.ref().child('chat_attachments/$fileName');
      final uploadTask = await ref.putFile(file);
      final url = await uploadTask.ref.getDownloadURL();
      return {'url': url, 'name': file.uri.pathSegments.last};
    } catch (e) {
      // 2. Fallback to Laravel Server
      try {
        final formData = FormData.fromMap({
          'attachment': await MultipartFile.fromFile(file.path, filename: file.uri.pathSegments.last),
        });
        
        final response = await _apiClient.post('/chat/upload', data: formData);
        if (response is Map && response.containsKey('url')) {
          final url = response['url'];
          return {'url': url, 'name': file.uri.pathSegments.last};
        }
        throw Exception("Invalid response from server");
      } catch (e2) {
        throw Exception("Gửi tập tin thất bại (Cả Firebase & Server đều lỗi).");
      }
    }
  }
}
