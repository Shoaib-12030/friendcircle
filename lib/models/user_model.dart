class User {
  final String id;
  final String? firebaseUid; // Store Firebase UID separately
  final String email;
  final String name;
  final String nickname;
  final String? photoUrl;
  final String? status;
  final String? phoneNumber;
  final String? dateOfBirth;
  final String? gender;
  final String? address;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime lastSeen;
  final bool isOnline;
  final List<String> friendIds;
  final List<String> groupIds;

  User({
    required this.id,
    this.firebaseUid,
    required this.email,
    required this.name,
    required this.nickname,
    this.photoUrl,
    this.status,
    this.phoneNumber,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.isEmailVerified = false,
    required this.createdAt,
    required this.lastSeen,
    this.isOnline = false,
    this.friendIds = const [],
    this.groupIds = const [],
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      firebaseUid: map['firebaseUid'],
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      nickname: map['nickname'] ?? '',
      photoUrl: map['photoUrl'],
      status: map['status'],
      phoneNumber: map['phoneNumber'],
      dateOfBirth: map['dateOfBirth'],
      gender: map['gender'],
      address: map['address'],
      isEmailVerified: map['isEmailVerified'] ?? false,
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
      'firebaseUid': firebaseUid,
      'email': email,
      'name': name,
      'nickname': nickname,
      'photoUrl': photoUrl,
      'status': status,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'address': address,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt.toIso8601String(),
      'lastSeen': lastSeen.toIso8601String(),
      'isOnline': isOnline,
      'friendIds': friendIds,
      'groupIds': groupIds,
    };
  }

  User copyWith({
    String? id,
    String? firebaseUid,
    String? email,
    String? name,
    String? nickname,
    String? photoUrl,
    String? status,
    String? phoneNumber,
    String? dateOfBirth,
    String? gender,
    String? address,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? lastSeen,
    bool? isOnline,
    List<String>? friendIds,
    List<String>? groupIds,
  }) {
    return User(
      id: id ?? this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      email: email ?? this.email,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      friendIds: friendIds ?? this.friendIds,
      groupIds: groupIds ?? this.groupIds,
    );
  }
}
