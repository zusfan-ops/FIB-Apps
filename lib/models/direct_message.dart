import 'user.dart';

class DirectMessage {
  final int id;
  final int senderId;
  final int receiverId;
  final String? message;
  final String? attachmentUrl;
  final String? attachmentType;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  DirectMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.message,
    this.attachmentUrl,
    this.attachmentType,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory DirectMessage.fromJson(Map<String, dynamic> json) {
    return DirectMessage(
      id: json['id'] as int,
      senderId: json['sender_id'] as int,
      receiverId: json['receiver_id'] as int,
      message: json['message'] as String?,
      attachmentUrl: json['attachment_url'] as String?,
      attachmentType: json['attachment_type'] as String?,
      isRead: json['is_read'] == true || json['is_read'] == 1,
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'].toString()) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString()).toLocal()
          : DateTime.now(),
    );
  }
}

class ChatConversation {
  final User user;
  final DirectMessage? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;

  ChatConversation({
    required this.user,
    this.lastMessage,
    required this.unreadCount,
    required this.updatedAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      lastMessage: json['last_message'] != null
          ? DirectMessage.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString()).toLocal()
          : DateTime.now(),
    );
  }
}
