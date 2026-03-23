import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/chat.dart';
import '../utils/api_config.dart';
import 'api_client.dart';

class ChatService {
  final Dio _dio = ApiClient().dio;

  Future<List<ChatContact>> fetchContacts() async {
    final response = await _dio.get('/chat/contacts');
    final data = response.data as List<dynamic>;
    return data.map((row) => ChatContact.fromJson(row as Map<String, dynamic>)).toList();
  }

  Future<List<ChatMessage>> fetchMessages(int userId) async {
    final response = await _dio.get('/chat/messages/$userId');
    final data = response.data as List<dynamic>;
    return data.map((row) => ChatMessage.fromJson(row as Map<String, dynamic>)).toList();
  }

  Future<ChatMessage> sendMessage(int recipientId, String content, {String? clientMessageId}) async {
    final response = await _dio.post('/chat/messages', data: {
      'recipient_id': recipientId,
      'content': content,
      if (clientMessageId != null) 'client_message_id': clientMessageId,
    });
    return ChatMessage.fromJson(response.data as Map<String, dynamic>);
  }

  WebSocketChannel connectSocket({required String token}) {
    final uri = Uri.parse('$wsBaseUrl/chat/ws?token=${Uri.encodeComponent(token)}');
    return WebSocketChannel.connect(uri);
  }

  Map<String, dynamic> encodeSocketMessage({
    required int recipientId,
    required String content,
    String? clientMessageId,
  }) {
    return {
      'recipient_id': recipientId,
      'content': content,
      if (clientMessageId != null) 'client_message_id': clientMessageId,
    };
  }

  Map<String, dynamic> decodeSocketEvent(dynamic payload) {
    if (payload is String) {
      return jsonDecode(payload) as Map<String, dynamic>;
    }
    if (payload is List<int>) {
      final text = utf8.decode(payload);
      return jsonDecode(text) as Map<String, dynamic>;
    }
    return payload as Map<String, dynamic>;
  }
}
