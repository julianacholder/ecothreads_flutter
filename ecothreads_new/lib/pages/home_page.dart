import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'itemdetail.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  String _searchQuery = '';
  String _selectedCategory = 'All Items';
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allItems = [];
  bool _isLoading = true;
  String _userFullName = '';
  String? _userProfileImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadItems();
  }

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

  Future<void> _loadItems() async {
    try {
      setState(() => _isLoading = true);

      // Fetch donations
      final QuerySnapshot donationsSnapshot = await _firestore
          .collection('donations')
          .where('status', isEqualTo: 'available')
          .get();

      // Fetch clothing items
      final QuerySnapshot clothingSnapshot =
          await _firestore.collection('home_clothing').get();

      List<Map<String, dynamic>> items = [];

      // Add donations
      for (var doc in donationsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        items.add({
          'id': doc.id,
          'name': data['itemName'] ?? 'Unnamed Item',
          'points': data['points'] ?? 0,
          'image': data['imageUrl'] ?? '',
          'category': data['category'] ?? 'All Items',
          'condition': data['condition'] ?? 'New',
          'isManual': false,
          'description': data['description'] ?? 'New Clothes'
        });
      }

      // Add clothing items
      for (var doc in clothingSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        items.add({
          'id': doc.id,
          'name': data['itemName'] ?? 'Unnamed Item',
          'points': data['points'] ?? 0,
          'image': data['imageUrl'] ?? '',
          'category': data['category'] ?? 'All Items',
          'condition': data['condition'] ?? 'New',
          'isManual': true,
          'description': data['description'] ?? 'New Clothes'
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
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 80),
                  ),
                ],
              ),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
