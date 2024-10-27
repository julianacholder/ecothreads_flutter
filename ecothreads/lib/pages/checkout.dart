import 'package:flutter/material.dart';

// Model for cart items
class CartItem {
  final String name;
  final String condition;
  final int points;
  final String size;
  final String imageUrl;

  CartItem({
    required this.name,
    required this.condition,
    required this.points,
    required this.size,
    required this.imageUrl,
  });
}

class CheckoutPage extends StatefulWidget {
  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool hasMessagedDonor = false;
  bool showConfirmation = false;

  // Sample cart items - in real app, this would come from a cart provider/state management
  final List<CartItem> cartItems = [
    CartItem(
      name: 'Vintage Green Bag',
      condition: 'New',
      points: 100,
      size: 'M',
      imageUrl: 'assets/images/green bag.jpg', // Add comment: Replace with actual image path
    ),
    CartItem(
      name: 'Vintage kitten heels',
      condition: 'Slightly used',
      points: 50,
      size: 'L',
      imageUrl: 'assets/images/strawberry.jpg', // Add comment: Replace with actual image path
    ),
    CartItem(
      name: 'Pink blouse',
      condition: 'New',
      points: 100,
      size: 'S',
      imageUrl: 'assets/images/pink blouse.jpg', // Add comment: Replace with actual image path
    ),
  ];

  int get totalPoints => cartItems.fold(0, (sum, item) => sum + item.points);
  int totalAvailablePoints = 30000; // This would normally come from user's account

  void _showConfirmationDialog() {
    setState(() {
      showConfirmation = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ...cartItems.map((item) => _buildCartItem(item)),
                      _buildDonorCheckbox(),
                      _buildTotalSection(),
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
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Checkout',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                item.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    item.condition,
                    style: TextStyle(color: Colors.grey),
                  ),
                  Text(
                    '${item.points} points',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.more_vert),
                  onPressed: () {},
                ),
                Text(
                  'Size: ${item.size}',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
        title: Text("Confirm you've messaged donor(s)"),
      ),
    );
  }

  Widget _buildTotalSection() {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTotalRow('Total (${cartItems.length} items)', '$totalPoints points'),
            _buildTotalRow('Total Points', '$totalAvailablePoints points'),
            _buildTotalRow('Discount', '0.00'),
            Divider(),
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

  Widget _buildPayButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton(
        onPressed: hasMessagedDonor ? _showConfirmationDialog : null,
        child: Text('Pay'),
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, 50), backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: EdgeInsets.all(32),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'Congratulations!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your order has been placed.',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to shop page
                    Navigator.pop(context);
                  },
                  child: Text('Shop More'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(200, 50), backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
}
