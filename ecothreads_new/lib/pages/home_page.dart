// Import necessary packages for UI, fonts, and Firebase functionality
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'itemdetail.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';

// StatefulWidget for the home page that displays available clothing items
class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Firebase instances for database and authentication
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  // State variables for search and filtering
  String _searchQuery = '';
  String _selectedCategory = 'All Items';
  final TextEditingController _searchController = TextEditingController();

  // State variables for items and loading state
  List<Map<String, dynamic>> _allItems = [];
  bool _isLoading = true;

  // User profile information
  String _userFullName = '';
  String? _userProfileImage;

  // Add new variables for filtering
  RangeValues _priceRange = RangeValues(0, 10000);
  List<String> _selectedConditions = [];
  String _selectedSort = 'Newest';

  // Add this method near other state variables
  Map<String, Map<String, dynamic>> _donorRatings = {};

  @override
  void initState() {
    super.initState();
    // Load initial data when widget is created
    _loadUserData();
    _loadItems();
  }

  Future<void> _shareInviteLink() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text("Loading your referral code..."),
                ],
              ),
            ),
          );
        },
      );

      // Get user data to access their referral code
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please log in to share your referral code')),
        );
        return;
      }

      // Get user document
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // Close loading dialog
      Navigator.of(context).pop();

      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User profile not found')),
        );
        return;
      }

      final userData = userDoc.data();
      if (userData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User data is empty')),
        );
        return;
      }

      // Safely extract referral code
      final String referralCode = userData['referralCode'] ?? '';

      // Debug: Print to console
      print('Retrieved referral code: $referralCode');

      if (referralCode.isEmpty) {
        // If code is empty, try to generate one
        await _generateReferralCode(user.uid);

        // Fetch updated user data with new code
        final updatedDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final String newCode = updatedDoc.data()?['referralCode'] ?? '';

        if (newCode.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not generate a referral code')),
          );
          return;
        }

        // Show dialog with the new code
        _showReferralCodeDialog(newCode);
      } else {
        // Show dialog with existing code
        _showReferralCodeDialog(referralCode);
      }
    } catch (e) {
      print('Error with invite: $e');
      // Make sure to close loading dialog if there's an error
      Navigator.of(context, rootNavigator: true)
          .popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to generate invite code: $e'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Helper method to generate a referral code
  Future<void> _generateReferralCode(String userId) async {
    try {
      // Generate new code from user ID
      final referralCode = userId.substring(0, 8).toUpperCase();

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'referralCode': referralCode});
    } catch (e) {
      print('Error generating referral code: $e');
      throw e;
    }
  }

  void _showReferralCodeDialog(String referralCode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Invite Friends',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Share your referral code with friends:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText(
                  referralCode,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    letterSpacing: 2,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'You and your friend will each earn 10 points!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
              ),
              onPressed: () async {
                await Share.share(
                  'Join me on EcoThreads! Use my referral code: $referralCode to get 10 points when you sign up!',
                );
                Navigator.of(context).pop();

                // Add points to user
                _addPointsToUser();
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: Text(
                  'Share Code',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

// New method to add points to the user after sharing
  Future<void> _addPointsToUser() async {
    if (user == null) return;

    try {
      // Reference to the user document
      final userRef = _firestore.collection('users').doc(user!.uid);

      // Get current user data
      final userDoc = await userRef.get();

      if (userDoc.exists) {
        // Get current points
        int currentPoints = userDoc.get('points') ?? 0;

        // Update user points
        await userRef.update({
          'points': currentPoints + 5,
        });

        // Add record to points history
        await _firestore.collection('points_history').add({
          'userId': user!.uid,
          'points': 5,
          'reason': 'Invited a friend',
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Show success message using SnackBar instead of toast
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You earned 5 points for sharing!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Refresh user data
        _loadUserData();
      }
    } catch (e) {
      print('Error adding points: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add points. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Fetch user profile data from Firestore
  Future<void> _loadUserData() async {
    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user!.uid).get();

        if (userDoc.exists) {
          setState(() {
            _userFullName = userDoc.get('fullName') ?? 'User';
            _userProfileImage = userDoc.get('profileImageUrl');
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  // Fetch available items from both donations and clothing collections
  // Updated method to fetch available items with donor information
  Future<void> _loadItems() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final donationsSnapshot = await _firestore
          .collection('donations')
          .where('status', isEqualTo: 'available')
          .get(); // Remove limit to get all items

      List<Map<String, dynamic>> items = [];

      for (var doc in donationsSnapshot.docs) {
        final data = doc.data();
        // Normalize category names
        String category = 'All Items';
        String itemName = data['itemName']?.toString().toLowerCase() ?? '';

        // Determine category based on item name or existing category
        if (data['category'] != null) {
          category = data['category'];
        } else if (itemName.contains('dress')) {
          category = 'Dress';
        } else if (itemName.contains('shirt') ||
            itemName.contains('tshirt') ||
            itemName.contains('t-shirt')) {
          category = 'T-Shirt';
        } else if (itemName.contains('jeans') || itemName.contains('pants')) {
          category = 'Jeans';
        }

        items.add({
          'id': doc.id,
          'name': data['itemName'] ?? 'Unnamed Item',
          'points': data['points'] ?? 0,
          'image': data['imageUrl'] ?? '',
          'material': data['material'] ?? 'N/A',
          'category': category, // Use normalized category
          'condition': data['condition'] ?? 'New',
          'isManual': false,
          'description': data['description'] ?? 'New Clothes',
          'size': data['size'] ?? 'N/A',
          'userId': data['userId'],
          'userFullName': data['userFullName'] ?? 'Anonymous',
          'userProfileImage': data['userProfileImage'],
        });
      }

      if (mounted) {
        setState(() {
          _allItems = items;
          _isLoading = false;
        });
      }

      _loadMoreItems();
    } catch (e) {
      print('Error loading items: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // New method to load additional items
  Future<void> _loadMoreItems() async {
    try {
      final clothingSnapshot = await _firestore
          .collection('home_clothing')
          .get(); // Remove limit to get all items

      List<Map<String, dynamic>> additionalItems = [];

      for (var doc in clothingSnapshot.docs) {
        final data = doc.data();
        // Normalize category names
        String category = 'All Items';
        String itemName = data['itemName']?.toString().toLowerCase() ?? '';

        // Determine category based on item name or existing category
        if (data['category'] != null) {
          category = data['category'];
        } else if (itemName.contains('dress')) {
          category = 'Dress';
        } else if (itemName.contains('shirt') ||
            itemName.contains('tshirt') ||
            itemName.contains('t-shirt')) {
          category = 'T-Shirt';
        } else if (itemName.contains('jeans') || itemName.contains('pants')) {
          category = 'Jeans';
        }

        additionalItems.add({
          'id': doc.id,
          'name': data['itemName'] ?? 'Unnamed Item',
          'points': data['points'] ?? 0,
          'image': data['imageUrl'] ?? '',
          'category': category, // Use normalized category
          'condition': data['condition'] ?? 'New',
          'isManual': true,
          'description': data['description'] ?? 'New Clothes',
          'size': data['size'] ?? 'N/A',
          'userId': data['addedBy'],
          'userFullName': 'Store Item',
          'userProfileImage': null,
        });
      }

      if (mounted) {
        setState(() {
          _allItems.addAll(additionalItems);
        });
      }
    } catch (e) {
      print('Error loading additional items: $e');
    }
  }

  // Filter items based on search query and selected category
  List<Map<String, dynamic>> get filteredItems {
    return _allItems.where((item) {
      final matchesSearch = item['name']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == 'All Items' ||
          item['category'].toString().toLowerCase() ==
              _selectedCategory.toLowerCase();

      final int itemPoints =
          int.tryParse(item['points']?.toString() ?? '0') ?? 0;
      final matchesPrice =
          itemPoints >= _priceRange.start && itemPoints <= _priceRange.end;
      final matchesCondition = _selectedConditions.isEmpty ||
          _selectedConditions.contains(item['condition']);

      return matchesSearch &&
          matchesCategory &&
          matchesPrice &&
          matchesCondition;
    }).toList()
      ..sort((a, b) {
        switch (_selectedSort) {
          case 'Price: Low to High':
            return (int.parse(a['points'].toString()) -
                int.parse(b['points'].toString()));
          case 'Price: High to Low':
            return (int.parse(b['points'].toString()) -
                int.parse(a['points'].toString()));
          default: // 'Newest'
            return 0; // Keep original order
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 50.0),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Main content with CustomScrollView for better performance
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildSearchBar(),
                      const SizedBox(height: 20),
                      _buildBanner(),
                      const SizedBox(height: 20),
                      _buildCategories(),
                    ],
                  ),
                ),
              ),
              _buildItemsGrid(),
              // Bottom padding to account for navigation bar
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build the welcome header with user profile
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Hello, Welcome ',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const Text('👋'),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _userFullName.isNotEmpty ? _userFullName : 'Loading...',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        // Fixed profile image display
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey[300],
          child: _userProfileImage != null
              ? ClipOval(
                  child: Image.network(
                    _userProfileImage!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.grey.shade600,
                      );
                    },
                  ),
                )
              : Icon(
                  Icons.person,
                  size: 30,
                  color: Colors.grey.shade600,
                ),
        ),
      ],
    );
  }

  // Build the search bar with filter button
  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                icon: Icon(Icons.search, color: Colors.grey[400]),
                hintText: 'Search clothes...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey[400]),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Filter button
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: GestureDetector(
            onTap: _showFilterDialog,
            child: const Icon(Icons.tune, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // Build the promotional banner
  Widget _buildBanner() {
    return GestureDetector(
      onTap: _shareInviteLink,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 120,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/friends.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Invite\nYour\nFriends',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(16.0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Earn 5 points',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build the category filter buttons
  Widget _buildCategories() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCategoryButton(
              'All Items', Icons.grid_4x4, _selectedCategory == 'All Items'),
          _buildCategoryButton(
              'Dress', Icons.checkroom, _selectedCategory == 'Dress'),
          _buildCategoryButton(
              'T-Shirt', Icons.dry_cleaning, _selectedCategory == 'T-Shirt'),
          _buildCategoryButton(
              'Jeans', Icons.style, _selectedCategory == 'Jeans'),
        ],
      ),
    );
  }

  // Build individual category button
  Widget _buildCategoryButton(String text, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = text;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: isSelected ? Colors.black : Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.black,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build the grid of clothing items
  Widget _buildItemsGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      sliver: _isLoading
          ? SliverToBoxAdapter(child: _buildShimmerLoading())
          : filteredItems.isEmpty
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No items found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = filteredItems[index];
                      return _buildItemCard(item);
                    },
                    childCount: filteredItems.length,
                  ),
                ),
    );
  }

  // Add new method for shimmer loading effect
  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.62,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 9, // Show more shimmer items
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                height: 12,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 4),
              Container(
                width: 60,
                height: 12,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 4),
              Container(
                width: 40,
                height: 12,
                color: Colors.grey[300],
              ),
            ],
          );
        },
      ),
    );
  }

  // Add this method before _buildItemCard
  Future<void> _loadDonorRating(String? donorId) async {
    if (donorId == null) return;

    try {
      final ratingStats = await _firestore
          .collection('users')
          .doc(donorId)
          .collection('rating_stats')
          .doc('stats')
          .get();

      if (ratingStats.exists) {
        setState(() {
          _donorRatings[donorId] = {
            'average': ratingStats.data()?['average'] ?? 0.0,
            'count': ratingStats.data()?['count'] ?? 0,
          };
        });
      }
    } catch (e) {
      print('Error loading donor rating: $e');
    }
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final String name = item['name']?.toString() ?? 'Unnamed Item';
    final String condition = item['condition']?.toString() ?? 'New';
    final int points = int.tryParse(item['points']?.toString() ?? '0') ?? 0;
    final String imageUrl = item['image']?.toString() ?? '';
    final String? donorId = item['userId']?.toString();

    // Load donor rating if not already loaded
    if (donorId != null && !_donorRatings.containsKey(donorId)) {
      _loadDonorRating(donorId);
    }

    // Get rating data
    final double rating = _donorRatings[donorId]?['average']?.toDouble() ?? 5.0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProductPage(item: item)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.image_not_supported_outlined,
                          color: Colors.grey[400]),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            children: [
              Text(
                condition,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.star, color: Colors.amber, size: 12),
              Text(
                ' ${rating.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            '${points}pts',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Add method to show filter dialog
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          // renamed setState to setModalState for clarity
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Items',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Price Range (Points)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              RangeSlider(
                values: _priceRange,
                min: 0,
                activeColor: Color(0xFF16A637),
                max: 10000,
                divisions: 100,
                labels: RangeLabels(
                  _priceRange.start.round().toString(),
                  _priceRange.end.round().toString(),
                ),
                onChanged: (RangeValues values) {
                  setModalState(() {
                    _priceRange = values;
                  });
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Condition',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                children: [
                  'New',
                  'Slightly Used',
                  'Well Worn',
                ]
                    .map((condition) => FilterChip(
                          label: Text(condition),
                          selected: _selectedConditions.contains(condition),
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                _selectedConditions.add(condition);
                              } else {
                                _selectedConditions.remove(condition);
                              }
                            });
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              Text(
                'Sort By',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                children: [
                  'Newest',
                  'Price: Low to High',
                  'Price: High to Low',
                ]
                    .map((sort) => ChoiceChip(
                          label: Text(sort),
                          selected: _selectedSort == sort,
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                _selectedSort = sort;
                              }
                            });
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                      ),
                      onPressed: () {
                        // Update both modal state and parent state
                        setModalState(() {
                          _priceRange = RangeValues(0, 10000);
                          _selectedConditions = [];
                          _selectedSort = 'Newest';
                        });
                        setState(() {
                          _priceRange = RangeValues(0, 10000);
                          _selectedConditions = [];
                          _selectedSort = 'Newest';
                        });
                      },
                      child:
                          Text('Reset', style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                      ),
                      onPressed: () {
                        setState(() {}); // Refresh parent widget
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Apply',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Clean up resources when widget is disposed
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
