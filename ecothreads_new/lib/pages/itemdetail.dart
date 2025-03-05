// Import necessary packages for UI, Firebase functionality, and state management
import 'package:ecothreads/pages/messagedonor.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../pages/card_provider.dart';
import 'checkout.dart';
import 'donor_profile_page.dart';
import '../models/cart_item.dart'; // Make sure this is the only CartItem import

// StatefulWidget for displaying detailed product information
class ProductPage extends StatefulWidget {
  final Map<String, dynamic> item;
  const ProductPage({Key? key, required this.item}) : super(key: key);

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  bool isFavorite = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(widget.item['id'])
          .get();

      setState(() {
        isFavorite = doc.exists;
        isLoading = false;
      });
    } catch (e) {
      print('Error checking favorite status: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to favorite items')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final favoriteRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(widget.item['id']);

      if (isFavorite) {
        await favoriteRef.delete();
      } else {
        await favoriteRef.set({
          'itemId': widget.item['id'],
          'name': widget.item['name'],
          'points': widget.item['points'],
          'image': widget.item['image'],
          'condition': widget.item['condition'],
          'size': widget.item['size'],
          'addedAt': FieldValue.serverTimestamp(),
        });
      }

      setState(() {
        isFavorite = !isFavorite;
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              isFavorite ? 'Added to favorites' : 'Removed from favorites'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print('Error toggling favorite: $e');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating favorites')),
      );
    }
  }

  void _startChat(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to message the donor')),
      );
      return;
    }

    final donorId = widget.item['userId'];
    if (donorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot identify the donor')),
      );
      return;
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessageDonor(
            chatId: null,
            donorId: donorId,
            donorName: widget.item['userFullName'] ?? 'Donor',
            itemName: widget.item['name'] ?? 'Item',
            itemId: widget.item['id'],
            itemImage: widget.item['image'],
          ),
        ),
      );
    }
  }

  void _addToCart(BuildContext context) {
    try {
      final int itemPoints =
          int.tryParse(widget.item['points']?.toString() ?? '0') ?? 0;

      final cartItem = CartItem(
        name: widget.item['name']?.toString() ?? 'Unnamed Item',
        condition: widget.item['condition']?.toString() ?? 'New',
        points: itemPoints,
        size: widget.item['size']?.toString() ?? 'N/A',
        imageUrl: widget.item['image']?.toString() ?? '',
      );

      context.read<CartProvider>().addItem(cartItem);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Item added to cart'),
          action: SnackBarAction(
            label: 'View Cart',
            onPressed: () => Navigator.pushNamed(context, '/checkout'),
          ),
        ),
      );
    } catch (e) {
      print('Error adding to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not add item to cart'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Item data: ${widget.item}');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.pink,
            ),
            onPressed: isLoading ? null : _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16, top: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: CachedNetworkImage(
                    imageUrl: widget.item['image'] ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.grey[400],
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Image not available',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.item['name'] ?? 'Unnamed Item',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.yellow[700], size: 20),
                  const Text(
                    ' 5.0 ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '(${widget.item['condition'] ?? 'Unknown condition'})',
                    style: const TextStyle(color: Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.item['description'] ?? "No description available",
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
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
                      widget.item['size'] ?? 'N/A',
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
                    '${widget.item['points'] ?? 0} points',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DonorProfilePage(
                        donorId: widget.item['userId'] ?? '',
                        donorName: widget.item['userFullName'] ?? 'Anonymous',
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[300],
                      child: widget.item['userProfileImage'] != null
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: widget.item['userProfileImage'],
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(color: Colors.white),
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  Icons.person,
                                  color: Colors.grey[400],
                                  size: 25,
                                ),
                              ),
                            )
                          : Icon(Icons.person,
                              color: Colors.grey[400], size: 25),
                    ),
                    const SizedBox(width: 8),
                    const Text('Donated by: ',
                        style: TextStyle(color: Colors.grey)),
                    Text(
                      widget.item['userFullName'] ?? 'Anonymous',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                  ],
                ),
              ),
              const SizedBox(height: 30),
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
                    onPressed: () => _startChat(context),
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
                          horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => _addToCart(context),
                    icon: const Icon(Icons.add_shopping_cart,
                        color: Colors.white),
                    label: const Text(
                      'Add to Cart',
                      style: TextStyle(color: Colors.white, fontSize: 16),
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
