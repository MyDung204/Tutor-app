import 'package:doantotnghiep/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(apiClientProvider));
});

class ChatRepository {
  final ApiClient _client;

  ChatRepository(this._client);

  Future<List<dynamic>> getConversations() async {
    try {
      final response = await _client.get('/conversations');
      if (response is List) {
        return response;
      }
      return [];
    } catch (e) {
      print('Error fetching conversations: $e');
      return [];
    }
  }

  Future<List<dynamic>> getMessages(int conversationId) async {
    try {
      final response = await _client.get('/conversations/$conversationId/messages');
      if (response is List) {
        return response;
      }
      return [];
    } catch (e) {
      print('Error fetching messages: $e');
      return [];
    }
  }

  Future<dynamic> sendMessage({
    int? conversationId, 
    int? receiverId, 
    String? content,
    String? originalPath, // Path to file
    String? mimeType, // 'image' or 'file' for logic check, actual mime in MultipartFile
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (content != null) data['content'] = content;
      if (conversationId != null) data['conversation_id'] = conversationId;
      if (receiverId != null) data['receiver_id'] = receiverId;

      FormData formData = FormData.fromMap(data);

      if (originalPath != null) {
        formData.files.add(MapEntry(
          'attachment',
          await MultipartFile.fromFile(originalPath),
        ));
      }
      
      final response = await _client.post('/messages', data: formData);
      return response;
    } catch (e) {
      print('Error sending message: $e');
      return null;
    }
  }

  // Helper to find conversation ID by partner ID from list
  Future<int?> findConversationId(String partnerId) async {
    final convs = await getConversations();
    for (var c in convs) {
      // partner object inside conversation
      final partner = c['partner'];
      if (partner != null && partner['id'].toString() == partnerId) {
        return c['id'];
      }
    }
    return null;
  }
}
