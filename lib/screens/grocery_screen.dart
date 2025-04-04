import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import '../main.dart' show primaryColor, textColor, accentColor;
import '../auth_provider.dart';
import 'restaurant_screen.dart';
import 'create_grocery_product_screen.dart';

class GroceryScreen extends StatefulWidget {
  const GroceryScreen({super.key});

  @override
  State<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends State<GroceryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _selectedIndex = 2;
  List<Map<String, dynamic>> cart = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  List<Map<String, dynamic>> _allGroceries = [];
  List<Map<String, dynamic>> _filteredGroceries = [];
  StreamSubscription? _sub;
  bool _isLoading = false;
  final _appLinks = AppLinks();

  static const Color doorDashRed = Color(0xFFEF2A39);
  static const Color doorDashGrey = Color(0xFF757575);
  static const Color doorDashLightGrey = Color(0xFFF5F5F5);
  static const Color backgroundColor = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _fetchGroceries();
    _initDeepLinkListener();
    _searchController.addListener(_onFilterChanged);
    _locationController.addListener(_onFilterChanged);
  }

  Future<void> _fetchGroceries() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final groceries = await authProvider.fetchGroceryProducts();
      if (mounted) {
        setState(() {
          _allGroceries = List<Map<String, dynamic>>.from(groceries);
          _filteredGroceries = _flattenAndFilterGroceries(_allGroceries);
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching groceries: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load groceries: $e',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.redAccent,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _fetchGroceries,
            ),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _initDeepLinkListener() async {
    try {
      final initialLink = await _appLinks.getInitialLinkString();
      if (initialLink != null && mounted) {
        debugPrint('Initial deep link: $initialLink');
        _handleDeepLink(initialLink);
      }

      _sub = _appLinks.stringLinkStream.listen(
        (String? link) {
          if (link != null && mounted) {
            debugPrint('Received deep link: $link');
            _handleDeepLink(link);
          }
        },
        onError: (err, stackTrace) {
          debugPrint('Deep link error: $err\n$stackTrace');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to process deep link: $err',
                    style: GoogleFonts.poppins(color: Colors.white)),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
      );
    } catch (e, stackTrace) {
      debugPrint('Error initializing deep link listener: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting up deep link: $e',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _handleDeepLink(String link) {
    // Note: Kept for compatibility, but we'll rely on polling since backend uses JSON callbacks
    try {
      final uri = Uri.parse(link);
      final status = uri.queryParameters['status'];
      if (status == 'completed' && mounted) {
        setState(() => cart.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment successful!',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: doorDashRed,
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error handling deep link: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid deep link: $e',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _onFilterChanged() async {
    final query = _searchController.text.trim();
    final location = _locationController.text.trim();

    if (query.isEmpty && location.isEmpty) {
      if (mounted) {
        setState(() =>
            _filteredGroceries = _flattenAndFilterGroceries(_allGroceries));
      }
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final filtered = await authProvider.getFilteredGroceries(query, location);
      if (mounted) {
        setState(() => _filteredGroceries = _flattenAndFilterGroceries(
            List<Map<String, dynamic>>.from(filtered)));
      }
    } catch (e, stackTrace) {
      debugPrint('Error filtering groceries: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to filter groceries: $e',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.orange,
          ),
        );
        _filterGroceriesClientSide(query, location);
      }
    }
  }

  List<Map<String, dynamic>> _flattenAndFilterGroceries(
      List<Map<String, dynamic>> groceries) {
    try {
      final allItems = groceries.expand((grocery) {
        final items = grocery['items'] as List<dynamic>? ?? [];
        return items.map((item) => ({
              'id': grocery['id']?.toString() ?? 'unknown',
              'name': item['name']?.toString() ?? 'Unnamed',
              'stock_quantity': item['quantity'] ?? 1,
              'price': (item['price'] as num?)?.toDouble() ?? 0.0,
              'image': item['image']?.toString(),
              'location': grocery['location']?.toString() ?? '',
            }));
      }).toList();

      final query = _searchController.text.toLowerCase().trim();
      final location = _locationController.text.toLowerCase().trim();

      return allItems.where((item) {
        final matchesName = (item['name'] ?? '').toLowerCase().contains(query);
        final matchesLocation = location.isEmpty ||
            (item['location'] ?? '').toLowerCase().contains(location);
        return matchesName && matchesLocation;
      }).toList();
    } catch (e, stackTrace) {
      debugPrint('Error flattening groceries: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing grocery data: $e',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return [];
    }
  }

  void _filterGroceriesClientSide(String query, String location) {
    try {
      setState(() {
        _filteredGroceries = _allGroceries.expand((grocery) {
          final items = grocery['items'] as List<dynamic>? ?? [];
          return items.map((item) => ({
                'id': grocery['id']?.toString() ?? 'unknown',
                'name': item['name']?.toString() ?? 'Unnamed',
                'stock_quantity': item['quantity'] ?? 1,
                'price': (item['price'] as num?)?.toDouble() ?? 0.0,
                'image': item['image']?.toString(),
                'location': grocery['location']?.toString() ?? '',
              }));
        }).where((item) {
          final matchesName =
              (item['name'] ?? '').toLowerCase().contains(query.toLowerCase());
          final matchesLocation = location.isEmpty ||
              (item['location'] ?? '')
                  .toLowerCase()
                  .contains(location.toLowerCase());
          return matchesName && matchesLocation;
        }).toList();
      });
    } catch (e, stackTrace) {
      debugPrint('Error filtering groceries client-side: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error filtering groceries locally: $e',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _filteredGroceries = []);
      }
    }
  }

  void _addToCart(Map<String, dynamic> item) {
    try {
      setState(() {
        final existingItemIndex =
            cart.indexWhere((cartItem) => cartItem['id'] == item['id']);
        if (existingItemIndex != -1) {
          cart[existingItemIndex]['ordered_quantity'] =
              (cart[existingItemIndex]['ordered_quantity'] ?? 0) + 1;
        } else {
          cart.add({
            'id': item['id'] ?? 'unknown',
            'name': item['name'] ?? 'Unnamed',
            'stock_quantity': item['stock_quantity'] ?? 1,
            'ordered_quantity': 1,
            'price': item['price'] ?? 0.0,
            'image': item['image'],
          });
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item['name'] ?? 'Item'} added to cart!',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: doorDashRed,
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error adding to cart: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add item to cart: $e',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _removeFromCart(Map<String, dynamic> item) {
    try {
      setState(() {
        final existingItemIndex =
            cart.indexWhere((cartItem) => cartItem['id'] == item['id']);
        if (existingItemIndex != -1) {
          final currentQuantity =
              cart[existingItemIndex]['ordered_quantity'] as int? ?? 0;
          if (currentQuantity > 1) {
            cart[existingItemIndex]['ordered_quantity'] = currentQuantity - 1;
          } else {
            cart.removeAt(existingItemIndex);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item['name'] ?? 'Item'} removed from cart!',
                    style: GoogleFonts.poppins(color: Colors.white)),
                backgroundColor: doorDashRed,
              ),
            );
          }
        }
      });
    } catch (e, stackTrace) {
      debugPrint('Error removing from cart: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove item from cart: $e',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _checkout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please log in to proceed',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
        Navigator.pushNamed(context, '/login');
      }
      return;
    }

    if (cart.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cart is empty!',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    final paymentMethod = await _showPaymentMethodDialog();
    if (paymentMethod == null) return;

    setState(() => _isLoading = true);

    String? paymentLink;
    String? trackingNumber;

    try {
      debugPrint(
          'Starting checkout from GroceryScreen with ${cart.length} items');
      final groceryItems = cart
          .map((item) => ({
                'id': item['id'] ?? 'unknown',
                'name': item['name'] ?? 'Unnamed',
                'quantity': item['ordered_quantity'] ?? 1,
                'price': item['price'] ?? 0.0,
                'image': item['image'],
              }))
          .toList();

      final total = groceryItems.fold<double>(
          0.0, (sum, item) => sum + (item['quantity'] * item['price']));
      debugPrint('Calculated total: $total');

      debugPrint('Cart items payload: $groceryItems');

      final response = await authProvider.createGroceryWithPayment(
          groceryItems, paymentMethod, total);

      debugPrint('Raw response from createGroceryWithPayment: $response');

      paymentLink = response['payment_link']?.toString();
      trackingNumber = response['grocery']?['tracking_number']?.toString();

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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment initiated! Complete it in your browser.',
                  style: GoogleFonts.poppins(color: Colors.white)),
              backgroundColor: doorDashRed,
            ),
          );
        }

        await authProvider.refreshGroceries();
        final status = await authProvider.pollGroceryStatus(trackingNumber);
        debugPrint('Order status: $status');
        if (status == 'completed') {
          if (mounted) {
            setState(() => cart.clear());
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Grocery order completed successfully!',
                    style: GoogleFonts.poppins(color: Colors.white)),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pushReplacementNamed(context, '/orders');
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Order processing. Check status in Orders.',
                    style: GoogleFonts.poppins(color: Colors.white)),
                backgroundColor: doorDashRed,
              ),
            );
            Navigator.pushReplacementNamed(context, '/orders');
          }
        }
      } else {
        debugPrint('Failed to launch URL: $uri');
        _showManualPaymentOption(paymentLink);
      }
    } catch (e, stackTrace) {
      debugPrint('Checkout error in GroceryScreen: $e\n$stackTrace');
      String errorMessage = 'Checkout failed: $e';
      if (e.toString().contains('app model grocery')) {
        errorMessage =
            'Checkout failed: Grocery model error detected. Please check logs.';
      } else if (e.toString().contains('Invalid payment URL')) {
        errorMessage = 'Invalid payment URL received from server: $paymentLink';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage,
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
    try {
      setState(() => _selectedIndex = index);
      final routes = {
        0: '/home',
        1: '/restaurants',
        2: '/groceries',
        3: '/orders',
        4: '/profile',
        5: '/restaurant-owner',
      };
      if (index != 2 && routes.containsKey(index)) {
        if (index == 1) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const RestaurantScreen()));
        } else {
          Navigator.pushReplacementNamed(context, routes[index]!);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error navigating to route: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to navigate: $e',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showImageZoomDialog(BuildContext context, String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No image available to view',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }
    try {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(20.0),
              minScale: 0.5,
              maxScale: 3.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    size: 50,
                    color: doorDashGrey),
              ),
            ),
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Error showing image dialog: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to display image: $e',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.removeListener(_onFilterChanged);
    _searchController.dispose();
    _locationController.removeListener(_onFilterChanged);
    _locationController.dispose();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const bottomNavHeight = 80.0; // Approximate height of BottomNavigationBar
    const fabHeight = 60.0; // Height of FloatingActionButton

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
                      const Icon(Icons.local_grocery_store,
                          color: Colors.white, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        'Groceries',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth > 600 ? 28 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (authProvider.isLoggedIn &&
                          authProvider.isRestaurantOwner)
                        IconButton(
                          icon: const Icon(Icons.add_circle,
                              color: Colors.white, size: 28),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const CreateGroceryProductScreen()),
                          ),
                          tooltip: 'Add Grocery Product',
                        ),
                      IconButton(
                        icon: const Icon(Icons.refresh,
                            color: Colors.white, size: 28),
                        onPressed: _isLoading ? null : _fetchGroceries,
                        tooltip: 'Refresh Groceries',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        toolbarHeight: 80,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: doorDashRed, strokeWidth: 4),
                  const SizedBox(height: 20),
                  Text(
                    'Loading Groceries...',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: doorDashGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchGroceries,
              color: doorDashRed,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  left: screenWidth > 600 ? 30.0 : 20.0,
                  right: screenWidth > 600 ? 30.0 : 20.0,
                  top: 20.0,
                  bottom: bottomInset +
                      bottomNavHeight +
                      (cart.isNotEmpty ? fabHeight + 20 : 0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search for groceries...',
                              hintStyle: GoogleFonts.poppins(
                                  color: doorDashGrey.withOpacity(0.6),
                                  fontSize: 16),
                              prefixIcon:
                                  const Icon(Icons.search, color: doorDashRed),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear,
                                          color: doorDashGrey),
                                      onPressed: () =>
                                          _searchController.clear(),
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: doorDashLightGrey,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 15),
                            ),
                            style: GoogleFonts.poppins(
                                color: textColor, fontSize: 16),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _locationController,
                            decoration: InputDecoration(
                              hintText: 'Filter by location...',
                              hintStyle: GoogleFonts.poppins(
                                  color: doorDashGrey.withOpacity(0.6),
                                  fontSize: 16),
                              prefixIcon: const Icon(Icons.location_on,
                                  color: doorDashRed),
                              suffixIcon: _locationController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear,
                                          color: doorDashGrey),
                                      onPressed: () =>
                                          _locationController.clear(),
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: doorDashLightGrey,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 15),
                            ),
                            style: GoogleFonts.poppins(
                                color: textColor, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    _filteredGroceries.isEmpty
                        ? SizedBox(
                            height: screenHeight * 0.5,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.local_grocery_store_outlined,
                                      size: 100, color: doorDashGrey),
                                  const SizedBox(height: 20),
                                  Text(
                                    'No Groceries Found',
                                    style: GoogleFonts.poppins(
                                      fontSize: screenWidth > 600 ? 22 : 20,
                                      fontWeight: FontWeight.w600,
                                      color: doorDashGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Try adjusting your search or location filters.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: screenWidth > 600 ? 16 : 14,
                                      color: doorDashGrey.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: screenWidth > 600
                                  ? 3
                                  : screenWidth > 400
                                      ? 2
                                      : 1,
                              crossAxisSpacing: 15,
                              mainAxisSpacing: 15,
                              childAspectRatio: screenWidth > 600
                                  ? 0.75
                                  : screenWidth > 400
                                      ? 0.7
                                      : 0.65,
                            ),
                            itemCount: _filteredGroceries.length,
                            itemBuilder: (context, index) {
                              final item = _filteredGroceries[index];
                              final inCart = cart.any(
                                  (cartItem) => cartItem['id'] == item['id']);
                              final cartItem = cart.firstWhere(
                                (cartItem) => cartItem['id'] == item['id'],
                                orElse: () => {'ordered_quantity': 0},
                              );
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: Card(
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  color: Colors.white,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onTap: () => _showImageZoomDialog(
                                            context, item['image']),
                                        child: Hero(
                                          tag: 'grocery_${item['id']}',
                                          child: ClipRRect(
                                            borderRadius:
                                                const BorderRadius.only(
                                              topLeft: Radius.circular(20),
                                              topRight: Radius.circular(20),
                                            ),
                                            child: item['image'] != null &&
                                                    item['image']
                                                        .toString()
                                                        .isNotEmpty
                                                ? Image.network(
                                                    item['image'],
                                                    height: screenWidth > 600
                                                        ? 120
                                                        : 100,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context,
                                                            error,
                                                            stackTrace) =>
                                                        Container(
                                                      height: screenWidth > 600
                                                          ? 120
                                                          : 100,
                                                      color: doorDashLightGrey,
                                                      child: const Icon(
                                                        Icons
                                                            .local_grocery_store,
                                                        color: doorDashRed,
                                                        size: 50,
                                                      ),
                                                    ),
                                                  )
                                                : Container(
                                                    height: screenWidth > 600
                                                        ? 120
                                                        : 100,
                                                    color: doorDashLightGrey,
                                                    child: const Icon(
                                                      Icons.local_grocery_store,
                                                      color: doorDashRed,
                                                      size: 50,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['name'] ?? 'Unnamed',
                                              style: GoogleFonts.poppins(
                                                fontSize:
                                                    screenWidth > 600 ? 16 : 14,
                                                fontWeight: FontWeight.w600,
                                                color: textColor,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              '${(item['price'] as double?)?.toStringAsFixed(2) ?? '0.00'} Naira',
                                              style: GoogleFonts.poppins(
                                                fontSize:
                                                    screenWidth > 600 ? 14 : 12,
                                                color: doorDashRed,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              'Stock: ${item['stock_quantity']?.toString() ?? '0'}',
                                              style: GoogleFonts.poppins(
                                                fontSize:
                                                    screenWidth > 600 ? 12 : 10,
                                                color: doorDashGrey,
                                              ),
                                            ),
                                            if (item['location']?.isNotEmpty ??
                                                false)
                                              Text(
                                                'Location: ${item['location']}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: screenWidth > 600
                                                      ? 12
                                                      : 10,
                                                  color: doorDashGrey,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            const SizedBox(height: 10),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                if (inCart)
                                                  Row(
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.remove_circle,
                                                            color: doorDashRed,
                                                            size: 24),
                                                        onPressed: () =>
                                                            _removeFromCart(
                                                                item),
                                                        padding:
                                                            EdgeInsets.zero,
                                                        constraints:
                                                            const BoxConstraints(),
                                                      ),
                                                      const SizedBox(width: 5),
                                                      Text(
                                                        '${cartItem['ordered_quantity']}',
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize:
                                                              screenWidth > 600
                                                                  ? 14
                                                                  : 12,
                                                          color: doorDashRed,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 5),
                                                    ],
                                                  ),
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.add_circle,
                                                      color: doorDashRed,
                                                      size: 24),
                                                  onPressed: () =>
                                                      _addToCart(item),
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
      floatingActionButton: cart.isNotEmpty
          ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(15),
                child: InkWell(
                  onTap: _isLoading ? null : _checkout,
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [doorDashRed, doorDashRed.withOpacity(0.9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.shopping_cart,
                                color: Colors.white, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          'Checkout (${cart.length})',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home), label: 'Home', tooltip: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.restaurant),
                label: 'Restaurants',
                tooltip: 'Restaurants'),
            BottomNavigationBarItem(
                icon: Icon(Icons.local_grocery_store),
                label: 'Groceries',
                tooltip: 'Groceries'),
            BottomNavigationBarItem(
                icon: Icon(Icons.receipt), label: 'Orders', tooltip: 'Orders'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person), label: 'Profile', tooltip: 'Profile'),
            BottomNavigationBarItem(
                icon: Icon(Icons.store), label: 'Owner', tooltip: 'Owner'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: doorDashRed,
          unselectedItemColor: doorDashGrey,
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: GoogleFonts.poppins(
            fontSize: screenWidth > 600 ? 14 : 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle:
              GoogleFonts.poppins(fontSize: screenWidth > 600 ? 14 : 12),
          elevation: 0,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
