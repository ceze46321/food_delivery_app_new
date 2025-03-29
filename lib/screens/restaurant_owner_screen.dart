import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../auth_provider.dart';
import '../main.dart' show textColor;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RestaurantOwnerScreen extends StatefulWidget {
  const RestaurantOwnerScreen({super.key});

  @override
  State<RestaurantOwnerScreen> createState() => _RestaurantOwnerScreenState();
}

class _RestaurantOwnerScreenState extends State<RestaurantOwnerScreen> {
  List<dynamic> restaurants = [];
  bool isLoading = true;
  int _selectedIndex = 5; // Owner tab as default

  static const Color doorDashRed = Color(0xFFEF2A39);
  static const Color doorDashGrey = Color(0xFF757575);
  static const Color doorDashLightGrey = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _checkAccessAndFetch();
  }

  Future<void> _checkAccessAndFetch() async {
    setState(() => isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (auth.token == null || auth.role == null) {
      await auth.loadToken();
    }

    print('Checking access - Role: ${auth.role}, Is Owner: ${auth.isRestaurantOwner}');
    if (!auth.isRestaurantOwner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAccessDeniedDialog();
      });
      setState(() => isLoading = false);
      return;
    }
    await _fetchRestaurantData();
  }

  Future<void> _fetchRestaurantData() async {
    setState(() => isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final response = await auth.getRestaurantOwnerData();
      if (mounted) {
        setState(() {
          restaurants = response['restaurants'] ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching restaurant data: $e', style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _deleteRestaurant(String restaurantId) async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.apiService.delete('/restaurants/$restaurantId'); // Add this endpoint in ApiService
      await _fetchRestaurantData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restaurant deleted', style: GoogleFonts.poppins(color: Colors.white))),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting restaurant: $e', style: GoogleFonts.poppins(color: Colors.white))),
      );
    }
  }

  Future<void> _editRestaurant(Map<String, dynamic> restaurant) async {
    // Navigate to an edit screen or show a dialog
    // For simplicity, assume a dialog here
    // You can create a separate EditRestaurantScreen for a full form
    final nameController = TextEditingController(text: restaurant['name']);
    final addressController = TextEditingController(text: restaurant['address']);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Restaurant', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'Name')),
            TextField(controller: addressController, decoration: InputDecoration(labelText: 'Address')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: doorDashRed)),
          ),
          TextButton(
            onPressed: () async {
              try {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                await auth.apiService.put('/restaurants/${restaurant['id']}', {
                  'name': nameController.text,
                  'address': addressController.text,
                  // Add other fields as needed
                });
                await _fetchRestaurantData();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Restaurant updated', style: GoogleFonts.poppins(color: Colors.white))),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating restaurant: $e', style: GoogleFonts.poppins(color: Colors.white))),
                );
              }
            },
            child: Text('Save', style: GoogleFonts.poppins(color: doorDashRed)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMenuItem(String restaurantId, String menuItemId) async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.apiService.delete('/restaurants/$restaurantId/menu-items/$menuItemId'); // Add this endpoint
      await _fetchRestaurantData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Menu item deleted', style: GoogleFonts.poppins(color: Colors.white))),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting menu item: $e', style: GoogleFonts.poppins(color: Colors.white))),
      );
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
    if (index != 5 && routes.containsKey(index)) {
      Navigator.pushReplacementNamed(context, routes[index]!);
    }
  }

  void _showAccessDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Access Denied',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: doorDashRed),
        ),
        content: Text(
          'This page is exclusive to restaurant owners. Redirecting to home...',
          style: GoogleFonts.poppins(fontSize: 16, color: doorDashGrey),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: Text(
              'OK',
              style: GoogleFonts.poppins(fontSize: 16, color: doorDashRed, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ).animate().scale(duration: 200.ms),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (!auth.isRestaurantOwner && !isLoading) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.store, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text(
              'Restaurant Dashboard',
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: doorDashRed,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: isLoading ? null : _fetchRestaurantData,
            tooltip: 'Refresh Restaurants',
          ),
        ],
      ),
      body: isLoading
          ? Center(child: SpinKitFadingCircle(color: doorDashRed, size: 60))
          : RefreshIndicator(
              onRefresh: _fetchRestaurantData,
              color: doorDashRed,
              child: restaurants.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.storefront, size: 80, color: doorDashGrey),
                          SizedBox(height: 16),
                          Text(
                            'No Restaurants Found',
                            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w500, color: doorDashGrey),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Your Restaurants',
                                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: doorDashRed,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${restaurants.length}',
                                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 300.ms),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.all(16),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: restaurants.length,
                            itemBuilder: (context, index) {
                              final restaurant = restaurants[index];
                              return Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                      child: CachedNetworkImage(
                                        imageUrl: restaurant['image'] ?? 'https://via.placeholder.com/150',
                                        height: 120,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Center(child: SpinKitFadingCircle(color: doorDashRed, size: 30)),
                                        errorWidget: (context, url, error) => Icon(Icons.error, color: doorDashRed),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            restaurant['name'],
                                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            restaurant['address'],
                                            style: GoogleFonts.poppins(fontSize: 12, color: doorDashGrey),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 8),
                                          ExpansionTile(
                                            title: Text(
                                              'Menu (${restaurant['menu_items'].length})',
                                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                                            ),
                                            children: restaurant['menu_items'].map<Widget>((item) => ListTile(
                                                  title: Text(
                                                    item['name'],
                                                    style: GoogleFonts.poppins(fontSize: 12),
                                                  ),
                                                  subtitle: Text(
                                                    '₦${item['price'] ?? 'N/A'}',
                                                    style: GoogleFonts.poppins(fontSize: 10, color: doorDashRed),
                                                  ),
                                                  trailing: IconButton(
                                                    icon: Icon(Icons.delete, color: doorDashRed, size: 20),
                                                    onPressed: () => _deleteMenuItem(restaurant['id'].toString(), item['id'].toString()),
                                                  ),
                                                )).toList(),
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.edit, color: doorDashGrey),
                                                onPressed: () => _editRestaurant(restaurant),
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.delete, color: doorDashRed),
                                                onPressed: () => _deleteRestaurant(restaurant['id'].toString()),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().scale(duration: 300.ms, delay: (index * 100).ms);
                            },
                          ),
                        ],
                      ),
                    ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home', tooltip: 'Go to Home'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Restaurants', tooltip: 'Browse Restaurants'),
          BottomNavigationBarItem(icon: Icon(Icons.local_grocery_store), label: 'Groceries', tooltip: 'Shop Groceries'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders', tooltip: 'View Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile', tooltip: 'My Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Owner', tooltip: 'Restaurant Dashboard'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: doorDashRed,
        unselectedItemColor: doorDashGrey.withOpacity(0.6),
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        showUnselectedLabels: true,
        elevation: 8,
        onTap: _onItemTapped,
      ),
    );
  }
}