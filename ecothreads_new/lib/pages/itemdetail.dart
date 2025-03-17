// Import necessary packages for UI, Firebase functionality, and state management
import 'package:ecothreads/pages/messagedonor.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../pages/card_provider.dart';
import '../services/notification_service.dart';
import 'checkout.dart';
import 'donor_profile_page.dart';
import '../services/messaging_service.dart';
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
  bool isProcessing = false; // Add this line

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

  Future<void> _requestItem(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to request items')),
      );
      return;
    }

    try {
      // Get user's current points
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final int currentPoints = userDoc.data()?['points'] ?? 0;
      final int itemPoints = widget.item['points'] ?? 0;

      if (currentPoints < itemPoints) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Insufficient Points'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('You don\'t have enough points for this item.'),
                SizedBox(height: 16),
                RichText(
                  text: TextSpan(
                    style: TextStyle(color: Colors.black87),
                    children: [
                      TextSpan(text: 'Your balance: '),
                      TextSpan(
                        text: '$currentPoints points',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: TextStyle(color: Colors.black87),
                    children: [
                      TextSpan(text: 'Item cost: '),
                      TextSpan(
                        text: '$itemPoints points',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // Show confirmation dialog with updated UI
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.shopping_bag_outlined, color: Colors.green),
              SizedBox(width: 8),
              Text('Confirm Request'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Item: ${widget.item['name']}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildPointsRow(
                          'Your Balance', currentPoints, Colors.blue),
                      Divider(height: 16),
                      _buildPointsRow('Item Cost', itemPoints, Colors.red),
                      Divider(height: 16),
                      _buildPointsRow(
                        'Remaining Balance',
                        currentPoints - itemPoints,
                        Colors.green,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Confirm Request',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      setState(() {
        isProcessing = true; // Show processing overlay
      });

      // Create batch for atomic operations
      final batch = FirebaseFirestore.instance.batch();

      // Get references
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final itemRef = FirebaseFirestore.instance
          .collection('donations')
          .doc(widget.item['id']);
      final requestRef =
          FirebaseFirestore.instance.collection('requests').doc();
      final notificationRef =
          FirebaseFirestore.instance.collection('notifications').doc();

      // Update item status to pending
      batch.update(itemRef, {
        'status': 'pending',
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Deduct points from user
      batch.update(userRef, {
        'points': FieldValue.increment(-itemPoints),
      });

      // Create request document
      batch.set(requestRef, {
        'itemId': widget.item['id'],
        'itemName': widget.item['name'],
        'itemPoints': itemPoints,
        'buyerId': user.uid,
        'sellerId': widget.item['userId'],
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Get user data first
      final userData = (await userRef.get()).data() as Map<String, dynamic>;
      final userName = userData['fullName'] ?? 'Someone';

      // Create notification for donor
      batch.set(notificationRef, {
        'userId': widget.item['userId'],
        'type': 'item_request',
        'title': 'New Item Request',
        'message': '$userName has requested your item "${widget.item['name']}"',
        'itemId': widget.item['id'],
        'itemName': widget.item['name'],
        'itemImage': widget.item['image'],
        'imageUrl':
            userData['profileImageUrl'] ?? '', // Add requester's profile image
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'requestId': requestRef.id,
        'buyerId': user.uid,
        'buyerName': userName,
      });

      // Get donor's FCM token
      final donorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.item['userId'])
          .get();

      final donorFcmToken = donorDoc.data()?['fcmToken'];

      // Commit the batch
      await batch.commit();

      // Send push notification if token exists
      if (donorFcmToken != null) {
        await MessagingService.sendPushMessage(
          token: donorFcmToken,
          title: 'New Item Request',
          body: '$userName has requested your item "${widget.item['name']}"',
          data: {
            'type': 'item_request',
            'itemId': widget.item['id'],
            'requestId': requestRef.id,
          },
        );
      }

      // Show local notification to the donor
      await NotificationService.showLocalNotification(
        title: 'New Request',
        body: '$userName has requested your item "${widget.item['name']}"',
      );

      // Add a small delay for better UX
      await Future.delayed(Duration(seconds: 1));

      // Show success message to requester
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request sent successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to message donor using push and pop current screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => MessageDonor(
              donorId: widget.item['userId'],
              donorName: widget.item['userFullName'] ?? 'Donor',
              itemName: widget.item['name'],
              itemId: widget.item['id'],
              itemImage: widget.item['image'],
            ),
          ),
          (route) => route.isFirst, // Keep only the first route (home screen)
        );
      }
    } catch (e) {
      print('Error requesting item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing request')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false; // Hide processing overlay
        });
      }
    }
  }

  Widget _buildPointsRow(String label, int points, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        Text(
          '$points points',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
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

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Processing your request...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Please wait while we connect you\nwith the donor',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
      body: Stack(
        children: [
          SingleChildScrollView(
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.grey[400]!),
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
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
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
                  // Size and Points Row with Material
                  Row(
                    children: [
                      // Size info
                      const Text(
                        'Size:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
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
                      const SizedBox(width: 16),
                      // Material info

                      const Spacer(),
                      const Text(
                        'Price: ',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${widget.item['points'] ?? 0} points',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Material info
                      const Text(
                        'Material:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.item['material'] ?? 'N/A',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DonorProfilePage(
                            donorId: widget.item['userId'] ?? '',
                            donorName:
                                widget.item['userFullName'] ?? 'Anonymous',
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
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 24.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _requestItem(context),
                        child: Text(
                          'Request Item',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isProcessing) _buildProcessingOverlay(),
        ],
      ),
    );
  }
}
