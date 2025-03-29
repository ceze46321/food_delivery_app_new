import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_launcher/url_launcher.dart';
import '../auth_provider.dart';
import '../main.dart' show textColor;
import 'package:flutter_animate/flutter_animate.dart';

class RestaurantProfileScreen extends StatefulWidget {
  final Map<String, dynamic> restaurant;
  const RestaurantProfileScreen({super.key, required this.restaurant});

  @override
  State<RestaurantProfileScreen> createState() => _RestaurantProfileScreenState();
}

class _RestaurantProfileScreenState extends State<RestaurantProfileScreen> {
  List<Map<String, dynamic>>? _menuItems;
  bool _isLoading = true;
  int _selectedIndex = 1; // Restaurants tab as default
  bool _isProcessing = false; // Added for checkout loading state

  static const Color doorDashRed = Color(0xFFEF2A39);
  static const Color doorDashGrey = Color(0xFF757575);
  static const Color doorDashLightGrey = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _fetchMenu();
  }

  Future<void> _fetchMenu() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final restaurants = await auth.getRestaurants();
      final restaurantId = widget.restaurant['id'].toString();
      final matchedRestaurant = restaurants.firstWhere(
        (r) => r['id'].toString() == restaurantId,
        orElse: () => null,
      );
      if (mounted && matchedRestaurant != null && matchedRestaurant['menus'] != null) {
        setState(() {
          _menuItems = List<Map<String, dynamic>>.from(matchedRestaurant['menus']).map((menu) {
            return {
              'id': menu['id'],
              'name': menu['name'],
              'price': double.tryParse(menu['price'].toString()) ?? 0.0,
              'description': menu['description'] ?? 'No description available',
            };
          }).toList();
        });
      } else {
        setState(() => _menuItems = []);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching menu: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _menuItems = []);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addToCart(AuthProvider auth, Map<String, dynamic> item) {
    final restaurantName = widget.restaurant['name'] ?? 'Unnamed Restaurant';
    auth.addToCart(item['name'], item['price'] as double, restaurantName: restaurantName, id: item['id'].toString());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item['name']} added to cart', style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: doorDashRed,
      ),
    );
  }

  void _updateQuantity(AuthProvider auth, String itemName, double itemPrice, int change, String itemId) {
    final restaurantName = widget.restaurant['name'] ?? 'Unnamed Restaurant';
    auth.updateCartItemQuantity(itemName, itemPrice, change, restaurantName: restaurantName, id: itemId);
  }

  Future<void> _handleCheckout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to proceed'), backgroundColor: Colors.redAccent),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    if (authProvider.cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final cartItems = authProvider.cartItems.map((item) => item.toJson()).toList();
      final response = await authProvider.initiateCheckout(cartItems.toString(), paymentMethod: 'flutterwave');

      final paymentLink = response['payment_link'];
      if (await canLaunchUrl(Uri.parse(paymentLink))) {
        await launchUrl(Uri.parse(paymentLink), mode: LaunchMode.externalApplication);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment initiated! Complete in browser.'), backgroundColor: doorDashRed),
          );
        }
      } else {
        throw 'Could not launch $paymentLink';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
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
    if (index != 1 && routes.containsKey(index)) { // 1 is RestaurantProfile (Restaurants)
      Navigator.pushReplacementNamed(context, routes[index]!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final restaurantName = widget.restaurant['name'] ?? 'Unnamed Restaurant';

    return Scaffold(
      backgroundColor: doorDashLightGrey,
      appBar: AppBar(
        title: Text(
          restaurantName,
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: doorDashRed,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchMenu,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: SpinKitFadingCircle(color: doorDashRed, size: 50))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      widget.restaurant['image'] ?? 'https://via.placeholder.com/300',
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: doorDashGrey.withOpacity(0.2),
                        child: Center(
                          child: Text(
                            'No Image Available',
                            style: GoogleFonts.poppins(color: doorDashGrey),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          restaurantName,
                          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600, color: textColor),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: doorDashRed, size: 20),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Location: Lat ${widget.restaurant['lat'] ?? 'N/A'}, Lon ${widget.restaurant['lon'] ?? 'N/A'}',
                                style: GoogleFonts.poppins(fontSize: 14, color: doorDashGrey),
                              ),
                            ),
                          ],
                        ),
                        if (widget.restaurant['address'] != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.home, color: doorDashRed, size: 20),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Address: ${widget.restaurant['address']}',
                                  style: GoogleFonts.poppins(fontSize: 14, color: doorDashGrey),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Menu',
                              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
                            ),
                            if (auth.cartItems.isNotEmpty)
                              Text(
                                'Cart: ₦${auth.cartTotal.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(fontSize: 14, color: doorDashRed),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _menuItems == null || _menuItems!.isEmpty
                            ? Center(
                                child: Text(
                                  'No menu items available',
                                  style: GoogleFonts.poppins(fontSize: 16, color: doorDashGrey),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _menuItems!.length,
                                itemBuilder: (context, index) {
                                  final item = _menuItems![index];
                                  final cartItemCount = auth.cartItems
                                      .where((cartItem) => cartItem.id == item['id'].toString())
                                      .fold(0, (sum, item) => sum + item.quantity);
                                  return Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    color: Colors.white,
                                    margin: EdgeInsets.symmetric(vertical: 8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item['name'],
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
                                                ),
                                                Text(
                                                  item['description'],
                                                  style: GoogleFonts.poppins(fontSize: 14, color: doorDashGrey),
                                                ),
                                                Text(
                                                  '₦${item['price'].toStringAsFixed(2)}',
                                                  style: GoogleFonts.poppins(fontSize: 14, color: doorDashRed),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          cartItemCount == 0
                                              ? IconButton(
                                                  icon: const Icon(Icons.add_circle, color: doorDashRed),
                                                  onPressed: () => _addToCart(auth, item),
                                                )
                                              : Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(Icons.remove, color: doorDashRed),
                                                      onPressed: () => _updateQuantity(
                                                          auth, item['name'], item['price'] as double, -1, item['id'].toString()),
                                                    ),
                                                    Text(
                                                      '$cartItemCount',
                                                      style: GoogleFonts.poppins(fontSize: 16, color: textColor),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.add, color: doorDashRed),
                                                      onPressed: () => _updateQuantity(
                                                          auth, item['name'], item['price'] as double, 1, item['id'].toString()),
                                                    ),
                                                  ],
                                                ),
                                        ],
                                      ),
                                    ),
                                  ).animate().fadeIn(duration: 300.ms);
                                },
                              ),
                      ],
                    ),
                  ),
                ],
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        )
                      : const Icon(Icons.shopping_cart, color: Colors.white),
                  if (!_isProcessing)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.white,
                        child: Text(
                          '${auth.cartItems.length}',
                          style: GoogleFonts.poppins(fontSize: 10, color: doorDashRed),
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
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Restaurants'),
          BottomNavigationBarItem(icon: Icon(Icons.local_grocery_store), label: 'Groceries'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Owner'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: doorDashRed,
        unselectedItemColor: doorDashGrey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(),
        onTap: _onItemTapped,
      ),
    );
  }
}