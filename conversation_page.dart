import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:version2/profile_page.dart';

// New animated background that looks like oil on water
class OilWaterBackground extends StatefulWidget {
  const OilWaterBackground({super.key});

  @override
  State<OilWaterBackground> createState() => _OilWaterBackgroundState();
}

class _OilWaterBackgroundState extends State<OilWaterBackground> with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late Animation<double> _animation1;
  late Animation<double> _animation2;

  @override
  void initState() {
    super.initState();
    
    _controller1 = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat(reverse: true);
    
    _controller2 = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation1 = Tween<double>(begin: -100, end: 100).animate(_controller1);
    _animation2 = Tween<double>(begin: 100, end: -100).animate(_controller2);
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller1, _controller2]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black,
            gradient: RadialGradient(
              center: Alignment(_animation1.value / 200, _animation2.value / 200),
              radius: 1.8,
              colors: const [
                Color(0xFF101010),
                Color(0xFF050505),
              ],
            ),
          ),
          child: CustomPaint(
            painter: OilDropsPainter(
              animation1: _animation1.value,
              animation2: _animation2.value,
            ),
            size: MediaQuery.of(context).size,
          ),
        );
      },
    );
  }
}

class OilDropsPainter extends CustomPainter {
  final double animation1;
  final double animation2;

  OilDropsPainter({required this.animation1, required this.animation2});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    // Create oil-like circles with different gradients
    for (int i = 0; i < 15; i++) {
      final radius = (30 + i * 15 + animation1 / 5) % 200;
      final x = (size.width / 2) + animation1 * (i % 3) / 10;
      final y = (size.height / 2) + animation2 * ((i + 1) % 3) / 10;
      
      final gradient = RadialGradient(
        center: const Alignment(0.2, 0.2),
        radius: 1.0,
        colors: [
          const Color(0xFF1A237E).withOpacity(0.1 + (i % 5) * 0.02),
          const Color(0xFF000000).withOpacity(0.05),
        ],
      );
      
      paint.shader = gradient.createShader(
        Rect.fromCircle(center: Offset(x, y), radius: radius),
      );
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
    
    // Add more subtle oil-like patterns
    for (int i = 0; i < 10; i++) {
      final radius = (20 + i * 25 - animation2 / 10) % 150;
      final x = (size.width / 3) - animation2 * (i % 4) / 15;
      final y = (size.height / 4 * 3) - animation1 * ((i + 2) % 4) / 15;
      
      final gradient = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 1.0,
        colors: [
          const Color(0xFF0D47A1).withOpacity(0.08 + (i % 3) * 0.01),
          const Color(0xFF000000).withOpacity(0.03),
        ],
      );
      
      paint.shader = gradient.createShader(
        Rect.fromCircle(center: Offset(x, y), radius: radius),
      );
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(OilDropsPainter oldDelegate) {
    return oldDelegate.animation1 != animation1 || oldDelegate.animation2 != animation2;
  }
}

class ConversationPage extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUsername;

  const ConversationPage({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUsername,
  });

