import 'package:flutter/material.dart';
import 'package:version2/HomepageBackground.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:version2/post_model.dart';
import 'package:version2/user_provider.dart';
import 'package:version2/application_screen.dart';
import 'package:version2/post_provider.dart';
import 'package:version2/conversation_page.dart';

class ProfilePage extends StatefulWidget {
  final String? userId; // Optional - if null, show current user's profile
  
  const ProfilePage({super.key, this.userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _descriptionController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = true;
  String _username = '';
  String _description = '';
  int _followerCount = 0;
  int _projectCount = 0;
  List<Post> _userPosts = [];
  late String _userId;
  bool _isCurrentUserProfile = false;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _initializeProfile();
  }

  Future<void> _initializeProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    setState(() {
      // If userId is provided, use it, otherwise use current user's ID
      _userId = widget.userId ?? currentUser.uid;
      _isCurrentUserProfile = _userId == currentUser.uid;
      _isLoading = true;
    });
    
    await _loadUserProfile();
    await _loadUserPosts();
    await _checkFollowingStatus();
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _username = data['username'] ?? '';
          _description = data['description'] ?? 'No description available.';
          _followerCount = data['followerCount'] ?? 0;
          _projectCount = data['projectCount'] ?? 0;
          _descriptionController.text = _description;
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> _loadUserPosts() async {
    try {
      print('Loading posts for user: $_userId');
      final querySnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true)
          .get();

      if (mounted) {
        setState(() {
          _userPosts = querySnapshot.docs
              .map((doc) => Post.fromFirestore(doc))
              .toList();
          
          print('Loaded ${_userPosts.length} posts');
          // Update the project count based on actual posts
          _projectCount = _userPosts.length;
        });
      }
    } catch (e) {
      print('Error loading user posts: $e');
    }
  }

  Future<void> _checkFollowingStatus() async {
    if (_isCurrentUserProfile) return;
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    try {
      final followDoc = await FirebaseFirestore.instance
          .collection('followers')
          .doc(_userId)
          .collection('userFollowers')
          .doc(currentUser.uid)
          .get();
          
      setState(() {
        _isFollowing = followDoc.exists;
      });
    } catch (e) {
      print('Error checking follow status: $e');
    }
  }

  Future<void> _toggleFollow() async {
    if (_isCurrentUserProfile) return;
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final batch = FirebaseFirestore.instance.batch();
      final followersRef = FirebaseFirestore.instance
          .collection('followers')
          .doc(_userId)
          .collection('userFollowers')
          .doc(currentUser.uid);
          
      final followingRef = FirebaseFirestore.instance
          .collection('following')
          .doc(currentUser.uid)
          .collection('userFollowing')
          .doc(_userId);
      
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_userId);
      
      if (_isFollowing) {
        // Unfollow
        batch.delete(followersRef);
        batch.delete(followingRef);
        batch.update(userRef, {
          'followerCount': FieldValue.increment(-1)
        });
      } else {
        // Follow
        final currentUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        final currentUsername = currentUserDoc.data()?['username'] ?? '';
        
        batch.set(followersRef, {
          'userId': currentUser.uid,
          'username': currentUsername,
          'timestamp': FieldValue.serverTimestamp()
        });
        
        batch.set(followingRef, {
          'userId': _userId,
          'username': _username,
          'timestamp': FieldValue.serverTimestamp()
        });
        
        batch.update(userRef, {
          'followerCount': FieldValue.increment(1)
        });
      }
      
      await batch.commit();
      
