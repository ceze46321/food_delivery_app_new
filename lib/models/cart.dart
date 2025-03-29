class CartItem {
  final String id;
  final String name;
  final double price;
  int quantity;
  final String? restaurantName; // Nullable, matches backend flexibility

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.restaurantName,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'quantity': quantity,
        'restaurant_name': restaurantName, // Matches Laravel validation (items.*.restaurant_name)
      };
}