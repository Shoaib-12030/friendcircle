enum MessageType {
  text,
  image,
  system,
  expense,
  event,
}

class Message {
  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final List<String>? attachments;
  final Map<String, dynamic>? metadata;
  final String? replyToId;
  final bool isEdited;

  Message({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    required this.timestamp,
    this.attachments,
    this.metadata,
    this.replyToId,
    this.isEdited = false,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] ?? '',
      groupId: map['groupId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      content: map['content'] ?? '',
      type: MessageType.values[map['type'] ?? 0],
      timestamp: DateTime.parse(map['timestamp']),
      attachments: map['attachments'] != null
          ? List<String>.from(map['attachments'])
          : null,
      metadata: map['metadata'],
      replyToId: map['replyToId'],
      isEdited: map['isEdited'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type.index,
      'timestamp': timestamp.toIso8601String(),
      'attachments': attachments,
      'metadata': metadata,
      'replyToId': replyToId,
      'isEdited': isEdited,
    };
  }

  static Message createSystemMessage({
    required String groupId,
    required String content,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      groupId: groupId,
      senderId: 'system',
      senderName: 'System',
      content: content,
      type: MessageType.system,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }

  Message copyWith({
    String? id,
    String? groupId,
    String? senderId,
    String? senderName,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
    String? replyToId,
    bool? isEdited,
  }) {
    return Message(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
      replyToId: replyToId ?? this.replyToId,
      isEdited: isEdited ?? this.isEdited,
    );
  }
}