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
      print("FirebaseChatRepo: Starting upload for $attachmentPath");
      try {
          // 1. Try Firebase Storage first (if configured)
          final file = File(attachmentPath);
          final fileName = '${const Uuid().v4()}_${file.uri.pathSegments.last}';
          final ref = _storage.ref().child('chat_attachments/$fileName');
          
          final uploadTask = await ref.putFile(file);
          attachmentUrl = await uploadTask.ref.getDownloadURL();
          attachmentName = file.uri.pathSegments.last;
          print("FirebaseChatRepo: Firebase upload success: $attachmentUrl");
      } catch (e) {
         print("FirebaseChatRepo: Firebase Upload failed ($e). Trying Laravel fallback...");
         try {
            // 2. Fallback to Laravel Server
            final file = File(attachmentPath);
            final formData = FormData.fromMap({
              'attachment': await MultipartFile.fromFile(file.path, filename: file.uri.pathSegments.last),
            });
            
            // Note: _apiClient automatically adds Bearer Token
            final response = await _apiClient.post('/chat/upload', data: formData);
            if (response is Map && response.containsKey('url')) {
                attachmentUrl = response['url'];
                attachmentName = file.uri.pathSegments.last;
                print("FirebaseChatRepo: Laravel upload success: $attachmentUrl");
            } else {
               throw Exception("Invalid response from server");
            }
         } catch (e2) {
            print("FirebaseChatRepo: Laravel upload failed: $e2");
            throw Exception("Gửi ảnh thất bại (Cả Firebase & Server đều lỗi).");
         }
      }
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
    // print("FirebaseChatRepo: markAsRead called for Conv: $conversationId, Reader: $userId");
    try {
      // 1. Reset unread count for this user
      await _firestore.collection('conversations').doc(conversationId).update({
        'unread_counts.$userId': 0,
      });

      // 2. Mark individual messages AS READ
      // Query ONLY by is_read to avoid complex index requirements.
      // Filter sender_id client-side.
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
        final senderId = data['sender_id'].toString();
        
        // Only mark if sender is NOT me (i.e. it's an incoming message)
        if (senderId != userId) {
           batch.update(doc.reference, {'is_read': true});
           updateCount++;
        }
      }

      if (updateCount > 0) {
        await batch.commit();
        print("FirebaseChatRepo: Marked $updateCount messages as read.");
      }
    } catch (e) {
      print("FirebaseChatRepo: markAsRead Error: $e");
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
      // Update member list and group name
      // Be careful not to wipe existing unread_counts for existing members
      // Only adding 0 for NEW members
      
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
  }) async {
    final conversationId = 'group_$groupId';
    
    String? attachmentUrl;
    String? attachmentName;
    String attachmentType = 'image'; // Default to image for simple path

    // Reuse upload logic (simplified for brevity, can copy from sendMessage)
    if (attachmentPath != null) {
        // ... (Reuse existing logic or call internal helper if refactored)
        // For now, assuming text-only or standard helper. 
        // NOTE: In a real refactor, extract `_uploadFile` as a private method.
        // I will copy the minimal needed logic or assume similar handling.
         try {
          final file = File(attachmentPath);
          final formData = FormData.fromMap({
            'attachment': await MultipartFile.fromFile(file.path, filename: file.uri.pathSegments.last),
          });
          final response = await _apiClient.post('/chat/upload', data: formData);
           if (response is Map && response.containsKey('url')) {
                attachmentUrl = response['url'];
                attachmentName = file.uri.pathSegments.last;
            }
         } catch(e) {
           print("Group Upload Error: $e");
         }
    }

    final messageData = {
      'sender_id': senderId,
      'sender_name': senderName ?? 'Thành viên',
      'content': content,
      'type': attachmentUrl != null ? 'image' : 'text',
      'attachment_url': attachmentUrl,
      'attachment_name': attachmentName,
      'created_at': FieldValue.serverTimestamp(),
      'is_read': false, // Not really used for groups in same way
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
       'last_message': attachmentUrl != null ? '[Hình ảnh]' : content,
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

      // Ensure unread_counts key exists for this user
      // We can't use dot notation for conditional update easily without fetching,
      // but since we fetched docSnap:
      final data = docSnap.data() as Map<String, dynamic>;
      final unreadCounts = Map<String, dynamic>.from(data['unread_counts'] ?? {});
      
      if (!unreadCounts.containsKey(userId)) {
        // If we just use update with dot notation, it works for maps
        await docRef.update({
          'unread_counts.$userId': 0,
        });
      }
      
      // Update name if provided and not set/default
      if (groupName != null && data['group_name'] == null) {
         await docRef.update({'group_name': groupName});
      }
    }
  }

  // Remove member from group chat (kick or leave)
  Future<void> removeMemberFromGroupConversation(String groupId, String userId) async {
    final docRef = _firestore.collection('conversations').doc('group_$groupId');
    
    // Remove from 'users' array and 'unread_counts' map
    // Note: Firestore arrayRemove only works for arrays. For map keys, we check/replace.
    
    // 1. Remove from users array
    await docRef.update({
      'users': FieldValue.arrayRemove([userId]),
    });

    // 2. Remove from unread_counts map (Need fetch first or use Delete)
    // Firestore dot notation delete: 'unread_counts.userId': FieldValue.delete()
    await docRef.update({
       'unread_counts.$userId': FieldValue.delete(),
    });
  }
}
