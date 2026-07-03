class NotificationModel {
  final int id;
  final int userId;
  final String type; // 'system_notification' or 'announcement'
  final String category; // realtime, therapy, analysis, reengagement, subscription, system
  final String title;
  final String subtitle;
  final String? deepLink;
  final Map<String, dynamic> metadata;
  final bool isRead;
  final String? sentTime;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    this.category = 'system',
    required this.title,
    required this.subtitle,
    this.deepLink,
    required this.metadata,
    this.isRead = false,
    this.sentTime,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    final meta = map['metadata'] as Map<String, dynamic>? ?? {};
    return NotificationModel(
      id: map['id'] as int,
      userId: map['userId'] as int,
      type: map['type'] as String,
      category: (map['category'] as String?) ?? 'system',
      title: map['title'] as String,
      subtitle: map['subtitle'] as String,
      deepLink: (map['deepLink'] as String?) ?? (meta['deepLink'] as String?),
      metadata: meta,
      isRead: map['isRead'] == true,
      sentTime: map['sentTime'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'category': category,
      'title': title,
      'subtitle': subtitle,
      'deepLink': deepLink,
      'metadata': metadata,
      'isRead': isRead,
      'sentTime': sentTime,
    };
  }
}

