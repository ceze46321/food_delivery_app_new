import 'package:flutter/material.dart' as material; // Alias for Material
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../auth_provider.dart';
import '../main.dart' show primaryColor, textColor, accentColor;
import 'package:flutter/foundation.dart'; // For debugPrint

class CartScreen extends material.StatefulWidget {
  const CartScreen({super.key});

  @override
  material.State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends material.State<CartScreen> {
  static const material.Color doorDashRed = material.Color(0xFFEF2A39);
  static const material.Color doorDashGrey = material.Color(0xFF757575);
  static const material.Color doorDashLightGrey = material.Color(0xFFF5F5F5);
  static const material.Color doorDashWhite = material.Color(0xFFFFFFFF);

  int _selectedIndex = 3; // Set to Orders tab (index 3 in new navigation)
  bool _isProcessing = false;
  String? _paymentStatus;
  String? _transactionId;
  String? _errorMessage;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    final routes = {
      0: '/orders', // Changed from '/home' to '/orders' to avoid undefined route
      1: '/restaurants',
      2: '/groceries',
      3: '/orders', // Current screen
      4: '/profile',
      5: '/restaurant-owner',
    };
    if (index != 3 && routes.containsKey(index)) {
      material.Navigator.pushReplacementNamed(context, routes[index]!);
    }
  }

  Future<String?> _showPaymentMethodDialog() async {
    return material.showDialog<String>(
      context: context,
      builder: (context) => material.AlertDialog(
        title: material.Text('Select Payment Method',
            style: GoogleFonts.poppins(fontWeight: material.FontWeight.bold)),
        content: material.Column(
          mainAxisSize: material.MainAxisSize.min,
          children: [
            material.ListTile(
                leading: const material.Icon(material.Icons.payment,
                    color: doorDashRed),
                title:
                    material.Text('Flutterwave', style: GoogleFonts.poppins()),
                onTap: () => material.Navigator.pop(context, 'flutterwave')),
            material.ListTile(
                leading: const material.Icon(material.Icons.payment,
                    color: doorDashRed),
                title: material.Text('Paystack', style: GoogleFonts.poppins()),
                onTap: () => material.Navigator.pop(context, 'paystack')),
          ],
        ),
        actions: [
          material.TextButton(
              onPressed: () => material.Navigator.pop(context, null),
              child: material.Text('Cancel',
                  style: GoogleFonts.poppins(color: doorDashRed)))
        ],
        shape: material.RoundedRectangleBorder(
            borderRadius: material.BorderRadius.circular(15)),
      ),
    );
  }

