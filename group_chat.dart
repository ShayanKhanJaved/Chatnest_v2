import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'group_chat_model.dart';
import 'oil_animation_background.dart';

class GroupChatPage extends StatefulWidget {
  final String groupChatId;
  final String groupTitle;

  const GroupChatPage({
    super.key,
    required this.groupChatId,
    required this.groupTitle,
  });

  @override
  _GroupChatPageState createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late Stream<QuerySnapshot> _messagesStream;
  bool _isLoading = true;
  String? _currentUserId;
  bool _isAdmin = false;
  bool _showMembersList = false;
  List<Map<String, dynamic>> _members = [];
  
  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid;
    _setupMessagesStream();
    _loadGroupChatDetails();
  }
  
  void _setupMessagesStream() {
    setState(() {
      _isLoading = true;
    });
    
    _messagesStream = _firestore
        .collection('groupChats')
        .doc(widget.groupChatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
        
    setState(() {
      _isLoading = false;
    });
    
    // Scroll to bottom when messages load
    Future.delayed(const Duration(milliseconds: 300), () {
      _scrollToBottom();
    });
  }
  
  Future<void> _loadGroupChatDetails() async {
    try {
      final docSnapshot = await _firestore
          .collection('groupChats')
          .doc(widget.groupChatId)
          .get();
      
      if (docSnapshot.exists) {
        final groupChat = GroupChat.fromFirestore(docSnapshot);
        setState(() {
          _isAdmin = groupChat.adminId == _currentUserId;
          _members = groupChat.members;
        });
      }
    } catch (e) {
      print('Error loading group chat details: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final message = _messageController.text.trim();
    _messageController.clear();
    
    // Focus on text field to keep keyboard open
    FocusScope.of(context).requestFocus(FocusNode());
    
    final timestamp = Timestamp.now();
    
    try {
      // Get current user info
      final userDoc = await _firestore.collection('users').doc(_currentUserId).get();
      final userData = userDoc.data() ?? {};
      final String username = userData['username'] ?? 'Unknown User';
      
      // Create message document
      await _firestore
          .collection('groupChats')
          .doc(widget.groupChatId)
          .collection('messages')
          .add({
        'senderId': _currentUserId,
        'senderUsername': username,
        'content': message,
        'timestamp': timestamp,
        'isAdmin': _isAdmin,
      });
      
      // Update group chat with last message
      await _firestore
          .collection('groupChats')
          .doc(widget.groupChatId)
          .update({
        'lastMessage': message,
        'lastMessageSender': username,
        'lastMessageTime': timestamp,
      });
      
      // Scroll to see the new message
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToBottom();
      });
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }
  
  Future<void> _kickMember(String memberId, String memberUsername) async {
    if (!_isAdmin || memberId == _currentUserId) return;
    
    // Show confirmation dialog
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text('Kick Member', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to remove $memberUsername from this group?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('REMOVE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirm) return;
    
    try {
      // Update group chat document
      final groupChatDoc = await _firestore
          .collection('groupChats')
          .doc(widget.groupChatId)
          .get();
      
      final groupChat = GroupChat.fromFirestore(groupChatDoc);
      
      // Remove member from lists
      final List<String> updatedMemberIds = groupChat.memberIds
          .where((id) => id != memberId)
          .toList();
          
      final List<Map<String, dynamic>> updatedMembers = groupChat.members
          .where((member) => member['id'] != memberId)
          .toList();
      
      // Update the document
      await _firestore
          .collection('groupChats')
          .doc(widget.groupChatId)
          .update({
        'memberIds': updatedMemberIds,
        'members': updatedMembers,
      });
      
      // Add system message about removal
      await _firestore
          .collection('groupChats')
          .doc(widget.groupChatId)
          .collection('messages')
          .add({
        'senderId': 'system',
        'senderUsername': 'System',
        'content': '$memberUsername has been removed from the group',
        'timestamp': Timestamp.now(),
        'isSystem': true,
      });
      
      // Refresh members list
      _loadGroupChatDetails();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$memberUsername has been removed from the group')),
      );
    } catch (e) {
      print('Error kicking member: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing member: $e')),
      );
    }
  }

  Future<void> _leaveGroup() async {
    if (_currentUserId == null) return;
    
    // If user is admin, show warning that leaving will delete the group
    if (_isAdmin) {
      final bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.black87,
          title: const Text('Leave Group', style: TextStyle(color: Colors.white)),
          content: const Text(
            'You are the admin of this group. Leaving will delete the group for everyone. Continue?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('LEAVE', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ) ?? false;
      
      if (!confirm) return;
      
      // Delete the group
      try {
        await _firestore.collection('groupChats').doc(widget.groupChatId).delete();
        // Pop back to chat page
        Navigator.of(context).pop();
      } catch (e) {
        print('Error deleting group: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error leaving group: $e')),
        );
      }
    } else {
      // Regular member leaving
      final bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.black87,
          title: const Text('Leave Group', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to leave this group?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('LEAVE', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ) ?? false;
      
      if (!confirm) return;
      
      try {
        // Get current group data
        final groupChatDoc = await _firestore
            .collection('groupChats')
            .doc(widget.groupChatId)
            .get();
        
        final groupChat = GroupChat.fromFirestore(groupChatDoc);
        
        // Remove user from lists
        final List<String> updatedMemberIds = groupChat.memberIds
            .where((id) => id != _currentUserId)
            .toList();
            
        final List<Map<String, dynamic>> updatedMembers = groupChat.members
            .where((member) => member['id'] != _currentUserId)
            .toList();
        
        // Update the document
        await _firestore
            .collection('groupChats')
            .doc(widget.groupChatId)
            .update({
          'memberIds': updatedMemberIds,
          'members': updatedMembers,
        });
        
        // Add system message about leaving
        final userDoc = await _firestore.collection('users').doc(_currentUserId).get();
        final userData = userDoc.data() ?? {};
        final String username = userData['username'] ?? 'Unknown User';
        
        await _firestore
            .collection('groupChats')
            .doc(widget.groupChatId)
            .collection('messages')
            .add({
          'senderId': 'system',
          'senderUsername': 'System',
          'content': '$username has left the group',
          'timestamp': Timestamp.now(),
          'isSystem': true,
        });
        
        // Pop back to chat page
        Navigator.of(context).pop();
      } catch (e) {
        print('Error leaving group: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error leaving group: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          const OilAnimationBackground(),
          
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
                      const SizedBox(width: 8),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.groupTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${_members.length} members',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Leave group button
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: _leaveGroup,
                        tooltip: 'Leave Group',
                      ),
                      
                      // Members list button
                      IconButton(
                        icon: Icon(
                          _showMembersList ? Icons.close : Icons.people,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _showMembersList = !_showMembersList;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Main content - either messages or members list
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: 0,
            right: 0,
            bottom: 80, // Space for input
            child: _showMembersList
                ? _buildMembersList()
                : _buildMessagesList(),
          ),
          
          // Message input - only show if not viewing members list
          if (!_showMembersList)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 12,
                      bottom: 12 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _messageController,
                              style: const TextStyle(color: Colors.white),
                              cursorColor: Colors.white,
                              maxLines: 4,
                              minLines: 1,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                border: InputBorder.none,
                              ),
                              onChanged: (value) {
                                setState(() {});
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: _messageController.text.trim().isEmpty
                                ? Colors.white.withOpacity(0.2)
                                : const Color.fromARGB(255, 11, 56, 92).withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: _messageController.text.trim().isEmpty
                                ? null
                                : _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildMembersList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _members.length,
        itemBuilder: (context, index) {
          final member = _members[index];
          final String memberId = member['id'] ?? '';
          final String username = member['username'] ?? 'Unknown User';
          final bool isAdmin = member['isAdmin'] ?? false;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: ListTile(
              title: Text(
                username,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                isAdmin ? 'Admin' : 'Member',
                style: TextStyle(
                  color: isAdmin
                      ? Colors.amber.withOpacity(0.8)
                      : Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              trailing: _isAdmin && !isAdmin && memberId != _currentUserId
                  ? IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      onPressed: () => _kickMember(memberId, username),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _messagesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading messages',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          );
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        
        final messages = snapshot.data!.docs;
        
        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white.withOpacity(0.4),
                  size: 70,
                ),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start a conversation!',
                  style: TextStyle(color: Colors.white.withOpacity(0.4)),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final messageData = messages[index].data() as Map<String, dynamic>;
            final String senderId = messageData['senderId'] ?? '';
            final String senderUsername = messageData['senderUsername'] ?? 'Unknown';
            final String content = messageData['content'] ?? '';
            final Timestamp timestamp = messageData['timestamp'] as Timestamp? ?? Timestamp.now();
            final bool isAdmin = messageData['isAdmin'] ?? false;
            final bool isSystem = messageData['isSystem'] ?? false;
            final bool isCurrentUser = senderId == _currentUserId;
            
            // Format timestamp
            final DateTime messageTime = timestamp.toDate();
            final String formattedTime = DateFormat('h:mm a').format(messageTime);
            
            // System message (join/leave notifications)
            if (isSystem) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        content,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return Align(
              alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                child: Column(
                  crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!isCurrentUser)
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              senderUsername,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isAdmin)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.amber.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  'ADMIN',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrentUser
                            ? const Color.fromARGB(255, 11, 56, 92).withOpacity(0.8)
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            content,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formattedTime,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}