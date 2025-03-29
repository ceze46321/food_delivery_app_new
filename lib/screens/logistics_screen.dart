import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../services/api_service.dart';
import '../main.dart' show primaryColor, textColor, accentColor;

class LogisticsScreen extends StatefulWidget {
  const LogisticsScreen({super.key});

  @override
  State<LogisticsScreen> createState() => _LogisticsScreenState();
}

class _LogisticsScreenState extends State<LogisticsScreen> {
  late final ApiService apiService;
  final TextEditingController _locationController = TextEditingController();
  List<dynamic> orders = [];
  bool isLoading = true;
  bool isUpdatingLocation = false;
  int _selectedIndex = 2; // Default to Orders tab (index 2)

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    apiService = ApiService()..setToken(auth.token ?? '');
    _locationController.text = auth.deliveryLocation ?? ''; // Pre-fill with existing delivery location
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final allOrders = await apiService.getOrders();
      if (mounted) {
        setState(() {
          final userRole = auth.role ?? 'customer';
          if (userRole == 'merchant' || userRole == 'owner') {
            orders = allOrders.where((order) => order['restaurant_id'] != null).toList(); // Merchant/owner orders
          } else if (userRole == 'dasher') {
            orders = allOrders.where((order) => order['status'] == 'in_transit').toList(); // Dasher deliveries
          } else {
            orders = allOrders; // Customer orders
          }
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching orders: $e'), backgroundColor: Colors.red));
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _updateLocation() async {
    if (_locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a location'), backgroundColor: Colors.red));
      return;
    }
    setState(() => isUpdatingLocation = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.updateProfile(auth.name!, auth.email!, deliveryLocation: _locationController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delivery location updated'), backgroundColor: accentColor));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating location: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => isUpdatingLocation = false);
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/restaurants');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/orders');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/restaurant-owner');
        break;
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final userRole = auth.role ?? 'customer';

    return Scaffold(
      appBar: AppBar(
        title: Text('Logistics', style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: isLoading ? null : _fetchOrders,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Delivery Location Section
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery Location ($userRole)',
                            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _locationController,
                            decoration: InputDecoration(
                              labelText: 'Enter your delivery address',
                              labelStyle: GoogleFonts.poppins(color: textColor.withOpacity(0.7)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.location_on, color: primaryColor),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isUpdatingLocation ? null : _updateLocation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: isUpdatingLocation
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text('Save Location', style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Orders Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Orders',
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      Text(
                        '${orders.length} item${orders.length == 1 ? '' : 's'}',
                        style: GoogleFonts.poppins(fontSize: 14, color: textColor.withOpacity(0.7)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: orders.isEmpty
                        ? Center(child: Text('No orders yet', style: GoogleFonts.poppins(color: textColor.withOpacity(0.7))))
                        : ListView.builder(
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  title: Text('Order #${order['id']}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Total: \$${order['total'] ?? 'N/A'}', style: GoogleFonts.poppins()),
                                      Text('Status: ${order['status']}', style: GoogleFonts.poppins(color: textColor.withOpacity(0.7))),
                                      Text('Address: ${order['address'] ?? 'Unknown'}', style: GoogleFonts.poppins(color: textColor.withOpacity(0.7))),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Restaurants'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Owner'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor: textColor.withOpacity(0.6),
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}