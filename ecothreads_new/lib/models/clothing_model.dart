// lib/models/clothing_model.dart

class ClothingItem {
  final String name;
  final String imageUrl;
  final int price;
  final String condition;

  ClothingItem({
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.condition,
  });
}

// Sample list of clothing items
List<ClothingItem> myClothingItems = [
  ClothingItem(
    name: 'Flowery Dress',
    imageUrl: 'assets/images/dress.jpg',
    price: 300,
    condition: 'New',
  ),
  ClothingItem(
    name: 'Puma Sneakers',
    imageUrl: 'assets/images/puma.jpg',
    price: 300,
    condition: 'New',
  ),
  ClothingItem(
    name: 'Dark Cargo Jeans',
    imageUrl: 'assets/images/jeans.jpg',
    price: 300,
    condition: 'New',
  ),
  ClothingItem(
    name: 'Black crop top',
    imageUrl: 'assets/images/shirt.jpg',
    price: 300,
    condition: 'New',
  ),
  ClothingItem(
    name: 'Jeans skirt',
    imageUrl: 'assets/images/skirt.jpg',
    price: 100,
    condition: 'Slighty Used',
  ),
  ClothingItem(
    name: 'White Top',
    imageUrl: 'assets/images/whitetop.jpg',
    price: 300,
    condition: 'New',
  ),
];

// // lib/models/clothing_model.dart
// class ClothingItem {
//   final String name;
//   final String imageUrl;
//   final double price;

//   ClothingItem({
//     required this.name,
//     required this.imageUrl,
//     required this.price,
//   });
// }

// // Sample list with placeholder images
// List<ClothingItem> myClothingItems = [
//   ClothingItem(
//     name: 'Flowery Dress',
//     imageUrl:
//         'assets/images/placeholder.jpg', // Use a placeholder image that exists
//     price: 29.99,
//   ),
//   ClothingItem(
//     name: 'Puma Sneakers',
//     imageUrl: 'assets/images/placeholder.jpg',
//     price: 99.99,
//   ),
//   ClothingItem(
//     name: 'Dark Cargo Jeans',
//     imageUrl: 'assets/images/placeholder.jpg',
//     price: 19.99,
//   ),
//   ClothingItem(
//     name: 'Summer Dress',
//     imageUrl: 'assets/images/placeholder.jpg',
//     price: 29.99,
//   ),
//   ClothingItem(
//     name: 'Leather Jacket',
//     imageUrl: 'assets/images/placeholder.jpg',
//     price: 99.99,
//   ),
//   ClothingItem(
//     name: 'Casual T-Shirt',
//     imageUrl: 'assets/images/placeholder.jpg',
//     price: 19.09,
//   ),
// ];
