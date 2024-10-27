import 'package:ecothreads/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../models/clothing_model.dart';
import '../pages/env_page.dart';

class UserProfile extends StatelessWidget {
  const UserProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Cover Image
                Container(
                  height: 210,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/cover.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Profile image
                Positioned(
                  bottom: -45,
                  left: 20,
                  child: Container(
                    height: 105,
                    width: 105,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/profile.png'),
                        fit: BoxFit.cover,
                      ),
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
                  const Text(
                    'Crystal Holder',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    '@fashionlover29',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color.fromARGB(255, 131, 131, 131),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'I love all things fashion and colorful. Excited to swap on ecothreads, hit me up if you see anything you like',
                    style: TextStyle(
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
                            Navigator.pushNamed(context, '/editprofile');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            minimumSize: const Size(0, 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Update Profile',
                            style: TextStyle(fontSize: 15, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const EnvironmentalImpactPage(),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                const begin = Offset(1.0, 0.0);
                                const end = Offset.zero;
                                const curve = Curves.easeInOut;
                                var tween = Tween(begin: begin, end: end).chain(
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
                      _buildStatColumn(
                          Icons.volunteer_activism_sharp, '150', 'Donations'),
                      const SizedBox(width: 30),
                      _buildStatColumn(Icons.monetization_on, '30k', 'Points'),
                      const SizedBox(width: 30),
                      _buildStatColumn(
                          Symbols.checkroom_rounded, '700', 'Items'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'My Listings',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),

                  // Grid View
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.62,
                    ),
                    itemCount: myClothingItems.length,
                    itemBuilder: (context, index) {
                      final item = myClothingItems[index];
                      return _buildClothingItem(item);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildClothingItem(ClothingItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Added this
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              item.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13, // Reduced font size
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min, // Added this
          children: [
            Expanded(
              // Added this
              child: Text(
                item.condition,
                style: const TextStyle(
                  fontSize: 12, // Reduced font size
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4), // Reduced spacing
            Row(
              mainAxisSize: MainAxisSize.min, // Added this
              children: const [
                Icon(
                  Icons.star,
                  color: Colors.yellow,
                  size: 14, // Reduced icon size
                ),
                SizedBox(width: 2), // Added small spacing
                Text(
                  '5.0',
                  style: TextStyle(fontSize: 12), // Reduced font size
                )
              ],
            )
          ],
        ),
        const SizedBox(height: 3),
        Text(
          '\$${item.price}pts',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12, // Reduced font size
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
