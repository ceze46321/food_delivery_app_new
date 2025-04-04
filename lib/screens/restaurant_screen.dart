import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../auth_provider.dart';
import '../main.dart' show textColor, accentColor;
import 'restaurant_profile_screen.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class RestaurantScreen extends StatefulWidget {
  const RestaurantScreen({super.key});

  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  static const Color doorDashRed = Color(0xFFEF2A39);
  static const Color doorDashGrey = Color(0xFF757575);
  static const Color doorDashLightGrey = Color(0xFFF5F5F5);
  static const Color doorDashWhite = Colors.white;
  static const Color backgroundColor = Color(0xFFF8F9FA);

  late Future<List<dynamic>> _futureRestaurants;
  List<dynamic> _allRestaurants = [];
  List<dynamic> _filteredRestaurants = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  int _currentPage = 1;
  static const int _itemsPerPage = 6;
  int _selectedIndex = 1;
  bool _isCheckingOut = false;

  @override
  void initState() {
    super.initState();
    _futureRestaurants = _fetchRestaurants();
    _searchController.addListener(_onFilterChanged);
    _locationController.addListener(_onFilterChanged);
  }

  Future<List<dynamic>> _fetchRestaurants() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final restaurants = await authProvider.getRestaurants();
      debugPrint('Fetched restaurants: ${restaurants.length} items');
      if (mounted) {
        setState(() {
          _allRestaurants = restaurants;
          _filteredRestaurants = restaurants;
        });
      }
      return restaurants;
    } catch (e, stackTrace) {
      debugPrint('Error fetching restaurants: $e\n$stackTrace');
      return [];
    }
  }

  Future<void> _onFilterChanged() async {
    final query = _searchController.text.trim();
    final location = _locationController.text.trim();

    if (query.isEmpty && location.isEmpty) {
      setState(() {
        _filteredRestaurants = _allRestaurants;
        _currentPage = 1;
      });
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final filtered =
          await authProvider.getFilteredRestaurants(query, location);
      debugPrint('Filtered restaurants: ${filtered.length} items');
      if (mounted) {
        setState(() {
          _filteredRestaurants = filtered;
          _currentPage = 1;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error filtering restaurants: $e\n$stackTrace');
      _filterRestaurantsClientSide(query, location);
    }
  }

  void _filterRestaurantsClientSide(String query, String location) {
    setState(() {
      _filteredRestaurants = _allRestaurants.where((restaurant) {
        final name = (restaurant['name'] ?? '').toString().toLowerCase();
        final restaurantLocation =
            (restaurant['location'] ?? '').toString().toLowerCase();
        return name.contains(query.toLowerCase()) &&
            (location.isEmpty ||
                restaurantLocation.contains(location.toLowerCase()));
      }).toList();
      debugPrint('Client-side filtered: ${_filteredRestaurants.length} items');
      _currentPage = 1;
    });
  }

  List<dynamic> _getPaginatedRestaurants() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex =
        (startIndex + _itemsPerPage).clamp(0, _filteredRestaurants.length);
    return _filteredRestaurants.sublist(startIndex, endIndex);
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    final routes = {
      0: '/home',
      1: '/restaurants',
      2: '/orders',
      3: '/profile',
      4: '/restaurant-owner'
    };
    if (routes.containsKey(index) && index != 1) {
      Navigator.pushReplacementNamed(context, routes[index]!);
    }
  }

  Future<void> _checkout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      _showSnackBar('Please log in to proceed', Colors.redAccent);
      Navigator.pushNamed(context, '/login');
      return;
    }

    if (authProvider.cartItems.isEmpty) {
      _showSnackBar('Your cart is empty', Colors.redAccent);
      return;
    }

    final paymentMethod = await _showPaymentMethodDialog();
    if (paymentMethod == null) return;

    setState(() => _isCheckingOut = true);

    String? paymentLink;
    String? trackingNumber;

    try {
      debugPrint(
          'Starting checkout from RestaurantScreen with ${authProvider.cartItems.length} items');
      final total = authProvider.cartItems.fold<double>(
        0,
        (sum, item) => sum + (item.price * item.quantity),
      );
      debugPrint('Calculated total: $total');

      final cartItemsJson = authProvider.cartItems
          .map((item) => {
                'id': item.id ?? 'default_${item.name}',
                'name': item.name,
                'price': item.price,
                'quantity': item.quantity,
                'restaurant_name': item.restaurantName ?? 'Unknown',
              })
          .toList();
      debugPrint('Cart items payload: $cartItemsJson');

      final response = await authProvider.createOrderWithPayment(
        authProvider.cartItems,
        paymentMethod,
        total,
      );

      debugPrint('Raw response from createOrderWithPayment: $response');

      paymentLink = response['payment_link']?.toString();
      trackingNumber = response['order']?['tracking_number']?.toString();

      if (paymentLink == null || trackingNumber == null) {
        throw Exception(
            'Payment link or tracking number missing from response: $response');
      }

      debugPrint(
          'Payment link: $paymentLink, Tracking number: $trackingNumber');

      final uri = Uri.tryParse(paymentLink.trim());
      if (uri == null ||
          !uri.isAbsolute ||
          (!uri.hasScheme && !uri.hasAuthority)) {
        throw Exception('Invalid payment URL: $paymentLink');
      }

      debugPrint('Parsed URI: $uri');
      debugPrint('Attempting to launch URL in external application: $uri');
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        debugPrint(
            'External application launch failed, trying platform default');
        launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      }

      if (launched) {
        _showSnackBar(
          'Payment initiated! Complete it in your browser.',
          doorDashRed,
        );

        await authProvider.refreshOrders();
        final status = await authProvider.pollOrderStatus(trackingNumber);
        debugPrint('Order status: $status');
        if (status == 'completed') {
          _showSnackBar('Order completed successfully!', Colors.green);
          authProvider.clearCart();
          Navigator.pushReplacementNamed(context, '/orders');
        } else {
          _showSnackBar(
            'Order processing. Check status in Orders.',
            doorDashRed,
          );
          Navigator.pushReplacementNamed(context, '/orders');
        }
      } else {
        debugPrint('Failed to launch URL: $uri');
        _showManualPaymentOption(paymentLink);
      }
    } catch (e, stackTrace) {
      debugPrint('Checkout error in RestaurantScreen: $e\n$stackTrace');
      String errorMessage = 'Checkout failed: $e';
      if (e.toString().contains('app model grocery')) {
        errorMessage =
            'Checkout failed: Grocery model error detected. Please check logs.';
      } else if (e.toString().contains('/checkout') ||
          e.toString().contains('/payment-callback')) {
        errorMessage =
            'Checkout failed: Wrong endpoint used. Should use /orders.';
      } else if (e.toString().contains('Invalid payment URL')) {
        errorMessage = 'Invalid payment URL received from server: $paymentLink';
      }
      _showSnackBar(errorMessage, Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: GoogleFonts.poppins(color: doorDashWhite)),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<String?> _showPaymentMethodDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Payment Method',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.payment, color: doorDashRed),
              title: Text('Flutterwave', style: GoogleFonts.poppins()),
              onTap: () => Navigator.pop(context, 'flutterwave'),
            ),
            ListTile(
              leading: Icon(Icons.payment, color: doorDashRed),
              title: Text('Paystack', style: GoogleFonts.poppins()),
              onTap: () => Navigator.pop(context, 'paystack'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child:
                Text('Cancel', style: GoogleFonts.poppins(color: doorDashRed)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  void _showManualPaymentOption(String paymentLink) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment URL Launch Failed',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We couldn\'t open the payment link automatically. Please copy it and open it in your browser manually:',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 10),
            SelectableText(
              paymentLink,
              style: GoogleFonts.poppins(color: Colors.blue, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.poppins(color: doorDashRed)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const bottomNavHeight = 80.0;
    const fabHeight = 56.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [doorDashRed, doorDashRed.withOpacity(0.85)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.restaurant,
                          color: doorDashWhite, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        'Restaurants',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth > 600 ? 28 : 24,
                          fontWeight: FontWeight.bold,
                          color: doorDashWhite,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Consumer<AuthProvider>(
                    builder: (context, auth, child) => IconButton(
                      icon: Stack(
                        children: [
                          const Icon(Icons.shopping_cart,
                              color: doorDashWhite, size: 28),
                          if (auth.cartItems.isNotEmpty)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: CircleAvatar(
                                radius: 8,
                                backgroundColor: doorDashWhite,
                                child: Text(
                                  '${auth.cartItems.length}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 10, color: doorDashRed),
                                ),
                              ),
                            ),
                        ],
                      ),
                      onPressed: () => Navigator.pushNamed(context, '/cart'),
                      tooltip: 'View Cart',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        toolbarHeight: 80,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureRestaurants,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: doorDashRed, strokeWidth: 4),
                  const SizedBox(height: 20),
                  Text('Loading Restaurants...',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: doorDashGrey,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            debugPrint('Snapshot error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 100, color: doorDashGrey),
                  const SizedBox(height: 20),
                  Text('Error loading restaurants',
                      style: GoogleFonts.poppins(
                          fontSize: screenWidth > 600 ? 22 : 20,
                          color: doorDashGrey)),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            debugPrint('No restaurants in snapshot: ${snapshot.data}');
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restaurant,
                      size: screenWidth > 600 ? 120 : 100,
                      color: doorDashGrey.withOpacity(0.3)),
                  const SizedBox(height: 20),
                  Text('No restaurants available',
                      style: GoogleFonts.poppins(
                          fontSize: screenWidth > 600 ? 22 : 20,
                          color: doorDashGrey)),
                ],
              ),
            );
          }

          final authProvider = Provider.of<AuthProvider>(context);

          return RefreshIndicator(
            onRefresh: _fetchRestaurants,
            color: doorDashRed,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                bottom: bottomInset +
                    bottomNavHeight +
                    (authProvider.cartItems.isNotEmpty ? fabHeight + 80 : 20),
              ),
              child: Column(
                children: [
                  _buildSearchFilters(screenWidth),
                  _buildRestaurantGrid(screenWidth),
                  _buildPaginationControls(screenWidth),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [doorDashRed, doorDashRed.withOpacity(0.9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.restaurant), label: 'Restaurants'),
            BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long), label: 'Orders'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Owner'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: doorDashWhite,
          unselectedItemColor: doorDashWhite.withOpacity(0.6),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle:
              GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
          onTap: _onItemTapped,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          final total = auth.cartItems.fold<double>(
            0,
            (sum, item) => sum + (item.price * item.quantity),
          );
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                onPressed: () =>
                    setState(() => _futureRestaurants = _fetchRestaurants()),
                backgroundColor: doorDashRed,
                tooltip: 'Refresh Restaurants',
                child:
                    const Icon(Icons.refresh, color: doorDashWhite, size: 28),
              ),
              if (auth.cartItems.isNotEmpty) const SizedBox(width: 20),
              if (auth.cartItems.isNotEmpty)
                FloatingActionButton.extended(
                  onPressed: _isCheckingOut ? null : _checkout,
                  backgroundColor: doorDashRed,
                  label: _isCheckingOut
                      ? const CircularProgressIndicator(color: doorDashWhite)
                      : Text(
                          'Checkout ${total.toStringAsFixed(2)} naira (${auth.cartItems.length})',
                          style: GoogleFonts.poppins(
                            color: doorDashWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  icon: const Icon(Icons.payment, color: doorDashWhite),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchFilters(double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: screenWidth > 600 ? 30.0 : 20.0, vertical: 20.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: doorDashWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildSearchField(
                _searchController, 'Search by name', Icons.search, screenWidth),
            const SizedBox(height: 15),
            _buildSearchField(_locationController, 'Filter by location',
                Icons.location_on, screenWidth),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildSearchField(TextEditingController controller, String label,
      IconData icon, double screenWidth) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: GoogleFonts.poppins(
            color: doorDashGrey.withOpacity(0.6), fontSize: 16),
        prefixIcon: Icon(icon, color: doorDashRed, size: 24),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: doorDashGrey, size: 20),
                onPressed: () => controller.clear(),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: doorDashLightGrey,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
      style: GoogleFonts.poppins(color: textColor, fontSize: 16),
    );
  }

  Widget _buildRestaurantGrid(double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: screenWidth > 600 ? 30.0 : 20.0, vertical: 10.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: screenWidth > 900
              ? 3
              : screenWidth > 600
                  ? 2
                  : 1,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 0.75,
        ),
        itemCount: _getPaginatedRestaurants().length,
        itemBuilder: (context, index) => _buildRestaurantCard(
            _getPaginatedRestaurants()[index], screenWidth, index),
      ),
    );
  }

  Widget _buildRestaurantCard(
      dynamic restaurant, double screenWidth, int index) {
    final menus = (restaurant['menus'] as List<dynamic>?) ?? [];
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RestaurantProfileScreen(restaurant: restaurant),
        ),
      ),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: doorDashWhite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRestaurantImage(restaurant['image'], screenWidth),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRestaurantInfo(restaurant, screenWidth),
                  const SizedBox(height: 10),
                  _buildMenuGrid(menus, screenWidth),
                ],
              ),
            ),
          ],
        ),
      ).animate().scale(duration: 300.ms, delay: (index * 100).ms),
    );
  }

  Widget _buildRestaurantImage(String? imageUrl, double screenWidth) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: CachedNetworkImage(
        imageUrl: imageUrl?.trim().isNotEmpty == true
            ? imageUrl!
            : 'https://via.placeholder.com/300',
        height: screenWidth > 600 ? 180 : 150,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: screenWidth > 600 ? 180 : 150,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [doorDashLightGrey, doorDashGrey.withOpacity(0.3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(child: CircularProgressIndicator(color: doorDashRed)),
        ),
        errorWidget: (context, url, error) => Container(
          height: screenWidth > 600 ? 180 : 150,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [doorDashLightGrey, doorDashGrey.withOpacity(0.3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Icon(Icons.broken_image, color: doorDashGrey, size: 50),
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantInfo(dynamic restaurant, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          restaurant['name'] ?? 'Unnamed',
          style: GoogleFonts.poppins(
            fontSize: screenWidth > 600 ? 18 : 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 5),
        Text(
          restaurant['location'] ?? 'No location',
          style: GoogleFonts.poppins(
            fontSize: screenWidth > 600 ? 14 : 12,
            color: doorDashGrey,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 5),
        Text(
          'Contact: ${restaurant['customer_care_phone'] ?? 'Not available'}',
          style: GoogleFonts.poppins(
            fontSize: screenWidth > 600 ? 14 : 12,
            color: doorDashGrey,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMenuGrid(List<dynamic> menus, double screenWidth) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) => menus.isEmpty
          ? Text(
              'No menu items available',
              style: GoogleFonts.poppins(
                fontSize: screenWidth > 600 ? 14 : 12,
                color: doorDashGrey,
              ),
            )
          : SizedBox(
              height: screenWidth > 600 ? 120 : 100,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: screenWidth > 600 ? 200 : 180,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: menus.length > 4 ? 4 : menus.length,
                itemBuilder: (context, index) =>
                    _buildMenuItem(menus[index], auth, context, screenWidth),
              ),
            ),
    );
  }

  Widget _buildMenuItem(dynamic item, AuthProvider auth, BuildContext context,
      double screenWidth) {
    final itemName = item['name'] ?? 'Unnamed';
    final itemPrice = (item['price'] as num?)?.toDouble() ?? 0.0;
    final restaurantName = item['restaurant_name'] ?? 'Unknown';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: doorDashLightGrey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  itemName,
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth > 600 ? 12 : 10,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${itemPrice.toStringAsFixed(2)} naira',
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth > 600 ? 12 : 10,
                    color: doorDashRed,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_shopping_cart,
                color: doorDashRed, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              auth.addToCart(itemName, itemPrice,
                  restaurantName: restaurantName, id: item['id'].toString());
              _showSnackBar('$itemName added to cart', doorDashRed);
            },
            tooltip: 'Add to cart',
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(double screenWidth) {
    final totalPages = (_filteredRestaurants.length / _itemsPerPage).ceil();
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: screenWidth > 600 ? 24 : 16,
        horizontal: screenWidth > 600 ? 30 : 20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap:
                _currentPage > 1 ? () => setState(() => _currentPage--) : null,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _currentPage > 1
                      ? [doorDashRed, doorDashRed.withOpacity(0.9)]
                      : [doorDashGrey, doorDashGrey.withOpacity(0.9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios,
                  color: doorDashWhite, size: 22),
            ),
          ),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [doorDashRed, doorDashRed.withOpacity(0.9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$_currentPage / $totalPages',
              style: GoogleFonts.poppins(
                fontSize: screenWidth > 600 ? 16 : 14,
                color: doorDashWhite,
              ),
            ),
          ),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: _currentPage < totalPages
                ? () => setState(() => _currentPage++)
                : null,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _currentPage < totalPages
                      ? [doorDashRed, doorDashRed.withOpacity(0.9)]
                      : [doorDashGrey, doorDashGrey.withOpacity(0.9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward_ios,
                  color: doorDashWhite, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
