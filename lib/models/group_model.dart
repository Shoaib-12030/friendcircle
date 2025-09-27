class Group {
  final String id;
  final String name;
  final String description;
  final String? photoUrl;
  final String createdBy;
  final List<String> adminIds;
  final List<String> memberIds;
  final DateTime createdAt;
  final String? inviteCode;

  Group({
    required this.id,
    required this.name,
    required this.description,
    this.photoUrl,
    required this.createdBy,
    required this.adminIds,
    required this.memberIds,
    required this.createdAt,
    this.inviteCode,
  });

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      photoUrl: map['photoUrl'],
      createdBy: map['createdBy'] ?? '',
      adminIds: List<String>.from(map['adminIds'] ?? []),
      memberIds: List<String>.from(map['memberIds'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
      inviteCode: map['inviteCode'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'photoUrl': photoUrl,
      'createdBy': createdBy,
      'adminIds': adminIds,
      'memberIds': memberIds,
      'createdAt': createdAt.toIso8601String(),
      'inviteCode': inviteCode,
    };
  }

  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? photoUrl,
    String? createdBy,
    List<String>? adminIds,
    List<String>? memberIds,
    DateTime? createdAt,
    String? inviteCode,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      createdBy: createdBy ?? this.createdBy,
      adminIds: adminIds ?? this.adminIds,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      inviteCode: inviteCode ?? this.inviteCode,
    );
  }
}