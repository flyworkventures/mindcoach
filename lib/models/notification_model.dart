class NotificationModel {
  final int id;
  final int userId;
  final String type; // 'system_notification' or 'announcement'
  final String title;
  final String subtitle;
  final Map<String, dynamic> metadata;
  final String? sentTime;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.metadata,
    this.sentTime,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as int,
      userId: map['userId'] as int,
      type: map['type'] as String,
      title: map['title'] as String,
      subtitle: map['subtitle'] as String,
      metadata: map['metadata'] as Map<String, dynamic>? ?? {},
      sentTime: map['sentTime'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'subtitle': subtitle,
      'metadata': metadata,
      'sentTime': sentTime,
    };
  }
}

