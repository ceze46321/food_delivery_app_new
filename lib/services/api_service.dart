import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io'; // For File

class ApiService {
  static const String baseUrl = 'https://plus.apexjets.org/api';
  static const String overpassUrl = 'https://overpass-api.de/api/interpreter';
  static const String googlePlacesUrl =
      'https://maps.googleapis.com/maps/api/place';
  static String get googleApiKey =>
      dotenv.env['GOOGLE_API_KEY'] ?? 'YOUR_GOOGLE_API_KEY';
  String? _token;

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Getter for token
  String? get token => _token;

  // Headers with token
  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // Load token from persistent storage
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    if (kDebugMode) debugPrint('Token loaded: $_token');
  }

  // Set token and persist it
  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    if (kDebugMode) debugPrint('Token set: $_token');
  }

  // Clear token
  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    if (kDebugMode) debugPrint('Token cleared');
  }

  // Generic HTTP Methods
  Future<dynamic> get(String path) async {
    if (_token == null &&
        !path.startsWith('/login') &&
        !path.startsWith('/register') &&
        !path.startsWith('/admin/login')) {
      throw Exception('No token set. Please log in.');
    }
    final url = '$baseUrl$path';
    final response = await http.get(Uri.parse(url), headers: headers);
    return _handleResponse(response, action: 'GET $path');
  }

  Future<dynamic> post(String path, dynamic data) async {
    if (_token == null &&
        !path.startsWith('/login') &&
        !path.startsWith('/register') &&
        !path.startsWith('/admin/login')) {
      throw Exception('No token set. Please log in.');
    }
    final url = '$baseUrl$path';
    final body = json.encode(data);
    if (kDebugMode) debugPrint('POST $url with body: $body');
    final response =
        await http.post(Uri.parse(url), headers: headers, body: body);
    return _handleResponse(response, action: 'POST $path');
  }

  Future<dynamic> postMultipart(String path, Map<String, String> fields,
      {File? imageFile, String? imageFieldName}) async {
    if (_token == null &&
        !path.startsWith('/login') &&
        !path.startsWith('/register') &&
        !path.startsWith('/admin/login')) {
      throw Exception('No token set. Please log in.');
    }

    final url = '$baseUrl$path';
    final request = http.MultipartRequest('POST', Uri.parse(url));

    // Add headers
    request.headers.addAll({
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    });

    // Add fields
    request.fields.addAll(fields);

    // Add image file if provided
    if (imageFile != null && imageFieldName != null) {
      request.files.add(
          await http.MultipartFile.fromPath(imageFieldName, imageFile.path));
    }

    // Send the request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response, action: 'POST Multipart $path');
  }

  Future<dynamic> put(String path, dynamic data) async {
    if (_token == null) throw Exception('No token set. Please log in.');
    final url = '$baseUrl$path';
    final body = json.encode(data);
    if (kDebugMode) debugPrint('PUT $url with body: $body');
    final response =
        await http.put(Uri.parse(url), headers: headers, body: body);
    return _handleResponse(response, action: 'PUT $path');
  }

  Future<dynamic> delete(String path) async {
    if (_token == null) throw Exception('No token set. Please log in.');
    final url = '$baseUrl$path';
    final response = await http.delete(Uri.parse(url), headers: headers);
    return _handleResponse(response, action: 'DELETE $path');
  }

  // Handle HTTP response
  Future<dynamic> _handleResponse(http.Response response,
      {String action = 'API request'}) async {
    if (kDebugMode) {
      debugPrint('Request: $action');
      debugPrint('URL: ${response.request?.url}');
      debugPrint('Headers: ${response.request?.headers}');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.isNotEmpty ? json.decode(response.body) : null;
    }
    throw Exception(
        '$action failed with status ${response.statusCode}: ${response.body}');
  }

  // Authentication Methods
  Future<Map<String, dynamic>> register(
      String name, String email, String password, String role) async {
    return await post('/register',
        {'name': name, 'email': email, 'password': password, 'role': role});
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    return await post('/login', {'email': email, 'password': password});
  }

  Future<Map<String, dynamic>> adminLogin(String email, String password) async {
    return await post('/admin/login', {'email': email, 'password': password});
  }

  Future<Map<String, dynamic>> loginWithGoogle(
      String email, String accessToken) async {
    return await post(
        '/google-login', {'email': email, 'google_token': accessToken});
  }

  Future<void> logout({bool isAdmin = false}) async {
    if (_token == null) {
      await clearToken();
      return;
    }
    final path = isAdmin ? '/admin/logout' : '/logout';
    await post(path, {});
    await clearToken();
  }

  Future<Map<String, dynamic>> getProfile() async {
    return await get('/profile');
  }

  Future<Map<String, dynamic>> upgradeRole(String newRole) async {
    return await post('/upgrade-role', {'role': newRole});
  }

  // Admin Methods
  Future<List<dynamic>> getAllUsers() async {
    final data = await get('/admin/users');
    return data['users'] ?? data ?? [];
  }

  Future<List<dynamic>> getDashers() async {
    final data = await get('/admin/dashers');
    return data['dashers'] ?? data ?? [];
  }

  Future<List<dynamic>> getRestaurantOwners() async {
    final data = await get('/admin/restaurant-owners');
    return data['restaurant_owners'] ?? data ?? [];
  }

  Future<List<dynamic>> getCustomers() async {
    final data = await get('/admin/customers');
    return data['customers'] ?? data ?? [];
  }

  Future<void> updateMenuPrice(String menuId, double price) async {
    final response = await put('/admin/menu/$menuId/price', {'price': price});
    if (response != null && response['success'] != true) {
      throw Exception(
          'Failed to update menu price: ${response['message'] ?? 'Unknown error'}');
    }
  }

  Future<void> updateGroceryItemPrice(String groceryId, double price,
      {int itemIndex = 0}) async {
    final response = await put('/admin/grocery/$groceryId/price', {
      'price': price,
      'item_index': itemIndex,
    });
    if (response != null && response['success'] != true) {
      throw Exception(
          'Failed to update grocery price: ${response['message'] ?? 'Unknown error'}');
    }
  }

  Future<void> sendEmail(
      String subject, String message, String recipient) async {
    final response = await post('/admin/send-email', {
      'subject': subject,
      'message': message,
      'recipient': recipient,
    });
    if (response != null && response['success'] != true) {
      throw Exception(
          'Failed to send email: ${response['message'] ?? 'Unknown error'}');
    }
  }

  // Restaurant Methods
  Future<List<Map<String, dynamic>>> getRestaurantsFromOverpass({
    double south = 4.0,
    double west = 2.0,
    double north = 14.0,
    double east = 15.0,
  }) async {
    final query =
        '[out:json];node["amenity"="restaurant"]($south,$west,$north,$east);out;';
    final url = '$overpassUrl?data=${Uri.encodeQueryComponent(query)}';
    final response = await http.get(Uri.parse(url));
    final overpassData =
        await _handleResponse(response, action: 'Overpass Fetch');
    final elements = overpassData['elements'] as List<dynamic>;
    List<Map<String, dynamic>> restaurants = [];

    for (var restaurant in elements) {
      final name = restaurant['tags']['name'] ?? 'Unnamed Restaurant';
      final lat = restaurant['lat'].toString();
      final lon = restaurant['lon'].toString();

      String? imageUrl;
      final googleUrl =
          '$googlePlacesUrl/nearbysearch/json?location=$lat,$lon&radius=500&type=restaurant&keyword=$name&key=$googleApiKey';
      final googleResponse = await http.get(Uri.parse(googleUrl));
      if (googleResponse.statusCode == 200) {
        final googleData = json.decode(googleResponse.body);
        if (googleData['results'].isNotEmpty &&
            googleData['results'][0]['photos'] != null) {
          final photoReference =
              googleData['results'][0]['photos'][0]['photo_reference'];
          imageUrl =
              '$googlePlacesUrl/photo?maxwidth=400&photoreference=$photoReference&key=$googleApiKey';
        }
      }

      restaurants.add({
        'id': restaurant['id'].toString(),
        'name': name,
        'lat': lat,
        'lon': lon,
        'image': imageUrl ?? 'https://via.placeholder.com/300',
        'tags': restaurant['tags'],
      });
    }
    return restaurants;
  }

  Future<Map<String, double>> getBoundingBox(String location) async {
    final locations = await locationFromAddress(location);
    if (locations.isEmpty) throw Exception('Location not found');
    final lat = locations.first.latitude;
    final lon = locations.first.longitude;
    const delta = 0.45; // ~50km
    return {
      'south': lat - delta,
      'west': lon - delta,
      'north': lat + delta,
      'east': lon + delta
    };
  }

  Future<Map<String, dynamic>> addRestaurant(
    String name,
    String location,
    String customerCarePhone, {
    String? image,
    required List<Map<String, dynamic>> menuItems,
  }) async {
    final data = {
      'name': name,
      'location': location,
      'customer_care_phone': customerCarePhone,
      if (image != null) 'image': image,
      'menu_items': menuItems, // Pass as array directly, not json-encoded
    };
    return await post('/restaurants', data);
  }

  Future<List<dynamic>> getFilteredGroceries(
      String name, String location) async {
    final queryParams = <String, String>{};
    if (name.isNotEmpty) queryParams['name'] = name;
    if (location.isNotEmpty) queryParams['location'] = location;

    final uri = Uri.parse('$baseUrl/grocery/filter')
        .replace(queryParameters: queryParams);
    final data = await get('/grocery/filter?${uri.query}');
    if (kDebugMode) debugPrint('Raw response from /grocery/filter: $data');

    if (data is List) return data;
    if (data is Map) return data['groceries'] ?? data['data'] ?? [];
    if (kDebugMode)
      debugPrint(
          'Unexpected response type: ${data.runtimeType}, returning empty list');
    return [];
  }

  Future<List<dynamic>> getRestaurantsFromApi() async {
    final data = await get('/restaurants');
    return data is List ? data : data['restaurants'] ?? data['data'] ?? [];
  }

  Future<List<dynamic>> getFilteredRestaurants(
      String name, String location) async {
    final queryParams = <String, String>{};
    if (name.isNotEmpty) queryParams['name'] = name;
    if (location.isNotEmpty) queryParams['location'] = location;

    final uri = Uri.parse('$baseUrl/restaurants/filter')
        .replace(queryParameters: queryParams);
    final data = await get('/restaurants/filter?${uri.query}');
    if (kDebugMode) debugPrint('Raw response from /restaurants/filter: $data');

    if (data is List) return data;
    if (data is Map) return data['restaurants'] ?? data['data'] ?? [];
    if (kDebugMode)
      debugPrint(
          'Unexpected response type: ${data.runtimeType}, returning empty list');
    return [];
  }

  Future<Map<String, dynamic>> getRestaurantOwnerData() async {
    final data = await get('/restaurant-owner/data');
    return data is Map<String, dynamic> ? data : {'restaurants': data ?? []};
  }

  // Order Management
  Future<List<dynamic>> getOrders() async {
    final data = await get('/orders');
    return data is List ? data : data['orders'] ?? [];
  }

  Future<Map<String, dynamic>> createOrderWithPayment(
      List<Map<String, dynamic>> items,
      String paymentMethod,
      double total) async {
    if (_token == null) {
      throw Exception('No token set. Please log in.');
    }

    // Validate items structure
    for (var item in items) {
      if (!item.containsKey('id') ||
          !item.containsKey('name') ||
          !item.containsKey('price') ||
          !item.containsKey('quantity') ||
          !item.containsKey('restaurant_name')) {
        throw Exception('Invalid item format: $item');
      }
    }

    // Validate payment method
    if (!['flutterwave', 'paystack'].contains(paymentMethod)) {
      throw Exception('Invalid payment method: $paymentMethod');
    }

    final orderData = {
      'items': items,
      'total': total,
      'payment_method': paymentMethod,
    };

    debugPrint('Sending order payload to /orders: ${jsonEncode(orderData)}');
    final response = await post('/orders', orderData);
    debugPrint('Order creation response: $response');

    if (response is! Map<String, dynamic>) {
      throw Exception('Unexpected response format: $response');
    }

    if (!response.containsKey('order') ||
        !response.containsKey('payment_link')) {
      throw Exception('Missing order or payment_link in response: $response');
    }

    return response;
  }

  Future<void> cancelOrder(String orderId) async {
    await post('/orders/$orderId/cancel', {});
  }

  Future<Map<String, dynamic>> getOrderTracking(String trackingNumber) async {
    return await get('/orders/track/$trackingNumber');
  }

  Future<List<dynamic>> getRestaurantOrders() async {
    final data = await get('/restaurant-orders');
    return data is List ? data : data['orders'] ?? [];
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await put('/orders/$orderId/status', {'status': status});
  }

  // Grocery Methods
  Future<List<dynamic>> getGroceries() async {
    final data = await get('/grocery');
    return data is List ? data : data['data'] ?? [];
  }

  Future<List<dynamic>> fetchGroceryProducts() async {
    return await getGroceries();
  }

  Future<Map<String, dynamic>> createGrocery(
      List<Map<String, dynamic>> items) async {
    final totalAmount = items.fold(
        0.0, (sum, item) => sum + (item['quantity'] * item['price']));
    final body = {
      'items': items,
      'total_amount': totalAmount,
      'status': 'pending',
    };
    return await post('/grocery', body);
  }

  Future<Map<String, dynamic>> createGroceryWithPayment(
      List<Map<String, dynamic>> items,
      String paymentMethod,
      double total) async {
    final groceryData = {
      'items': items,
      'total_amount': total,
      'payment_method': paymentMethod,
    };
    return await post('/grocery', groceryData);
  }

  Future<void> deleteGrocery(String groceryId) async {
    await delete('/grocery/$groceryId');
  }

  Future<Map<String, dynamic>> initiateCheckout(String groceryId,
      {String paymentMethod = 'flutterwave'}) async {
    debugPrint(
        'WARNING: Initiating grocery checkout for $groceryId - is this intended?');
    return await post(
        '/grocery/$groceryId/checkout', {'payment_method': paymentMethod});
  }

  Future<List<dynamic>> fetchUserGroceries() async {
    final data = await get('/user/groceries');
    return data is List ? data : data['groceries'] ?? data['data'] ?? [];
  }

  Future<Map<String, dynamic>> getGroceryTracking(String trackingNumber) async {
    return await get('/grocery/track/$trackingNumber');
  }

  // Dasher Methods
  Future<List<dynamic>> getDasherOrders() async {
    final data = await get('/dasher/orders');
    return data is List ? data : data['orders'] ?? [];
  }

  Future<Map<String, dynamic>> acceptOrder(String orderId) async {
    return await post('/dasher/orders/$orderId/accept', {});
  }

  Future<void> deleteRestaurant(String restaurantId) async {
    await delete('/restaurants/$restaurantId');
  }

  Future<Map<String, dynamic>> updateRestaurant(
      String restaurantId, Map<String, dynamic> data) async {
    return await put('/restaurants/$restaurantId', data);
  }

  Future<void> deleteMenuItem(String restaurantId, String menuItemId) async {
    await delete('/restaurants/$restaurantId/menu-items/$menuItemId');
  }

// Review Methods
  Future<List<dynamic>> fetchCustomerReviews() async {
    final data = await get('/customer-reviews');
    if (data is! List) {
      debugPrint('Unexpected response format for customer reviews: $data');
      throw Exception(
          'Expected a list of reviews, but got: ${data.runtimeType}');
    }
    debugPrint('Fetched ${data.length} customer reviews');
    return data;
  }

  Future<Map<String, dynamic>> submitCustomerReview(
      Map<String, dynamic> reviewData) async {
    if (!reviewData.containsKey('rating') || reviewData['rating'] is! int) {
      throw Exception('Review data must include a valid rating');
    }
    final response = await post('/customer-reviews', reviewData);
    if (response is! Map<String, dynamic>) {
      debugPrint('Unexpected response format for submitted review: $response');
      throw Exception(
          'Expected a review object, but got: ${response.runtimeType}');
    }
    debugPrint('Submitted review: $response');
    return response;
  }
}
