import 'package:flutter/material.dart';
import 'package:version2/HomepageBackground.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:version2/conversation_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        print('DEBUG: Current user ID is null');
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      print('DEBUG: Current user ID: $currentUserId');

      // Get all conversations where the current user is a participant
      print('DEBUG: Querying conversations for user: $currentUserId');
      final querySnapshot = await _firestore
          .collection('conversations')
          .where('participants', arrayContains: currentUserId)
          .orderBy('lastMessageTime', descending: true)
          .get();
      
      print('DEBUG: Found ${querySnapshot.docs.length} conversations');

      final List<Map<String, dynamic>> conversations = [];
      
      for (var doc in querySnapshot.docs) {
        print('DEBUG: Processing conversation document: ${doc.id}');
        final data = doc.data();
        final participantIds = List<String>.from(data['participants'] ?? []);
        
        print('DEBUG: Participants: $participantIds');
        
        // Filter out the current user to get the other participant
        final otherUserId = participantIds.firstWhere(
          (id) => id != currentUserId,
          orElse: () => '',
        );
        
        print('DEBUG: Other user ID: $otherUserId');
        
        if (otherUserId.isNotEmpty) {
          try {
            // Get the other user's info
            print('DEBUG: Fetching user info for: $otherUserId');
            final userDoc = await _firestore.collection('users').doc(otherUserId).get();
            
            if (!userDoc.exists) {
              print('DEBUG: User document does not exist for ID: $otherUserId');
              continue;
            }
            
            final userData = userDoc.data() ?? {};
            print('DEBUG: User data: $userData');
            
            conversations.add({
              'id': doc.id,
              'otherUserId': otherUserId,
              'otherUsername': userData['username'] ?? 'Unknown User',
              'lastMessage': data['lastMessage'] ?? '',
              'lastMessageTime': data['lastMessageTime'] ?? Timestamp.now(),
              'unreadCount': data['unreadCount_$currentUserId'] ?? 0,
            });
            
            print('DEBUG: Added conversation to list');
          } catch (userError) {
            print('DEBUG: Error fetching user data: $userError');
          }
        } else {
          print('DEBUG: Could not determine other user ID');
        }
      }

      print('DEBUG: Final conversations list size: ${conversations.length}');
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      print('DEBUG: Error loading conversations: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (DragEndDetails details) {
        if (details.primaryVelocity! < 0) {
          // Swiped left -> go back to home page
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            const HomePageBackground(),
            
            // Blurred App bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top,
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const Expanded(
                          child: Text(
                            'MESSAGES',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: _loadConversations,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Content
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 0,
              right: 0,
              bottom: 0,
              child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _conversations.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 80,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No conversations yet',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Visit a user\'s profile to start a conversation',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : _buildConversationsList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildConversationsList() {
    return RefreshIndicator(
      onRefresh: _loadConversations,
      color: Colors.white,
      backgroundColor: Colors.black.withOpacity(0.4),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          final lastMessageTime = conversation['lastMessageTime'] as Timestamp;
          final timeAgo = _getTimeAgo(lastMessageTime.toDate());
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConversationPage(
                      conversationId: conversation['id'],
                      otherUserId: conversation['otherUserId'],
                      otherUsername: conversation['otherUsername'],
                    ),
                  ),
                ).then((_) => _loadConversations());
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // User circle avatar
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              conversation['otherUsername'][0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Conversation details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    conversation['otherUsername'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    timeAgo,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      conversation['lastMessage'].length > 30
                                        ? '${conversation['lastMessage'].substring(0, 30)}...'
                                        : conversation['lastMessage'],
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 14,
                                        fontWeight: conversation['unreadCount'] > 0
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (conversation['unreadCount'] > 0)
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.8),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        conversation['unreadCount'].toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      // Format as date
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      return '$day/$month';
    }
  }
}