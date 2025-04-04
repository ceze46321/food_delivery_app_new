import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_launcher/url_launcher.dart';
import '../auth_provider.dart';
import '../main.dart' show textColor;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class RestaurantProfileScreen extends StatefulWidget {
  final Map<String, dynamic> restaurant;
  const RestaurantProfileScreen({super.key, required this.restaurant});

  @override
  State<RestaurantProfileScreen> createState() =>
      _RestaurantProfileScreenState();
}

class _RestaurantProfileScreenState extends State<RestaurantProfileScreen> {
  List<Map<String, dynamic>>? _menuItems;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedIndex = 1; // Restaurants tab as default
  bool _isProcessing = false;

  static const Color doorDashRed = Color(0xFFEF2A39);
  static const Color doorDashGrey = Color(0xFF757575);
  static const Color doorDashLightGrey = Color(0xFFF5F5F5);
  static const Color doorDashWhite = Colors.white;

  @override
  void initState() {
    super.initState();
    _fetchMenu();
  }

  Future<void> _fetchMenu() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final restaurants = await auth.getRestaurants();
      final restaurantId = widget.restaurant['id'].toString();
      final matchedRestaurant = restaurants.firstWhere(
        (r) => r['id'].toString() == restaurantId,
        orElse: () => null,
      );
      if (mounted) {
        if (matchedRestaurant == null) {
          throw 'Restaurant not found';
        }
        setState(() {
          _menuItems = matchedRestaurant['menus'] != null
              ? List<Map<String, dynamic>>.from(matchedRestaurant['menus'])
                  .map((menu) {
                  return {
                    'id': menu['id'],
                    'name': menu['name'],
                    'price': double.tryParse(menu['price'].toString()) ?? 0.0,
                    'description':
                        menu['description'] ?? 'No description available',
                  };
                }).toList()
              : [];
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching menu: $e\n$stackTrace');
      String message;
      if (e.toString().contains('network') ||
          e.toString().contains('timeout')) {
        message = 'Network error. Please check your connection and retry.';
      } else if (e.toString().contains('401') ||
          e.toString().contains('unauthorized')) {
        message = 'Authentication failed. Please log in again.';
      } else {
        message = 'Failed to load menu. Please try again.';
      }
      if (mounted) {
        setState(() => _errorMessage = message);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addToCart(AuthProvider auth, Map<String, dynamic> item) {
    final restaurantName = widget.restaurant['name'] ?? 'Unnamed Restaurant';
    auth.addToCart(item['name'], item['price'] as double,
        restaurantName: restaurantName, id: item['id'].toString());
    _showSnackBar('${item['name']} added to cart', doorDashRed);
  }

  void _updateQuantity(AuthProvider auth, String itemName, double itemPrice,
      int change, String itemId) {
    final restaurantName = widget.restaurant['name'] ?? 'Unnamed Restaurant';
    auth.updateCartItemQuantity(itemName, itemPrice, change,
        restaurantName: restaurantName, id: itemId);
  }

  Future<void> _handleCheckout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      _showSnackBar('Please log in to proceed', Colors.redAccent);
      Navigator.pushNamed(context, '/login');
      return;
    }

    if (authProvider.cartItems.isEmpty) {
      _showSnackBar('Cart is empty!', Colors.redAccent);
      return;
    }

    final paymentMethod = await _showPaymentMethodDialog();
    if (paymentMethod == null) return;

    setState(() => _isProcessing = true);

    String? paymentLink;
    String? trackingNumber;

    try {
      debugPrint(
          'Starting checkout from RestaurantProfileScreen with ${authProvider.cartItems.length} items');
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

        // Poll order status to confirm payment completion
        final status = await authProvider.pollOrderStatus(trackingNumber);
        debugPrint('Order status after polling: $status');

        if (status == 'completed') {
          debugPrint('Payment completed, clearing cart');
          authProvider.clearCart(); // Clear cart on successful payment
          _showSnackBar('Order completed successfully!', Colors.green);
          Navigator.pushReplacementNamed(context, '/orders');
        } else if (status == 'cancelled' || status == 'failed') {
          _showSnackBar(
            'Payment $status. Cart remains unchanged.',
            Colors.redAccent,
          );
          Navigator.pushReplacementNamed(context, '/orders');
        } else {
          // Pending or timeout case
          _showSnackBar(
            'Order processing. Check status in Orders.',
            doorDashRed,
          );
          // Optionally clear cart here if you assume payment will complete
          // authProvider.clearCart();
          Navigator.pushReplacementNamed(context, '/orders');
        }

        await authProvider.refreshOrders(); // Refresh orders after status check
      } else {
        debugPrint('Failed to launch URL: $uri');
        _showManualPaymentOption(paymentLink);
      }
    } catch (e, stackTrace) {
      debugPrint('Checkout error in RestaurantProfileScreen: $e\n$stackTrace');
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
      if (mounted) setState(() => _isProcessing = false);
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

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    final routes = {
      0: '/home',
      1: '/restaurants',
      2: '/groceries',
      3: '/orders',
      4: '/profile',
      5: '/restaurant-owner',
    };
    if (index != 1 && routes.containsKey(index)) {
      Navigator.pushReplacementNamed(context, routes[index]!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final restaurantName = widget.restaurant['name'] ?? 'Unnamed Restaurant';
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: doorDashLightGrey,
      appBar: AppBar(
        title: Text(
          restaurantName,
          style: GoogleFonts.poppins(
              fontSize: screenWidth > 600 ? 22 : 20,
              fontWeight: FontWeight.w600,
              color: doorDashWhite),
        ),
        backgroundColor: doorDashRed,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [doorDashRed, doorDashRed.withOpacity(0.8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: doorDashWhite),
            onPressed: _isLoading ? null : _fetchMenu,
            tooltip: 'Refresh Menu',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: SpinKitFadingCircle(
                      color: doorDashRed, size: screenWidth > 600 ? 60 : 50)
                  .animate()
                  .fadeIn())
          : RefreshIndicator(
              onRefresh: _fetchMenu,
              color: doorDashRed,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12)),
                      child: Image.network(
                        widget.restaurant['image'] ??
                            'https://via.placeholder.com/300',
                        height: screenWidth > 600 ? 250 : 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: screenWidth > 600 ? 250 : 200,
                          color: doorDashGrey.withOpacity(0.2),
                          child: Center(
                            child: Text(
                              'No Image Available',
                              style: GoogleFonts.poppins(
                                  fontSize: screenWidth > 600 ? 18 : 16,
                                  color: doorDashGrey),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(screenWidth > 600 ? 24 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            restaurantName,
                            style: GoogleFonts.poppins(
                                fontSize: screenWidth > 600 ? 28 : 24,
                                fontWeight: FontWeight.w600,
                                color: textColor),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  color: doorDashRed, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Location: ${widget.restaurant['location'] ?? 'Lat ${widget.restaurant['lat'] ?? 'N/A'}, Lon ${widget.restaurant['lon'] ?? 'N/A'}'}',
                                  style: GoogleFonts.poppins(
                                      fontSize: screenWidth > 600 ? 16 : 14,
                                      color: doorDashGrey),
                                ),
                              ),
                            ],
                          ),
                          if (widget.restaurant['address'] != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.home,
                                    color: doorDashRed, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Address: ${widget.restaurant['address']}',
                                    style: GoogleFonts.poppins(
                                        fontSize: screenWidth > 600 ? 16 : 14,
                                        color: doorDashGrey),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Menu',
                                style: GoogleFonts.poppins(
                                    fontSize: screenWidth > 600 ? 22 : 20,
                                    fontWeight: FontWeight.w600,
                                    color: textColor),
                              ),
                              if (auth.cartItems.isNotEmpty)
                                Text(
                                  'Cart: ${auth.cartTotal.toStringAsFixed(2)} naira',
                                  style: GoogleFonts.poppins(
                                      fontSize: screenWidth > 600 ? 16 : 14,
                                      color: doorDashRed,
                                      fontWeight: FontWeight.w600),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_errorMessage != null)
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline,
                                      size: 60, color: doorDashRed),
                                  const SizedBox(height: 16),
                                  Text(
                                    _errorMessage!,
                                    style: GoogleFonts.poppins(
                                        fontSize: screenWidth > 600 ? 18 : 16,
                                        color: doorDashGrey),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: _fetchMenu,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: doorDashRed,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
                                    ),
                                    child: Text(
                                      'Retry',
                                      style: GoogleFonts.poppins(
                                          fontSize: screenWidth > 600 ? 16 : 14,
                                          color: doorDashWhite),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (_menuItems!.isEmpty)
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.restaurant_menu,
                                      size: 60, color: doorDashGrey),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No Menu Items Available',
                                    style: GoogleFonts.poppins(
                                        fontSize: screenWidth > 600 ? 18 : 16,
                                        fontWeight: FontWeight.w500,
                                        color: doorDashGrey),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'This restaurant hasn\'t added any items yet.',
                                    style: GoogleFonts.poppins(
                                        fontSize: screenWidth > 600 ? 16 : 14,
                                        color: doorDashGrey),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _menuItems!.length,
                              itemBuilder: (context, index) {
                                final item = _menuItems![index];
                                final cartItemCount = auth.cartItems
                                    .where((cartItem) =>
                                        cartItem.id == item['id'].toString())
                                    .fold(
                                        0, (sum, item) => sum + item.quantity);
                                return Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  color: doorDashWhite,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['name'],
                                                style: GoogleFonts.poppins(
                                                    fontSize: screenWidth > 600
                                                        ? 18
                                                        : 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: textColor),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                item['description'],
                                                style: GoogleFonts.poppins(
                                                    fontSize: screenWidth > 600
                                                        ? 14
                                                        : 12,
                                                    color: doorDashGrey),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${item['price'].toStringAsFixed(2)} naira',
                                                style: GoogleFonts.poppins(
                                                    fontSize: screenWidth > 600
                                                        ? 16
                                                        : 14,
                                                    color: doorDashRed,
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        cartItemCount == 0
                                            ? ElevatedButton(
                                                onPressed: () =>
                                                    _addToCart(auth, item),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: doorDashRed,
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8)),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16,
                                                      vertical: 8),
                                                ),
                                                child: Text(
                                                  'Add',
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      color: doorDashWhite),
                                                ),
                                              )
                                            : Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.remove_circle,
                                                        color: doorDashRed),
                                                    onPressed: () =>
                                                        _updateQuantity(
                                                            auth,
                                                            item['name'],
                                                            item['price']
                                                                as double,
                                                            -1,
                                                            item['id']
                                                                .toString()),
                                                  ),
                                                  Text(
                                                    '$cartItemCount',
                                                    style: GoogleFonts.poppins(
                                                        fontSize: 16,
                                                        color: textColor,
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.add_circle,
                                                        color: doorDashRed),
                                                    onPressed: () =>
                                                        _updateQuantity(
                                                            auth,
                                                            item['name'],
                                                            item['price']
                                                                as double,
                                                            1,
                                                            item['id']
                                                                .toString()),
                                                  ),
                                                ],
                                              ),
                                      ],
                                    ),
                                  ),
                                ).animate().fadeIn(
                                    duration: 300.ms, delay: (index * 100).ms);
                              },
                            ),
                          if (auth.cartItems.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Center(
                              child: ElevatedButton(
                                onPressed:
                                    _isProcessing ? null : _handleCheckout,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: doorDashRed,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth > 600 ? 32 : 24,
                                      vertical: 16),
                                  elevation: 4,
                                ),
                                child: _isProcessing
                                    ? SpinKitThreeBounce(
                                        color: doorDashWhite, size: 24)
                                    : Text(
                                        'Checkout (${auth.cartTotal.toStringAsFixed(2)} naira)',
                                        style: GoogleFonts.poppins(
                                            fontSize:
                                                screenWidth > 600 ? 18 : 16,
                                            color: doorDashWhite,
                                            fontWeight: FontWeight.w600),
                                      ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: auth.cartItems.isNotEmpty
          ? FloatingActionButton(
              onPressed: _isProcessing ? null : _handleCheckout,
              backgroundColor: doorDashRed,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _isProcessing
                      ? const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(doorDashWhite),
                          strokeWidth: 2)
                      : const Icon(Icons.shopping_cart, color: doorDashWhite),
                  if (!_isProcessing)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        radius: 8,
                        backgroundColor: doorDashWhite,
                        child: Text(
                          '${auth.cartItems.fold(0, (sum, item) => sum + item.quantity)}',
                          style: GoogleFonts.poppins(
                              fontSize: 10, color: doorDashRed),
                        ),
                      ),
                    ),
                ],
              ),
            ).animate().scale(duration: 300.ms)
          : null,
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.restaurant), label: 'Restaurants'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_grocery_store), label: 'Groceries'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Owner'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: doorDashRed,
        unselectedItemColor: doorDashGrey.withOpacity(0.6),
        backgroundColor: doorDashWhite,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.poppins(
            fontSize: screenWidth > 600 ? 14 : 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            GoogleFonts.poppins(fontSize: screenWidth > 600 ? 14 : 12),
        showUnselectedLabels: true,
        elevation: 8,
        onTap: _onItemTapped,
      ),
    );
  }
}
