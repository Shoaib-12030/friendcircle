class ChatRoom {
  final String id;
  final String type; // 'private' or 'group'
  final List<String> participantIds;
  final Map<String, String> participantNicknames;
  final String? groupName;
  final String? groupPhotoUrl;
  final String? groupDescription;
  final String? adminId;
  final Message? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, DateTime> lastReadAt; // participantId -> lastReadTime
  final Map<String, int> unreadCount; // participantId -> unread count
  final bool isActive;

  ChatRoom({
    required this.id,
    required this.type,
    required this.participantIds,
    required this.participantNicknames,
    this.groupName,
    this.groupPhotoUrl,
    this.groupDescription,
    this.adminId,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    this.lastReadAt = const {},
    this.unreadCount = const {},
    this.isActive = true,
  });

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['id'] ?? '',
      type: map['type'] ?? 'private',
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participantNicknames:
          Map<String, String>.from(map['participantNicknames'] ?? {}),
      groupName: map['groupName'],
      groupPhotoUrl: map['groupPhotoUrl'],
      groupDescription: map['groupDescription'],
      adminId: map['adminId'],
      lastMessage: map['lastMessage'] != null
          ? Message.fromMap(map['lastMessage'])
          : null,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      lastReadAt: (map['lastReadAt'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, DateTime.parse(value)),
          ) ??
          {},
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'participantIds': participantIds,
      'participantNicknames': participantNicknames,
      'groupName': groupName,
      'groupPhotoUrl': groupPhotoUrl,
      'groupDescription': groupDescription,
      'adminId': adminId,
      'lastMessage': lastMessage?.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastReadAt': lastReadAt
          .map((key, value) => MapEntry(key, value.toIso8601String())),
      'unreadCount': unreadCount,
      'isActive': isActive,
    };
  }

  ChatRoom copyWith({
    String? id,
    String? type,
    List<String>? participantIds,
    Map<String, String>? participantNicknames,
    String? groupName,
    String? groupPhotoUrl,
    String? groupDescription,
    String? adminId,
    Message? lastMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, DateTime>? lastReadAt,
    Map<String, int>? unreadCount,
    bool? isActive,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      type: type ?? this.type,
      participantIds: participantIds ?? this.participantIds,
      participantNicknames: participantNicknames ?? this.participantNicknames,
      groupName: groupName ?? this.groupName,
      groupPhotoUrl: groupPhotoUrl ?? this.groupPhotoUrl,
      groupDescription: groupDescription ?? this.groupDescription,
      adminId: adminId ?? this.adminId,
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isActive: isActive ?? this.isActive,
    );
  }
}

class Message {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String senderNickname;
  final MessageType type;
  final String? textContent;
  final String? mediaUrl;
  final String? mediaFileName;
  final String? thumbnailUrl;
  final double? mediaDuration; // for voice/video
  final LocationData? locationData;
  final String? stickerPackId;
  final String? stickerId;
  final Message? replyToMessage;
  final String encryptedContent; // Encrypted message content
  final String encryptionKeyId; // Reference to encryption key
  final MessageStatus status;
  final DateTime sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final bool isDeleted;
  final DateTime? deletedAt;
  final bool isEdited;
  final DateTime? editedAt;

  Message({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.senderNickname,
    required this.type,
    this.textContent,
    this.mediaUrl,
    this.mediaFileName,
    this.thumbnailUrl,
    this.mediaDuration,
    this.locationData,
    this.stickerPackId,
    this.stickerId,
    this.replyToMessage,
    required this.encryptedContent,
    required this.encryptionKeyId,
    required this.status,
    required this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.isDeleted = false,
    this.deletedAt,
    this.isEdited = false,
    this.editedAt,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] ?? '',
      chatRoomId: map['chatRoomId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderNickname: map['senderNickname'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${map['type']}',
        orElse: () => MessageType.text,
      ),
      textContent: map['textContent'],
      mediaUrl: map['mediaUrl'],
      mediaFileName: map['mediaFileName'],
      thumbnailUrl: map['thumbnailUrl'],
      mediaDuration: map['mediaDuration']?.toDouble(),
      locationData: map['locationData'] != null
          ? LocationData.fromMap(map['locationData'])
          : null,
      stickerPackId: map['stickerPackId'],
      stickerId: map['stickerId'],
      replyToMessage: map['replyToMessage'] != null
          ? Message.fromMap(map['replyToMessage'])
          : null,
      encryptedContent: map['encryptedContent'] ?? '',
      encryptionKeyId: map['encryptionKeyId'] ?? '',
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == 'MessageStatus.${map['status']}',
        orElse: () => MessageStatus.sent,
      ),
      sentAt: DateTime.parse(map['sentAt']),
      deliveredAt: map['deliveredAt'] != null
          ? DateTime.parse(map['deliveredAt'])
          : null,
      readAt: map['readAt'] != null ? DateTime.parse(map['readAt']) : null,
      isDeleted: map['isDeleted'] ?? false,
      deletedAt:
          map['deletedAt'] != null ? DateTime.parse(map['deletedAt']) : null,
      isEdited: map['isEdited'] ?? false,
      editedAt:
          map['editedAt'] != null ? DateTime.parse(map['editedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'senderNickname': senderNickname,
      'type': type.toString().split('.').last,
      'textContent': textContent,
      'mediaUrl': mediaUrl,
      'mediaFileName': mediaFileName,
      'thumbnailUrl': thumbnailUrl,
      'mediaDuration': mediaDuration,
      'locationData': locationData?.toMap(),
      'stickerPackId': stickerPackId,
      'stickerId': stickerId,
      'replyToMessage': replyToMessage?.toMap(),
      'encryptedContent': encryptedContent,
      'encryptionKeyId': encryptionKeyId,
      'status': status.toString().split('.').last,
      'sentAt': sentAt.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
      'isEdited': isEdited,
      'editedAt': editedAt?.toIso8601String(),
    };
  }
}

class LocationData {
  final double latitude;
  final double longitude;
  final String? address;
  final String? name;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    this.name,
  });

  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      address: map['address'],
      name: map['name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'name': name,
    };
  }
}

enum MessageType {
  text,
  image,
  video,
  voice,
  document,
  location,
  sticker,
  gif,
  contact,
  call, // For call logs
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}