  Future<void> _checkout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      _showSnackBar('Please log in to proceed', material.Colors.redAccent);
      material.Navigator.pushNamed(context, '/login');
      return;
    }

    if (authProvider.cartItems.isEmpty) {
      _showSnackBar('Your cart is empty', material.Colors.redAccent);
      return;
    }

    final paymentMethod = await _showPaymentMethodDialog();
    if (paymentMethod == null) return;

    setState(() {
      _isProcessing = true;
      _paymentStatus = null;
      _transactionId = null;
      _errorMessage = null;
    });

    String? paymentLink;
    String? trackingNumber;

    try {
      debugPrint(
          'Starting checkout from CartScreen with ${authProvider.cartItems.length} items');
      final total = authProvider.cartTotal;
      debugPrint('Calculated total: $total');

      final response = await authProvider.createOrderWithPayment(
        authProvider.cartItems,
        paymentMethod,
        total,
      );

      paymentLink = response['payment_link']?.toString();
      trackingNumber = response['order']?['tracking_number']?.toString();

      if (paymentLink == null || trackingNumber == null) {
        throw Exception(
            'Payment link or tracking number missing from response');
      }

      debugPrint(
          'Payment link: $paymentLink, Tracking number: $trackingNumber');

      // Validate URL before attempting to launch
      if (paymentLink.isEmpty || !Uri.tryParse(paymentLink)!.isAbsolute) {
        throw Exception('Invalid payment URL: $paymentLink');
      }

      final uri = Uri.parse(paymentLink);
      final canLaunch = await canLaunchUrl(uri);
      debugPrint('Can launch URL: $canLaunch');

      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _showSnackBar(
          'Payment initiated! Complete it in your browser.',
          doorDashRed,
        );

        // Wait for the deep link callback
        final result = await material.Navigator.push(
          context,
          material.MaterialPageRoute(
            builder: (context) => const material.Scaffold(
              body:
                  material.Center(child: material.CircularProgressIndicator()),
            ),
          ),
        );

        if (result != null && result is Map) {
          setState(() {
            _paymentStatus = result['status'];
            _transactionId = result['transaction_id'];
            _errorMessage = result['message'];
          });

          if (_paymentStatus == 'success') {
            _showSnackBar(
                'Order completed successfully!', material.Colors.green);
            authProvider.clearCart();
            material.Navigator.pushReplacementNamed(context, '/orders');
          } else if (_paymentStatus == 'failed' ||
              _paymentStatus == 'cancelled') {
            _showSnackBar(
              'Order $_paymentStatus${_errorMessage != null ? ': $_errorMessage' : ''}',
              material.Colors.redAccent,
            );
          } else if (_paymentStatus == 'error') {
            _showSnackBar(
              'Error: ${_errorMessage ?? 'Unknown error'}',
              material.Colors.redAccent,
            );
          }
        } else {
          _showSnackBar(
            'Payment cancelled or failed',
            material.Colors.redAccent,
          );
        }
      } else {
        _showSnackBar(
          'Unable to launch payment URL. Please try again or copy this link: $paymentLink',
          material.Colors.redAccent,
        );
        throw Exception('Cannot launch payment URL: $paymentLink');
      }
    } catch (e, stackTrace) {
      debugPrint('Checkout error in CartScreen: $e\n$stackTrace');
      String errorMessage;
      if (e.toString().contains('No query results')) {
        errorMessage =
            'Checkout failed: Invalid order type or endpoint. Please try again.';
      } else if (e.toString().contains('Payment link') ||
          e.toString().contains('tracking')) {
        errorMessage = 'Checkout failed: Payment setup issue. Contact support.';
      } else if (e.toString().contains('Server error')) {
        errorMessage = 'Checkout failed: Server issue. Please try again later.';
      } else if (e.toString().contains('Cannot launch')) {
        errorMessage =
            'Unable to launch payment URL. Check your device settings or try this link: ${paymentLink ?? 'Not available'}';
      } else {
        errorMessage = 'Checkout failed: $e';
      }
      _showSnackBar(errorMessage, material.Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSnackBar(String message, material.Color backgroundColor) {
    material.ScaffoldMessenger.of(context).showSnackBar(
      material.SnackBar(
        content: material.Text(message,
            style: GoogleFonts.poppins(color: doorDashWhite)),
        backgroundColor: backgroundColor,
        behavior: material.SnackBarBehavior.floating,
        shape: material.RoundedRectangleBorder(
            borderRadius: material.BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  material.Widget build(material.BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return material.Scaffold(
      backgroundColor: doorDashLightGrey,
      appBar: material.AppBar(
        backgroundColor: doorDashRed,
        elevation: 0,
        leading: material.IconButton(
          icon: const material.Icon(material.Icons.arrow_back_ios,
              color: doorDashWhite, size: 20),
          onPressed: () => material.Navigator.pop(context),
        ),
        title: material.Text(
          'Your Cart',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: material.FontWeight.bold,
            color: doorDashWhite,
          ),
        ),
        centerTitle: true,
        flexibleSpace: material.Container(
          decoration: material.BoxDecoration(
            gradient: material.LinearGradient(
              colors: [doorDashRed, doorDashRed.withOpacity(0.9)],
              begin: material.Alignment.topCenter,
              end: material.Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: auth.cartItems.isEmpty
          ? material.Center(
              child: material.Column(
                mainAxisAlignment: material.MainAxisAlignment.center,
                children: [
                  const material.Icon(material.Icons.shopping_cart_outlined,
                      size: 100, color: doorDashGrey),
                  const material.SizedBox(height: 20),
                  material.Text(
                    'Your cart is empty',
                    style:
                        GoogleFonts.poppins(fontSize: 18, color: doorDashGrey),
                  ),
                ],
              ),
            )
          : material.Column(
              children: [
                material.Expanded(
                  child: material.ListView.builder(
                    padding: const material.EdgeInsets.all(16.0),
                    itemCount: auth.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = auth.cartItems[index];
                      return material.Card(
                        elevation: 2,
                        shape: material.RoundedRectangleBorder(
                            borderRadius: material.BorderRadius.circular(12)),
                        margin: const material.EdgeInsets.only(bottom: 12.0),
                        child: material.Padding(
                          padding: const material.EdgeInsets.all(12.0),
                          child: material.Row(
                            children: [
                              material.Expanded(
                                child: material.Column(
                                  crossAxisAlignment:
                                      material.CrossAxisAlignment.start,
                                  children: [
                                    material.Text(
                                      item.name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: material.FontWeight.bold,
                                        color: textColor,
                                      ),
                                      maxLines: 1,
                                      overflow: material.TextOverflow.ellipsis,
                                    ),
                                    const material.SizedBox(height: 4),
                                    material.Text(
                                      item.restaurantName ??
                                          'Unknown Restaurant',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: doorDashGrey,
                                      ),
                                      maxLines: 1,
                                      overflow: material.TextOverflow.ellipsis,
                                    ),
                                    const material.SizedBox(height: 4),
                                    material.Text(
                                      '${item.price.toStringAsFixed(2)} Naira x ${item.quantity}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              material.Row(
                                children: [
                                  material.IconButton(
                                    icon: const material.Icon(
                                        material.Icons.remove_circle,
                                        color: doorDashRed),
                                    onPressed: () {
                                      auth.updateCartItemQuantity(
                                          item.name, item.price, -1,
                                          restaurantName: item.restaurantName,
                                          id: item.id);
                                      _showSnackBar(
                                          'Removed 1 ${item.name} from cart',
                                          doorDashRed);
                                    },
                                  ),
                                  material.Text(
                                    '${item.quantity}',
                                    style: GoogleFonts.poppins(
                                        fontSize: 16, color: textColor),
                                  ),
                                  material.IconButton(
                                    icon: const material.Icon(
                                        material.Icons.add_circle,
                                        color: doorDashRed),
                                    onPressed: () {
                                      auth.updateCartItemQuantity(
                                          item.name, item.price, 1,
                                          restaurantName: item.restaurantName,
                                          id: item.id);
                                      _showSnackBar(
                                          'Added 1 ${item.name} to cart',
                                          doorDashRed);
                                    },
                                  ),
                                  material.IconButton(
                                    icon: const material.Icon(
                                        material.Icons.delete,
                                        color: material.Colors.redAccent),
                                    onPressed: () {
                                      auth.removeFromCart(item.id);
                                      _showSnackBar(
                                          '${item.name} removed from cart',
                                          doorDashRed);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                material.Container(
                  color: doorDashWhite,
                  padding: const material.EdgeInsets.all(16.0),
                  child: material.Column(
                    children: [
                      material.Row(
                        mainAxisAlignment:
                            material.MainAxisAlignment.spaceBetween,
                        children: [
                          material.Text(
                            'Total:',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: material.FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          material.Text(
                            '${auth.cartTotal.toStringAsFixed(2)} Naira',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: material.FontWeight.bold,
                              color: doorDashRed,
                            ),
                          ),
                        ],
                      ),
                      const material.SizedBox(height: 16),
                      _isProcessing
                          ? const material.Center(
                              child: material.CircularProgressIndicator(
                                  color: doorDashRed))
                          : material.ElevatedButton(
                              onPressed: _checkout,
                              style: material.ElevatedButton.styleFrom(
                                backgroundColor: doorDashRed,
                                minimumSize:
                                    const material.Size(double.infinity, 50),
                                shape: material.RoundedRectangleBorder(
                                    borderRadius:
                                        material.BorderRadius.circular(12)),
                              ),
                              child: material.Text(
                                'Checkout',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: doorDashWhite,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: material.BottomNavigationBar(
        items: const [
          material.BottomNavigationBarItem(
              icon: material.Icon(material.Icons.home), label: 'Home'),
          material.BottomNavigationBarItem(
              icon: material.Icon(material.Icons.restaurant),
              label: 'Restaurants'),
          material.BottomNavigationBarItem(
              icon: material.Icon(material.Icons.local_grocery_store),
              label: 'Groceries'),
          material.BottomNavigationBarItem(
              icon: material.Icon(material.Icons.shopping_cart),
              label: 'Orders'),
          material.BottomNavigationBarItem(
              icon: material.Icon(material.Icons.person), label: 'Profile'),
          material.BottomNavigationBarItem(
              icon: material.Icon(material.Icons.store), label: 'Owner'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: doorDashRed,
        unselectedItemColor: doorDashGrey,
        backgroundColor: doorDashWhite,
        type: material.BottomNavigationBarType.fixed,
        selectedLabelStyle:
            GoogleFonts.poppins(fontWeight: material.FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(),
        onTap: _onItemTapped,
      ),
    );
  }
}
