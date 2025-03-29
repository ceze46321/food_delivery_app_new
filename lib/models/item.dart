import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color brandTeal = Color(0xFF26A69A);
const Color brandOrange = Color(0xFFFF7043);
const Color brandCream = Color(0xFFFFF8E1);
const Color brandGray = Color(0xFF37474F);

class Item {
  final String name;
  final double price;
  final String restaurantName;
  final int calories;

  Item({
    required this.name,
    required this.price,
    required this.restaurantName,
    this.calories = 0,
  });
}

class Cart with ChangeNotifier {
  final List<Item> _items = [];

  List<Item> get items => _items;

  double get total => _items.fold(0, (sum, item) => sum + item.price);

  void addItem(String name, double price, String restaurantName) {
    _items.add(Item(name: name, price: price, restaurantName: restaurantName));
    notifyListeners();
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

class FoodieDasher {
  final String id;
  String name;
  String status;
  double earnings;

  FoodieDasher({
    required this.id,
    required this.name,
    this.status = 'Available',
    this.earnings = 0.0,
  });
}

class Order {
  final String id;
  final List<Item> items;
  final double total;
  String status;
  final DateTime placedAt;
  final String notes;
  final bool isRush;
  String? dasherId;

  Order({
    required this.id,
    required this.items,
    required this.total,
    this.status = 'Placed',
    required this.placedAt,
    this.notes = '',
    this.isRush = false,
    this.dasherId,
  });
}

class OrderProvider with ChangeNotifier {
  final List<Order> _orders = [];
  final List<FoodieDasher> _dashers = [
    FoodieDasher(id: 'd1', name: 'Alex'),
    FoodieDasher(id: 'd2', name: 'Sam'),
  ];

  List<Order> get orders => _orders;
  List<FoodieDasher> get dashers => _dashers;

  void addOrder(List<Item> items, double total, {String notes = '', bool isRush = false}) {
    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      items: List.from(items),
      total: total,
      placedAt: DateTime.now(),
      notes: notes,
      isRush: isRush,
    );
    _orders.add(order);

    final availableDasher = _dashers.firstWhere(
      (dasher) => dasher.status == 'Available',
      orElse: () => FoodieDasher(id: 'd0', name: 'Default Dasher'),
    );
    order.dasherId = availableDasher.id;
    availableDasher.status = 'On Delivery';
    availableDasher.earnings += isRush ? 5.0 : 3.0;

    notifyListeners();

    int delayFactor = isRush ? 2 : 5;
    Future.delayed(Duration(seconds: delayFactor), () {
      if (_orders.contains(order)) {
        order.status = 'Preparing';
        notifyListeners();
      }
    });
    Future.delayed(Duration(seconds: delayFactor * 2), () {
      if (_orders.contains(order)) {
        order.status = 'Out for Delivery';
        notifyListeners();
      }
    });
    Future.delayed(Duration(seconds: delayFactor * 3), () {
      if (_orders.contains(order)) {
        order.status = 'Delivered';
        final dasher = _dashers.firstWhere((d) => d.id == order.dasherId!);
        dasher.status = 'Available';
        notifyListeners();
      }
    });
  }

  void updateOrderStatuses() {
    for (var order in _orders) {
      if (order.status == 'Placed') {
        order.status = 'Preparing';
      } else if (order.status == 'Preparing') order.status = 'Out for Delivery';
      else if (order.status == 'Out for Delivery') order.status = 'Delivered';
    }
    notifyListeners();
  }
}

class GroupItem extends Item {
  final String addedBy;

  GroupItem({
    required super.name,
    required super.price,
    required super.restaurantName,
    required this.addedBy,
  });
}

class GroupCart with ChangeNotifier {
  final List<GroupItem> _items = [];
  List<GroupItem> get items => _items;

  double get total => _items.fold(0, (sum, item) => sum + item.price);

  void addItem(String name, double price, String restaurantName, String addedBy) {
    _items.add(GroupItem(name: name, price: price, restaurantName: restaurantName, addedBy: addedBy));
    notifyListeners();
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

class MealPlanProvider with ChangeNotifier {
  final Map<DateTime, List<Item>> _plan = {};
  Map<DateTime, List<Item>> get plan => _plan;

  void addMeal(DateTime date, Item item) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    _plan.putIfAbsent(normalizedDate, () => []).add(item);
    notifyListeners();
  }

  void removeMeal(DateTime date, int index) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    if (_plan[normalizedDate] != null && index >= 0 && index < _plan[normalizedDate]!.length) {
      _plan[normalizedDate]!.removeAt(index);
      if (_plan[normalizedDate]!.isEmpty) _plan.remove(normalizedDate);
      notifyListeners();
    }
  }

  int totalCalories(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _plan[normalizedDate]?.fold(0, (sum, item) => sum + item.calories) ?? 0;
  }
}

class LoyaltyProvider with ChangeNotifier {
  int _orderCount = 0;
  final List<String> _nfts = [];
  List<String> get nfts => _nfts;
  int get orderCount => _orderCount;

  void incrementOrder() {
    _orderCount++;
    if (_orderCount % 5 == 0) {
      _nfts.add('FoodieNFT-${DateTime.now().millisecondsSinceEpoch}');
      notifyListeners();
    }
  }

  void reset() {
    _orderCount = 0;
    _nfts.clear();
    notifyListeners();
  }
}

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeData getTheme() {
    return _isDarkMode
        ? ThemeData.dark().copyWith(
            primaryColor: brandTeal,
            scaffoldBackgroundColor: Colors.grey[900],
            appBarTheme: const AppBarTheme(backgroundColor: brandTeal, foregroundColor: Colors.white),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: brandOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
          )
        : ThemeData(
            primaryColor: brandTeal,
            scaffoldBackgroundColor: brandCream,
            appBarTheme: const AppBarTheme(backgroundColor: brandTeal, foregroundColor: Colors.white, elevation: 0),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: brandOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            textTheme: GoogleFonts.poppinsTextTheme(),
          );
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}