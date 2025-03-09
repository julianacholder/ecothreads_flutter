import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart'; // This should be the only CartItem import
import './card_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'itemdetail.dart';

class CheckoutPage extends StatefulWidget {
  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool hasMessagedDonor = false;
  bool showConfirmation = false;
  int totalAvailablePoints = 30000; // This would come from user's account
  int? _userPoints;

  @override
  void initState() {
    super.initState();
    _loadUserPoints();
  }

  Future<void> _loadUserPoints() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _userPoints = userDoc.data()?['points'] ?? 0;
          });
        }
      } catch (e) {
        print('Error loading user points: $e');
      }
    }
  }

  // Add this method to check if user has enough points
  bool _hasEnoughPoints() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    return (_userPoints ?? 0) >= cartProvider.totalPoints;
  }

  // Add this method to deduct points from user account
  Future<void> _deductPoints(int points) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      // Use a transaction to ensure atomic update
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception('User document not found');
        }

        final currentPoints = userDoc.data()?['points'] ?? 0;
        final newPoints = currentPoints - points;

        if (newPoints < 0) {
          throw Exception('Insufficient points');
        }

        // Update user points atomically
        transaction.update(userRef, {
          'points': newPoints,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // Record the transaction
        final transactionRef =
            FirebaseFirestore.instance.collection('points_history').doc();
        transaction.set(transactionRef, {
          'userId': user.uid,
          'type': 'purchase',
          'pointsDeducted': points,
          'previousBalance': currentPoints,
          'newBalance': newPoints,
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      // Refresh the UI
      await _loadUserPoints();
    } catch (e) {
      print('Error deducting points: $e');
      throw e;
    }
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.refresh),
              title: Text('Refresh Points'),
              onTap: () {
                Navigator.pop(context);
                _loadUserPoints();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline),
              title: Text('Clear Cart'),
              onTap: () {
                Navigator.pop(context);
                _showClearCartDialog();
              },
            ),
            ListTile(
              leading: Icon(Icons.help_outline),
              title: Text('Help'),
              onTap: () {
                Navigator.pop(context);
                _showHelpDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Cart'),
        content: Text('Are you sure you want to clear your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<CartProvider>().clearCart();
              Navigator.pop(context);
            },
            child: Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Checkout Help'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Message donors before checkout'),
            Text('2. Confirm your points balance'),
            Text('3. Review your items'),
            Text('4. Complete your order'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }

  // Updated _showConfirmationDialog method
  void _showConfirmationDialog() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final totalPoints = cartProvider.totalPoints;
    final pointsNeeded = totalPoints - (_userPoints ?? 0);

    if (!_hasEnoughPoints()) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 30),
              SizedBox(width: 10),
              Text('Insufficient Points',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      'Current Balance',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${_userPoints ?? 0} points',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15),
              Text(
                'You need ${pointsNeeded} more points',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Donate more items to earn points!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(
                  context,
                  '/main',
                  arguments: 2, // Index for donate tab
                );
              },
              child: Text('Donate Now'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final totalPoints = cartProvider.totalPoints;

      // Perform the point deduction
      await _deductPoints(totalPoints);

      // Important: Remove the loading dialog before showing confirmation
      if (mounted) {
        Navigator.of(context).pop(); // Remove loading dialog
      }

      // Add transaction record
      await FirebaseFirestore.instance.collection('transactions').add({
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'type': 'purchase',
        'amount': -totalPoints,
        'items': cartProvider.items
            .map((item) => {
                  'name': item.name,
                  'points': item.points,
                  'condition': item.condition,
                  'size': item.size,
                })
            .toList(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        // Clear the cart
        cartProvider.clearCart();

        // Show success confirmation
        setState(() {
          showConfirmation = true;
        });

        // Refresh points display
        await _loadUserPoints();
      }
    } catch (e) {
      print('Error processing checkout: $e');
      if (mounted) {
        // Make sure to remove loading dialog on error
        Navigator.of(context).pop(); // Remove loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete purchase: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleBackPress() {
    // Check if we can pop the current route
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      // If we can't pop, navigate to the main screen with home tab
      Navigator.pushReplacementNamed(
        context,
        '/main',
        arguments: 0, // Navigate to home tab
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final cartItems = cartProvider.items;

        return Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(),
                    if (cartItems.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shopping_cart_outlined,
                                  size: 64),
                              const SizedBox(height: 16),
                              const Text('Your cart is empty'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                ),
                                child: const Text('Continue Shopping',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            ...cartItems.map(
                                (item) => _buildCartItem(item, cartProvider)),
                            _buildDonorCheckbox(),
                            _buildTotalSection(cartProvider.totalPoints),
                            _buildPayButton(),
                          ],
                        ),
                      ),
                  ],
                ),
                if (showConfirmation) _buildConfirmationOverlay(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBackPress, // Use the new method
          ),
          const Expanded(
            child: Text(
              'Checkout',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showOptionsMenu,
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, CartProvider cartProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        // Wrap with InkWell for tap effect
        onTap: () => _showItemDetails(item),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 80,
                      height: 80,
                      color: Colors.white,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: Icon(Icons.error),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      item.condition,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    Text(
                      '${item.points} points',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () =>
                        cartProvider.removeItem(item), // Pass the item directly
                  ),
                  Text(
                    'Size: ${item.size}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add this new method to handle item tap
  void _showItemDetails(CartItem item) async {
    try {
      // Look up the item in both donations and clothing collections
      final donationsQuery = await FirebaseFirestore.instance
          .collection('donations')
          .where('itemName', isEqualTo: item.name)
          .where('points', isEqualTo: item.points)
          .get();

      final clothingQuery = await FirebaseFirestore.instance
          .collection('clothing')
          .where('itemName', isEqualTo: item.name)
          .where('points', isEqualTo: item.points)
          .get();

      Map<String, dynamic>? itemDetails;

      // Check donations first
      if (donationsQuery.docs.isNotEmpty) {
        itemDetails = donationsQuery.docs.first.data();
        itemDetails['id'] = donationsQuery.docs.first.id;
      }
      // If not found in donations, check clothing
      else if (clothingQuery.docs.isNotEmpty) {
        itemDetails = clothingQuery.docs.first.data();
        itemDetails['id'] = clothingQuery.docs.first.id;
      }

      if (itemDetails != null && mounted) {
        // Convert CartItem to the format expected by ProductPage
        final detailedItem = {
          'id': itemDetails['id'],
          'name': item.name,
          'points': item.points,
          'image': item.imageUrl,
          'condition': item.condition,
          'size': item.size,
          'description':
              itemDetails['description'] ?? 'No description available',
          'userId': itemDetails['userId'] ?? itemDetails['donorId'],
          'userFullName':
              itemDetails['userFullName'] ?? itemDetails['donorName'],
          'userProfileImage': itemDetails['userProfileImage'] ??
              itemDetails['donorProfileImage'],
        };

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductPage(item: detailedItem),
          ),
        );
      }
    } catch (e) {
      print('Error fetching item details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load item details')),
        );
      }
    }
  }

  Widget _buildDonorCheckbox() {
    return Card(
      child: CheckboxListTile(
        value: hasMessagedDonor,
        onChanged: (value) {
          setState(() {
            hasMessagedDonor = value ?? false;
          });
        },
        title: const Text("Confirm you've messaged donor(s)"),
      ),
    );
  }

  Widget _buildTotalSection(int totalPoints) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTotalRow('Total Items', '$totalPoints points'),
            _buildTotalRow(
              'Available Points',
              _userPoints != null ? '$_userPoints points' : 'Loading...',
            ),
            _buildTotalRow('Discount', '0 points'),
            const Divider(),
            _buildTotalRow('Sub Total', '$totalPoints points'),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value),
        ],
      ),
    );
  }

  // Update the _buildPayButton to show more attractive insufficient points message
  Widget _buildPayButton() {
    final cartProvider = Provider.of<CartProvider>(context);
    final hasEnoughPoints = _hasEnoughPoints();
    final totalPoints = cartProvider.totalPoints;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          if (!hasEnoughPoints)
            Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.red[400], size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Need ${totalPoints - (_userPoints ?? 0)} more points',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: hasMessagedDonor ? _showConfirmationDialog : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: hasEnoughPoints ? Colors.black : Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
                hasEnoughPoints ? 'Complete Order' : 'Insufficient Points'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationOverlay() {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button during confirmation
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(32),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Congratulations!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your order has been placed.',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Clear the cart after successful order
                      context.read<CartProvider>().clearCart();
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/main',
                        (route) => false,
                        arguments: 0,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 50),
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Continue Shopping'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
