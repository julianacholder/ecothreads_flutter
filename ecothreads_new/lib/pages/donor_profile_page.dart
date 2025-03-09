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

  Future<Map<String, dynamic>> getDonorData() async {
    try {
      final userDoc =
          await _firestore.collection('users').doc(widget.donorId).get();
      final donationsSnapshot = await _firestore
          .collection('donations')
          .where('userId', isEqualTo: widget.donorId)
          .where('status', isEqualTo: 'available')
          .get();

      return {
        'userData': userDoc.data() ?? {},
        'listings': donationsSnapshot.docs.map((doc) => doc.data()).toList(),
        'donationsCount': donationsSnapshot.docs.length,
      };
    } catch (e) {
      print('Error fetching donor data: $e');
      return {
        'userData': {},
        'listings': [],
        'donationsCount': 0,
      };
    }
  }

  Future<void> _startChat() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to message the donor')),
      );
      return;
    }

    try {
      // Generate a unique chat ID
      String chatId = '${currentUser.uid}_${widget.donorId}';

      // Check if chat already exists
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();

      if (!chatDoc.exists) {
        // Create new chat document only with donor information
        await _firestore.collection('chats').doc(chatId).set({
          'participants': [currentUser.uid, widget.donorId],
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastSenderId': '',
          'hasUnreadMessages': false,
          'unreadCount': 0,
          'deletedFor': [],
          'donorName': widget.donorName, // Store only donor name
        });
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessageDonor(
              chatId: chatId,
              donorId: widget.donorId,
              donorName: widget.donorName, // Pass only donor name
            ),
          ),
        );
      }
    } catch (e) {
      print('Error starting chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting conversation')),
      );
    }
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rate ${widget.donorName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => IconButton(
                  icon: Icon(Icons.star_border),
                  onPressed: () {
                    // Implement rating logic
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Thank you for rating!')),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Open Dispute'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe your issue...',
                border: OutlineInputBorder(),
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
            onPressed: () {
              // Add dispute to Firestore
              FirebaseFirestore.instance.collection('disputes').add({
                'reportedUserId': widget.donorId,
                'reportedBy': FirebaseAuth.instance.currentUser?.uid,
                'timestamp': FieldValue.serverTimestamp(),
                'status': 'pending',
                'type': 'dispute',
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Dispute submitted successfully')),
              );
            },
            child: Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _reportAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
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
              onChanged: (_) {},
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Provide additional details...',
                border: OutlineInputBorder(),
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
            onPressed: () {
              // Add report to Firestore
              FirebaseFirestore.instance.collection('reports').add({
                'reportedUserId': widget.donorId,
                'reportedBy': FirebaseAuth.instance.currentUser?.uid,
                'timestamp': FieldValue.serverTimestamp(),
                'status': 'pending',
                'type': 'account_report',
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Report submitted successfully')),
              );
            },
            child: Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
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
          final donationsCount = snapshot.data!['donationsCount'] as int;

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
                              onPressed: _startChat,
                              icon: Icon(Icons.message, color: Colors.white),
                              label: Text(
                                'Message',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn(Icons.volunteer_activism_sharp,
                              donationsCount.toString(), 'Donations'),
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
