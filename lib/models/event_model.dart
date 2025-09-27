class Event {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime startDate;
  final DateTime? endDate;
  final String groupId;
  final String createdBy;
  final List<String> attendeeIds;
  final List<String> maybeIds;
  final List<String> declinedIds;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startDate,
    this.endDate,
    required this.groupId,
    required this.createdBy,
    this.attendeeIds = const [],
    this.maybeIds = const [],
    this.declinedIds = const [],
    required this.createdAt,
    this.metadata,
  });

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      groupId: map['groupId'] ?? '',
      createdBy: map['createdBy'] ?? '',
      attendeeIds: List<String>.from(map['attendeeIds'] ?? []),
      maybeIds: List<String>.from(map['maybeIds'] ?? []),
      declinedIds: List<String>.from(map['declinedIds'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'groupId': groupId,
      'createdBy': createdBy,
      'attendeeIds': attendeeIds,
      'maybeIds': maybeIds,
      'declinedIds': declinedIds,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    String? groupId,
    String? createdBy,
    List<String>? attendeeIds,
    List<String>? maybeIds,
    List<String>? declinedIds,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      groupId: groupId ?? this.groupId,
      createdBy: createdBy ?? this.createdBy,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      maybeIds: maybeIds ?? this.maybeIds,
      declinedIds: declinedIds ?? this.declinedIds,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
}