  @override
  _ConversationPageState createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late Stream<QuerySnapshot> _messagesStream;
  bool _isLoading = true;
  String? _currentUserId;
  Message? _selectedMessage;
  Message? _replyMessage; // Added for reply functionality
  
  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid;
    _setupMessagesStream();
    _markConversationAsRead();
  }
  
  void _setupMessagesStream() {
    setState(() {
      _isLoading = true;
    });
    
    _messagesStream = _firestore
        .collection('conversations')
        .doc(widget.conversationId)
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
  
  Future<void> _markConversationAsRead() async {
    if (_currentUserId != null) {
      await _firestore
          .collection('conversations')
          .doc(widget.conversationId)
          .update({
        'unreadCount_$_currentUserId': 0,
      });
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
      // Create message document with reply data if applicable
      final messageData = {
        'senderId': _currentUserId,
        'content': message,
        'timestamp': timestamp,
        'isDeleted': false,
      };
      
      // Add reply information if replying to a message
      if (_replyMessage != null) {
        messageData['replyToId'] = _replyMessage!.id;
        messageData['replyToContent'] = _replyMessage!.content;
        messageData['replyToSenderId'] = _replyMessage!.senderId;
      }
      
      // Add message to the messages subcollection
      await _firestore
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .add(messageData);
      
      // Update conversation document with last message
      await _firestore
          .collection('conversations')
          .doc(widget.conversationId)
          .update({
        'lastMessage': message,
        'lastMessageTime': timestamp,
        'unreadCount_${widget.otherUserId}': FieldValue.increment(1),
      });
      
      // Clear reply message
      setState(() {
        _replyMessage = null;
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
  
  Future<void> _deleteMessage(String messageId) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .doc(messageId)
          .update({
        'isDeleted': true,
        'content': 'This message was deleted',
      });
      
      setState(() {
        _selectedMessage = null;
      });
    } catch (e) {
      print('Error deleting message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting message: $e')),
      );
    }
  }
  
  void _showMessageOptions(Message message) {
    if (message.senderId != _currentUserId) return;
    
    setState(() {
      _selectedMessage = _selectedMessage?.id == message.id ? null : message;
    });
  }
  
  void _replyToMessage(Message message) {
    setState(() {
      _replyMessage = message;
      _selectedMessage = null;
    });
    
    // Focus the text field
    FocusScope.of(context).requestFocus(FocusNode());
  }
  
  void _cancelReply() {
    setState(() {
      _replyMessage = null;
    });
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMessage = null;
        });
        // Hide keyboard when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // New oil-water effect background
            const OilWaterBackground(),
            
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
                        
                        // User avatar and name wrapped in InkWell to make tappable
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              // Navigate to profile page
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfilePage(
                                    userId: widget.otherUserId,
                                  ),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                // User circle avatar
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      widget.otherUsername[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.otherUsername,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Messages list
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 0,
              right: 0,
              bottom: 80, // Space for message input
              child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : StreamBuilder<QuerySnapshot>(
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
                      
                      final messages = snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return Message(
                          id: doc.id,
                          senderId: data['senderId'],
                          content: data['content'],
                          timestamp: data['timestamp'],
                          isDeleted: data['isDeleted'] ?? false,
                          replyToId: data['replyToId'],
                          replyToContent: data['replyToContent'],
                          replyToSenderId: data['replyToSenderId'],
                        );
                      }).toList();
                      
                      if (messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 60,
                                color: Colors.white.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Send a message to start the conversation',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      // Ensure we scroll to bottom when new messages arrive
                      Future.delayed(const Duration(milliseconds: 100), () {
                        _scrollToBottom();
                      });
                      
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isCurrentUser = message.senderId == _currentUserId;
                          
                          // Show date separator if needed
                          final showDateSeparator = index == 0 || 
                              !_isSameDay(
                                messages[index].timestamp.toDate(), 
                                messages[index - 1].timestamp.toDate()
                              );
                              
                          return Column(
                            children: [
                              if (showDateSeparator)
                                _buildDateSeparator(message.timestamp.toDate()),
                              GestureDetector(
                                onLongPress: () => _showMessageOptions(message),
                                onTap: () {
                                  setState(() {
                                    _selectedMessage = null;
                                  });
                                },
                                // Add swipe to reply functionality
                                child: Dismissible(
                                  key: Key(message.id),
                                  direction: DismissDirection.startToEnd,
                                  dismissThresholds: const {
                                    DismissDirection.startToEnd: 0.3,
                                  },
                                  confirmDismiss: (direction) async {
                                    if (direction == DismissDirection.startToEnd) {
                                      _replyToMessage(message);
                                      return false;
                                    }
                                    return false;
                                  },
                                  background: Container(
                                    color: Colors.blue.withOpacity(0.2),
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.only(left: 20),
                                    child: const Icon(
                                      Icons.reply,
                                      color: Colors.white,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          mainAxisAlignment: isCurrentUser
                                              ? MainAxisAlignment.end
                                              : MainAxisAlignment.start,
                                          children: [
                                            if (!isCurrentUser)
                                              Container(
                                                width: 32,
                                                height: 32,
                                                margin: const EdgeInsets.only(right: 8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.15),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    widget.otherUsername[0].toUpperCase(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            Flexible(
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(16),
                                                child: BackdropFilter(
                                                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 10,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: isCurrentUser
                                                          ? const Color.fromARGB(255, 9, 45, 75).withOpacity(0.6)
                                                          : Colors.black.withOpacity(0.4),
                                                      borderRadius: BorderRadius.circular(16),
                                                      border: Border.all(
                                                        color: Colors.white.withOpacity(0.1),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        // Show the replied message if there is one
                                                        if (message.replyToContent != null)
                                                          Container(
                                                            margin: const EdgeInsets.only(bottom: 8),
                                                            padding: const EdgeInsets.all(8),
                                                            decoration: BoxDecoration(
                                                              color: Colors.white.withOpacity(0.1),
                                                              borderRadius: BorderRadius.circular(8),
                                                              border: Border.all(
                                                                color: Colors.white.withOpacity(0.15),
                                                                width: 1,
                                                              ),
                                                            ),
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  message.replyToSenderId == _currentUserId ? 'You' : widget.otherUsername,
                                                                  style: TextStyle(
                                                                    color: Colors.white.withOpacity(0.8),
                                                                    fontSize: 12,
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                                ),
                                                                const SizedBox(height: 4),
                                                                Text(
                                                                  message.replyToContent!,
                                                                  style: TextStyle(
                                                                    color: Colors.white.withOpacity(0.6),
                                                                    fontSize: 13,
                                                                  ),
                                                                  maxLines: 2,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        Text(
                                                          message.content,
                                                          style: TextStyle(
                                                            color: Colors.white.withOpacity(
                                                              message.isDeleted ? 0.5 : 0.9,
                                                            ),
                                                            fontSize: 15,
                                                            fontStyle: message.isDeleted
                                                                ? FontStyle.italic
                                                                : FontStyle.normal,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          DateFormat('h:mm a').format(message.timestamp.toDate()),
                                                          style: TextStyle(
                                                            color: Colors.white.withOpacity(0.5),
                                                            fontSize: 10,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (isCurrentUser)
                                              Container(
                                                width: 32,
                                                height: 32,
                                                margin: const EdgeInsets.only(left: 8),
                                                decoration: const BoxDecoration(
                                                  color: Colors.transparent,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (_selectedMessage?.id == message.id && !message.isDeleted)
                                        Positioned(
                                          top: 0,
                                          right: isCurrentUser ? 40 : null,
                                          left: isCurrentUser ? null : 40,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.8),
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.3),
                                                  blurRadius: 10,
                                                  spreadRadius: 0,
                                                ),
                                              ],
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: Column(
                                                children: [
                                                  // Add reply option in the menu
                                                  InkWell(
                                                    onTap: () => _replyToMessage(message),
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 12, 
                                                        vertical: 8,
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.reply,
                                                            color: Colors.white.withOpacity(0.8),
                                                            size: 18,
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Text(
                                                            'Reply',
                                                            style: TextStyle(
                                                              color: Colors.white.withOpacity(0.8),
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  // Only show delete for own messages
                                                  if (message.senderId == _currentUserId)
                                                    InkWell(
                                                      onTap: () => _deleteMessage(message.id),
                                                      child: Padding(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 12, 
                                                          vertical: 8,
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons.delete_outline,
                                                              color: Colors.white.withOpacity(0.8),
                                                              size: 18,
                                                            ),
                                                            const SizedBox(width: 8),
                                                            Text(
                                                              'Delete',
                                                              style: TextStyle(
                                                                color: Colors.white.withOpacity(0.8),
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
            ),
            
            // Message input
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Reply preview
                      if (_replyMessage != null)
                        Container(
                          color: Colors.black.withOpacity(0.5),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Replying to ${_replyMessage!.senderId == _currentUserId ? 'yourself' : widget.otherUsername}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _replyMessage!.content,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: _cancelReply,
                                splashRadius: 20,
                              ),
                            ],
                          ),
                        ),
                      Container(
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
                                    // Force rebuild to update send button state
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
  
  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(date.year, date.month, date.day);
    
    String dateText;
    if (messageDate == DateTime(now.year, now.month, now.day)) {
      dateText = 'Today';
    } else if (messageDate == yesterday) {
      dateText = 'Yesterday';
    } else if (now.difference(messageDate).inDays < 7) {
      dateText = DateFormat('EEEE').format(date); // Day name
    } else {
      dateText = DateFormat('MMM d, yyyy').format(date);
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              dateText,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
  
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }
}

class Message {
  final String id;
  final String senderId;
  final String content;
  final Timestamp timestamp;
  final bool isDeleted;
  final String? replyToId;
  final String? replyToContent;
  final String? replyToSenderId;
  
  Message({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.isDeleted,
    this.replyToId,
    this.replyToContent,
    this.replyToSenderId,
  });
}