      setState(() {
        _isFollowing = !_isFollowing;
        _followerCount = _isFollowing ? _followerCount + 1 : _followerCount - 1;
      });
      
    } catch (e) {
      print('Error toggling follow status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating follow status: $e'))
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showFollowersList() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('followers')
          .doc(_userId)
          .collection('userFollowers')
          .get();
          
      final followers = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': data['userId'] as String,
          'username': data['username'] as String,
        };
      }).toList();
      
      setState(() {
        _isLoading = false;
      });
      
      if (followers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No followers yet'))
        );
        return;
      }
      
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.8,
          builder: (_, controller) => Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Followers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: followers.length,
                    itemBuilder: (context, index) {
                      final follower = followers[index];
                      return ListTile(
                        title: Text(
                          follower['username'] as String,
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfilePage(userId: follower['userId'] as String),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error loading followers: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading followers: $e'))
      );
    }
  }

  Future<void> _saveDescription() async {
    if (_descriptionController.text.length > 160) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Description must be 160 characters or less')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .update({
        'description': _descriptionController.text,
      });

      setState(() {
        _description = _descriptionController.text;
        _isEditing = false;
      });
      
      // Refresh user data in provider
      await Provider.of<UserProvider>(context, listen: false).loadUserData(_userId);
      
    } catch (e) {
      print('Error saving description: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving description: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showDeleteConfirmation(BuildContext context, String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.8),
        title: const Text('Delete Post?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deletePost(context, postId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deletePost(BuildContext context, String postId) async {
    try {
      // Delete the post using FirebaseFirestore
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .delete();
          
      // Update the local posts list
      setState(() {
        _userPosts.removeWhere((post) => post.id == postId);
        _projectCount = _userPosts.length;
      });
      
      // If you're using a PostProvider, update it too
      try {
        final postProvider = Provider.of<PostProvider>(context, listen: false);
        postProvider.deletePost(postId);
      } catch (e) {
        print("Error updating post provider: $e");
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted successfully')),
      );
    } catch (e) {
      print('Error deleting post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting post: $e')),
      );
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (DragEndDetails details) {
        if (details.primaryVelocity! > 0) {
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
                        const Text(
                          'PROFILE',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
                : RefreshIndicator(
                    onRefresh: () async {
                      await _loadUserProfile();
                      await _loadUserPosts();
                      await _checkFollowingStatus();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile header
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Username
                                        Text(
                                          _username,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        
                                        // Stats row
                                        Row(
                                          children: [
                                            // Followers - Now clickable
                                            InkWell(
                                              onTap: () => _showFollowersList(),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    _followerCount.toString(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Followers',
                                                    style: TextStyle(
                                                      color: Colors.white.withOpacity(0.7),
                                                      fontSize: 12,
                                                      decoration: TextDecoration.underline,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            
                                            const SizedBox(width: 16),
                                            
                                            // Projects
                                            Column(
                                              children: [
                                                Text(
                                                  _projectCount.toString(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  'Projects',
                                                  style: TextStyle(
                                                    color: Colors.white.withOpacity(0.7),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 20),
                                    
                                    // Description
                                    _isEditing
                                      ? Column(
                                          children: [
                                            TextField(
                                              controller: _descriptionController,
                                              style: const TextStyle(color: Colors.white),
                                              maxLines: 3,
                                              maxLength: 160,
                                              decoration: InputDecoration(
                                                hintText: 'Enter your description...',
                                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                TextButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _isEditing = false;
                                                      _descriptionController.text = _description;
                                                    });
                                                  },
                                                  child: const Text('Cancel'),
                                                ),
                                                const SizedBox(width: 10),
                                                ElevatedButton(
                                                  onPressed: _saveDescription,
                                                  child: const Text('Save'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        )
                                      : Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _description,
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.9),
                                                fontSize: 16,
                                              ),
                                            ),
                                            if (_isCurrentUserProfile) ... [
                                              const SizedBox(height: 10),
                                              Align(
                                                alignment: Alignment.topRight,
                                                child: TextButton.icon(
                                                  icon: const Icon(Icons.edit, size: 16),
                                                  label: const Text('Edit'),
                                                  onPressed: () {
                                                    setState(() {
                                                      _isEditing = true;
                                                    });
                                                  },
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                    
                                    const SizedBox(height: 20),
                                    
                                    // Action buttons
                                    if (!_isCurrentUserProfile)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              icon: Icon(_isFollowing ? Icons.person_remove : Icons.person_add),
                                              label: Text(_isFollowing ? 'Unfollow' : 'Follow'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: _isFollowing 
                                                  ? Colors.red.withOpacity(0.3) 
                                                  : Colors.white.withOpacity(0.2),
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: _toggleFollow,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              icon: const Icon(Icons.message),
                                              label: const Text('Message'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color.fromARGB(255, 11, 56, 92).withOpacity(0.2),
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () async {
                                                final currentUser = FirebaseAuth.instance.currentUser;
                                                if (currentUser == null) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('You need to be logged in to send messages')),
                                                  );
                                                  return;
                                                }
                                                
                                                // Show loading indicator
                                                setState(() {
                                                  _isLoading = true;
                                                });
                                                
                                                try {
                                                  // Check if conversation already exists
                                                  final querySnapshot = await FirebaseFirestore.instance
                                                    .collection('conversations')
                                                    .where('participants', arrayContains: currentUser.uid)
                                                    .get();
                                                    
                                                  String? conversationId;
                                                  
                                                  // Find if there's already a conversation with this user
                                                  for (var doc in querySnapshot.docs) {
                                                    final participants = List<String>.from(doc.data()['participants'] ?? []);
                                                    if (participants.contains(_userId)) {
                                                      conversationId = doc.id;
                                                      break;
                                                    }
                                                  }
                                                  
                                                  // If no conversation exists, create one
                                                  if (conversationId == null) {
                                                    final docRef = await FirebaseFirestore.instance
                                                      .collection('conversations')
                                                      .add({
                                                        'participants': [currentUser.uid, _userId],
                                                        'lastMessage': '',
                                                        'lastMessageTime': Timestamp.now(),
                                                        'unreadCount_${currentUser.uid}': 0,
                                                        'unreadCount_$_userId': 0,
                                                      });
                                                      
                                                    conversationId = docRef.id;
                                                  }
                                                  
                                                  setState(() {
                                                    _isLoading = false;
                                                  });
                                                  
                                                  // Navigate to conversation page
                                                  if (!mounted) return;
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => ConversationPage(
                                                        conversationId: conversationId!,
                                                        otherUserId: _userId,
                                                        otherUsername: _username,
                                                      ),
                                                    ),
                                                  );
                                                } catch (e) {
                                                  setState(() {
                                                    _isLoading = false;
                                                  });
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Error starting conversation: $e')),
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Posts Section
                          const Text(
                            'POSTS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          const SizedBox(height: 10),
                          
                          // User posts
                          _userPosts.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    _isCurrentUserProfile
                                      ? 'You haven\'t created any posts yet'
                                      : 'This user hasn\'t created any posts yet',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _userPosts.length,
                                itemBuilder: (context, index) {
                                  final post = _userPosts[index];
                                  return _buildPostCard(post);
                                },
                              ),
                        ],
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPostCard(Post post) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUserId == post.userId;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      post.category,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  _isCurrentUserProfile || isOwner
                    ? ElevatedButton(
                        onPressed: () {
                          _showDeleteConfirmation(context, post.id);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.3),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Delete'),
                      )
                    : ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ApplicationScreen(post: post),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Join'),
                      ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                post.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                post.description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getTimeDifference(post.createdAt),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    post.username,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (post.isEdited)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Edited',
                    style: TextStyle(
                      color: Colors.grey.withOpacity(0.7),
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getTimeDifference(Timestamp timestamp) {
    final now = DateTime.now();
    final postTime = timestamp.toDate();
    final difference = now.difference(postTime);

    if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}