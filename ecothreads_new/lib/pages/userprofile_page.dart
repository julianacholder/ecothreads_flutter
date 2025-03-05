import '../constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'env_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'itemdetail.dart'; // Add this import

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile>
    with SingleTickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  late TabController _tabController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Fetch user data including donations and points
  Future<Map<String, dynamic>> getUserData() async {
    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user!.uid).get();
        QuerySnapshot donationsSnapshot = await _firestore
            .collection('donations')
            .where('userId', isEqualTo: user!.uid)
            .get();

        int totalPoints = 0;
        for (var doc in donationsSnapshot.docs) {
          var points = (doc.data() as Map<String, dynamic>)['points'] ?? 0;
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

  // Upload cover image to Firebase Storage
  Future<void> _uploadCoverImage() async {
    try {
      setState(() => _isLoading = true);

      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        print('No image selected');
        return;
      }

      final File imageFile = File(pickedFile.path);

      final fileRef = _storage
          .ref()
          .child('images')
          .child('cover_${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = await fileRef.putFile(imageFile);

      if (uploadTask.state == TaskState.success) {
        final downloadUrl = await fileRef.getDownloadURL();

        await _firestore.collection('users').doc(user!.uid).set({
          'coverImageUrl': downloadUrl,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cover image updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  // Show dialog to update listing status

  void _showStatusUpdateDialog(String listingId, String currentStatus) {
    print('Opening dialog for listing ID: $listingId');
    final List<String> statusOptions = ['Available', 'Pending', 'Sold'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Update Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ...statusOptions
                    .map((status) => ListTile(
                          title: Text(status),
                          trailing: currentStatus.toLowerCase() ==
                                  status.toLowerCase()
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green)
                              : null,
                          onTap: () async {
                            try {
                              print('Updating status for document: $listingId');

                              // Get reference to the donation document
                              final donationRef = _firestore
                                  .collection('donations')
                                  .doc(listingId);

                              // Update the donation status
                              await donationRef.update({
                                'status': status.toLowerCase(),
                                'lastUpdated': FieldValue.serverTimestamp(),
                              });

                              // Get the clothing document with matching originalDonationId
                              final clothingQuery = await _firestore
                                  .collection('clothing')
                                  .where('originalDonationId',
                                      isEqualTo: listingId)
                                  .get();

                              // Update the clothing status if found
                              if (clothingQuery.docs.isNotEmpty) {
                                await clothingQuery.docs.first.reference
                                    .update({
                                  'status': status.toLowerCase(),
                                  'lastUpdated': FieldValue.serverTimestamp(),
                                });
                              }

                              if (mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Status updated to $status'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                setState(() {}); // Refresh the UI
                              }
                            } catch (e) {
                              print('Error updating status: $e');
                              if (mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Failed to update status: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ))
                    .toList(),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Build a single listing item
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
          Expanded(
            child: Stack(
              children: [
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  listing['itemName'] ?? 'Unnamed Item',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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

  // Build an action button
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

  // Build a stat column
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

  // Get status color based on status
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

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Cover image shimmer
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
                // Profile image shimmer with white border
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
                // Bio shimmer - multiple lines
                Column(
                  children: List.generate(
                    2,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: double.infinity,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Action buttons shimmer
                Row(
                  children: List.generate(
                    3,
                    (index) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 35,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Update profile button shimmer
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: double.infinity,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(width: 2.0, color: Colors.black),
          ),
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey[600],
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.grid_on_outlined, size: 16),
                  SizedBox(width: 8),
                  Text('My Listings'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 16),
                  SizedBox(width: 8),
                  Text('Favorites'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 0), // Reduced from 10 to 5
      ],
    );
  }

  Widget _buildFavoritesGrid() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchFavoritesWithDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildGridShimmer();
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.favorite_border, size: 50, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No favorites yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Items you favorite will appear here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.62,
          ),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final item = snapshot.data![index];

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductPage(item: item),
                  ),
                );
              },
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
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(12)),
                        child: CachedNetworkImage(
                          imageUrl: item['image'] ?? '',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.image_not_supported,
                                color: Colors.grey[400]),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] ?? 'Unnamed Item',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['condition'] ?? 'Unknown',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${item['points'] ?? 0} pts',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
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

  Future<List<Map<String, dynamic>>> _fetchFavoritesWithDetails() async {
    final favoritesSnapshot = await _firestore
        .collection('users')
        .doc(user?.uid)
        .collection('favorites')
        .get();

    List<Map<String, dynamic>> favoritesWithDetails = [];

    for (var doc in favoritesSnapshot.docs) {
      final favoriteData = doc.data();

      try {
        // Try to find the item in donations collection first
        final donationQuery = await _firestore
            .collection('donations')
            .where('itemName', isEqualTo: favoriteData['name'])
            .get();

        Map<String, dynamic> itemDetails = {};
        if (donationQuery.docs.isNotEmpty) {
          // Found in donations
          final donationData = donationQuery.docs.first.data();
          itemDetails = {
            'id': doc.id,
            'name': favoriteData['name'] ?? donationData['itemName'],
            'points': favoriteData['points'] ?? donationData['points'],
            'image': favoriteData['image'] ?? donationData['imageUrl'],
            'condition': favoriteData['condition'] ?? donationData['condition'],
            'size': favoriteData['size'] ?? donationData['size'],
            'description': donationData['description'] ?? 'No description',
            'userFullName': donationData['userFullName'] ?? 'Anonymous Donor',
            'userProfileImage': donationData['userProfileImage'],
            'userId': donationData['userId'],
          };
        } else {
          // Fallback to home_clothing collection
          final clothingQuery = await _firestore
              .collection('home_clothing')
              .where('itemName', isEqualTo: favoriteData['name'])
              .get();

          if (clothingQuery.docs.isNotEmpty) {
            final clothingData = clothingQuery.docs.first.data();
            itemDetails = {
              'id': doc.id,
              'name': favoriteData['name'] ?? clothingData['itemName'],
              'points': favoriteData['points'] ?? clothingData['points'],
              'image': favoriteData['image'] ?? clothingData['imageUrl'],
              'condition':
                  favoriteData['condition'] ?? clothingData['condition'],
              'size': favoriteData['size'] ?? clothingData['size'],
              'description': clothingData['description'] ?? 'No description',
              'userFullName': 'Store Item',
              'userProfileImage': null,
              'userId': null,
            };
          } else {
            // Use favorite data as fallback
            itemDetails = {
              'id': doc.id,
              'name': favoriteData['name'] ?? 'Unnamed Item',
              'points': favoriteData['points'] ?? 0,
              'image': favoriteData['image'] ?? '',
              'condition': favoriteData['condition'] ?? 'Unknown',
              'size': favoriteData['size'] ?? 'N/A',
              'description': 'No description available',
              'userFullName': 'Unknown Donor',
              'userProfileImage': null,
              'userId': null,
            };
          }
        }

        favoritesWithDetails.add(itemDetails);
      } catch (e) {
        print('Error fetching favorite item details: $e');
      }
    }

    return favoritesWithDetails;
  }

  Future<void> _toggleFavorite(Map<String, dynamic> item) async {
    if (user == null) return;

    try {
      final favoriteRef = _firestore
          .collection('users')
          .doc(user!.uid)
          .collection('favorites')
          .doc(item['id']);

      // Check if item already exists in favorites
      final doc = await favoriteRef.get();
      if (doc.exists) {
        // Item already in favorites, show message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item already in favorites')),
        );
        return;
      }

      // Add the item to favorites
      await favoriteRef.set({
        'id': item['id'],
        'name': item['itemName'],
        'points': item['points'],
        'image': item['imageUrl'],
        'condition': item['condition'],
        'size': item['size'],
        'addedAt': FieldValue.serverTimestamp(),
      });

      setState(() {}); // Refresh UI
    } catch (e) {
      print('Error toggling favorite: $e');
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
                return _buildShimmerLoading();
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
                        // Cover Image with Camera Icon
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: _isLoading ? null : _uploadCoverImage,
                              child: Container(
                                height: 230,
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
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              right: 15,
                              child: GestureDetector(
                                onTap: _uploadCoverImage,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black54,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Profile image
                        Positioned(
                          bottom: -45,
                          left: 20,
                          child: GestureDetector(
                            onTap: _uploadCoverImage,
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
                                        const EdgeInsets.symmetric(vertical: 8),
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

                          const SizedBox(height: 20),

                          // Stats Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatColumn(Icons.volunteer_activism_sharp,
                                  donationsCount.toString(), 'Donations'),
                              _buildStatColumn(Icons.monetization_on,
                                  totalPoints.toString(), 'Points'),
                              _buildStatColumn(Symbols.checkroom_rounded,
                                  '${donationsCount * 2}', 'Items'),
                            ],
                          ),
                          const SizedBox(height: 8), // Reduced from 10 to 0
                          // Replace the old TabBar with the new styled one
                          _buildTabs(),

                          // TabBarView with consistent styling
                          SizedBox(
                            height: 400,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildListingsGrid(),
                                _buildFavoritesGrid(),
                              ],
                            ),
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
              child: _buildShimmerLoading(),
            ),
        ],
      ),
    );
  }

  Widget _buildGridShimmer() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: 4,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildListingsGrid() {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('donations')
          .where('userId', isEqualTo: user?.uid)
          .get(),
      builder: (context, listingsSnapshot) {
        if (listingsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!listingsSnapshot.hasData || listingsSnapshot.data!.docs.isEmpty) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.inventory_2_outlined, size: 50),
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
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.62,
          ),
          itemCount: listingsSnapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = listingsSnapshot.data!.docs[index];
            final listing = doc.data() as Map<String, dynamic>;

            return GestureDetector(
              onTap: () {
                print('Tapped listing with ID: ${doc.id}');
                _showStatusUpdateDialog(
                    doc.id, listing['status'] ?? 'available');
              },
              child: _buildListingItem(listing),
            );
          },
        );
      },
    );
  }
}
