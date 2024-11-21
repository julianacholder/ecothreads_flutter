import '../constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'env_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;

  Future<Map<String, dynamic>> getUserData() async {
    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user!.uid).get();
        QuerySnapshot donationsSnapshot = await _firestore
            .collection('donations')
            .where('userId', isEqualTo: user!.uid)
            .get();

        // Change the total points calculation to handle both int and double
        int totalPoints = 0;
        for (var doc in donationsSnapshot.docs) {
          var points = (doc.data() as Map<String, dynamic>)['points'] ?? 0;
          // Convert to int if it's a double
          if (points is double) {
            totalPoints += points.toInt();
          } else if (points is int) {
            totalPoints += points;
          }
        }

        return {
          'userData': userDoc.data() as Map<String, dynamic>?,
          'donationsCount': donationsSnapshot.docs.length,
          'totalPoints': totalPoints,
        };
      } catch (e) {
        print('Error fetching user data: $e');
        return {};
      }
    }
    return {};
  }

  Future<void> _uploadCoverImage() async {
    try {
      setState(() => _isLoading = true);

      final XFile? image =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      File imageFile = File(image.path);
      String fileName =
          'cover_${user!.uid}_${DateTime.now().millisecondsSinceEpoch}';
      Reference storageRef = _storage.ref().child('cover_images/$fileName');

      await storageRef.putFile(imageFile);
      String downloadURL = await storageRef.getDownloadURL();

      await _firestore.collection('users').doc(user!.uid).update({
        'coverImageUrl': downloadURL,
      });

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error uploading cover image: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload cover image')),
      );
    }
  }

  Future<void> _uploadProfileImage() async {
    try {
      setState(() => _isLoading = true);

      final XFile? image =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      File imageFile = File(image.path);
      String fileName =
          'profile_${user!.uid}_${DateTime.now().millisecondsSinceEpoch}';
      Reference storageRef = _storage.ref().child('profile_images/$fileName');

      await storageRef.putFile(imageFile);
      String downloadURL = await storageRef.getDownloadURL();

      await _firestore.collection('users').doc(user!.uid).update({
        'profileImageUrl': downloadURL,
      });

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error uploading profile image: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload profile image')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder<Map<String, dynamic>>(
            future: getUserData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final userData = snapshot.data?['userData'] ?? {};
              final donationsCount = snapshot.data?['donationsCount'] ?? 0;
              final totalPoints = snapshot.data?['totalPoints'] ?? 0;

              return SingleChildScrollView(
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Cover Image
                        GestureDetector(
                          onTap: _isLoading ? null : _uploadCoverImage,
                          child: Container(
                            height: 210,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              image: userData['coverImageUrl'] != null
                                  ? DecorationImage(
                                      image: NetworkImage(
                                          userData['coverImageUrl']),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: userData['coverImageUrl'] == null
                                ? const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate,
                                            size: 40, color: Colors.grey),
                                        Text('Add Cover Image',
                                            style:
                                                TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        // Profile image
                        Positioned(
                          bottom: -45,
                          left: 20,
                          child: GestureDetector(
                            onTap: _isLoading ? null : _uploadProfileImage,
                            child: Container(
                              height: 105,
                              width: 105,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                image: userData['profileImageUrl'] != null
                                    ? DecorationImage(
                                        image: NetworkImage(
                                            userData['profileImageUrl']),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: userData['profileImageUrl'] == null
                                  ? const Icon(Icons.person,
                                      size: 50, color: Colors.grey)
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 55),

                    // Profile Info
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userData['fullName'] ?? 'No Name',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '@${userData['username'] ?? 'username'}',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color.fromARGB(255, 131, 131, 131),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            userData['bio'] ?? 'No bio added yet',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Action Buttons
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildActionButton('Donate'),
                                const SizedBox(width: 10),
                                _buildActionButton('Redeem'),
                                const SizedBox(width: 10),
                                _buildActionButton('Explore'),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Update Profile Row
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/settings');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    minimumSize: const Size(0, 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Update Profile',
                                    style: TextStyle(
                                        fontSize: 15, color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation,
                                              secondaryAnimation) =>
                                          const EnvironmentalImpactPage(),
                                      transitionsBuilder: (context, animation,
                                          secondaryAnimation, child) {
                                        const begin = Offset(1.0, 0.0);
                                        const end = Offset.zero;
                                        const curve = Curves.easeInOut;
                                        var tween =
                                            Tween(begin: begin, end: end).chain(
                                          CurveTween(curve: curve),
                                        );
                                        return SlideTransition(
                                          position: animation.drive(tween),
                                          child: child,
                                        );
                                      },
                                      transitionDuration:
                                          const Duration(milliseconds: 300),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color.fromARGB(255, 225, 218, 218),
                                  ),
                                  child: const Icon(Icons.recycling),
                                ),
                              )
                            ],
                          ),

                          const SizedBox(height: 15),

                          // Stats Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              _buildStatColumn(Icons.volunteer_activism_sharp,
                                  donationsCount.toString(), 'Donations'),
                              const SizedBox(width: 30),
                              _buildStatColumn(Icons.monetization_on,
                                  totalPoints.toString(), 'Points'),
                              const SizedBox(width: 30),
                              _buildStatColumn(Symbols.checkroom_rounded,
                                  '${donationsCount * 2}', 'Items'),
                            ],
                          ),

                          const SizedBox(height: 16),

                          const Text(
                            'My Listings',
                            style: TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 15),
                          ),

                          // Listings
                          FutureBuilder<QuerySnapshot>(
                            future: _firestore
                                .collection('donations')
                                .where('userId', isEqualTo: user?.uid)
                                .get(),
                            builder: (context, listingsSnapshot) {
                              if (listingsSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              if (!listingsSnapshot.hasData ||
                                  listingsSnapshot.data!.docs.isEmpty) {
                                return SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.inventory_2_outlined,
                                            size: 50),
                                        SizedBox(height: 8),
                                        Text('No listings available'),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 0.62,
                                ),
                                itemCount: listingsSnapshot.data!.docs.length,
                                itemBuilder: (context, index) {
                                  final listing =
                                      listingsSnapshot.data!.docs[index].data()
                                          as Map<String, dynamic>;
                                  return _buildListingItem(listing);
                                },
                              );
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
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text) {
    return Container(
      width: 70,
      height: 23,
      decoration: BoxDecoration(
        color: AppColors.primarylight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: Colors.black,
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildListingItem(Map<String, dynamic> listing) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image Container
          Expanded(
            child: Stack(
              children: [
                // Main Image
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(listing['imageUrl'] ?? ''),
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) {},
                    ),
                  ),
                ),
                // Status Badge (if needed)
                if (listing['status'] != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(listing['status']),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        listing['status'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Item Details Container
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Item Name
                Text(
                  listing['name'] ?? 'Unnamed Item',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Condition and Rating Row
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Condition
                    Expanded(
                      child: Text(
                        listing['condition'] ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Rating
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber[400],
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          (listing['rating']?.toString() ?? '5.0'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Points
                Row(
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      size: 14,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${listing['points']?.toString() ?? '0'} pts',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'sold':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
