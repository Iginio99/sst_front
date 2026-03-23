class ChatContact {
  final int id;
  final String email;
  final String name;
  final List<String> roles;

  ChatContact({
    required this.id,
    required this.email,
    required this.name,
    required this.roles,
  });

  factory ChatContact.fromJson(Map<String, dynamic> json) {
    return ChatContact(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String,
      roles: (json['roles'] as List<dynamic>).map((e) => e.toString()).toList(),
    );
  }
}

class ChatMessage {
  final int? id;
  final int senderId;
  final int recipientId;
  final String content;
  final DateTime createdAt;
  final String? senderName;
  final String? clientMessageId;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.createdAt,
    this.senderName,
    this.clientMessageId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int?,
      senderId: json['sender_id'] as int,
      recipientId: json['recipient_id'] as int,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      senderName: json['sender_name'] as String?,
      clientMessageId: json['client_message_id'] as String?,
    );
  }

  ChatMessage copyWith({
    int? id,
    DateTime? createdAt,
    String? senderName,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId,
      recipientId: recipientId,
      content: content,
      createdAt: createdAt ?? this.createdAt,
      senderName: senderName ?? this.senderName,
      clientMessageId: clientMessageId,
    );
  }
}
