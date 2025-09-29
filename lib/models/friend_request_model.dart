class FriendRequest {
  final String id;
  final String senderId;
  final String senderNickname;
  final String senderName;
  final String? senderPhotoUrl;
  final String receiverId;
  final String receiverNickname;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.senderNickname,
    required this.senderName,
    this.senderPhotoUrl,
    required this.receiverId,
    required this.receiverNickname,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  factory FriendRequest.fromMap(Map<String, dynamic> map) {
    return FriendRequest(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      senderNickname: map['senderNickname'] ?? '',
      senderName: map['senderName'] ?? '',
      senderPhotoUrl: map['senderPhotoUrl'],
      receiverId: map['receiverId'] ?? '',
      receiverNickname: map['receiverNickname'] ?? '',
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.toString() == 'FriendRequestStatus.${map['status']}',
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      respondedAt: map['respondedAt'] != null
          ? DateTime.parse(map['respondedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderNickname': senderNickname,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'receiverId': receiverId,
      'receiverNickname': receiverNickname,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
    };
  }

  FriendRequest copyWith({
    String? id,
    String? senderId,
    String? senderNickname,
    String? senderName,
    String? senderPhotoUrl,
    String? receiverId,
    String? receiverNickname,
    FriendRequestStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return FriendRequest(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderNickname: senderNickname ?? this.senderNickname,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      receiverId: receiverId ?? this.receiverId,
      receiverNickname: receiverNickname ?? this.receiverNickname,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}

enum FriendRequestStatus {
  pending,
  accepted,
  declined,
  blocked,
}
