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

  Map<String, dynamic> toJson() => {
        'name': name,
        'condition': condition,
        'points': points,
        'size': size,
        'imageUrl': imageUrl,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        name: json['name'] ?? '',
        condition: json['condition'] ?? '',
        points: json['points'] ?? 0,
        size: json['size'] ?? '',
        imageUrl: json['imageUrl'] ?? '',
      );
}
