import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../auth_provider.dart';
import '../main.dart' show textColor;
import 'add_restaurant_screen.dart';

class RestaurantOwnerScreen extends StatefulWidget {
  const RestaurantOwnerScreen({super.key});

  @override
  State<RestaurantOwnerScreen> createState() => _RestaurantOwnerScreenState();
}

class _RestaurantOwnerScreenState extends State<RestaurantOwnerScreen> {
  List<dynamic> restaurants = [];
  bool isLoading = true;
  String? errorMessage;
  int _selectedIndex = 5;
  bool _accessChecked = false; // Flag to prevent repeated checks

  static const Color doorDashRed = Color(0xFFEF2A39);
  static const Color doorDashGrey = Color(0xFF757575);
  static const Color doorDashLightGrey = Color(0xFFF5F5F5);
  static const Color doorDashWhite = Colors.white;

  @override
  void initState() {
    super.initState();
    _checkAccessAndFetch();
  }

  Future<void> _checkAccessAndFetch() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (auth.token == null || auth.role == null) {
      await auth.loadToken();
    }

    debugPrint(
        'Checking access - Role: ${auth.role}, Is Owner: ${auth.isRestaurantOwner}');
    if (auth.role != 'restaurant_owner' || !auth.isRestaurantOwner) {
      setState(() => _accessChecked = true); // Mark access as checked
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAccessDeniedDialog();
      });
      setState(() => isLoading = false);
      return;
    }

    await _fetchRestaurantData();
    setState(
        () => _accessChecked = true); // Mark access as checked after success
  }

  Future<void> _fetchRestaurantData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final response = await auth.getRestaurantOwnerData();
      if (mounted) {
        setState(() {
          restaurants = response['restaurants'] ?? [];
          isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching restaurant data: $e\n$stackTrace');
      String message;
      if (e.toString().contains('401') ||
          e.toString().contains('unauthorized')) {
        message = 'Authentication failed. Please log in again.';
      } else if (e.toString().contains('network') ||
          e.toString().contains('timeout')) {
        message = 'Network error. Please check your connection and try again.';
      } else {
        message = 'Failed to load restaurant data. Please try again.';
      }
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = message;
        });
      }
    }
  }

  Future<void> _deleteRestaurant(String restaurantId) async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.apiService.deleteRestaurant(restaurantId);
      await _fetchRestaurantData();
      if (mounted) {
        _showSnackBar('Restaurant deleted successfully!', doorDashRed);
      }
    } catch (e, stackTrace) {
      debugPrint('Error deleting restaurant: $e\n$stackTrace');
      _showErrorSnackBar(e);
    }
  }

  Future<void> _editRestaurant(Map<String, dynamic> restaurant) async {
    final nameController = TextEditingController(text: restaurant['name']);
    final addressController =
        TextEditingController(text: restaurant['address']);
    final stateController = TextEditingController(text: restaurant['state']);
    final countryController =
        TextEditingController(text: restaurant['country']);
    String category = restaurant['category'] ?? 'Restaurant';

    await showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: doorDashWhite,
          title: Text(
            'Edit Restaurant',
            style: GoogleFonts.poppins(
              fontSize: screenWidth > 600 ? 20 : 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: screenWidth > 600 ? 400 : double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(
                    controller: nameController,
                    label: 'Name',
                    icon: Icons.store,
                    validator: (value) =>
                        value!.isEmpty ? 'Name required' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: addressController,
                    label: 'Address',
                    icon: Icons.location_on,
                    validator: (value) =>
                        value!.isEmpty ? 'Address required' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: stateController,
                    label: 'State',
                    icon: Icons.map,
                    validator: (value) =>
                        value!.isEmpty ? 'State required' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: countryController,
                    label: 'Country',
                    icon: Icons.flag,
                    validator: (value) =>
                        value!.isEmpty ? 'Country required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: _inputDecoration('Category', Icons.category),
                    items: ['Restaurant', 'Fast Food', 'Cafe']
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat,
                                  style: GoogleFonts.poppins(color: textColor)),
                            ))
                        .toList(),
                    onChanged: (value) => category = value!,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(color: doorDashRed)),
            ),
            GestureDetector(
              onTap: () async {
                if (nameController.text.isEmpty ||
                    addressController.text.isEmpty ||
                    stateController.text.isEmpty ||
                    countryController.text.isEmpty) {
                  _showErrorSnackBar('Please fill all required fields');
                  return;
                }
                try {
                  final auth =
                      Provider.of<AuthProvider>(context, listen: false);
                  await auth.apiService
                      .put('/restaurants/${restaurant['id']}', {
                    'name': nameController.text,
                    'address': addressController.text,
                    'state': stateController.text,
                    'country': countryController.text,
                    'category': category,
                  });
                  await _fetchRestaurantData();
                  Navigator.pop(context);
                  if (mounted)
                    _showSnackBar(
                        'Restaurant updated successfully!', doorDashRed);
                } catch (e, stackTrace) {
                  debugPrint('Error updating restaurant: $e\n$stackTrace');
                  _showErrorSnackBar(e);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [doorDashRed, doorDashRed.withOpacity(0.9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Save',
                    style: GoogleFonts.poppins(color: doorDashWhite)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editMenuItem(
      String restaurantId, Map<String, dynamic> menuItem) async {
    final nameController = TextEditingController(text: menuItem['name']);
    final priceController =
        TextEditingController(text: menuItem['price']?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: doorDashWhite,
          title: Text(
            'Edit Menu Item',
            style: GoogleFonts.poppins(
              fontSize: screenWidth > 600 ? 20 : 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          content: SizedBox(
            width: screenWidth > 600 ? 400 : double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  controller: nameController,
                  label: 'Item Name',
                  icon: Icons.fastfood,
                  validator: (value) => value!.isEmpty ? 'Name required' : null,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: priceController,
                  label: 'Price (₦)',
                  icon: Icons.monetization_on,
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value!.isEmpty || double.tryParse(value) == null
                          ? 'Valid price required'
                          : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(color: doorDashRed)),
            ),
            GestureDetector(
              onTap: () async {
                if (nameController.text.isEmpty ||
                    priceController.text.isEmpty ||
                    double.tryParse(priceController.text) == null) {
                  _showErrorSnackBar(
                      'Please fill all required fields with valid data');
                  return;
                }
                try {
                  final auth =
                      Provider.of<AuthProvider>(context, listen: false);
                  await auth.apiService.put(
                      '/restaurants/$restaurantId/menu-items/${menuItem['id']}',
                      {
                        'name': nameController.text,
                        'price': double.parse(priceController.text),
                      });
                  await _fetchRestaurantData();
                  Navigator.pop(context);
                  if (mounted)
                    _showSnackBar(
                        'Menu item updated successfully!', doorDashRed);
                } catch (e, stackTrace) {
                  debugPrint('Error updating menu item: $e\n$stackTrace');
                  _showErrorSnackBar(e);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [doorDashRed, doorDashRed.withOpacity(0.9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Save',
                    style: GoogleFonts.poppins(color: doorDashWhite)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteMenuItem(String restaurantId, String menuItemId) async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.apiService
          .delete('/restaurants/$restaurantId/menu-items/$menuItemId');
      await _fetchRestaurantData();
      if (mounted)
        _showSnackBar('Menu item deleted successfully!', doorDashRed);
    } catch (e, stackTrace) {
      debugPrint('Error deleting menu item: $e\n$stackTrace');
      _showErrorSnackBar(e);
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
      barrierDismissible: true, // Allow dismissal to go back
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: doorDashWhite,
          title: Text(
            'Access Denied',
            style: GoogleFonts.poppins(
              fontSize: screenWidth > 600 ? 22 : 20,
              fontWeight: FontWeight.w600,
              color: doorDashRed,
            ),
          ),
          content: Text(
            'This page is exclusive to restaurant owners. Would you like to go back to the home screen?',
            style: GoogleFonts.poppins(
              fontSize: screenWidth > 600 ? 18 : 16,
              color: doorDashGrey,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Allow going back
              child: Text('Cancel',
                  style: GoogleFonts.poppins(color: doorDashRed)),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pop(context); // Close dialog
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [doorDashRed, doorDashRed.withOpacity(0.9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Go to Home',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: doorDashWhite,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ).animate().scale(duration: 200.ms);
      },
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: GoogleFonts.poppins(color: doorDashWhite)),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(dynamic error) {
    String message;
    if (error is String) {
      message = error;
    } else if (error.toString().contains('401') ||
        error.toString().contains('unauthorized')) {
      message = 'Authentication failed. Please log in again.';
    } else if (error.toString().contains('network') ||
        error.toString().contains('timeout')) {
      message = 'Network error. Please check your connection and try again.';
    } else {
      message = 'An error occurred: $error';
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(message, style: GoogleFonts.poppins(color: doorDashWhite)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: doorDashWhite,
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Only show dialog if access hasn't been checked yet and user isn't an owner
    if (!_accessChecked && !auth.isRestaurantOwner && !isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAccessDeniedDialog();
      });
      return const SizedBox.shrink();
    }

    // If access was checked and user isn't an owner, don't rebuild UI
    if (_accessChecked && !auth.isRestaurantOwner) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: doorDashLightGrey,
        appBar: AppBar(
          title: Row(
            children: [
              const Icon(Icons.store, color: doorDashWhite, size: 28),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Restaurant Dashboard',
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth > 600 ? 24 : 20,
                    fontWeight: FontWeight.w600,
                    color: doorDashWhite,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: doorDashRed,
          elevation: 0,
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
            IconButton(
              icon: const Icon(Icons.refresh, color: doorDashWhite),
              onPressed: isLoading ? null : _fetchRestaurantData,
              tooltip: 'Refresh Restaurants',
            ),
          ],
        ),
        body: isLoading
            ? Center(
                child: SpinKitFadingCircle(
                  color: doorDashRed,
                  size: screenWidth > 600 ? 80 : 60,
                ).animate().fadeIn(duration: 300.ms),
              )
            : RefreshIndicator(
                onRefresh: _fetchRestaurantData,
                color: doorDashRed,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(screenWidth > 600 ? 24 : 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Your Restaurants',
                                style: GoogleFonts.poppins(
                                  fontSize: screenWidth > 600 ? 28 : 24,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth > 600 ? 16 : 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        doorDashRed,
                                        doorDashRed.withOpacity(0.9)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${restaurants.length}',
                                    style: GoogleFonts.poppins(
                                      fontSize: screenWidth > 600 ? 16 : 14,
                                      color: doorDashWhite,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                SizedBox(width: screenWidth > 600 ? 16 : 12),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const AddRestaurantScreen()))
                                        .then((_) => _fetchRestaurantData());
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: screenWidth > 600 ? 20 : 16,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          doorDashRed,
                                          doorDashRed.withOpacity(0.9)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: doorDashRed.withOpacity(0.4),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.add,
                                            color: doorDashWhite, size: 18),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Add Restaurant',
                                          style: GoogleFonts.poppins(
                                            fontSize:
                                                screenWidth > 600 ? 16 : 14,
                                            color: doorDashWhite,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms),
                      if (errorMessage != null)
                        Center(
                          child: Padding(
                            padding:
                                EdgeInsets.all(screenWidth > 600 ? 32 : 16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline,
                                    size: 80, color: doorDashRed),
                                const SizedBox(height: 16),
                                Text(
                                  errorMessage!,
                                  style: GoogleFonts.poppins(
                                    fontSize: screenWidth > 600 ? 20 : 16,
                                    color: doorDashGrey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                GestureDetector(
                                  onTap: _fetchRestaurantData,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: screenWidth > 600 ? 24 : 16,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          doorDashRed,
                                          doorDashRed.withOpacity(0.9)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Retry',
                                      style: GoogleFonts.poppins(
                                        fontSize: screenWidth > 600 ? 16 : 14,
                                        color: doorDashWhite,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (restaurants.isEmpty)
                        Center(
                          child: Padding(
                            padding:
                                EdgeInsets.all(screenWidth > 600 ? 32 : 16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.storefront,
                                    size: 80, color: doorDashGrey),
                                const SizedBox(height: 16),
                                Text(
                                  'No Restaurants Found',
                                  style: GoogleFonts.poppins(
                                    fontSize: screenWidth > 600 ? 20 : 18,
                                    fontWeight: FontWeight.w500,
                                    color: doorDashGrey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'You haven\'t added any restaurants yet. Add one to get started!',
                                  style: GoogleFonts.poppins(
                                    fontSize: screenWidth > 600 ? 16 : 14,
                                    color: doorDashGrey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const AddRestaurantScreen()))
                                        .then((_) => _fetchRestaurantData());
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: screenWidth > 600 ? 24 : 16,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          doorDashRed,
                                          doorDashRed.withOpacity(0.9)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Add Restaurant',
                                      style: GoogleFonts.poppins(
                                        fontSize: screenWidth > 600 ? 16 : 14,
                                        color: doorDashWhite,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.all(screenWidth > 600 ? 24 : 16),
                          gridDelegate:
                              SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: screenWidth > 900
                                ? 400
                                : screenWidth > 600
                                    ? 450
                                    : 600,
                            childAspectRatio: screenWidth > 600 ? 0.85 : 0.9,
                            crossAxisSpacing: screenWidth > 600 ? 24 : 16,
                            mainAxisSpacing: screenWidth > 600 ? 24 : 16,
                          ),
                          itemCount: restaurants.length,
                          itemBuilder: (context, index) {
                            final restaurant = restaurants[index];
                            return Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              color: doorDashWhite,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12)),
                                    child: CachedNetworkImage(
                                      imageUrl: restaurant['image'] ??
                                          'https://via.placeholder.com/150',
                                      height: screenWidth > 600 ? 180 : 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Center(
                                        child: SpinKitFadingCircle(
                                          color: doorDashRed,
                                          size: screenWidth > 600 ? 40 : 30,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error,
                                              color: doorDashRed),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(
                                        screenWidth > 600 ? 12 : 8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          restaurant['name'] ??
                                              'Unnamed Restaurant',
                                          style: GoogleFonts.poppins(
                                            fontSize:
                                                screenWidth > 600 ? 18 : 16,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          restaurant['address'] ?? 'No address',
                                          style: GoogleFonts.poppins(
                                            fontSize:
                                                screenWidth > 600 ? 14 : 12,
                                            color: doorDashGrey,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        ExpansionTile(
                                          title: Text(
                                            'Menu (${restaurant['menu_items']?.length ?? 0})',
                                            style: GoogleFonts.poppins(
                                              fontSize:
                                                  screenWidth > 600 ? 16 : 14,
                                              fontWeight: FontWeight.w600,
                                              color: textColor,
                                            ),
                                          ),
                                          children:
                                              (restaurant['menu_items']
                                                          as List<dynamic>?)
                                                      ?.map<Widget>(
                                                          (item) => ListTile(
                                                                dense: true,
                                                                title: Text(
                                                                  item['name'] ??
                                                                      'Unnamed Item',
                                                                  style: GoogleFonts.poppins(
                                                                      fontSize: screenWidth >
                                                                              600
                                                                          ? 14
                                                                          : 12),
                                                                ),
                                                                subtitle: Text(
                                                                  '₦${item['price']?.toStringAsFixed(2) ?? 'N/A'}',
                                                                  style: GoogleFonts
                                                                      .poppins(
                                                                    fontSize:
                                                                        screenWidth >
                                                                                600
                                                                            ? 12
                                                                            : 10,
                                                                    color:
                                                                        doorDashRed,
                                                                  ),
                                                                ),
                                                                trailing: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    IconButton(
                                                                      icon: const Icon(
                                                                          Icons
                                                                              .edit,
                                                                          color:
                                                                              doorDashGrey,
                                                                          size:
                                                                              20),
                                                                      onPressed: () => _editMenuItem(
                                                                          restaurant['id']
                                                                              .toString(),
                                                                          item),
                                                                    ),
                                                                    IconButton(
                                                                      icon: const Icon(
                                                                          Icons
                                                                              .delete,
                                                                          color:
                                                                              doorDashRed,
                                                                          size:
                                                                              20),
                                                                      onPressed: () => _deleteMenuItem(
                                                                          restaurant['id']
                                                                              .toString(),
                                                                          item['id']
                                                                              .toString()),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ))
                                                      .toList() ??
                                                  [],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit,
                                                  color: doorDashGrey),
                                              onPressed: () =>
                                                  _editRestaurant(restaurant),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete,
                                                  color: doorDashRed),
                                              onPressed: () =>
                                                  _deleteRestaurant(
                                                      restaurant['id']
                                                          .toString()),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().scale(
                                duration: 300.ms, delay: (index * 100).ms);
                          },
                        ),
                    ],
                  ),
                ),
              ),
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home), label: 'Home', tooltip: 'Go to Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.restaurant_menu),
                label: 'Restaurants',
                tooltip: 'Browse Restaurants'),
            BottomNavigationBarItem(
                icon: Icon(Icons.local_grocery_store),
                label: 'Groceries',
                tooltip: 'Shop Groceries'),
            BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long),
                label: 'Orders',
                tooltip: 'View Orders'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
                tooltip: 'My Profile'),
            BottomNavigationBarItem(
                icon: Icon(Icons.storefront),
                label: 'Owner',
                tooltip: 'Restaurant Dashboard'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: doorDashRed,
          unselectedItemColor: doorDashGrey.withOpacity(0.6),
          backgroundColor: doorDashWhite,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: GoogleFonts.poppins(
              fontSize: screenWidth > 600 ? 14 : 12,
              fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              GoogleFonts.poppins(fontSize: screenWidth > 600 ? 14 : 12),
          showUnselectedLabels: true,
          elevation: 8,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: TextFormField(
        controller: controller,
        decoration: _inputDecoration(label, icon),
        validator: validator,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(color: textColor, fontSize: 16),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: doorDashGrey),
      prefixIcon: Icon(icon, color: doorDashRed),
      filled: true,
      fillColor: doorDashWhite,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: doorDashRed, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
