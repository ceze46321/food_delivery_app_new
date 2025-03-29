import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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

class _GroceryScreenState extends State<GroceryScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _selectedIndex = 2;
  List<Map<String, dynamic>> cart = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  List<Map<String, dynamic>> _allGroceries = [];
  List<Map<String, dynamic>> _filteredGroceries = [];
  StreamSubscription? _sub;
  bool _isLoading = true;
  final _appLinks = AppLinks();

  static const Color doorDashRed = Color(0xFFEF2A39);
  static const Color doorDashGrey = Color(0xFF757575);
  static const Color doorDashLightGrey = Color(0xFFF5F5F5);

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
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final groceries = await authProvider.fetchGroceryProducts();
      if (mounted) {
        setState(() {
          _allGroceries = List<Map<String, dynamic>>.from(groceries); // Ensure type safety
          _filteredGroceries = _flattenAndFilterGroceries(_allGroceries);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching groceries: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _initDeepLinkListener() async {
    // Handle initial deep link
    final initialLink = await _appLinks.getInitialLinkString();
    if (initialLink != null && mounted) {
      debugPrint('Initial deep link: $initialLink');
      _handleDeepLink(initialLink);
    }

    // Listen for deep links during runtime
    _sub = _appLinks.stringLinkStream.listen((String? link) {
      if (link != null && mounted) {
        debugPrint('Received deep link: $link');
        _handleDeepLink(link);
      }
    }, onError: (err) {
      debugPrint('Deep link error: $err');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deep link error: $err'), backgroundColor: Colors.redAccent),
        );
      }
    });
  }

  void _handleDeepLink(String link) {
    final uri = Uri.parse(link);
    final status = uri.queryParameters['status'];
    if (status == 'completed' && mounted) {
      setState(() => cart.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful!'), backgroundColor: doorDashRed),
      );
    }
  }

  Future<void> _onFilterChanged() async {
    final query = _searchController.text.trim();
    final location = _locationController.text.trim();

    if (query.isEmpty && location.isEmpty) {
      setState(() {
        _filteredGroceries = _flattenAndFilterGroceries(_allGroceries);
      });
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final filtered = await authProvider.getFilteredGroceries(query, location);
      if (mounted) {
        setState(() {
          _filteredGroceries = _flattenAndFilterGroceries(List<Map<String, dynamic>>.from(filtered)); // Type cast
        });
      }
    } catch (e) {
      debugPrint('Error filtering groceries: $e');
      _filterGroceriesClientSide(query, location);
    }
  }

  List<Map<String, dynamic>> _flattenAndFilterGroceries(List<Map<String, dynamic>> groceries) {
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
      final matchesLocation = location.isEmpty || (item['location'] ?? '').toLowerCase().contains(location);
      return matchesName && matchesLocation;
    }).toList();
  }

  void _filterGroceriesClientSide(String query, String location) {
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
        final matchesName = (item['name'] ?? '').toLowerCase().contains(query.toLowerCase());
        final matchesLocation = location.isEmpty || (item['location'] ?? '').toLowerCase().contains(location.toLowerCase());
        return matchesName && matchesLocation;
      }).toList();
    });
  }

  void _addToCart(Map<String, dynamic> item) {
    setState(() {
      final existingItemIndex = cart.indexWhere((cartItem) => cartItem['id'] == item['id']);
      if (existingItemIndex != -1) {
        cart[existingItemIndex]['ordered_quantity'] = (cart[existingItemIndex]['ordered_quantity'] ?? 0) + 1;
      } else {
        cart.add({
          'id': item['id'],
          'name': item['name'],
          'stock_quantity': item['stock_quantity'],
          'ordered_quantity': 1,
          'price': item['price'],
          'image': item['image'],
        });
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item['name']} added to cart!'), backgroundColor: doorDashRed),
    );
  }

  void _removeFromCart(Map<String, dynamic> item) {
    setState(() {
      final existingItemIndex = cart.indexWhere((cartItem) => cartItem['id'] == item['id']);
      if (existingItemIndex != -1) {
        final currentQuantity = cart[existingItemIndex]['ordered_quantity'] as int;
        if (currentQuantity > 1) {
          cart[existingItemIndex]['ordered_quantity'] = currentQuantity - 1;
        } else {
          cart.removeAt(existingItemIndex);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item['name']} removed from cart!'), backgroundColor: doorDashRed),
        );
      }
    });
  }

  Future<void> _checkout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to proceed'), backgroundColor: Colors.redAccent),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    try {
      final groceryItems = cart.map((item) => ({
            'name': item['name'],
            'quantity': item['stock_quantity'],
            'ordered_quantity': item['ordered_quantity'],
            'price': item['price'],
            'image': item['image'],
          })).toList();
      final newGrocery = await authProvider.createGrocery(groceryItems);
      final groceryId = newGrocery['id'].toString();
      final response = await authProvider.initiateCheckout(groceryId, paymentMethod: 'flutterwave');

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
    if (index != 2 && routes.containsKey(index)) {
      if (index == 1) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RestaurantScreen()));
      } else {
        Navigator.pushReplacementNamed(context, routes[index]!);
      }
    }
  }

  void _showImageZoomDialog(BuildContext context, String? imageUrl) {
    if (imageUrl == null) return;
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
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _locationController.dispose();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: doorDashRed,
        title: Text(
          'Grocery',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          if (authProvider.isLoggedIn && authProvider.isRestaurantOwner)
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateGroceryProductScreen()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchGroceries,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: doorDashRed))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search groceries...',
                      prefixIcon: const Icon(Icons.search, color: doorDashGrey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: doorDashGrey),
                      ),
                      filled: true,
                      fillColor: doorDashLightGrey,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: 'Filter by location...',
                      prefixIcon: const Icon(Icons.location_on, color: doorDashGrey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: doorDashGrey),
                      ),
                      filled: true,
                      fillColor: doorDashLightGrey,
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredGroceries.isEmpty
                      ? const Center(child: Text('No groceries found'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: _filteredGroceries.length,
                          itemBuilder: (context, index) {
                            final item = _filteredGroceries[index];
                            final inCart = cart.any((cartItem) => cartItem['id'] == item['id']);
                            final cartItem = cart.firstWhere(
                              (cartItem) => cartItem['id'] == item['id'],
                              orElse: () => {'ordered_quantity': 0},
                            );
                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: GestureDetector(
                                  onTap: () => _showImageZoomDialog(context, item['image']),
                                  child: item['image'] != null
                                      ? Image.network(
                                          item['image'],
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Icon(Icons.fastfood, size: 50, color: doorDashRed),
                                        )
                                      : const Icon(Icons.fastfood, size: 50, color: doorDashRed),
                                ),
                                title: Text(
                                  item['name'] ?? 'Unnamed',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Price: \$${item['price']?.toStringAsFixed(2) ?? '0.00'}',
                                      style: GoogleFonts.poppins(color: doorDashGrey),
                                    ),
                                    Text(
                                      'Stock: ${item['stock_quantity'] ?? 0}',
                                      style: GoogleFonts.poppins(color: doorDashGrey),
                                    ),
                                    if (item['location'] != null && item['location'].isNotEmpty)
                                      Text(
                                        'Location: ${item['location']}',
                                        style: GoogleFonts.poppins(color: doorDashGrey),
                                      ),
                                    if (inCart)
                                      Text(
                                        'In Cart: ${cartItem['ordered_quantity']}',
                                        style: GoogleFonts.poppins(color: doorDashRed),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (inCart)
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle, color: doorDashRed),
                                        onPressed: () => _removeFromCart(item),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle, color: doorDashRed),
                                      onPressed: () => _addToCart(item),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (cart.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: _checkout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: doorDashRed,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Checkout (${cart.length} items)',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Restaurants'),
          BottomNavigationBarItem(icon: Icon(Icons.local_grocery_store), label: 'Groceries'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Owner'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: doorDashRed,
        unselectedItemColor: doorDashGrey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}