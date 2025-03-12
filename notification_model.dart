// Create a new file called notification_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Notification {
  final String id;
  final String userId;
  final String recipientId;
  final String type; // follow, application_received, application_accepted, application_rejected
  final String content;
  final Timestamp timestamp;
  final bool isRead;
  final Map<String, dynamic> data; // Additional data related to the notification

  Notification({
    required this.id,
    required this.userId,
    required this.recipientId,
    required this.type,
    required this.content,
    required this.timestamp,
    required this.isRead,
    required this.data,
  });

  factory Notification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Notification(
      id: doc.id,
      userId: data['userId'] ?? '',
      recipientId: data['recipientId'] ?? '',
      type: data['type'] ?? '',
      content: data['content'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      isRead: data['isRead'] ?? false,
      data: data['data'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'recipientId': recipientId,
      'type': type,
      'content': content,
      'timestamp': timestamp,
      'isRead': isRead,
      'data': data,
    };
  }
}
