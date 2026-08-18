import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../models/direct_message.dart';
import '../models/user.dart';
import 'api_client.dart';

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  final ValueNotifier<int> totalUnreadNotifier = ValueNotifier<int>(0);

  /// Mengambil daftar seluruh thread obrolan aktif
  Future<List<ChatConversation>> getConversations() async {
    final res = await ApiClient.instance.get('/chats');
    if (res is List) {
      final list = res.map((item) => ChatConversation.fromJson(item as Map<String, dynamic>)).toList();
      // Hitung total unread
      final total = list.fold<int>(0, (sum, c) => sum + c.unreadCount);
      totalUnreadNotifier.value = total;
      return list;
    }
    return [];
  }

  /// Mengambil direktori mahasiswa FIB UNDIP untuk memulai chat baru
  Future<List<User>> getStudentDirectory({String? search, String? studyProgram, int page = 1}) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': '30',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (studyProgram != null && studyProgram.isNotEmpty && studyProgram != 'Semua Prodi')
        'study_program': studyProgram,
    };

    final uri = Uri(path: '/chats/directory', queryParameters: queryParams.isNotEmpty ? queryParams : null);
    final res = await ApiClient.instance.get(uri.toString());

    if (res is Map<String, dynamic> && res['data'] is List) {
      return (res['data'] as List)
          .map((item) => User.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Mengambil riwayat pesan antara user yang login dan recipient
  Future<Map<String, dynamic>> getChatHistory(int recipientId) async {
    final res = await ApiClient.instance.get('/chats/$recipientId');
    if (res is Map<String, dynamic>) {
      final recipient = User.fromJson(res['recipient'] as Map<String, dynamic>);
      final messagesList = (res['messages'] as List<dynamic>?) ?? [];
      final messages = messagesList
          .map((m) => DirectMessage.fromJson(m as Map<String, dynamic>))
          .toList();

      // Refresh total unread badge setelah membaca percakapan
      refreshUnreadCount();

      return {
        'recipient': recipient,
        'messages': messages,
      };
    }
    throw Exception('Gagal memuat pesan');
  }

  /// Mengirim pesan (teks dan/atau lampiran gambar)
  Future<DirectMessage> sendMessage({
    required int recipientId,
    String? message,
    Uint8List? imageBytes,
    String? filename,
  }) async {
    dynamic res;
    if (imageBytes != null) {
      try {
        // Coba upload multipart
        final fields = <String, String>{
          if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
          'attachment_type': 'image',
        };
        res = await ApiClient.instance.postMultipart(
          '/chats/$recipientId',
          fields: fields,
          fileField: 'attachment',
          fileBytes: imageBytes,
          filename: filename ?? 'chat_image.jpg',
        );
      } catch (_) {
        // Fallback Base64 Data URI
        final base64Image = 'data:image/jpeg;base64,${base64Encode(imageBytes)}';
        final payload = {
          if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
          'attachment_url': base64Image,
          'attachment_type': 'image',
        };
        res = await ApiClient.instance.post('/chats/$recipientId', payload);
      }
    } else {
      final payload = {
        'message': message?.trim() ?? '',
      };
      res = await ApiClient.instance.post('/chats/$recipientId', payload);
    }

    if (res is Map<String, dynamic>) {
      return DirectMessage.fromJson(res);
    }
    throw Exception('Format balasan pesan tidak valid');
  }

  /// Tandai pesan sebagai telah dibaca
  Future<void> markAsRead(int recipientId) async {
    try {
      await ApiClient.instance.post('/chats/$recipientId/read');
      refreshUnreadCount();
    } catch (_) {}
  }

  /// Refresh total badge pesan belum dibaca
  Future<int> refreshUnreadCount() async {
    try {
      final res = await ApiClient.instance.get('/chats/unread-count');
      if (res is Map<String, dynamic> && res['unread_count'] != null) {
        final count = (res['unread_count'] as num).toInt();
        totalUnreadNotifier.value = count;
        return count;
      }
    } catch (_) {}
    return totalUnreadNotifier.value;
  }
}
