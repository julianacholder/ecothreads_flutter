// Import necessary packages for UI, Firebase functionality, and state management
import 'package:ecothreads/pages/messagedonor.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../pages/card_provider.dart';
import 'checkout.dart';

// StatelessWidget for displaying detailed product information
class ProductPage extends StatelessWidget {
  // Item data passed from the previous screen
  final Map<String, dynamic> item;

  const ProductPage({Key? key, required this.item}) : super(key: key);

  // Initialize chat with the donor in Firestore
  void _startChat(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final donorId = item['userId'];
    if (donorId == null) return;

    try {
      // Create a unique chat ID combining user and donor IDs
      final chatId = '${currentUser.uid}_$donorId';
      final firestore = FirebaseFirestore.instance;

      // Create or update chat document in Firestore
      await firestore.collection('chats').doc(chatId).set({
        'participants': [currentUser.uid, donorId],
        'lastMessage': 'Chat started',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'itemId': item['id'],
        'itemName': item['name'],
        'itemImage': item['image'],
      }, SetOptions(merge: true));

      // Navigate to chat screen if context is still valid
      if (context.mounted) {
        Navigator.pushNamed(
          context,
          '/message',
          arguments: {
            'chatId': chatId,
            'otherUserId': donorId,
            'otherUserName': item['userFullName'] ?? 'User',
            'itemName': item['name'],
          },
        );
      }
    } catch (e) {
      print('Error starting chat: $e');
    }
  }

  // Add item to shopping cart using CartProvider
  void _addToCart(BuildContext context) {
    final cartItem = CartItem(
      name: item['name'] ?? 'Unnamed Item',
      condition: item['condition'] ?? 'New',
      points: item['points'] ?? 0,
      size: item['size'] ?? 'N/A',
      imageUrl: item['image'] ?? '',
    );

    // Add item to cart using provider
    context.read<CartProvider>().addItem(cartItem);

    // Show success message with action to view cart
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Item added to cart'),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CheckoutPage()),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Item data: $item');

    return Scaffold(
      backgroundColor: Colors.white,
      // Custom app bar with back button and favorite icon
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.pink),
            onPressed: () {
              // TODO: Add favorite functionality
            },
          ),
        ],
      ),
      // Scrollable content area
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16, top: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image with error handling
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  item['image'] ?? '',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 350,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 350,
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Product name
              Text(
                item['name'] ?? 'Unnamed Item',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              // Rating and condition
              Row(
                children: [
                  Icon(Icons.star, color: Colors.yellow[700], size: 20),
                  const Text(
                    ' 5.0 ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '(${item['condition'] ?? 'Unknown condition'})',
                    style: const TextStyle(color: Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Product description
              Text(
                item['description'] ?? "No description available",
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              // Size and price information
              Row(
                children: [
                  const Text(
                    'Size:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item['size'] ?? 'N/A',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Price: ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${item['points'] ?? 0} points',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Donor information
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: item['userProfileImage'] != null
                        ? NetworkImage(item['userProfileImage'])
                        : const AssetImage('assets/images/donor.png')
                            as ImageProvider,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Donated by: ',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Text(
                    item['userFullName'] ?? 'Lydia Vannie',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Action buttons for messaging donor and adding to cart
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MessageDonor(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline,
                        color: Colors.white),
                    label: const Text(
                      'Message donor',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => _addToCart(context),
                    icon: const Icon(Icons.add_shopping_cart,
                        color: Colors.white),
                    label: const Text(
                      'Add to Cart',
                      style: TextStyle(color: Colors.white),
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
}
