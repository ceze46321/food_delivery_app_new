class Product {
  final String id; // We'll use grocery ID + item index for uniqueness
  final String name;
  final double price;
  final String? imageUrl;
  final int quantity; // Added to match API

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.quantity = 1,
  });

  factory Product.fromJson(Map<String, dynamic> json, {required String groceryId}) {
    return Product(
      id: '$groceryId-${json['name']}', // Unique ID combining grocery ID and item name
      name: json['name'] ?? 'Unnamed Product',
      price: (json['price'] is int ? json['price'].toDouble() : json['price']) ?? 0.0,
      imageUrl: json['image'],
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'image': imageUrl,
      'quantity': quantity,
    };
  }
}