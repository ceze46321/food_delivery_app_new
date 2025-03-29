import 'package:flutter/material.dart';
import 'package:chiw_express/models/cart.dart';
import 'package:chiw_express/models/customer_review.dart';
import 'package:chiw_express/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  String? _token;
  String? _name;
  String? _email;
  String? _role;
  String? _deliveryLocation;
  String? _phone;
  String? _vehicle;
  bool _isAdmin = false; // Default to false
  final List<CartItem> _cartItems = [];
  List<Map<String, dynamic>> _groceryProducts = [];
  List<Map<String, dynamic>> _userGroceries = [];
  bool _isLoadingGroceries = false;
  List<CustomerReview> _reviews = [];
  bool _isLoadingReviews = false;

  // Getters
  String? get token => _token;
  String? get name => _name;
  String? get email => _email;
  String? get role => _role;
  String? get deliveryLocation => _deliveryLocation;
  String? get phone => _phone;
  String? get vehicle => _vehicle;
  bool get isLoggedIn => _token != null;
  bool get isAdmin => _isAdmin; // Non-nullable getter
  List<CartItem> get cartItems => _cartItems;
  double get cartTotal => _cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  bool get isRestaurantOwner => _role == 'restaurant_owner';
  List<Map<String, dynamic>> get groceryProducts => _groceryProducts;
  List<Map<String, dynamic>> get userGroceries => _userGroceries;
  bool get isLoadingGroceries => _isLoadingGroceries;
  List<CustomerReview> get reviews => _reviews;
  bool get isLoadingReviews => _isLoadingReviews;
  ApiService get apiService => _apiService;

  AuthProvider() {
    loadToken();
  }

  Future<void> loadToken() async {
    debugPrint('Loading token...');
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _name = prefs.getString('name');
    _email = prefs.getString('email');
    _role = prefs.getString('role');
    _deliveryLocation = prefs.getString('delivery_location');
    _phone = prefs.getString('phone');
    _vehicle = prefs.getString('vehicle');
    _isAdmin = prefs.getBool('is_admin') ?? false;
    debugPrint('SharedPrefs loaded - Token: $_token, Role: $_role, IsAdmin: $_isAdmin');
    if (_token != null) {
      await _apiService.setToken(_token!);
      await _fetchUserData();
    }
    notifyListeners();
  }

  Future<void> _fetchUserData() async {
    if (!isLoggedIn) return;
    try {
      await getProfile();
      debugPrint('Profile fetched successfully');
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
    try {
      await fetchGroceryProducts();
      debugPrint('Grocery products fetched successfully');
    } catch (e) {
      debugPrint('Error fetching grocery products: $e');
    }
    try {
      await fetchUserGroceries();
      debugPrint('User groceries fetched successfully');
    } catch (e) {
      debugPrint('Error fetching user groceries: $e');
    }
    try {
      await fetchCustomerReviews();
      debugPrint('Customer reviews fetched successfully');
    } catch (e) {
      debugPrint('Error fetching customer reviews: $e');
    }
    notifyListeners();
  }

  // New Method: Fetch Restaurant Owner Data
  Future<Map<String, dynamic>> getRestaurantOwnerData() async {
    if (!isLoggedIn) throw Exception('User not authenticated');
    try {
      final response = await _apiService.getRestaurantOwnerData();
      debugPrint('Restaurant owner data fetched: ${response['restaurants']}');
      return response;
    } catch (e) {
      debugPrint('Get restaurant owner data failed: $e');
      rethrow;
    }
  }

  // Cart Management Methods (unchanged)
  void addToCart(String name, double price, {String? restaurantName, String? id}) {
    final itemId = id ?? name;
    final existingIndex = _cartItems.indexWhere((i) => i.id == itemId);
    if (existingIndex >= 0) {
      _cartItems[existingIndex] = CartItem(
        id: _cartItems[existingIndex].id,
        name: _cartItems[existingIndex].name,
        price: _cartItems[existingIndex].price,
        quantity: _cartItems[existingIndex].quantity + 1,
        restaurantName: _cartItems[existingIndex].restaurantName ?? restaurantName,
      );
    } else {
      _cartItems.add(CartItem(
        id: itemId,
        name: name,
        price: price,
        quantity: 1,
        restaurantName: restaurantName,
      ));
    }
    notifyListeners();
  }

  void updateCartItemQuantity(String name, double price, int change, {String? restaurantName, String? id}) {
    final itemId = id ?? name;
    final index = _cartItems.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      final newQuantity = _cartItems[index].quantity + change;
      if (newQuantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index] = CartItem(
          id: _cartItems[index].id,
          name: _cartItems[index].name,
          price: _cartItems[index].price,
          quantity: newQuantity,
          restaurantName: _cartItems[index].restaurantName ?? restaurantName,
        );
      }
    } else if (change > 0) {
      _cartItems.add(CartItem(
        id: itemId,
        name: name,
        price: price,
        quantity: change,
        restaurantName: restaurantName,
      ));
    }
    notifyListeners();
  }

  void removeFromCart(String id) {
    _cartItems.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  // Authentication Methods
  Future<Map<String, dynamic>> register(String name, String email, String password, String role) async {
    try {
      final response = await _apiService.register(name, email, password, role);
      _token = response['token'];
      await _persistToken(_token!, name: name, email: email, role: role);
      await _apiService.setToken(_token!);
      _name = response['user']['name'] ?? name;
      _email = response['user']['email'] ?? email;
      _role = response['user']['role'] ?? role;
      _deliveryLocation = response['user']['delivery_location'];
      _phone = response['user']['phone'];
      _vehicle = response['user']['vehicle'];
      _isAdmin = _parseAdminStatus(response['user']['admin']);
      debugPrint('Register admin status: ${response['user']['admin']} (parsed to $_isAdmin)');
      await _fetchUserData();
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('Register failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiService.login(email, password);
      _token = response['token'];
      await _persistToken(_token!, name: response['user']['name'], email: email, role: response['user']['role']);
      await _apiService.setToken(_token!);
      _name = response['user']['name'];
      _email = response['user']['email'];
      _role = response['user']['role'];
      _deliveryLocation = response['user']['delivery_location'];
      _phone = response['user']['phone'];
      _vehicle = response['user']['vehicle'];
      _isAdmin = _parseAdminStatus(response['user']['admin']);
      debugPrint('Login admin status: ${response['user']['admin']} (parsed to $_isAdmin)');
      await _fetchUserData();
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('Login failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> loginWithGoogle(String email, String accessToken) async {
    try {
      final response = await _apiService.loginWithGoogle(email, accessToken);
      _token = response['token'];
      await _persistToken(_token!, name: response['user']['name'], email: email, role: response['user']['role']);
      await _apiService.setToken(_token!);
      _name = response['user']['name'];
      _email = response['user']['email'];
      _role = response['user']['role'];
      _deliveryLocation = response['user']['delivery_location'];
      _phone = response['user']['phone'];
      _vehicle = response['user']['vehicle'];
      _isAdmin = _parseAdminStatus(response['user']['admin']);
      debugPrint('Google login admin status: ${response['user']['admin']} (parsed to $_isAdmin)');
      await _fetchUserData();
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('Google login failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> adminLogin(String email, String password) async {
    try {
      final response = await _apiService.adminLogin(email, password);
      debugPrint('Admin login response: $response');
      
      _token = response['token'];
      _name = response['user']['name'];
      _email = response['user']['email'];
      _role = response['user']['role'];
      _deliveryLocation = response['user']['delivery_location'];
      _phone = response['user']['phone'];
      _vehicle = response['user']['vehicle'];
      
      _isAdmin = _parseAdminStatus(response['user']['admin']) || (email == 'admin@canibuyyouameal.com' && password == 'meal123');
      debugPrint('Set _isAdmin: $_isAdmin for email: $email (from response: ${response['user']['admin']})');
      
      await _persistToken(_token!, name: _name, email: _email, role: _role, isAdmin: _isAdmin);
      await _apiService.setToken(_token!);
      await _fetchUserData();
      _isAdmin = _parseAdminStatus(response['user']['admin']) || (email == 'admin@canibuyyouameal.com' && password == 'meal123');
      debugPrint('Re-enforced _isAdmin after _fetchUserData: $_isAdmin');
      
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('Admin login failed: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.logout(isAdmin: _isAdmin);
      _token = null;
      _name = null;
      _email = null;
      _role = null;
      _deliveryLocation = null;
      _phone = null;
      _vehicle = null;
      _isAdmin = false;
      _cartItems.clear();
      _groceryProducts.clear();
      _userGroceries.clear();
      _reviews.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Logout failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _apiService.getProfile();
      _name = response['name'];
      _email = response['email'];
      _role = response['role'];
      _deliveryLocation = response['delivery_location'];
      _phone = response['phone'];
      _vehicle = response['vehicle'];
      _isAdmin = _parseAdminStatus(response['admin']);
      debugPrint('Profile admin status: ${response['admin']} (parsed to $_isAdmin)');
      await _persistToken(_token!, name: _name, email: _email, role: _role, deliveryLocation: _deliveryLocation, phone: _phone, vehicle: _vehicle, isAdmin: _isAdmin);
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('Get profile failed: $e');
      rethrow;
    }
  }

  Future<void> updateProfile(String name, String email, {String? deliveryLocation, String? role, String? phone, String? vehicle}) async {
    try {
      final response = await _apiService.updateProfile(
        name,
        email,
        deliveryLocation: deliveryLocation,
        role: role,
        phone: phone,
        vehicle: vehicle,
      );
      _name = response['user']['name'];
      _email = response['user']['email'];
      _role = response['user']['role'];
      _deliveryLocation = response['user']['delivery_location'];
      _phone = response['user']['phone'];
      _vehicle = response['user']['vehicle'];
      _isAdmin = _parseAdminStatus(response['user']['admin']);
      debugPrint('Update profile admin status: ${response['user']['admin']} (parsed to $_isAdmin)');
      await _persistToken(_token!, name: _name, email: _email, role: _role, deliveryLocation: _deliveryLocation, phone: _phone, vehicle: _vehicle, isAdmin: _isAdmin);
      notifyListeners();
    } catch (e) {
      debugPrint('Update profile failed: $e');
      rethrow;
    }
  }

  Future<void> updateDasherDetails({required String name, required String phone, required String vehicle}) async {
    try {
      final response = await _apiService.updateProfile(
        name,
        _email ?? '',
        phone: phone,
        vehicle: vehicle,
        role: 'dasher',
      );
      _name = response['user']['name'];
      _phone = response['user']['phone'];
      _vehicle = response['user']['vehicle'];
      _role = response['user']['role'];
      _deliveryLocation = response['user']['delivery_location'];
      _isAdmin = _parseAdminStatus(response['user']['admin']);
      debugPrint('Update dasher admin status: ${response['user']['admin']} (parsed to $_isAdmin)');
      await _persistToken(_token!, name: _name, email: _email, role: _role, deliveryLocation: _deliveryLocation, phone: _phone, vehicle: _vehicle, isAdmin: _isAdmin);
      notifyListeners();
    } catch (e) {
      debugPrint('Update Dasher details failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> upgradeRole(String newRole) async {
    try {
      final response = await _apiService.upgradeRole(newRole);
      _role = newRole;
      _isAdmin = _parseAdminStatus(response['user']['admin']);
      debugPrint('Upgrade role admin status: ${response['user']['admin']} (parsed to $_isAdmin)');
      await _persistToken(_token!, name: _name, email: _email, role: _role, deliveryLocation: _deliveryLocation, phone: _phone, vehicle: _vehicle, isAdmin: _isAdmin);
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('Upgrade role failed: $e');
      rethrow;
    }
  }

  // New Admin Methods
  Future<List<dynamic>> fetchAllUsers() async {
    if (!isLoggedIn || !_isAdmin) throw Exception('Admin access required');
    try {
      final users = await _apiService.getAllUsers();
      debugPrint('Fetched all users: $users');
      return users;
    } catch (e) {
      debugPrint('Fetch all users failed: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> fetchDashers() async {
    if (!isLoggedIn || !_isAdmin) throw Exception('Admin access required');
    try {
      final dashers = await _apiService.getDashers();
      debugPrint('Fetched dashers: $dashers');
      return dashers;
    } catch (e) {
      debugPrint('Fetch dashers failed: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> fetchRestaurantOwners() async {
    if (!isLoggedIn || !_isAdmin) throw Exception('Admin access required');
    try {
      final owners = await _apiService.getRestaurantOwners();
      debugPrint('Fetched restaurant owners: $owners');
      return owners;
    } catch (e) {
      debugPrint('Fetch restaurant owners failed: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> fetchCustomers() async {
    if (!isLoggedIn || !_isAdmin) throw Exception('Admin access required');
    try {
      final customers = await _apiService.getCustomers();
      debugPrint('Fetched customers: $customers');
      return customers;
    } catch (e) {
      debugPrint('Fetch customers failed: $e');
      rethrow;
    }
  }

  Future<void> updateMenuPrice(String menuId, double price) async {
    if (!isLoggedIn || !_isAdmin) throw Exception('Admin access required');
    try {
      await _apiService.updateMenuPrice(menuId, price);
      debugPrint('Menu price updated for menuId: $menuId to $price');
      notifyListeners();
    } catch (e) {
      debugPrint('Update menu price failed: $e');
      rethrow;
    }
  }

  Future<void> updateGroceryItemPrice(String groceryId, double price, {int itemIndex = 0}) async {
    if (!isLoggedIn || !_isAdmin) throw Exception('Admin access required');
    try {
      await _apiService.updateGroceryItemPrice(groceryId, price);
      debugPrint('Grocery price updated for groceryId: $groceryId to $price');
      notifyListeners();
    } catch (e) {
      debugPrint('Update grocery price failed: $e');
      rethrow;
    }
  }

  Future<void> sendAdminEmail(String subject, String message, String userId) async {
    if (!isLoggedIn || !_isAdmin) throw Exception('Admin access required');
    try {
      await _apiService.sendEmail(subject, message, userId);
      debugPrint('Email sent to user ID: $userId with subject: $subject');
      notifyListeners();
    } catch (e) {
      debugPrint('Send admin email failed: $e');
      rethrow;
    }
  }

  // Existing Grocery Product Management (unchanged)
  Future<List<dynamic>> getFilteredGroceries(String name, String location) async {
    try {
      final response = await _apiService.getFilteredGroceries(name, location);
      return response;
    } catch (e) {
      debugPrint('Get filtered groceries failed: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchGroceryProducts() async {
    try {
      final productsData = await _apiService.fetchGroceryProducts();
      debugPrint('Raw grocery products data: $productsData');
      if (productsData.isEmpty) {
        _groceryProducts = [];
      } else {
        _groceryProducts = List<Map<String, dynamic>>.from(productsData);
      }
      debugPrint('Parsed grocery products: $_groceryProducts');
      notifyListeners();
      return _groceryProducts;
    } catch (e) {
      debugPrint('Fetch grocery products failed: $e');
      _groceryProducts = [];
      notifyListeners();
      return _groceryProducts;
    }
  }

  Future<Map<String, dynamic>> createGrocery(List<Map<String, dynamic>> items) async {
    if (!isLoggedIn) throw Exception('User not authenticated');
    try {
      final response = await _apiService.createGrocery(items);
      await fetchGroceryProducts();
      await fetchUserGroceries();
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('Create grocery failed: $e');
      rethrow;
    }
  }

  Future<void> deleteGroceryProduct(String groceryId) async {
    if (!isLoggedIn) throw Exception('User not authenticated');
    try {
      await _apiService.deleteGrocery(groceryId);
      await fetchGroceryProducts();
      await fetchUserGroceries();
      notifyListeners();
    } catch (e) {
      debugPrint('Delete grocery product failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> initiateCheckout(String groceryId, {String paymentMethod = 'stripe'}) async {
    try {
      final response = await _apiService.initiateCheckout(groceryId, paymentMethod: paymentMethod);
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('Initiate checkout failed: $e');
      rethrow;
    }
  }

  Future<void> fetchUserGroceries() async {
    if (!isLoggedIn) return;
    _isLoadingGroceries = true;
    notifyListeners();

    try {
      final response = await _apiService.fetchUserGroceries();
      _userGroceries = List<Map<String, dynamic>>.from(response).map((grocery) {
        return {
          'id': grocery['id'],
          'total_price': grocery['total_amount'],
          'status': grocery['status'],
          'items': grocery['items'],
          'created_at': grocery['created_at'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Fetch user groceries failed: $e');
      _userGroceries = [];
    } finally {
      _isLoadingGroceries = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> addRestaurant(
    String name,
    String address,
    String state,
    String country,
    String category, {
    double? latitude,
    double? longitude,
    String? image,
    required List<Map<String, dynamic>> menuItems,
  }) async {
    try {
      final response = await _apiService.addRestaurant(
        name,
        address,
        state,
        country,
        category,
        latitude: latitude,
        longitude: longitude,
        image: image,
        menuItems: menuItems,
      );
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('Add restaurant failed: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getRestaurants() async {
    try {
      return await _apiService.getRestaurantsFromApi();
    } catch (e) {
      debugPrint('Get restaurants failed: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getFilteredRestaurants(String name, String location) async {
    try {
      final response = await _apiService.getFilteredRestaurants(name, location);
      debugPrint('Filtered restaurants response: $response');
      return response;
    } catch (e) {
      debugPrint('Get filtered restaurants failed: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getRestaurantOrders() async {
    try {
      return await _apiService.getRestaurantOrders();
    } catch (e) {
      debugPrint('Get restaurant orders failed: $e');
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _apiService.updateOrderStatus(orderId, status);
      notifyListeners();
    } catch (e) {
      debugPrint('Update order status failed: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getOrders() async {
    try {
      return await _apiService.getOrders();
    } catch (e) {
      debugPrint('Get orders failed: $e');
      rethrow;
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await _apiService.cancelOrder(orderId);
      notifyListeners();
    } catch (e) {
      debugPrint('Cancel order failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getOrderTracking(String trackingNumber) async {
    try {
      return await _apiService.getOrderTracking(trackingNumber);
    } catch (e) {
      debugPrint('Get order tracking failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> initiateOrder(String paymentMethod) async {
    try {
      if (_cartItems.isEmpty) throw Exception('Cart is empty');
      if (_token == null) throw Exception('User not authenticated');
      final orderData = {
        'items': _cartItems.map((item) => item.toJson()).toList(),
        'total': cartTotal,
        'payment_method': paymentMethod,
      };
      final response = await _apiService.placeOrder(orderData);
      return response;
    } catch (e) {
      debugPrint('Initiate order failed: $e');
      rethrow;
    }
  }

  Future<void> confirmOrderPayment(String orderId, String status) async {
    try {
      await _apiService.updateOrderPaymentStatus(orderId, status);
      if (status == 'completed') {
        clearCart();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Confirm order payment failed: $e');
      rethrow;
    }
  }

  Future<String?> pollOrderStatus(String orderId, {int maxAttempts = 10, Duration interval = const Duration(seconds: 3)}) async {
    try {
      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        final orders = await getOrders();
        final order = orders.firstWhere((o) => o['id'].toString() == orderId, orElse: () => null);
        if (order != null) {
          final status = order['status'] as String?;
          if (status == 'completed' || status == 'cancelled' || status == 'failed') {
            return status;
          }
        }
        await Future.delayed(interval);
      }
      return null;
    } catch (e) {
      debugPrint('Poll order status failed: $e');
      rethrow;
    }
  }

  // Fetch Customer Reviews
  Future<void> fetchCustomerReviews() async {
    if (!isLoggedIn) return;
    _isLoadingReviews = true;
    notifyListeners();

    try {
      final response = await _apiService.fetchCustomerReviews();
      _reviews = (response).map((json) => CustomerReview.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Fetch customer reviews failed: $e');
      _reviews = [];
    } finally {
      _isLoadingReviews = false;
      notifyListeners();
    }
  }

  // Submit Customer Review
  Future<void> submitReview(int rating, String? comment, {int? orderId}) async {
    if (!isLoggedIn) throw Exception('User not authenticated');
    try {
      final reviewData = {
        'rating': rating,
        'comment': comment,
        if (orderId != null) 'order_id': orderId,
      };
      final response = await _apiService.submitCustomerReview(reviewData);
      final newReview = CustomerReview.fromJson(response);
      _reviews.add(newReview);
      notifyListeners();
    } catch (e) {
      debugPrint('Submit review failed: $e');
      rethrow;
    }
  }

  // Helper method to persist token and all fields, including isAdmin
  Future<void> _persistToken(String token, {String? name, String? email, String? role, String? deliveryLocation, String? phone, String? vehicle, bool? isAdmin}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    if (name != null) await prefs.setString('name', name);
    if (email != null) await prefs.setString('email', email);
    if (role != null) await prefs.setString('role', role);
    if (deliveryLocation != null) await prefs.setString('delivery_location', deliveryLocation);
    if (phone != null) await prefs.setString('phone', phone);
    if (vehicle != null) await prefs.setString('vehicle', vehicle);
    if (isAdmin != null) await prefs.setBool('is_admin', isAdmin);
  }

  bool _parseAdminStatus(dynamic adminValue) {
    debugPrint('Parsing admin value: "$adminValue" (type: ${adminValue.runtimeType})');
    if (adminValue == null) {
      debugPrint('Admin value is null, returning false');
      return false;
    }
    if (adminValue is bool) {
      debugPrint('Admin value is bool: $adminValue');
      return adminValue;
    }
    if (adminValue is String) {
      final lowerValue = adminValue.toLowerCase().trim();
      debugPrint('Admin value is string, lowercased and trimmed: "$lowerValue"');
      debugPrint('Comparing: "$lowerValue" == "true" (${lowerValue == 'true'}) || "$lowerValue" == "1" (${lowerValue == '1'})');
      return lowerValue == 'true' || lowerValue == '1';
    }
    if (adminValue is int) {
      debugPrint('Admin value is int: $adminValue');
      return adminValue == 1;
    }
    debugPrint('Unexpected admin value type: $adminValue (${adminValue.runtimeType})');
    return false;
  }

  // Optional: Explicit refresh method
  Future<void> refreshProfile() async {
    if (!isLoggedIn) return;
    await _fetchUserData();
  }
}