import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider extends ChangeNotifier {
  String _username = '';
  String _description = '';
  int _followerCount = 0;
  int _projectCount = 0;
  bool _isLoading = true;

  String get username => _username;
  String get description => _description;
  int get followerCount => _followerCount;
  int get projectCount => _projectCount;
  bool get isLoading => _isLoading;

  Future<void> loadUserData(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        _username = data?['username'] ?? '';
        _description = data?['description'] ?? '';
        _followerCount = data?['followerCount'] ?? 0;
        _projectCount = data?['projectCount'] ?? 0;
      } else {
        _username = '';
        _description = '';
        _followerCount = 0;
        _projectCount = 0;
      }
    } catch (e) {
      print('Error loading user data: $e');
      _username = '';
      _description = '';
      _followerCount = 0;
      _projectCount = 0;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setUsername(String username) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'username': username,
        'email': user.email,
        'description': '',
        'followerCount': 0,
        'projectCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _username = username;
      notifyListeners();
    } catch (e) {
      print('Error setting username: $e');
      rethrow;
    }
  }
  
  Future<void> updateDescription(String description) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'description': description,
      });
      
      _description = description;
      notifyListeners();
    } catch (e) {
      print('Error updating description: $e');
      rethrow;
    }
  }
  
  Future<bool> incrementProjectCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'projectCount': FieldValue.increment(1),
      });
      
      _projectCount += 1;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error incrementing project count: $e');
      return false;
    }
  }
}