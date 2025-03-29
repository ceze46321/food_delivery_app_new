import 'package:flutter/material.dart';
import 'services/api_service.dart';

class CartItem {
  final String name;
  final double price;
  final String restaurantName;

  CartItem(this.name, this.price, this.restaurantName);

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'restaurant_name': restaurantName,
      };
}

class Cart with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;
  double get total => _items.fold(0, (sum, item) => sum + item.price);

  void addItem(String name, double price, String restaurantName) {
    _items.add(CartItem(name, price, restaurantName));
    notifyListeners();
  }

  void removeItem(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

class OrderProvider with ChangeNotifier {
  final ApiService _apiService;

  OrderProvider(this._apiService);

  Future<void> addOrder(List<CartItem> items, double total) async {
    final itemList = items.map((item) => item.toJson()).toList();
    await _apiService.placeOrder(itemList, total);
    notifyListeners();
  }
}