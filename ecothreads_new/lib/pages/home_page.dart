// Import necessary packages for UI, fonts, and Firebase functionality
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'itemdetail.dart';

// StatefulWidget for the home page that displays available clothing items
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    // Load initial data when widget is created
    _loadUserData();
    _loadItems();
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
    try {
      setState(() => _isLoading = true);

      // Fetch available donations
      final QuerySnapshot donationsSnapshot = await _firestore
          .collection('donations')
          .where('status', isEqualTo: 'available')
          .get();

      // Fetch clothing items
      final QuerySnapshot clothingSnapshot =
          await _firestore.collection('home_clothing').get();

      List<Map<String, dynamic>> items = [];

      // Process donation items
      // Process donation items
      for (var doc in donationsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Instead of fetching donor info from the users collection,
        // use the data already present in the donation document.
        final String userFullName = data['userFullName'] ?? 'Anonymous';
        final String? userProfileImage = data['userProfileImage'];

        items.add({
          'id': doc.id,
          'name': data['itemName'] ?? 'Unnamed Item',
          'points': data['points'] ?? 0,
          'image': data['imageUrl'] ?? '',
          'category': data['category'] ?? 'All Items',
          'condition': data['condition'] ?? 'New',
          'isManual': false,
          'description': data['description'] ?? 'New Clothes',
          'size': data['size'] ?? 'N/A',
          'userId': data['userId'],
          'userFullName': userFullName,
          'userProfileImage': userProfileImage,
        });
      }

      // Process clothing items
      for (var doc in clothingSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Get information about who added this clothing item
        String userFullName = 'Store Item';
        String? userProfileImage;

        if (data['addedBy'] != null) {
          try {
            DocumentSnapshot userDoc =
                await _firestore.collection('users').doc(data['addedBy']).get();

            if (userDoc.exists) {
              Map<String, dynamic> userData =
                  userDoc.data() as Map<String, dynamic>;
              userFullName = userData['fullName'] ?? 'Store Admin';
              userProfileImage = userData['profileImageUrl'];
            }
          } catch (e) {
            print('Error fetching admin info: $e');
          }
        }

        items.add({
          'id': doc.id,
          'name': data['itemName'] ?? 'Unnamed Item',
          'points': data['points'] ?? 0,
          'image': data['imageUrl'] ?? '',
          'category': data['category'] ?? 'All Items',
          'condition': data['condition'] ?? 'New',
          'isManual': true,
          'description': data['description'] ?? 'New Clothes',
          'size': data['size'] ?? 'N/A',
          'userId': data['addedBy'],
          'userFullName': userFullName,
          'userProfileImage': userProfileImage,
        });
      }

      setState(() {
        _allItems = items;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading items: $e');
      setState(() => _isLoading = false);
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
          item['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 50.0),
        child: SafeArea(
          child: Stack(
            children: [
              // Main content with CustomScrollView for better performance
              CustomScrollView(
                slivers: [
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
              // Loading indicator overlay
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(),
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
        // User profile image
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey[300],
          backgroundImage: _userProfileImage != null
              ? NetworkImage(_userProfileImage!)
              : const AssetImage('assets/images/profile.png') as ImageProvider,
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
          child: const Icon(Icons.tune, color: Colors.white),
        ),
      ],
    );
  }

  // Build the promotional banner
  Widget _buildBanner() {
    return ClipRRect(
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
                  'Earn points',
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
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.62,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = filteredItems[index];
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProductPage(item: item),
                  ),
                );
              },
              child: _buildItemCard(item),
            );
          },
          childCount: filteredItems.length,
        ),
      ),
    );
  }

  // Build individual item card
  Widget _buildItemCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductPage(item: item),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(item['image']),
                  fit: BoxFit.cover,
                  onError: (error, stackTrace) {
                    print('Error loading image: $error');
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item['name'],
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
                item['condition'],
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.star, color: Colors.amber, size: 12),
              const Text(
                ' 5.0',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            '${item['points']}pts',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
