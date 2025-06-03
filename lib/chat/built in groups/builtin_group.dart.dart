class BuiltInGroup {
  final String id;
  final String name;
  final String description;
  final String diseaseType;

  BuiltInGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.diseaseType,
  });

  factory BuiltInGroup.fromJson(Map<String, dynamic> json) {
    return BuiltInGroup(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      diseaseType: json['disease_type'],
    );
  }
}

class BuiltInGroupMessage {
  final String id;
  final String groupId;
  final String? userId;
  final String content;
  final DateTime createdAt;

  BuiltInGroupMessage({
    required this.id,
    required this.groupId,
    this.userId,
    required this.content,
    required this.createdAt,
  });

  factory BuiltInGroupMessage.fromJson(Map<String, dynamic> json) {
    return BuiltInGroupMessage(
      id: json['id'],
      groupId: json['group_id'],
      userId: json['user_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}