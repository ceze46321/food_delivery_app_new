import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../main.dart' show textColor, accentColor;
import 'restaurant_profile_screen.dart';

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

  late Future<List<dynamic>> _futureRestaurants;
  List<dynamic> _allRestaurants = [];
  List<dynamic> _filteredRestaurants = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  int _currentPage = 1;
  static const int _itemsPerPage = 6;
  int _selectedIndex = 1;

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
      if (mounted) {
        setState(() {
          _allRestaurants = restaurants;
          _filteredRestaurants = restaurants;
        });
      }
      return restaurants;
    } catch (e) {
      debugPrint('Error fetching restaurants: $e');
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
      final filtered = await authProvider.getFilteredRestaurants(query, location);
      if (mounted) {
        setState(() {
          _filteredRestaurants = filtered;
          _currentPage = 1;
        });
      }
    } catch (e) {
      debugPrint('Error filtering restaurants: $e');
      // Fallback to client-side filtering
      _filterRestaurantsClientSide(query, location);
    }
  }

  void _filterRestaurantsClientSide(String query, String location) {
    setState(() {
      _filteredRestaurants = _allRestaurants.where((restaurant) {
        final name = (restaurant['name'] ?? '').toString().toLowerCase();
        final address = (restaurant['address'] ?? '').toString().toLowerCase();
        return name.contains(query.toLowerCase()) && (location.isEmpty || address.contains(location.toLowerCase()));
      }).toList();
      _currentPage = 1;
    });
  }

  List<dynamic> _getPaginatedRestaurants() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _filteredRestaurants.length);
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
      4: '/restaurant-owner',
    };

    if (routes.containsKey(index) && index != 1) {
      Navigator.pushReplacementNamed(context, routes[index]!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: doorDashLightGrey,
      appBar: AppBar(
        backgroundColor: doorDashRed,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: doorDashWhite, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Restaurants',
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: doorDashWhite),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [doorDashRed, doorDashRed.withOpacity(0.9)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, auth, child) => IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.shopping_cart, color: doorDashWhite),
                  if (auth.cartItems.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
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
              onPressed: () => Navigator.pushNamed(context, '/cart'),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureRestaurants,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: doorDashRed));
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(
                'Error loading restaurants',
                style: GoogleFonts.poppins(fontSize: 18, color: doorDashGrey),
              ),
            );
          }

          if (snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restaurant, size: 100, color: doorDashGrey.withOpacity(0.3)),
                  const SizedBox(height: 20),
                  Text(
                    'No restaurants available',
                    style: GoogleFonts.poppins(fontSize: 18, color: doorDashGrey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _fetchRestaurants,
            color: doorDashRed,
            child: Column(
              children: [
                _buildSearchFilters(),
                Expanded(child: _buildRestaurantGrid()),
                _buildPaginationControls(),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home', tooltip: 'Go to Home'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Restaurants', tooltip: 'Restaurants'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Orders', tooltip: 'View Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile', tooltip: 'Your Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Owner', tooltip: 'Restaurant Owner Dashboard'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: doorDashRed,
        unselectedItemColor: doorDashGrey.withOpacity(0.6),
        backgroundColor: doorDashWhite,
        elevation: 12,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400),
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _futureRestaurants = _fetchRestaurants()),
        backgroundColor: doorDashRed,
        tooltip: 'Refresh Restaurants',
        child: const Icon(Icons.refresh, color: doorDashWhite),
      ),
    );
  }

  Widget _buildSearchFilters() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSearchField(_searchController, 'Search by name', Icons.search),
          const SizedBox(height: 12),
          _buildSearchField(_locationController, 'Filter by location', Icons.location_on),
        ],
      ),
    );
  }

  Widget _buildSearchField(TextEditingController controller, String label, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: doorDashWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: doorDashGrey, fontSize: 14),
          prefixIcon: Icon(icon, color: doorDashRed),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: doorDashRed),
                  onPressed: () => controller.clear(),
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          filled: true,
          fillColor: doorDashWhite,
        ),
        style: GoogleFonts.poppins(fontSize: 16, color: textColor),
      ),
    );
  }

  Widget _buildRestaurantGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: _getPaginatedRestaurants().length,
      itemBuilder: (context, index) => _buildRestaurantCard(_getPaginatedRestaurants()[index]),
    );
  }

  Widget _buildRestaurantCard(dynamic restaurant) {
    final menus = (restaurant['menu_items'] ?? restaurant['menus'] as List<dynamic>?) ?? [];
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RestaurantProfileScreen(restaurant: restaurant)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: doorDashWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRestaurantImage(restaurant['image']),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRestaurantInfo(restaurant),
                  const SizedBox(height: 8),
                  _buildMenuSection(menus),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantImage(String? imageUrl) {
    debugPrint('Loading image from: $imageUrl');
    final validUrl = imageUrl != null && imageUrl.trim().isNotEmpty ? imageUrl : 'https://via.placeholder.com/300';

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Image.network(
        validUrl,
        height: 100,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 100,
            color: doorDashLightGrey,
            child: Center(child: CircularProgressIndicator(color: doorDashRed)),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Image load error: $error');
          return Container(
            height: 100,
            color: doorDashLightGrey,
            child: const Icon(Icons.broken_image, color: doorDashGrey),
          );
        },
      ),
    );
  }

  Widget _buildRestaurantInfo(dynamic restaurant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          restaurant['name'] ?? 'Unnamed',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          restaurant['address'] ?? 'No address',
          style: GoogleFonts.poppins(fontSize: 12, color: doorDashGrey),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMenuSection(List<dynamic> menus) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (menus.isEmpty)
            Text(
              'No menu items',
              style: GoogleFonts.poppins(fontSize: 12, color: doorDashGrey),
            )
          else
            ...menus.take(2).map((item) => _buildMenuItem(item, auth, context)),
        ],
      ),
    );
  }

  Widget _buildMenuItem(dynamic item, AuthProvider auth, BuildContext context) {
    final itemName = item['name'] ?? 'Unnamed';
    final itemPrice = (item['price'] as num?)?.toDouble() ?? 0.0;
    final restaurantName = item['restaurant_name'] ?? 'Unknown';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemName,
                  style: GoogleFonts.poppins(fontSize: 12, color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '₦${itemPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(fontSize: 12, color: doorDashRed),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_shopping_cart, color: doorDashRed, size: 20),
            onPressed: () {
              auth.addToCart(itemName, itemPrice, restaurantName: restaurantName);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$itemName added to cart', style: GoogleFonts.poppins(color: doorDashWhite)),
                  backgroundColor: doorDashRed,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    final totalPages = (_filteredRestaurants.length / _itemsPerPage).ceil();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: doorDashRed),
            onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: doorDashRed,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$_currentPage / $totalPages',
              style: GoogleFonts.poppins(fontSize: 14, color: doorDashWhite),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: doorDashRed),
            onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
          ),
        ],
      ),
    );
  }
}