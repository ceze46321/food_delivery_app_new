import 'dart:convert'; // Added for jsonEncode
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
  bool _isAdmin = false;
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
  bool get isAdmin => _isAdmin;
  List<CartItem> get cartItems => _cartItems;
  double get cartTotal =>
      _cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
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
    debugPrint('Loading token from SharedPreferences...');
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _name = prefs.getString('name');
    _email = prefs.getString('email');
    _role = prefs.getString('role');
    _deliveryLocation = prefs.getString('delivery_location');
    _phone = prefs.getString('phone');
    _vehicle = prefs.getString('vehicle');
    _isAdmin = prefs.getBool('is_admin') ?? false;
    debugPrint('Loaded - Token: $_token, Role: $_role, IsAdmin: $_isAdmin');
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
    } catch (e, stackTrace) {
      debugPrint('Error fetching profile: $e\n$stackTrace');
    }
    try {
      await fetchGroceryProducts();
      debugPrint('Grocery products fetched successfully');
    } catch (e, stackTrace) {
      debugPrint('Error fetching grocery products: $e\n$stackTrace');
    }
    try {
      await fetchUserGroceries();
      debugPrint('User groceries fetched successfully');
    } catch (e, stackTrace) {
      debugPrint('Error fetching user groceries: $e\n$stackTrace');
    }
    try {
      await fetchCustomerReviews();
      debugPrint('Customer reviews fetched successfully');
    } catch (e, stackTrace) {
      debugPrint('Error fetching customer reviews: $e\n$stackTrace');
    }
    notifyListeners();
  }

  // Cart Management Methods
  void addToCart(String name, double price,
      {String? restaurantName, String? id}) {
    final itemId = id ??
        '${name}_${restaurantName ?? DateTime.now().millisecondsSinceEpoch}';
    final existingIndex = _cartItems.indexWhere((i) => i.id == itemId);
    if (existingIndex >= 0) {
      _cartItems[existingIndex] = CartItem(
        id: _cartItems[existingIndex].id,
        name: _cartItems[existingIndex].name,
        price: _cartItems[existingIndex].price,
        quantity: _cartItems[existingIndex].quantity + 1,
        restaurantName:
            _cartItems[existingIndex].restaurantName ?? restaurantName,
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
    debugPrint(
        'Added to cart: $name (ID: $itemId), Total items: ${_cartItems.length}');
    notifyListeners();
  }

  void updateCartItemQuantity(String name, double price, int change,
      {String? restaurantName, String? id}) {
    final itemId = id ??
        '${name}_${restaurantName ?? DateTime.now().millisecondsSinceEpoch}';
    final index = _cartItems.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      final newQuantity = _cartItems[index].quantity + change;
      if (newQuantity <= 0) {
        _cartItems.removeAt(index);
        debugPrint('Removed from cart: $name (ID: $itemId)');
      } else {
        _cartItems[index] = CartItem(
          id: _cartItems[index].id,
          name: _cartItems[index].name,
          price: _cartItems[index].price,
          quantity: newQuantity,
          restaurantName: _cartItems[index].restaurantName ?? restaurantName,
        );
        debugPrint(
            'Updated cart quantity: $name (ID: $itemId) to $newQuantity');
      }
    } else if (change > 0) {
      _cartItems.add(CartItem(
        id: itemId,
        name: name,
        price: price,
        quantity: change,
        restaurantName: restaurantName,
      ));
      debugPrint('Added new item to cart: $name (ID: $itemId)');
    }
    notifyListeners();
  }

  void removeFromCart(String id) {
    _cartItems.removeWhere((item) => item.id == id);
    debugPrint(
        'Removed from cart by ID: $id, Remaining items: ${_cartItems.length}');
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    debugPrint('Cart cleared');
    notifyListeners();
  }

  // Authentication Methods
  Future<Map<String, dynamic>> register(
      String name, String email, String password, String role) async {
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
      debugPrint(
          'Register successful - Token: $_token, Role: $_role, IsAdmin: $_isAdmin');
      await _fetchUserData();
      notifyListeners();
      return response;
    } catch (e, stackTrace) {
      debugPrint('Register failed: $e\n$stackTrace');
      throw Exception('Failed to register: $e');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiService.login(email, password);
      _token = response['token'];
      await _persistToken(_token!,
          name: response['user']['name'],
          email: email,
          role: response['user']['role']);
      await _apiService.setToken(_token!);
      _name = response['user']['name'];
      _email = response['user']['email'];
      _role = response['user']['role'];
      _deliveryLocation = response['user']['delivery_location'];
      _phone = response['user']['phone'];
      _vehicle = response['user']['vehicle'];
      _isAdmin = _parseAdminStatus(response['user']['admin']);
      debugPrint(
          'Login successful - Token: $_token, Role: $_role, IsAdmin: $_isAdmin');
      await _fetchUserData();
      notifyListeners();
      return response;
    } catch (e, stackTrace) {
      debugPrint('Login failed: $e\n$stackTrace');
      throw Exception('Failed to login: $e');
    }
  }

  Future<Map<String, dynamic>> loginWithGoogle(
      String email, String accessToken) async {
    try {
      final response = await _apiService.loginWithGoogle(email, accessToken);
      _token = response['token'];
      await _persistToken(_token!,
          name: response['user']['name'],
          email: email,
          role: response['user']['role']);
      await _apiService.setToken(_token!);
      _name = response['user']['name'];
      _email = response['user']['email'];
      _role = response['user']['role'];
      _deliveryLocation = response['user']['delivery_location'];
      _phone = response['user']['phone'];
      _vehicle = response['user']['vehicle'];
      _isAdmin = _parseAdminStatus(response['user']['admin']);
      debugPrint(
          'Google login successful - Token: $_token, Role: $_role, IsAdmin: $_isAdmin');
      await _fetchUserData();
      notifyListeners();
      return response;
    } catch (e, stackTrace) {
      debugPrint('Google login failed: $e\n$stackTrace');
      throw Exception('Failed to login with Google: $e');
    }
  }

  Future<Map<String, dynamic>> adminLogin(String email, String password) async {
    try {
      final response = await _apiService.adminLogin(email, password);
      _token = response['token'];
      await _persistToken(_token!,
          name: response['user']['name'],
          email: email,
          role: response['user']['role'],
          isAdmin: true);
      await _apiService.setToken(_token!);
      _name = response['user']['name'];
      _email = response['user']['email'];
      _role = response['user']['role'];
      _deliveryLocation = response['user']['delivery_location'];
      _phone = response['user']['phone'];
      _vehicle = response['user']['vehicle'];
      _isAdmin = _parseAdminStatus(response['user']['admin']) || true;
      debugPrint(
          'Admin login successful - Token: $_token, Role: $_role, IsAdmin: $_isAdmin');
      await _fetchUserData();
      notifyListeners();
      return response;
    } catch (e, stackTrace) {
      debugPrint('Admin login failed: $e\n$stackTrace');
      throw Exception('Failed to login as admin: $e');
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
      debugPrint('Logout successful');
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Logout failed: $e\n$stackTrace');
      throw Exception('Failed to logout: $e');
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _apiService.get('/profile');
      _name = response['name']?.toString();
      _email = response['email']?.toString();
      _role = response['role']?.toString();
      _deliveryLocation = response['delivery_location']?.toString();
      _phone = response['phone']?.toString();
      _vehicle = response['vehicle']?.toString();
      _isAdmin = _parseAdminStatus(response['admin']);
      debugPrint('Profile fetched - Role: $_role, IsAdmin: $_isAdmin');
      await _persistToken(_token!,
          name: _name,
          email: _email,
          role: _role,
          deliveryLocation: _deliveryLocation,
          phone: _phone,
          vehicle: _vehicle,
          isAdmin: _isAdmin);
      notifyListeners();
      return response;
    } catch (e, stackTrace) {
      debugPrint('Get profile failed: $e\n$stackTrace');
      throw Exception('Failed to get profile: $e');
    }
  }

  Future<void> updateProfile(
    String name,
    String email, {
    String? role,
    String? phone,
    String? vehicle,
    String? deliveryLocation,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'name': name,
        'email': email,
        if (role != null) 'role': role,
        if (phone != null) 'phone': phone,
        if (vehicle != null) 'vehicle': vehicle,
        if (deliveryLocation != null) 'delivery_location': deliveryLocation,
      };

      debugPrint('Sending PUT request to update profile with data: $data');
      final response = await _apiService.put('/profile', data);
      debugPrint('Update profile response: $response');

      // Update local state with the response data (assuming API returns updated user data)
      _name = response['name']?.toString() ?? name;
      _email = response['email']?.toString() ?? email;
      _role = response['role']?.toString() ?? role ?? _role;
      _phone = response['phone']?.toString() ?? phone ?? _phone;
      _vehicle = response['vehicle']?.toString() ?? vehicle ?? _vehicle;
      _deliveryLocation = response['delivery_location']?.toString() ??
          deliveryLocation ??
          _deliveryLocation;

      // Persist the updated data
      await _persistToken(
        _token!,
        name: _name,
        email: _email,
        role: _role,
        phone: _phone,
        vehicle: _vehicle,
        deliveryLocation: _deliveryLocation,
        isAdmin: _isAdmin,
      );

      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Error updating profile: $e\n$stackTrace');
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> updateDasherDetails(
      {required String name,
      required String phone,
      required String vehicle}) async {
    try {
      final response = await _apiService.put('/profile', {
        'name': name,
        'email': _email ?? '',
        'phone': phone,
        'vehicle': vehicle,
        'role': 'dasher',
      });
      _name = response['name']?.toString();
      _phone = response['phone']?.toString();
      _vehicle = response['vehicle']?.toString();
      _role = response['role']?.toString();
      _deliveryLocation = response['delivery_location']?.toString();
      _isAdmin = _parseAdminStatus(response['admin']);
      debugPrint('Dasher details updated - Role: $_role, IsAdmin: $_isAdmin');
      await _persistToken(_token!,
          name: _name,
          email: _email,
          role: _role,
          deliveryLocation: _deliveryLocation,
          phone: _phone,
          vehicle: _vehicle,
          isAdmin: _isAdmin);
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Update dasher details failed: $e\n$stackTrace');
      throw Exception('Failed to update dasher details: $e');
    }
  }

  Future<Map<String, dynamic>> upgradeRole(String newRole) async {
    try {
      final response =
          await _apiService.post('/upgrade-role', {'role': newRole});
      _role = newRole;
      _isAdmin = _parseAdminStatus(response['user']['admin']);
      debugPrint('Role upgraded to: $_role, IsAdmin: $_isAdmin');
      await _persistToken(_token!,
          name: _name,
          email: _email,
          role: _role,
          deliveryLocation: _deliveryLocation,
          phone: _phone,
          vehicle: _vehicle,
          isAdmin: _isAdmin);
      notifyListeners();
      return response;
    } catch (e, stackTrace) {
      debugPrint('Upgrade role failed: $e\n$stackTrace');
      throw Exception('Failed to upgrade role: $e');
    }
  }

  // Admin Methods
  Future<List<dynamic>> fetchAllUsers() async {
    if (!isLoggedIn || !_isAdmin) throw Exception('Admin access required');
    try {
      final users = await _apiService.getAllUsers();
      debugPrint('Fetched all users: ${users.length}');
      return users;
    } catch (e, stackTrace) {
      debugPrint('Fetch all users failed: $e\n$stackTrace');
      throw Exception('Failed to fetch all users: $e');
    }
  }

  Future<List<dynamic>> fetchDashers() async {
    if (!isLoggedIn || !_isAdmin) throw Exception('Admin access required');
    try {
      final dashers = await _apiService.getDashers();
      debugPrint('Fetched dashers: ${dashers.length}');
      return dashers;
    } catch (e, stackTrace) {
      debugPrint('Fetch dashers failed: $e\n$stackTrace');
      throw Exception('Failed to fetch dashers: $e');
    }
  }

  Future<List<dynamic>> fetchRestaurantOwners() async {
    if (!isLoggedIn || !_isAdmin) throw Exception('Admin access required');
    try {
      final owners = await _apiService.getRestaurantOwners();
      debugPrint('Fetched restaurant owners: ${owners.length}');
      return owners;
    } catch (e, stackTrace) {
      debugPrint('Fetch restaurant owners failed: $e\n$stackTrace');
      throw Exception('Failed to fetch restaurant owners: $e');
    }
  }

  Future<List<dynamic>> fetchCustomers() async {
    if (!isLoggedIn || !_isAdmin) throw Exception('Admin access required');
    try {
      final customers = await _apiService.getCustomers();
      debugPrint('Fetched customers: ${customers.length}');
      return customers;
    } catch (e, stackTrace) {
      debugPrint('Fetch customers failed: $e\n$stackTrace');
      throw Exception('Failed to fetch customers: $e');
    }
  }

  Future<void> updateMenuPrice(String menuId, double price) async {
    if (!isLoggedIn || !_isAdmin) throw Exception('Admin access required');
    try {
      await _apiService.updateMenuPrice(menuId, price);
      debugPrint('Menu price updated for menuId: $menuId to $price');
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Update menu price failed: $e\n$stackTrace');
      throw Exception('Failed to update menu price: $e');
    }
  }

  Future<void> updateGroceryItemPrice(String groceryId, double price,
      {int itemIndex = 0}) async {
    if (!isLoggedIn || !_isAdmin) throw Exception('Admin access required');
    try {
      await _apiService.updateGroceryItemPrice(groceryId, price,
          itemIndex: itemIndex);
      debugPrint('Grocery price updated for groceryId: $groceryId to $price');
      await fetchGroceryProducts();
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Update grocery price failed: $e\n$stackTrace');
      throw Exception('Failed to update grocery price: $e');
    }
  }

  Future<void> sendAdminEmail(
      String subject, String message, String userId) async {
    if (!isLoggedIn || !_isAdmin) throw Exception('Admin access required');
    try {
      await _apiService.sendEmail(subject, message, userId);
      debugPrint('Email sent to user ID: $userId with subject: $subject');
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Send admin email failed: $e\n$stackTrace');
      throw Exception('Failed to send admin email: $e');
    }
  }

  // Grocery Product Management
  Future<List<Map<String, dynamic>>> fetchGroceryProducts() async {
    _isLoadingGroceries = true;
    notifyListeners();
    try {
      final productsData = await _apiService.fetchGroceryProducts();
      _groceryProducts =
          List<Map<String, dynamic>>.from(productsData).map((product) {
        return {
          'id': product['id']?.toString() ?? 'unknown',
          'location': product['location'] ?? '',
          'items': (product['items'] as List<dynamic>?)
                  ?.map((item) => ({
                        'name': item['name']?.toString() ?? 'Unnamed',
                        'quantity': item['quantity'] ?? 1,
                        'price': (item['price'] as num?)?.toDouble() ?? 0.0,
                        'image': item['image']?.toString(),
                      }))
                  .toList() ??
              [],
        };
      }).toList();
      debugPrint('Grocery products fetched: ${_groceryProducts.length} items');
      return _groceryProducts;
    } catch (e, stackTrace) {
      debugPrint('Fetch grocery products failed: $e\n$stackTrace');
      _groceryProducts = [];
      throw Exception('Failed to fetch grocery products: $e');
    } finally {
      _isLoadingGroceries = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> getFilteredGroceries(
      String name, String location) async {
    try {
      final response = await _apiService.getFilteredGroceries(name, location);
      final filteredGroceries =
          List<Map<String, dynamic>>.from(response).map((product) {
        return {
          'id': product['id']?.toString() ?? 'unknown',
          'location': product['location'] ?? '',
          'items': (product['items'] as List<dynamic>?)
                  ?.map((item) => ({
                        'name': item['name']?.toString() ?? 'Unnamed',
                        'quantity': item['quantity'] ?? 1,
                        'price': (item['price'] as num?)?.toDouble() ?? 0.0,
                        'image': item['image']?.toString(),
                      }))
                  .toList() ??
              [],
        };
      }).toList();
      debugPrint(
          'Filtered groceries fetched: ${filteredGroceries.length} items');
      return filteredGroceries;
    } catch (e, stackTrace) {
      debugPrint('Get filtered groceries failed: $e\n$stackTrace');
      throw Exception('Failed to get filtered groceries: $e');
    }
  }

  Future<Map<String, dynamic>> createGrocery(
      List<Map<String, dynamic>> items) async {
    if (!isLoggedIn) throw Exception('User not authenticated');
    _isLoadingGroceries = true;
    notifyListeners();
    try {
      final response = await _apiService.createGrocery(items);
      debugPrint('Grocery created: $response');
      await fetchGroceryProducts();
      await fetchUserGroceries();
      return response;
    } catch (e, stackTrace) {
      debugPrint('Create grocery failed: $e\n$stackTrace');
      throw Exception('Failed to create grocery: $e');
    } finally {
      _isLoadingGroceries = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createGroceryWithPayment(
      List<Map<String, dynamic>> items,
      String paymentMethod,
      double total) async {
    if (!isLoggedIn) throw Exception('User not authenticated');
    if (items.isEmpty) throw Exception('Cart is empty');
    if (!['flutterwave', 'paystack'].contains(paymentMethod))
      throw Exception('Invalid payment method: $paymentMethod');
    _isLoadingGroceries = true;
    notifyListeners();
    try {
      final response = await _apiService.createGroceryWithPayment(
          items, paymentMethod, total);
      debugPrint('Grocery created with payment: $response');
      await fetchUserGroceries();
      return response;
    } catch (e, stackTrace) {
      debugPrint('Create grocery with payment failed: $e\n$stackTrace');
      throw Exception('Failed to create grocery with payment: $e');
    } finally {
      _isLoadingGroceries = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> initiateCheckout(String groceryId,
      {String paymentMethod = 'flutterwave'}) async {
    if (!isLoggedIn) throw Exception('User not authenticated');
    try {
      final response = await _apiService.initiateCheckout(groceryId,
          paymentMethod: paymentMethod);
      debugPrint('Checkout initiated for grocery ID: $groceryId - $response');
      return response;
    } catch (e, stackTrace) {
      debugPrint('Initiate checkout failed: $e\n$stackTrace');
      throw Exception('Failed to initiate checkout: $e');
    }
  }

  Future<void> deleteGroceryProduct(String groceryId) async {
    if (!isLoggedIn) throw Exception('User not authenticated');
    try {
      await _apiService.deleteGrocery(groceryId);
      debugPrint('Grocery product deleted: $groceryId');
      await fetchGroceryProducts();
      await fetchUserGroceries();
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Delete grocery product failed: $e\n$stackTrace');
      throw Exception('Failed to delete grocery product: $e');
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
          'id': grocery['id']?.toString() ?? 'unknown',
          'total_price': (grocery['total_amount'] as num?)?.toDouble() ?? 0.0,
          'status': grocery['status'] ?? 'unknown',
          'tracking_number': grocery['tracking_number']?.toString(),
          'items': (grocery['items'] as List<dynamic>?)
                  ?.map((item) => ({
                        'name': item['name']?.toString() ?? 'Unnamed',
                        'quantity': item['quantity'] ?? 1,
                        'price': (item['price'] as num?)?.toDouble() ?? 0.0,
                        'image': item['image']?.toString(),
                      }))
                  .toList() ??
              [],
          'created_at': grocery['created_at'] ?? '',
        };
      }).toList();
      debugPrint('User groceries fetched: ${_userGroceries.length} items');
    } catch (e, stackTrace) {
      debugPrint('Fetch user groceries failed: $e\n$stackTrace');
      _userGroceries = [];
    } finally {
      _isLoadingGroceries = false;
      notifyListeners();
    }
  }

  Future<void> refreshGroceries() async {
    if (!isLoggedIn) return;
    try {
      await fetchUserGroceries();
      debugPrint('Groceries refreshed');
    } catch (e, stackTrace) {
      debugPrint('Refresh groceries failed: $e\n$stackTrace');
      throw Exception('Failed to refresh groceries: $e');
    }
  }

  Future<String?> pollGroceryStatus(String trackingNumber,
      {int maxAttempts = 10,
      Duration interval = const Duration(seconds: 3)}) async {
    if (!isLoggedIn) throw Exception('User not authenticated');
    try {
      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        final response = await _apiService.getGroceryTracking(trackingNumber);
        final status = response['status']?.toString().toLowerCase();
        if (status == 'completed' ||
            status == 'cancelled' ||
            status == 'failed') {
          debugPrint('Grocery status polled: $trackingNumber - $status');
          if (status == 'completed') {
            _userGroceries
                .removeWhere((g) => g['tracking_number'] == trackingNumber);
            notifyListeners();
          }
          return status;
        }
        debugPrint(
            'Polling attempt $attempt for grocery tracking number: $trackingNumber');
        await Future.delayed(interval);
      }
      debugPrint(
          'Polling timed out for grocery tracking number: $trackingNumber');
      return 'pending';
    } catch (e, stackTrace) {
      debugPrint('Poll grocery status failed: $e\n$stackTrace');
      throw Exception('Failed to poll grocery status: $e');
    }
  }

  // Restaurant Management
  Future<Map<String, dynamic>> addRestaurant(
      String name, String location, String customerCarePhone,
      {String? image, required List<Map<String, dynamic>> menuItems}) async {
    if (!isLoggedIn) throw Exception('User not authenticated');
    if (!isRestaurantOwner)
      throw Exception('Only restaurant owners can add restaurants');
    try {
      final formattedMenuItems = menuItems.map((item) {
        return {
          'name': item['name'] ?? '',
          'description': item['description'] ?? '',
          'price': item['price'] ?? 0.0,
          'image': item['image'],
        };
      }).toList();
      final response = await _apiService.addRestaurant(
          name, location, customerCarePhone,
          image: image, menuItems: formattedMenuItems);
      debugPrint('Restaurant added: $response');
      notifyListeners();
      return response;
    } catch (e, stackTrace) {
      debugPrint('Add restaurant failed: $e\n$stackTrace');
      throw Exception('Failed to add restaurant: $e');
    }
  }

  Future<Map<String, dynamic>> getRestaurantOwnerData() async {
    if (!isLoggedIn) throw Exception('User not authenticated');
    try {
      final response = await _apiService.getRestaurantOwnerData();
      debugPrint('Restaurant owner data fetched: $response');
      return response;
    } catch (e, stackTrace) {
      debugPrint('Get restaurant owner data failed: $e\n$stackTrace');
      throw Exception('Failed to get restaurant owner data: $e');
    }
  }

  Future<void> deleteRestaurant(String restaurantId) async {
    if (!isLoggedIn) throw Exception('User not authenticated');
    try {
      await _apiService.deleteRestaurant(restaurantId);
      debugPrint('Restaurant deleted: $restaurantId');
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Delete restaurant failed: $e\n$stackTrace');
      throw Exception('Failed to delete restaurant: $e');
    }
  }

  Future<List<dynamic>> getRestaurants() async {
    try {
      final response = await _apiService.getRestaurantsFromApi();
      debugPrint('Restaurants fetched: ${response.length} items');
      return response;
    } catch (e, stackTrace) {
      debugPrint('Get restaurants failed: $e\n$stackTrace');
      throw Exception('Failed to get restaurants: $e');
    }
  }

  Future<List<dynamic>> getFilteredRestaurants(
      String name, String location) async {
    try {
      final response = await _apiService.getFilteredRestaurants(name, location);
      debugPrint('Filtered restaurants fetched: ${response.length} items');
      return response;
    } catch (e, stackTrace) {
      debugPrint('Get filtered restaurants failed: $e\n$stackTrace');
      throw Exception('Failed to get filtered restaurants: $e');
    }
  }

  Future<List<dynamic>> getRestaurantOrders() async {
    if (!isLoggedIn) throw Exception('User not authenticated');
    if (!isRestaurantOwner)
      throw Exception('Only restaurant owners can access orders');
    try {
      final response = await _apiService.getRestaurantOrders();
      debugPrint('Restaurant orders fetched: ${response.length} items');
      return response;
    } catch (e, stackTrace) {
      debugPrint('Get restaurant orders failed: $e\n$stackTrace');
      throw Exception('Failed to get restaurant orders: $e');
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    if (!isLoggedIn) throw Exception('User not authenticated');
    try {
      await _apiService.updateOrderStatus(orderId, status);
      debugPrint('Order status updated: $orderId to $status');
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Update order status failed: $e\n$stackTrace');
      throw Exception('Failed to update order status: $e');
    }
  }

  // Order Management
  Future<List<dynamic>> getOrders() async {
    if (!isLoggedIn) throw Exception('User not authenticated');
    try {
      final response = await _apiService.getOrders();
      debugPrint('Orders fetched: ${response.length} items');
      return response;
    } catch (e, stackTrace) {
      debugPrint('Get orders failed: $e\n$stackTrace');
      throw Exception('Failed to get orders: $e');
    }
  }

  Future<void> cancelOrder(String orderId) async {
    if (!isLoggedIn) throw Exception('User not authenticated');
    try {
      await _apiService.cancelOrder(orderId);
      debugPrint('Order cancelled: $orderId');
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Cancel order failed: $e\n$stackTrace');
      throw Exception('Failed to cancel order: $e');
    }
  }

  Future<Map<String, dynamic>> getOrderTracking(String trackingNumber) async {
    if (!isLoggedIn) throw Exception('User not authenticated');
    try {
      final response = await _apiService.getOrderTracking(trackingNumber);
      debugPrint('Order tracking fetched for: $trackingNumber');
      return response;
    } catch (e, stackTrace) {
      debugPrint('Get order tracking failed: $e\n$stackTrace');
      throw Exception('Failed to get order tracking: $e');
    }
  }

  Future<Map<String, dynamic>> createOrderWithPayment(
      List<CartItem> items, String paymentMethod, double total) async {
    if (!isLoggedIn) throw Exception('User not authenticated');
    if (items.isEmpty) throw Exception('Cart is empty');
    if (!['flutterwave', 'paystack'].contains(paymentMethod)) {
      throw Exception('Invalid payment method: $paymentMethod');
    }

    try {
      final orderItems = items.map((item) => item.toJson()).toList();
      debugPrint('Creating order with payload: ${jsonEncode({
            'items': orderItems,
            'total': total,
            'payment_method': paymentMethod,
          })}');

      final response = await _apiService.createOrderWithPayment(
        orderItems,
        paymentMethod,
        total,
      );

      debugPrint('Order created with payment response: $response');

      if (response['payment_link'] == null || response['order'] == null) {
        throw Exception(
            'Invalid response: Missing payment_link or order details');
      }

      return response;
    } catch (e, stackTrace) {
      debugPrint('Create order with payment failed: $e\n$stackTrace');
      if (e.toString().contains('404') ||
          e.toString().contains('No query results')) {
        throw Exception('Order creation failed: Invalid endpoint or data');
      } else if (e.toString().contains('500')) {
        throw Exception('Server error during order creation');
      }
      throw Exception('Failed to create order with payment: $e');
    }
  }

  Future<String?> pollOrderStatus(String trackingNumber,
      {int maxAttempts = 10,
      Duration interval = const Duration(seconds: 3)}) async {
    if (!isLoggedIn) throw Exception('User not authenticated');
    try {
      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        final response = await _apiService.getOrderTracking(trackingNumber);
        final status = response['status']?.toString().toLowerCase();
        if (status == 'completed' ||
            status == 'cancelled' ||
            status == 'failed') {
          debugPrint('Order status polled: $trackingNumber - $status');
          if (status == 'completed') clearCart();
          return status;
        }
        debugPrint(
            'Polling attempt $attempt for tracking number: $trackingNumber');
        await Future.delayed(interval);
      }
      debugPrint('Polling timed out for tracking number: $trackingNumber');
      return 'pending';
    } catch (e, stackTrace) {
      debugPrint('Poll order status failed: $e\n$stackTrace');
      throw Exception('Failed to poll order status: $e');
    }
  }

  Future<void> refreshOrders() async {
    if (!isLoggedIn) return;
    try {
      await getOrders();
      notifyListeners();
      debugPrint('Orders refreshed');
    } catch (e, stackTrace) {
      debugPrint('Refresh orders failed: $e\n$stackTrace');
    }
  }

// Customer Reviews
  Future<void> fetchCustomerReviews() async {
    _isLoadingReviews = true;
    notifyListeners();

    try {
      final response = await _apiService.get('/customer-reviews');
      debugPrint('API response for customer reviews: $response');
      _reviews = (response as List<dynamic>)
          .map((json) => CustomerReview.fromJson(json))
          .toList();
      debugPrint('Customer reviews fetched: ${_reviews.length} reviews');
    } catch (e, stackTrace) {
      debugPrint('Fetch customer reviews failed: $e\n$stackTrace');
      _reviews = [];
      throw Exception('Failed to fetch customer reviews: $e');
    } finally {
      _isLoadingReviews = false;
      notifyListeners();
    }
  }

  Future<void> submitReview(int rating, String? comment, {int? orderId}) async {
    if (!isLoggedIn) throw Exception('User not authenticated');

    try {
      final reviewData = {
        'rating': rating,
        if (comment != null) 'comment': comment,
        if (orderId != null) 'order_id': orderId,
      };
      await _apiService.post('/customer-reviews', reviewData);
      debugPrint('Review submitted successfully');
      // Refresh the reviews list after submission
      await fetchCustomerReviews();
    } catch (e, stackTrace) {
      debugPrint('Submit review failed: $e\n$stackTrace');
      throw Exception('Failed to submit review: $e');
    }
  }

  // Helper Methods
  Future<void> _persistToken(String token,
      {String? name,
      String? email,
      String? role,
      String? deliveryLocation,
      String? phone,
      String? vehicle,
      bool? isAdmin}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    if (name != null) await prefs.setString('name', name);
    if (email != null) await prefs.setString('email', email);
    if (role != null) await prefs.setString('role', role);
    if (deliveryLocation != null)
      await prefs.setString('delivery_location', deliveryLocation);
    if (phone != null) await prefs.setString('phone', phone);
    if (vehicle != null) await prefs.setString('vehicle', vehicle);
    if (isAdmin != null) await prefs.setBool('is_admin', isAdmin);
    debugPrint('Token and user data persisted');
  }

  bool _parseAdminStatus(dynamic adminValue) {
    if (adminValue == null) return false;
    if (adminValue is bool) return adminValue;
    if (adminValue is String)
      return adminValue.toLowerCase() == 'true' || adminValue == '1';
    if (adminValue is int) return adminValue == 1;
    debugPrint(
        'Unexpected admin value type: $adminValue (${adminValue.runtimeType}), defaulting to false');
    return false;
  }

  Future<void> refreshProfile() async {
    if (!isLoggedIn) return;
    await _fetchUserData();
    debugPrint('Profile refreshed');
  }
}
