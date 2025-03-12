import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:version2/HomepageBackground.dart';
import 'package:version2/create_post.dart';
import 'package:version2/post_model.dart';
import 'package:version2/chat_page.dart';
import 'package:version2/profile_page.dart';
import 'package:version2/search_page.dart';
import 'package:version2/application_status_page.dart';
import 'package:version2/application_screen.dart';
import 'package:version2/received_applications_page.dart'; // Import the received applications page
import 'post_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  final PageController _pageController = PageController(initialPage: 1);
  int _currentIndex = -1; // No default selection

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    
    // Fetch posts when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch posts
      Provider.of<PostProvider>(context, listen: false).fetchPosts();
    });
  }

  void _scrollListener() {
    setState(() {
      _isScrolled = _scrollController.offset > 50;
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // Handle special cases (chats, search, and profile)
    if (index == 0) {
      // Chat page with custom transition
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const ChatPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(-1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            
            // Return a SlideTransition
            return SlideTransition(position: offsetAnimation, child: child);
          },
        ),
      ).then((_) {
        // Reset current index after returning
        setState(() {
          _currentIndex = -1;
        });
      });
    } else if (index == 1) {
      // Inbox page with custom transition
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const ReceivedApplicationsPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: offsetAnimation, child: child),
            );
          },
        ),
      ).then((_) {
        // Reset current index after returning
        setState(() {
          _currentIndex = -1;
        });
      });
    } else if (index == 2) {
      // Search page with custom transition
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const SearchPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            
            // Fade + Slide transition
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: offsetAnimation, child: child),
            );
          },
        ),
      ).then((_) {
        // Reset current index after returning
        setState(() {
          _currentIndex = -1;
        });
      });
    } else if (index == 3) {
      // Application status page with custom transition
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const ApplicationStatusPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: offsetAnimation, child: child),
            );
          },
        ),
      ).then((_) {
        // Reset current index after returning
        setState(() {
          _currentIndex = -1;
        });
      });
    } else if (index == 4) {
      // Profile page with custom transition
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const ProfilePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            
            // Return a SlideTransition
            return SlideTransition(position: offsetAnimation, child: child);
          },
        ),
      ).then((_) {
        // Reset current index after returning
        setState(() {
          _currentIndex = -1;
        });
      });
    }
  }

  void _showCategoryFilter() {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.25,
        maxChildSize: 0.75,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: controller,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Filter Posts',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...['All', 'Web dev', 'App dev', 'Game dev', 'Art/literature', 'Others']
                  .map((category) => ListTile(
                        title: Text(
                          category,
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          // Use the PostProvider method to set category and filter
                          postProvider.setCategory(category);
                          Navigator.of(context).pop();
                        },
                      ))
                  ,
            ],
          ),
        ),
      ),
    );
  }

  // Show following options
  void _showFollowingOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Following',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Feature coming soon',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  // Show notifications
  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.75,
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
                  'Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 48,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No notifications yet',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Feature coming soon',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: GestureDetector(
        onHorizontalDragEnd: (DragEndDetails details) {
          if (details.primaryVelocity! > 0) {
            // Swiped right -> go to chat page with custom transition
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const ChatPage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(-1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOutCubic;
                  
                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);
                  
                  return SlideTransition(position: offsetAnimation, child: child);
                },
              ),
            );
          } else if (details.primaryVelocity! < 0) {
            // Swiped left -> go to profile page with custom transition
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const ProfilePage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOutCubic;
                  
                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);
                  
                  return SlideTransition(position: offsetAnimation, child: child);
                },
              ),
            );
          }
        },
        child: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              const HomePageBackground(),
    
              // Blurred App bar with improved glass effect
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    boxShadow: _isScrolled 
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5)
                          )
                        ]
                      : [],
                  ),
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: _isScrolled ? 15 : 10, 
                        sigmaY: _isScrolled ? 15 : 10
                      ),
                      child: Container(
                        color: _isScrolled 
                          ? Colors.black.withOpacity(0.4) 
                          : Colors.transparent,
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top,
                          left: 16,
                          right: 16,
                          bottom: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'CHAT NEST',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Row(
                              children: [
                                Consumer<PostProvider>(
                                  builder: (context, postProvider, child) {
                                    return Text(
                                      postProvider.currentCategory,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12
                                      ),
                                    );
                                  }
                                ),
                                // Following button
                                IconButton(
                                  icon: const Icon(Icons.people_outline, color: Colors.white),
                                  onPressed: _showFollowingOptions,
                                  tooltip: 'Following',
                                ),
                                // Notifications button
                                IconButton(
                                  icon: const Icon(Icons.notifications_none, color: Colors.white),
                                  onPressed: _showNotifications,
                                  tooltip: 'Notifications',
                                ),
                                // Filter button
                                IconButton(
                                  icon: const Icon(Icons.filter_list, color: Colors.white),
                                  onPressed: _showCategoryFilter,
                                  tooltip: 'Filter',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
    
              // Posts list
              Positioned(
                top: MediaQuery.of(context).padding.top + 70,
                left: 0,
                right: 0,
                bottom: kBottomNavigationBarHeight + 10, // Add space for bottom bar
                child: Consumer<PostProvider>(
                  builder: (context, postProvider, child) {
                    if (postProvider.posts.isEmpty) {
                      return Center(
                        child: Text(
                          'No posts available in ${postProvider.currentCategory} category',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: postProvider.posts.length,
                      itemBuilder: (context, index) {
                        final post = postProvider.posts[index];
                        return _PostCard(post: post);
                      },
                    );
                  },
                ),
              ),
    
              // Create Post Button
              Positioned(
                bottom: kBottomNavigationBarHeight + 16,
                right: 16,
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreatePostScreen(),
                        fullscreenDialog: true,
                      ),
                    ).then((_) {
                      // Refresh posts when returning from create post screen
                      Provider.of<PostProvider>(context, listen: false).fetchPosts();
                    });
                  },
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
              
              // Bottom Navigation Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      height: kBottomNavigationBarHeight,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavBarItem(Icons.chat, 0),
                          _buildNavBarItem(Icons.inbox, 1),
                          _buildNavBarItem(Icons.search, 2),
                          _buildNavBarItem(Icons.description, 3), // Application status icon
                          _buildNavBarItem(Icons.person, 4),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNavBarItem(IconData icon, int index) {
    final bool isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
          size: 24,
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Post post;

  const _PostCard({required this.post});

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

  void _showDeleteConfirmation(BuildContext context) {
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
              _deletePost(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deletePost(BuildContext context) {
    Provider.of<PostProvider>(context, listen: false).deletePost(post.id);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUserId == post.userId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
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
                      isOwner
                          ? ElevatedButton(
                              onPressed: () {
                                _showDeleteConfirmation(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.withOpacity(0.3), // Transparent dark red
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Delete'),
                            )
                          : StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('applications')
                                  .where('applicantId', isEqualTo: currentUserId)
                                  .where('postId', isEqualTo: post.id)
                                  .limit(1)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                // Show loading indicator while checking
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  );
                                }
                                
                                // Check if user has already applied
                                final hasApplied = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                                
                                if (hasApplied) {
                                  // User has already applied
                                  return ElevatedButton(
                                    onPressed: null, // Disable button
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey.withOpacity(0.2),
                                      foregroundColor: Colors.white.withOpacity(0.5),
                                    ),
                                    child: const Text('Applied'),
                                  );
                                } else {
                                  // User hasn't applied yet
                                  return ElevatedButton(
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
                                  );
                                }
                              },
                            ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
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
                      // Make username clickable
                      InkWell(
                        onTap: () {
                          // Check if this is the current user's post
                          if (isOwner) {
                            // Navigate to the profile page directly
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfilePage(),
                              ),
                            );
                          } else {
                            // Navigate to search page with the user's profile
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfilePage(userId: post.userId),
                              ),
                            );
                          }
                        },
                        child: Text(
                          post.username,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
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
          ],
        ),
      ),
    );
  }
}