import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black.withOpacity(0.8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 40, bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
            ),
            child: Center(
              child: Text(
                'CHAT NEST',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildDrawerItem(
            context, 
            icon: Icons.group_add,
            title: 'Group Chat',
            onTap: () {
              // TODO: Implement Group Chat
            },
          ),
          _buildDrawerItem(
            context, 
            icon: Icons.map,
            title: 'Map Based Projects',
            onTap: () {
              // TODO: Implement Map Based Projects
            },
          ),
          _buildDrawerItem(
            context, 
            icon: Icons.assignment,
            title: 'My Applications',
            onTap: () {
              // TODO: Implement My Applications
            },
          ),
          _buildDrawerItem(
            context, 
            icon: Icons.inbox,
            title: 'Inbox',
            onTap: () {
              // TODO: Implement Inbox
            },
          ),
          _buildDrawerItem(
            context, 
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {
              // TODO: Implement Settings
            },
          ),
          const Spacer(),
          _buildDrawerItem(
            context, 
            icon: Icons.logout,
            title: 'Logout',
            onTap: () async {
              await FirebaseAuth.instance.signOut();
            },
            color: Colors.red,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(
        icon, 
        color: color ?? Colors.white,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.white,
        ),
      ),
      onTap: onTap,
    );
  }
}