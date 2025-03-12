import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';
import 'auth_provider.dart' as local_auth_provider;
import 'login_screen.dart';
import 'register_screen.dart';
import 'username_setup_screen.dart';
import 'home_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<local_auth_provider.AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            return authProvider.isLogin ? const LoginScreen() : const RegisterScreen();
          }

          // Load user data when authenticated
          userProvider.loadUserData(user.uid);

          return const UserDataWrapper();
        }
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );
      },
    );
  }
}

class UserDataWrapper extends StatelessWidget {
  const UserDataWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    if (userProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // If username is not set, show username setup screen
    if (userProvider.username.isEmpty) {
      return const UsernameSetupScreen();
    }

    // Otherwise show the home page
    return const HomePage();
  }
}