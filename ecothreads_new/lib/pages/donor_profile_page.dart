import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'messagedonor.dart';
import 'itemdetail.dart';

class DonorProfilePage extends StatefulWidget {
  final String donorId;
  final String donorName;

  const DonorProfilePage({
    Key? key,
    required this.donorId,
    required this.donorName,
  }) : super(key: key);

  @override
  State<DonorProfilePage> createState() => _DonorProfileState();
}

class _DonorProfileState extends State<DonorProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isSubscribed = false;

  // Add new state variables
  double _averageRating = 0.0;
  int _ratingCount = 0;
  bool _hasRated = false;

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
    _loadDonorRating();
    _checkIfUserHasRated();
  }

  Future<void> _checkSubscriptionStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('donor_subscriptions')
          .doc(widget.donorId)
          .get();

      if (mounted) {
        setState(() {
          _isSubscribed = doc.exists;
        });
      }
    } catch (e) {
      print('Error checking subscription status: $e');
    }
  }

  Future<void> _toggleNotifications() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to subscribe to notifications')),
      );
      return;
    }

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Reference to the subscription in both locations
      final userSubscriptionRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('donor_subscriptions')
          .doc(widget.donorId);

      final donorSubscriberRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.donorId)
          .collection('subscribers')
          .doc(currentUser.uid);

      // Reference to donor's document to track subscriber count
      final donorRef =
          FirebaseFirestore.instance.collection('users').doc(widget.donorId);

      if (_isSubscribed) {
        // Remove subscriptions
        batch.delete(userSubscriptionRef);
        batch.delete(donorSubscriberRef);
        // Decrement subscriber count
        batch.update(donorRef, {'subscriberCount': FieldValue.increment(-1)});
      } else {
        // Add subscriptions
        batch.set(userSubscriptionRef, {
          'donorId': widget.donorId,
          'donorName': widget.donorName,
          'subscribedAt': FieldValue.serverTimestamp(),
        });

        batch.set(donorSubscriberRef, {
          'userId': currentUser.uid,
          'userName': currentUser.displayName,
          'subscribedAt': FieldValue.serverTimestamp(),
        });

        // Increment subscriber count and check milestones
        final donorDoc = await donorRef.get();
        final currentCount = (donorDoc.data()?['subscriberCount'] ?? 0) as int;
        final newCount = currentCount + 1;

        batch.update(donorRef, {'subscriberCount': newCount});

        // Check if this is a milestone (multiple of 5)
        if (newCount % 5 == 0) {
          // Create milestone notification
          final notificationRef =
              FirebaseFirestore.instance.collection('notifications').doc();

          batch.set(notificationRef, {
            'userId': widget.donorId,
            'type': 'subscriber_milestone',
            'title': 'Subscriber Milestone! 🎉',
            'message': 'Congratulations! You now have $newCount subscribers',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }
      }

      await batch.commit();

      setState(() {
        _isSubscribed = !_isSubscribed;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSubscribed
              ? 'You will be notified when ${widget.donorName} posts new items'
              : 'Notifications turned off for ${widget.donorName}'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error toggling notifications: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating notification preferences')),
      );
    }
  }

  Future<Map<String, dynamic>> getDonorData() async {
    try {
      final userDoc =
          await _firestore.collection('users').doc(widget.donorId).get();
      final donationsSnapshot = await _firestore
          .collection('donations')
          .where('userId', isEqualTo: widget.donorId)
          .where('status', isEqualTo: 'available')
          .get();

      // Get subscribers count
      final subscribersSnapshot = await _firestore
          .collection('users')
          .doc(widget.donorId)
          .collection('subscribers')
          .get();

      return {
        'userData': userDoc.data() ?? {},
        'listings': donationsSnapshot.docs.map((doc) => doc.data()).toList(),
        'subscribersCount': subscribersSnapshot.docs.length,
      };
    } catch (e) {
      print('Error fetching donor data: $e');
      return {
        'userData': {},
        'listings': [],
        'subscribersCount': 0,
      };
    }
  }

  Future<void> _loadDonorRating() async {
    try {
      final ratingStats = await _firestore
          .collection('users')
          .doc(widget.donorId)
          .collection('rating_stats')
          .doc('stats')
          .get();

      if (mounted && ratingStats.exists) {
        setState(() {
          _averageRating = (ratingStats.data()?['average'] ?? 0.0).toDouble();
          _ratingCount = ratingStats.data()?['count'] ?? 0;
        });
      }
    } catch (e) {
      print('Error loading donor rating: $e');
    }
  }

  Future<void> _checkIfUserHasRated() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final rating = await _firestore
          .collection('users')
          .doc(widget.donorId)
          .collection('ratings')
          .doc(currentUser.uid)
          .get();

      if (mounted) {
        setState(() {
          _hasRated = rating.exists;
        });
      }
    } catch (e) {
      print('Error checking user rating: $e');
    }
  }

  void _showRatingDialog() {
    if (_hasRated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You have already rated this donor')),
      );
      return;
    }

    double selectedRating = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Rate ${widget.donorName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    icon: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      setState(() {
                        selectedRating = index + 1.0;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
              ),
              onPressed: selectedRating == 0
                  ? null
                  : () => _submitRating(selectedRating),
              child: Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRating(double rating) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final batch = _firestore.batch();

      // Add individual rating
      final ratingRef = _firestore
          .collection('users')
          .doc(widget.donorId)
          .collection('ratings')
          .doc(currentUser.uid);

      batch.set(ratingRef, {
        'rating': rating,
        'userId': currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update rating stats
      final statsRef = _firestore
          .collection('users')
          .doc(widget.donorId)
          .collection('rating_stats')
          .doc('stats');

      final statsDoc = await statsRef.get();
      if (statsDoc.exists) {
        final currentAvg = statsDoc.data()?['average'] ?? 0.0;
        final currentCount = statsDoc.data()?['count'] ?? 0;
        final newCount = currentCount + 1;
        final newAvg = ((currentAvg * currentCount) + rating) / newCount;

        batch.update(statsRef, {
          'average': newAvg,
          'count': newCount,
        });
      } else {
        batch.set(statsRef, {
          'average': rating,
          'count': 1,
        });
      }

      await batch.commit();

      // Update state
      setState(() {
        _hasRated = true;
        _ratingCount++;
        _averageRating =
            ((_averageRating * (_ratingCount - 1)) + rating) / _ratingCount;
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thank you for rating!')),
      );
    } catch (e) {
      print('Error submitting rating: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting rating')),
      );
    }
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.warning_amber_rounded, color: Colors.orange),
              title: Text('Open Dispute'),
              onTap: () {
                Navigator.pop(context);
                _openDispute();
              },
            ),
            ListTile(
              leading: Icon(Icons.report_problem_outlined, color: Colors.red),
              title: Text('Report Account'),
              onTap: () {
                Navigator.pop(context);
                _reportAccount();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openDispute() {
    final TextEditingController disputeController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Open Dispute'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: disputeController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe your issue...',
                  border: OutlineInputBorder(),
                  errorText: disputeController.text.isEmpty ? 'Required' : null,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (disputeController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please describe the issue')),
                        );
                        return;
                      }

                      setState(() => isSubmitting = true);

                      try {
                        await FirebaseFirestore.instance
                            .collection('disputes')
                            .add({
                          'reportedUserId': widget.donorId,
                          'reportedBy': FirebaseAuth.instance.currentUser?.uid,
                          'description': disputeController.text.trim(),
                          'timestamp': FieldValue.serverTimestamp(),
                          'status': 'pending',
                          'type': 'dispute',
                        });

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Dispute submitted successfully')),
                        );
                      } catch (e) {
                        setState(() => isSubmitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error submitting dispute')),
                        );
                      }
                    },
              child: Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateReportCount() async {
    try {
      // Get user document reference
      final userRef = _firestore.collection('users').doc(widget.donorId);

      // Get current user data
      final userDoc = await userRef.get();
      final userData = userDoc.data() ?? {};

      // Get or initialize report count
      int reportCount = (userData['reportCount'] ?? 0) + 1;

      // Update user document with new report count
      await userRef.update({
        'reportCount': reportCount,
        'isRestricted':
            reportCount >= 3, // Set restriction flag when count reaches 3
        'lastReportDate': FieldValue.serverTimestamp(),
      });

      // If report count reaches 3, create restriction notification
      if (reportCount >= 3) {
        // Create notification
        await _firestore.collection('notifications').add({
          'userId': widget.donorId,
          'type': 'restriction',
          'message':
              'Your account has been restricted due to multiple reports. Please contact support@ecothreads.com to appeal.',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });

        // Add to account_restrictions collection
        await _firestore.collection('account_restrictions').add({
          'userId': widget.donorId,
          'reason': 'Multiple user reports',
          'restrictionDate': FieldValue.serverTimestamp(),
          'status': 'active',
          'appealStatus': 'pending',
        });
      }
    } catch (e) {
      print('Error updating report count: $e');
    }
  }

  void _reportAccount() {
    final TextEditingController detailsController = TextEditingController();
    String? selectedReason;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Report Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedReason,
                items: [
                  'Inappropriate behavior',
                  'Suspicious activity',
                  'Fake account',
                  'Other'
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedReason = value);
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  errorText:
                      selectedReason == null ? 'Please select a reason' : null,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: detailsController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Provide additional details...',
                  border: OutlineInputBorder(),
                  errorText: detailsController.text.isEmpty ? 'Required' : null,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (selectedReason == null ||
                          detailsController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Please fill in all required fields')),
                        );
                        return;
                      }

                      setState(() => isSubmitting = true);

                      try {
                        await FirebaseFirestore.instance
                            .collection('reports')
                            .add({
                          'reportedUserId': widget.donorId,
                          'reportedBy': FirebaseAuth.instance.currentUser?.uid,
                          'reason': selectedReason,
                          'details': detailsController.text.trim(),
                          'timestamp': FieldValue.serverTimestamp(),
                          'status': 'pending',
                          'type': 'account_report',
                        });

                        // Update report count and check for restrictions
                        await _updateReportCount();

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Report submitted successfully')),
                        );
                      } catch (e) {
                        setState(() => isSubmitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error submitting report')),
                        );
                      }
                    },
              child: Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: getDonorData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  // Shimmer for cover image
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 230,
                      width: double.infinity,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 55),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile image shimmer
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                        // Name shimmer
                        Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            width: 200,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Username shimmer
                        Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            width: 150,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Action buttons shimmer
                        Row(
                          children: [
                            Expanded(
                              child: Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  height: 45,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  height: 45,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Stats row shimmer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(
                            3,
                            (index) => Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Column(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 40,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Listings grid shimmer
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.62,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: 6,
                          itemBuilder: (context, index) {
                            return Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          final userData = snapshot.data!['userData'];
          final listings = snapshot.data!['listings'] as List;
          final subscribersCount = snapshot.data!['subscribersCount'] as int;

          return SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Cover Image
                    Container(
                      height: 230,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        image: userData['coverImageUrl'] != null
                            ? DecorationImage(
                                image: NetworkImage(userData['coverImageUrl']),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                    ),
                    // Back Button
                    Positioned(
                      top: 40,
                      left: 10,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    // Add menu button
                    Positioned(
                      top: 40,
                      right: 10,
                      child: IconButton(
                        icon: Icon(Icons.more_vert, color: Colors.black),
                        onPressed: _showOptionsMenu,
                      ),
                    ),
                    // Profile Image
                    Positioned(
                      bottom: -45,
                      left: 20,
                      child: Container(
                        height: 105,
                        width: 105,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          image: userData['profileImageUrl'] != null
                              ? DecorationImage(
                                  image:
                                      NetworkImage(userData['profileImageUrl']),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: userData['profileImageUrl'] == null
                            ? Icon(Icons.person, size: 50, color: Colors.grey)
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 55),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.donorName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '@${userData['username'] ?? 'username'}',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color.fromARGB(255, 131, 131, 131),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        userData['bio'] ?? 'No bio added yet',
                        style: TextStyle(fontSize: 15, color: Colors.black),
                      ),
                      const SizedBox(height: 16),
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showRatingDialog,
                              icon: Icon(Icons.star,
                                  color: const Color.fromARGB(255, 77, 74, 74)),
                              label: Text(
                                'Rate Donor',
                                style: TextStyle(
                                    color:
                                        const Color.fromARGB(255, 77, 74, 74)),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: Icon(
                                _isSubscribed
                                    ? Icons.notifications_active
                                    : Icons.notifications_none,
                                color: Colors.white,
                              ),
                              label: Text(
                                _isSubscribed ? 'Subscribed' : 'Get Notified',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _isSubscribed ? Colors.green : Colors.black,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _toggleNotifications,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn(
                              Icons.person_add, // Changed icon
                              snapshot.data!['subscribersCount']
                                  .toString(), // Changed value
                              'Subscribers' // Changed label
                              ),
                          _buildStatColumn(Icons.star, '5.0', 'Rating'),
                          _buildStatColumn(
                              Icons.sell, '${listings.length}', 'Active'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Active Listings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 0),
                      // Grid of listings
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.62,
                        ),
                        itemCount: listings.length,
                        itemBuilder: (context, index) {
                          final item = listings[index];
                          return _buildListingItem(item);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(IconData icon, String value, String label) {
    if (label == 'Rating') {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.star, size: 20, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                _averageRating.toStringAsFixed(1),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          Text(
            '$_ratingCount ${_ratingCount == 1 ? 'Rating' : 'Ratings'}',
            style: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.black),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildListingItem(Map<String, dynamic> item) {
    // Convert the listing data to match the expected format
    final processedItem = {
      'id': item['id'],
      'name': item['itemName'], // Changed from itemName to name
      'points': item['points'],
      'image': item['imageUrl'], // Changed from imageUrl to image
      'imageUrl': item['imageUrl'], // Keep imageUrl for backwards compatibility
      'condition': item['condition'],
      'size': item['size'],
      'description': item['description'] ?? 'No description available',
      'userId': item['userId'] ?? widget.donorId,
      'userFullName': widget.donorName,
      'userProfileImage': item['userProfileImage'],
    };

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ProductPage(item: processedItem)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: item['imageUrl'] ?? '',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => _buildShimmerPlaceholder(),
                  errorWidget: (context, url, error) => _buildErrorWidget(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['itemName'] ?? 'Unnamed Item',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item['condition'] ?? 'Unknown',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    '${item['points'] ?? 0} pts',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(color: Colors.white),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
    );
  }
}
