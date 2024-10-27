import 'package:flutter/material.dart';

class ProductPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_border, color: Colors.pink),
            onPressed: () {
              // TODO: Add favorite functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/green bag.jpg',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 300,
                ),
              ),
              SizedBox(height: 16),
              
              // Product Title and Rating
              Text(
                'Vintage green bag',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.yellow[700], size: 20),
                  Text(
                    ' 5.0 ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '(Slightly used)',
                    style: TextStyle(color: Colors.blue),
                  ),
                ],
              ),
              SizedBox(height: 8),
              
              // Description
              Text(
                "Its simple and elegant shape makes it perfect for those of you who like minimalist clothes. Read More...",
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              
              // Size and Price
              Row(
                children: [
                  Text(
                    'Size:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'M',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Spacer(),
                  Text(
                    'Price: ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$100 points',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 16),
              
              // Donor Information
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage('https://via.placeholder.com/50'),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Donated by: ',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    'Philippa Gibwa',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 24),
              
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      // TODO: Add message donor functionality
                    },
                    icon: Icon(Icons.chat_bubble_outline, color: Colors.white),
                    label: Text(
                      'Message donor',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      // TODO: Add to cart functionality
                    },
                    icon: Icon(Icons.add_shopping_cart, color: Colors.white),
                    label: Text(
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
