import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLogin = true; // Tracks whether the app is in login mode or register mode

  bool get isLogin => _isLogin; // Getter to access the current mode

  void toggleAuthMode() {
    _isLogin = !_isLogin; // Toggle between login and register modes
    notifyListeners(); // Notify listeners to rebuild the UI
  }
}