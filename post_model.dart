import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String username;
  final String title;
  final String description;
  final String category;
  final Timestamp createdAt;
  final Timestamp? editedAt;
  final bool isEdited;

  Post({
    required this.id,
    required this.userId,
    required this.username,
    required this.title,
    required this.description,
    required this.category,
    required this.createdAt,
    this.editedAt,
    this.isEdited = false,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      userId: data['userId'],
      username: data['username'],
      title: data['title'],
      description: data['description'],
      category: data['category'],
      createdAt: data['createdAt'],
      editedAt: data['editedAt'],
      isEdited: data['isEdited'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'username': username,
      'title': title,
      'description': description,
      'category': category,
      'createdAt': createdAt,
      'editedAt': editedAt,
      'isEdited': isEdited,
    };
  }
}