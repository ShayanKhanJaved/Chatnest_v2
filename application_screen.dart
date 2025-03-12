import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'oil_animation_background.dart';
import 'post_model.dart';

class ApplicationScreen extends StatefulWidget {
  final Post post;

  const ApplicationScreen({super.key, required this.post});

  @override
  _ApplicationScreenState createState() => _ApplicationScreenState();
}

class _ApplicationScreenState extends State<ApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _applicationController = TextEditingController();
  bool _isSubmitting = false;
  bool _isCheckingApplication = true;
  bool _hasAlreadyApplied = false;

  @override
  void initState() {
    super.initState();
    _checkExistingApplication();
  }

  Future<void> _checkExistingApplication() async {
    setState(() {
      _isCheckingApplication = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return;
      }

      final applications = await FirebaseFirestore.instance
          .collection('applications')
          .where('applicantId', isEqualTo: currentUser.uid)
          .where('postId', isEqualTo: widget.post.id)
          .limit(1)
          .get();

      setState(() {
        _hasAlreadyApplied = applications.docs.isNotEmpty;
      });
    } catch (e) {
      print('Error checking existing application: $e');
    } finally {
      setState(() {
        _isCheckingApplication = false;
      });
    }
  }

  @override
  void dispose() {
    _applicationController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You need to be logged in to apply')),
        );
        return;
      }

      // Check again if user has already applied
      final existingApplications = await FirebaseFirestore.instance
          .collection('applications')
          .where('applicantId', isEqualTo: currentUser.uid)
          .where('postId', isEqualTo: widget.post.id)
          .limit(1)
          .get();

      if (existingApplications.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already applied to this post'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _hasAlreadyApplied = true;
        });
        return;
      }

      // Get current user's username
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final String applicantUsername = userDoc.data()?['username'] ?? 'Unknown User';

      // Create application document in Firestore
      await FirebaseFirestore.instance.collection('applications').add({
        'postId': widget.post.id,
        'postTitle': widget.post.title,
        'postOwnerId': widget.post.userId,
        'postOwnerUsername': widget.post.username,
        'applicantId': currentUser.uid,
        'applicantUsername': applicantUsername,
        'message': _applicationController.text.trim(),
        'status': 'pending', // Initially pending
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application sent successfully!')),
      );

      // Navigate back to homepage
      Navigator.pop(context);
    } catch (e) {
      print('Error submitting application: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send application: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get first 10 characters of title or the full title if shorter
    final truncatedTitle = widget.post.title.length > 10
        ? '${widget.post.title.substring(0, 10)}...'
        : widget.post.title;

    if (_isCheckingApplication) {
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
          title: const Text('Application', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Stack(
          children: [
            const OilAnimationBackground(),
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_hasAlreadyApplied) {
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
          title: const Text('Application', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Stack(
          children: [
            const OilAnimationBackground(),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.amber,
                            size: 70,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Already Applied',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'You have already submitted an application for this post. You can view your application status in the Applications tab.',
                            style: TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('GO BACK'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

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
        title: const Text('Application', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const OilAnimationBackground(),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'To: ${widget.post.username}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  truncatedTitle,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Why do you want to join this project?',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  child: TextFormField(
                                    controller: _applicationController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'Write your application here...',
                                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.all(16),
                                    ),
                                    maxLines: 5,
                                    maxLength: 200,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please explain why you want to join';
                                      }
                                      if (value.length < 10) {
                                        return 'Your application is too short';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitApplication,
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.black,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : const Text('SEND APPLICATION'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}