import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:version2/post_model.dart';

class PostProvider extends ChangeNotifier {
  List<Post> _posts = [];
  String _currentCategory = 'All';

  List<Post> get posts => _posts;
  String get currentCategory => _currentCategory;

  Future<void> fetchPosts() async {
    try {
      // Fetch all posts first
      final allPostsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .get();

      // Convert all posts to Post objects
      List<Post> allPosts = allPostsSnapshot.docs
          .map((doc) => Post.fromFirestore(doc))
          .toList();

      // Filter posts based on current category
      if (_currentCategory == 'All') {
        _posts = allPosts;
      } else {
        _posts = allPosts.where((post) => 
          post.category.toLowerCase() == _currentCategory.toLowerCase()
        ).toList();
      }
      
      // Debug print to verify posts
      print('Total posts: ${allPosts.length}');
      print('Filtered posts for category $currentCategory: ${_posts.length}');
      
      notifyListeners();
    } catch (e) {
      print('Error fetching posts: $e');
      _posts = []; // Ensure posts are cleared in case of error
      notifyListeners();
    }
  }

  Future<void> createPost({
    required String title,
    required String description,
    required String category,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final postRef = FirebaseFirestore.instance.collection('posts').doc();
      final post = Post(
        id: postRef.id,
        userId: user.uid,
        username: user.displayName ?? user.email?.split('@').first ?? 'User',
        title: title,
        description: description,
        category: category,
        createdAt: Timestamp.now(),
      );

      await postRef.set(post.toFirestore());
      
      // Refresh posts in the current category
      await fetchPosts();
    } catch (e) {
      print('Error creating post: $e');
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      // Delete the post document
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
      
      // Remove the post from the local list
      _posts.removeWhere((post) => post.id == postId);
      
      notifyListeners();
    } catch (e) {
      print('Error deleting post: $e');
    }
  }

  void setCategory(String category) {
    _currentCategory = category;
    fetchPosts(); // This ensures posts are fetched with the new category
  }
}