import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                        // Header with profile
                        Row(
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
                                  'Crystal Holder',
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            // Profile picture - Add your circular image here
                            const CircleAvatar(
                              radius: 25,
                              // backgroundImage: AssetImage('assets/images/profile.jpg'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Search bar
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TextField(
                                  decoration: InputDecoration(
                                    icon: Icon(Icons.search,
                                        color: Colors.grey[400]),
                                    hintText: 'Search clothes...',
                                    border: InputBorder.none,
                                    hintStyle:
                                        TextStyle(color: Colors.grey[400]),
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
                              child:
                                  const Icon(Icons.tune, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Banner - Add your banner image here
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              // image: DecorationImage(
                              //   image: AssetImage('assets/images/banner.jpg'),
                              //   fit: BoxFit.cover,
                              // ),
                              color: Colors.grey[200],
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
                        const SizedBox(height: 20),

                        // Categories
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildCategoryButton(
                                  'All Items', Icons.grid_4x4, true),
                              _buildCategoryButton(
                                  'Dress', Icons.checkroom, false),
                              _buildCategoryButton(
                                  'T-Shirt', Icons.dry_cleaning, false),
                              _buildCategoryButton('Jeans', Icons.style, false),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Grid of items
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildItemCard(itemsList[index]),
                      childCount: itemsList.length,
                    ),
                  ),
                ),

                // Bottom spacing for navigation bar
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ),

            // Bottom navigation
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNavItem(Icons.home, true),
                    _buildNavItem(Icons.shopping_bag_outlined, false),
                    _buildNavItem(Icons.add_circle_outline, false),
                    _buildNavItem(Icons.chat_bubble_outline, false),
                    _buildNavItem(Icons.person_outline, false),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String text, IconData icon, bool isSelected) {
    return Container(
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
    );
  }

  Widget _buildNavItem(IconData icon, bool isSelected) {
    return Icon(
      icon,
      color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Item image container - Add your product images here
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
              // image: DecorationImage(
              //   image: AssetImage(item['image']),
              //   fit: BoxFit.cover,
              // ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item['name'],
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          children: [
            Text(
              'New',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const Text(
              ' 5.0',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Text(
          '${item['points']}pts',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

final List<Map<String, dynamic>> itemsList = [
  {
    'name': 'Jeans Skirt',
    'points': 100,
    // 'image': 'assets/images/jeans_skirt.jpg',
  },
  {
    'name': 'Jeans Skirt',
    'points': 100,
    // 'image': 'assets/images/jeans_skirt_2.jpg',
  },
  {
    'name': 'Black Top',
    'points': 100,
    // 'image': 'assets/images/black_top.jpg',
  },
  {
    'name': 'Red sweater',
    'points': 100,
    // 'image': 'assets/images/red_sweater.jpg',
  },
  {
    'name': 'Grey nike shoes',
    'points': 100,
    // 'image': 'assets/images/grey_shoes.jpg',
  },
  {
    'name': 'Red flowery skirt',
    'points': 100,
    // 'image': 'assets/images/red_skirt.jpg',
  },
];
