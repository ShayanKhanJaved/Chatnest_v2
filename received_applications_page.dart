import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'oil_animation_background.dart';

class ReceivedApplicationsPage extends StatefulWidget {
  const ReceivedApplicationsPage({super.key});

  @override
  _ReceivedApplicationsPageState createState() => _ReceivedApplicationsPageState();
}

class _ReceivedApplicationsPageState extends State<ReceivedApplicationsPage> {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
          style: IconButton.styleFrom(
            backgroundColor: Colors.transparent,
          ),
        ),
        title: const Text('Received Applications', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Oil animation background
          const OilAnimationBackground(),
          
          // Applications list
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('applications')
                .where('postOwnerId', isEqualTo: userId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading applications: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }
              
              final applications = snapshot.data?.docs ?? [];
              
              if (applications.isEmpty) {
                return const Center(
                  child: Text(
                    'You haven\'t received any applications yet',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: applications.length,
                itemBuilder: (context, index) {
                  final application = applications[index].data() as Map<String, dynamic>;
                  final applicationId = applications[index].id;
                  final status = application['status'] ?? 'pending';
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        application['postTitle'] ?? 'Untitled Post',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    _buildStatusBadge(status),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'From: ${application['applicantUsername'] ?? 'Unknown'}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    application['message'] ?? 'No message',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (status == 'pending')
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          _updateApplicationStatus(applicationId, 'rejected');
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        child: const Text('Reject'),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: () {
                                          _updateApplicationStatus(applicationId, 'accepted');
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.green,
                                        ),
                                        child: const Text('Accept'),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
  
  Future<void> _updateApplicationStatus(String applicationId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(applicationId)
          .update({'status': status});
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Application ${status == 'accepted' ? 'accepted' : 'rejected'}')),
      );
    } catch (e) {
      print('Error updating application status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update application: ${e.toString()}')),
      );
    }
  }
  
  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    String statusText;
    
    switch (status.toLowerCase()) {
      case 'accepted':
        badgeColor = Colors.green;
        statusText = 'Accepted';
        break;
      case 'rejected':
        badgeColor = Colors.red;
        statusText = 'Rejected';
        break;
      case 'pending':
      default:
        badgeColor = Colors.amber;
        statusText = 'Pending';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}