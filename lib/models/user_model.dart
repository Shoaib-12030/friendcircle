class User {
  final String id;
  final String email;
  final String name;
  final String nickname;
  final String? photoUrl;
  final String? status;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime lastSeen;
  final bool isOnline;
  final List<String> friendIds;
  final List<String> groupIds;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.nickname,
    this.photoUrl,
    this.status,
    this.phoneNumber,
    required this.createdAt,
    required this.lastSeen,
    this.isOnline = false,
    this.friendIds = const [],
    this.groupIds = const [],
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      nickname: map['nickname'] ?? '',
      photoUrl: map['photoUrl'],
      status: map['status'],
      phoneNumber: map['phoneNumber'],
      createdAt: DateTime.parse(map['createdAt']),
      lastSeen: DateTime.parse(map['lastSeen']),
      isOnline: map['isOnline'] ?? false,
      friendIds: List<String>.from(map['friendIds'] ?? []),
      groupIds: List<String>.from(map['groupIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'nickname': nickname,
      'photoUrl': photoUrl,
      'status': status,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
      'lastSeen': lastSeen.toIso8601String(),
      'isOnline': isOnline,
      'friendIds': friendIds,
      'groupIds': groupIds,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? nickname,
    String? photoUrl,
    String? status,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? lastSeen,
    bool? isOnline,
    List<String>? friendIds,
    List<String>? groupIds,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      friendIds: friendIds ?? this.friendIds,
      groupIds: groupIds ?? this.groupIds,
    );
  }
}