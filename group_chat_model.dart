
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupChat {
  final String id;
  final String title;
  final String postId;
  final String adminId;
  final String adminUsername;
  final List<String> memberIds;
  final List<Map<String, dynamic>> members;
  final DateTime createdAt;

  GroupChat({
    required this.id,
    required this.title,
    required this.postId,
    required this.adminId,
    required this.adminUsername,
    required this.memberIds,
    required this.members,
    required this.createdAt,
  });

  factory GroupChat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupChat(
      id: doc.id,
      title: data['title'] ?? 'Untitled Chat',
      postId: data['postId'] ?? '',
      adminId: data['adminId'] ?? '',
      adminUsername: data['adminUsername'] ?? 'Unknown',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      members: List<Map<String, dynamic>>.from(data['members'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'postId': postId,
      'adminId': adminId,
      'adminUsername': adminUsername,
      'memberIds': memberIds,
      'members': members,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}