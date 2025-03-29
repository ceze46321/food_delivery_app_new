import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart' show primaryColor, textColor, accentColor;
import '../auth_provider.dart';
import 'grocery_screen.dart';

class MyGroceriesScreen extends StatefulWidget {
  const MyGroceriesScreen({super.key});

  @override
  State<MyGroceriesScreen> createState() => _MyGroceriesScreenState();
}

class _MyGroceriesScreenState extends State<MyGroceriesScreen> {
  static const Color doorDashRed = Color(0xFFEF2A39);
  static const Color doorDashGrey = Color(0xFF757575);
  static const Color doorDashLightGrey = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isLoggedIn) {
        authProvider.fetchUserGroceries();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          backgroundColor: doorDashLightGrey,
          appBar: AppBar(
            title: Text('My Grocery Orders', style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
            backgroundColor: doorDashRed,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: authProvider.isLoggedIn ? () => authProvider.fetchUserGroceries() : null,
              ),
            ],
          ),
          body: !authProvider.isLoggedIn
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Please log in to view your orders',
                        style: GoogleFonts.poppins(color: doorDashGrey, fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: doorDashRed,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: Text('Log In', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
                      ),
                    ],
                  ),
                )
              : authProvider.isLoadingGroceries
                  ? const Center(child: CircularProgressIndicator(color: doorDashRed))
                  : authProvider.userGroceries.isEmpty
                      ? Center(
                          child: Text(
                            'No grocery orders yet',
                            style: GoogleFonts.poppins(fontSize: 20, color: doorDashGrey),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.65, // Adjusted for image
                          ),
                          itemCount: authProvider.userGroceries.length,
                          itemBuilder: (context, index) {
                            final grocery = authProvider.userGroceries[index];
                            return _buildGroceryCard(grocery);
                          },
                        ),
          bottomNavigationBar: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Restaurants'),
              BottomNavigationBarItem(icon: Icon(Icons.local_grocery_store), label: 'Groceries'),
              BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Orders'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
              BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Owner'),
            ],
            currentIndex: 3,
            selectedItemColor: doorDashRed,
            unselectedItemColor: doorDashGrey,
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.poppins(),
            onTap: (index) => _onItemTapped(context, index),
          ),
        );
      },
    );
  }

  Widget _buildGroceryCard(Map<String, dynamic> grocery) {
    final totalPrice = grocery['total_price']?.toString() ?? 'N/A';
    final status = grocery['status']?.toString() ?? 'Unknown';
    final trackingNumber = grocery['tracking_number']?.toString() ?? 'Unknown';
    final items = grocery['items'] as List<dynamic>? ?? [];
    final image = grocery['image']?.toString(); // Fetch image

    return GestureDetector(
      onTap: () => _showOrderDetails(context, grocery),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: image != null
                  ? Image.network(
                      image,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 100,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, color: Colors.white, size: 40),
                      ),
                    )
                  : Container(
                      height: 100,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, color: Colors.white, size: 40),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '#$trackingNumber',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: status == 'completed' ? Colors.green[50] : Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status.capitalize(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: status == 'completed' ? Colors.green[700] : Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₦$totalPrice',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: doorDashRed),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${items.length} Item${items.length == 1 ? '' : 's'}',
                    style: GoogleFonts.poppins(fontSize: 14, color: doorDashGrey),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Icon(Icons.arrow_forward, color: doorDashRed, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(BuildContext context, Map<String, dynamic> grocery) {
    final items = grocery['items'] as List<dynamic>? ?? [];
    final totalPrice = grocery['total_price']?.toString() ?? 'N/A';
    final status = grocery['status']?.toString() ?? 'Unknown';
    final trackingNumber = grocery['tracking_number']?.toString() ?? 'Unknown';
    final createdAt = grocery['created_at']?.toString() ?? 'N/A';
    final image = grocery['image']?.toString();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: image != null
                    ? Image.network(
                        image,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 150,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported, color: Colors.white, size: 50),
                        ),
                      )
                    : Container(
                        height: 150,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, color: Colors.white, size: 50),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order #$trackingNumber',
                          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: doorDashGrey),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Status',
                          style: GoogleFonts.poppins(fontSize: 14, color: doorDashGrey),
                        ),
                        Text(
                          status.capitalize(),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: status == 'completed' ? Colors.green[700] : Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Date',
                          style: GoogleFonts.poppins(fontSize: 14, color: doorDashGrey),
                        ),
                        Text(
                          createdAt.split('T')[0],
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Items (${items.length})',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    ...items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item['name']} (x${item['quantity']})',
                                  style: GoogleFonts.poppins(fontSize: 14, color: textColor),
                                ),
                              ),
                              Text(
                                '₦${item['price']}',
                                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: doorDashGrey),
                              ),
                            ],
                          ),
                        )),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
                        ),
                        Text(
                          '₦$totalPrice',
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: doorDashRed),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    final routes = {
      0: '/home',
      1: '/restaurants',
      2: '/groceries',
      3: '/orders',
      4: '/profile',
      5: '/restaurant-owner',
    };
    if (routes.containsKey(index)) {
      if (index == 2) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GroceryScreen()));
      } else {
        Navigator.pushReplacementNamed(context, routes[index]!);
      }
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}