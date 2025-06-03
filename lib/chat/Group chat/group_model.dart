
class Group {
  final String id;
  final String name;
  final String? createdBy;
  final DateTime createdAt;

  Group({
    required this.id,
    required this.name,
    this.createdBy,
    required this.createdAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final DateTime joinedAt;
  final ChatUser? user;

  GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.joinedAt,
    this.user,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      user: json['users'] != null
          ? ChatUser.fromJson(json['users'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}

class GroupMessage {
  final String id;
  final String groupId;
  final String senderId;
  final String content;
  final String messageType;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;
  final ChatUser? sender;

  GroupMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.content,
    this.messageType = 'text',
    required this.createdAt,
    this.updatedAt,
    this.metadata,
    this.sender,
  });

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    return GroupMessage(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      messageType: json['message_type'] as String? ?? 'text',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      sender: json['sender'] != null
          ? ChatUser.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'sender_id': senderId,
      'content': content,
      'message_type': messageType,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  bool get isText => messageType == 'text';
  bool get isImage => messageType == 'image';
  bool get isVideo => messageType == 'video';
  bool get isFile => messageType == 'file';
  bool get isSystem => messageType == 'system';
}

  class ChatUser {
  final String id;
  final String? username;
  final String? email;
  // avatarUrl removed as it doesn't exist in the database

  ChatUser({
  required this.id,
  this.username,
  this.email,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
  return ChatUser(
  id: json['id'] as String,
  username: json['username'] as String?,
  email: json['email'] as String?,
  // avatarUrl removed from constructor
  );
  }

  Map<String, dynamic> toJson() {
  return {
  'id': id,
  'username': username,
  'email': email,
  // avatarUrl removed from JSON serialization
  };
  }

  String get displayName => username ?? email?.split('@').first ?? 'Unknown';
  String get initials => displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'U';
  }
