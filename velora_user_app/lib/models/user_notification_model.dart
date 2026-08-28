import 'package:cloud_firestore/cloud_firestore.dart';

class UserNotificationModel {
  final String id;
  final String notificationId;
  final String title;
  final String message;
  final String targetType;
  final String targetUserId;
  final bool isRead;
  final DateTime createdAt;

  const UserNotificationModel({
    required this.id,
    this.notificationId = '',
    required this.title,
    required this.message,
    this.targetType = 'all',
    this.targetUserId = '',
    this.isRead = false,
    required this.createdAt,
  });

  UserNotificationModel copyWith({
    String? id,
    String? notificationId,
    String? title,
    String? message,
    String? targetType,
    String? targetUserId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return UserNotificationModel(
      id: id ?? this.id,
      notificationId: notificationId ?? this.notificationId,
      title: title ?? this.title,
      message: message ?? this.message,
      targetType: targetType ?? this.targetType,
      targetUserId: targetUserId ?? this.targetUserId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'notificationId': notificationId,
      'title': title,
      'message': message,
      'targetType': targetType,
      'targetUserId': targetUserId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserNotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawId = doc.id;

    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return UserNotificationModel(
      id: rawId,
      notificationId: (data['notificationId'] ?? '').toString(),
      title: (data['title'] ?? 'Velora Notification').toString(),
      message: (data['message'] ?? data['body'] ?? '').toString(),
      targetType: (data['targetType'] ?? 'all').toString(),
      targetUserId: (data['targetUserId'] ?? '').toString(),
      isRead: data['isRead'] == true,
      createdAt: parseDate(data['createdAt']),
    );
  }
}
