import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../services/api_service.dart';
import '../main.dart' show primaryColor, textColor, accentColor;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class LogisticsScreen extends StatefulWidget {
  const LogisticsScreen({super.key});

  @override
  State<LogisticsScreen> createState() => _LogisticsScreenState();
}

class _LogisticsScreenState extends State<LogisticsScreen>
    with SingleTickerProviderStateMixin {
  late final ApiService apiService;
  List<dynamic> orders = [];
  bool isLoadingOrders = true;
  bool isUpdatingLocation = false;
  int _selectedIndex = 5; // Default to Dasher tab (index 5)
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    final auth = Provider.of<AuthProvider>(context, listen: false);
    apiService = ApiService()..setToken(auth.token ?? '');
    _locationController.text = auth.deliveryLocation ?? '';
    _fetchOrders();
    _animationController.forward();
  }

  Future<void> _fetchOrders() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final allOrders = await apiService.getOrders();
      if (mounted) {
        setState(() {
          orders = allOrders
              .where((order) => order['status'] == 'in_transit')
              .take(10)
              .toList(); // Show only in-transit orders for dashers
          isLoadingOrders = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      String errorMessage;
      if (e.toString().contains('401') ||
          e.toString().contains('unauthorized')) {
        errorMessage = 'Authentication failed. Please log in again.';
      } else if (e.toString().contains('network') ||
          e.toString().contains('timeout')) {
        errorMessage =
            'Network error. Please check your connection and try again.';
      } else {
        errorMessage = 'Failed to load orders. Please try again later.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () =>
                  ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          ),
        );
        setState(() => isLoadingOrders = false);
      }
    }
  }

  Future<void> _updateLocation() async {
    if (_locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a location'),
            backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => isUpdatingLocation = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.name == null || auth.email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('User profile incomplete'),
              backgroundColor: Colors.red),
        );
        return;
      }
      await auth.updateProfile(auth.name!, auth.email!,
          deliveryLocation: _locationController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Delivery location updated'),
              backgroundColor: accentColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error updating location: $e',
                  style: GoogleFonts.poppins()),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isUpdatingLocation = false);
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    final routes = {
      0: '/home',
      1: '/restaurants',
      2: '/orders',
      3: '/profile',
      4: '/restaurant-owner',
      5: '/dashers',
      6: '/admin-login',
    };
    if (index != 5 && routes.containsKey(index)) {
      Navigator.pushReplacementNamed(context, routes[index]!);
    }
  }

  // Show Terms Popup
  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Terms of Service',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, fontSize: 20, color: textColor),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome to Can I Buy You A Meal Express! By using our services, you agree to the following terms:',
                style: GoogleFonts.poppins(fontSize: 16, color: textColor),
              ),
              const SizedBox(height: 12),
              Text(
                '1. **Usage**: You agree to use  Can I Buy You A Meal Express for lawful purposes only and in a way that does not infringe on the rights of others.',
                style: GoogleFonts.poppins(
                    fontSize: 14, color: textColor.withOpacity(0.8)),
              ),
              const SizedBox(height: 8),
              Text(
                '2. **Account Responsibility**: You are responsible for maintaining the confidentiality of your account and password.',
                style: GoogleFonts.poppins(
                    fontSize: 14, color: textColor.withOpacity(0.8)),
              ),
              const SizedBox(height: 8),
              Text(
                '3. **Service Availability**: We strive to ensure our services are available at all times, but we are not liable for any interruptions.',
                style: GoogleFonts.poppins(
                    fontSize: 14, color: textColor.withOpacity(0.8)),
              ),
              const SizedBox(height: 8),
              Text(
                'For the full Terms of Service, please visit our website or contact support.',
                style: GoogleFonts.poppins(
                    fontSize: 14, color: textColor.withOpacity(0.8)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close',
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // Show Privacy Popup
  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, fontSize: 20, color: textColor),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'At  Can I Buy You A Meal Express, we value your privacy. Here’s how we handle your information:',
                style: GoogleFonts.poppins(fontSize: 16, color: textColor),
              ),
              const SizedBox(height: 12),
              Text(
                '1. **Data Collection**: We collect information such as your name, email, and delivery location to provide our services.',
                style: GoogleFonts.poppins(
                    fontSize: 14, color: textColor.withOpacity(0.8)),
              ),
              const SizedBox(height: 8),
              Text(
                '2. **Data Usage**: Your information is used to process orders, improve our services, and communicate with you.',
                style: GoogleFonts.poppins(
                    fontSize: 14, color: textColor.withOpacity(0.8)),
              ),
              const SizedBox(height: 8),
              Text(
                '3. **Data Protection**: We implement security measures to protect your data, but no system is 100% secure.',
                style: GoogleFonts.poppins(
                    fontSize: 14, color: textColor.withOpacity(0.8)),
              ),
              const SizedBox(height: 8),
              Text(
                'For more details, please review our full Privacy Policy on our website.',
                style: GoogleFonts.poppins(
                    fontSize: 14, color: textColor.withOpacity(0.8)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close',
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // Show Customer Support Popup
  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Customer Support',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, fontSize: 20, color: textColor),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'We’re here to help you with any issues or questions!',
                style: GoogleFonts.poppins(fontSize: 16, color: textColor),
              ),
              const SizedBox(height: 12),
              Text(
                'Company: Cani Buy You a Meal',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Email: canibuyyouameal@gmail.com',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFFFF3008)), // DoorDash red
              ),
              const SizedBox(height: 12),
              Text(
                'Our support team is available 24/7 to assist with your orders, account issues, or any other inquiries. Feel free to reach out, and we’ll get back to you as soon as possible!',
                style: GoogleFonts.poppins(
                    fontSize: 14, color: textColor.withOpacity(0.8)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close',
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final userName = auth.name ?? 'Dasher';
    final userRole = auth.role ?? 'dasher';
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: Colors.white, // DoorDash uses a white background
          ),
          Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: isLargeScreen ? 200.0 : 180.0,
                      floating: false,
                      pinned: true,
                      backgroundColor: const Color(0xFFFF3008), // DoorDash red
                      flexibleSpace: FlexibleSpaceBar(
                        titlePadding:
                            const EdgeInsets.only(left: 16, bottom: 16),
                        title: Text(
                          'Hi, $userName!',
                          style: GoogleFonts.poppins(
                            fontSize: isLargeScreen ? 24 : 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        background: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 40.0),
                          child: TextField(
                            controller: _locationController,
                            decoration: InputDecoration(
                              hintText: 'Enter your current location...',
                              hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey[400], fontSize: 16),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.location_on,
                                  color: Colors.grey),
                              suffixIcon: IconButton(
                                icon:
                                    const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () => _locationController.clear(),
                              ),
                            ),
                            onSubmitted: (value) => _updateLocation(),
                          ),
                        ),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.person, color: Colors.white),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/profile'),
                        ),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Padding(
                          padding: EdgeInsets.all(isLargeScreen ? 20.0 : 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Order Status Categories
                              Text(
                                'Order Status',
                                style: GoogleFonts.poppins(
                                    fontSize: isLargeScreen ? 22 : 20,
                                    fontWeight: FontWeight.bold,
                                    color: textColor),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: isLargeScreen ? 120 : 100,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    _buildStatusCard(
                                        'In Transit',
                                        Icons.local_shipping,
                                        Colors.blue,
                                        isLargeScreen),
                                    _buildStatusCard(
                                        'Delivered',
                                        Icons.check_circle,
                                        Colors.green,
                                        isLargeScreen),
                                    _buildStatusCard(
                                        'Pending',
                                        Icons.hourglass_empty,
                                        Colors.orange,
                                        isLargeScreen),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Active Deliveries
                              Text(
                                'Active Deliveries',
                                style: GoogleFonts.poppins(
                                    fontSize: isLargeScreen ? 22 : 20,
                                    fontWeight: FontWeight.bold,
                                    color: textColor),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: isLargeScreen ? 250 : 220,
                                child: isLoadingOrders
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Color(0xFFFF3008))))
                                    : orders.isEmpty
                                        ? Center(
                                            child: Text('No active deliveries',
                                                style: GoogleFonts.poppins(
                                                    color: textColor
                                                        .withOpacity(0.7))))
                                        : ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: orders.length,
                                            itemBuilder: (context, index) =>
                                                _buildOrderCard(orders[index],
                                                    isLargeScreen),
                                          ),
                              ),
                              const SizedBox(height: 24),

                              // Quick Actions for Dashers
                              Text(
                                'Quick Actions',
                                style: GoogleFonts.poppins(
                                    fontSize: isLargeScreen ? 22 : 20,
                                    fontWeight: FontWeight.bold,
                                    color: textColor),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: isLargeScreen ? 16 : 12,
                                runSpacing: isLargeScreen ? 16 : 12,
                                alignment: WrapAlignment.center,
                                children: [
                                  _buildActionButton(
                                      context,
                                      'Update Location',
                                      Icons.location_on,
                                      _updateLocation,
                                      isLargeScreen),
                                  _buildActionButton(
                                      context,
                                      'View All Orders',
                                      Icons.list,
                                      () => Navigator.pushNamed(
                                          context, '/orders'),
                                      isLargeScreen),
                                  _buildActionButton(
                                      context,
                                      'Contact Support',
                                      Icons.support_agent,
                                      _showSupportDialog,
                                      isLargeScreen),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  vertical: screenWidth > 600 ? 20.0 : 12.0,
                  horizontal: screenWidth > 600 ? 32.0 : 16.0,
                ),
                color: Colors.white,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: screenWidth > 600
                      ? 40
                      : screenWidth > 400
                          ? 20
                          : 10,
                  runSpacing: 10,
                  children: [
                    GestureDetector(
                      onTap: _showTermsDialog,
                      child: Text(
                        'Terms',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: screenWidth > 600
                              ? 16
                              : screenWidth > 400
                                  ? 14
                                  : 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _showPrivacyDialog,
                      child: Text(
                        'Privacy',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: screenWidth > 600
                              ? 16
                              : screenWidth > 400
                                  ? 14
                                  : 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.restaurant), label: 'Restaurants'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Owner'),
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_bike), label: 'Dasher'),
          BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFFF3008),
        unselectedItemColor: textColor.withOpacity(0.6),
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        backgroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchOrders,
        backgroundColor: const Color(0xFFFF3008),
        tooltip: 'Refresh Orders',
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildStatusCard(
      String status, IconData icon, Color iconColor, bool isLargeScreen) {
    return GestureDetector(
      onTap: () {
        // Placeholder for filtering orders by status
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Filtering by $status coming soon!')),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: isLargeScreen ? 100 : 80,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(icon, size: isLargeScreen ? 40 : 32, color: iconColor),
            ),
            const SizedBox(height: 8),
            Text(
              status,
              style: GoogleFonts.poppins(
                  fontSize: isLargeScreen ? 14 : 12,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(dynamic order, bool isLargeScreen) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/orders',
        arguments: {
          'orderId': order['id'].toString(),
          'status': order['status']
        },
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 16),
        width: isLargeScreen ? 200 : 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: isLargeScreen ? 140 : 120,
                width: double.infinity,
                color: Colors.grey[200],
                child: const Icon(Icons.fastfood, size: 60, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order['id']}',
                    style: GoogleFonts.poppins(
                        fontSize: isLargeScreen ? 18 : 16,
                        fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Status: ${order['status']}',
                    style: GoogleFonts.poppins(
                        fontSize: isLargeScreen ? 14 : 12,
                        color: textColor.withOpacity(0.6)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Address: ${order['address'] ?? 'Unknown'}',
                    style: GoogleFonts.poppins(
                        fontSize: isLargeScreen ? 14 : 12,
                        color: textColor.withOpacity(0.6)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon,
      VoidCallback onPressed, bool isLargeScreen) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF3008),
        padding: EdgeInsets.symmetric(
            vertical: isLargeScreen ? 16 : 12,
            horizontal: isLargeScreen ? 24 : 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isLargeScreen ? 24 : 20, color: Colors.white),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: isLargeScreen ? 16 : 14, color: Colors.white)),
        ],
      ),
    );
  }
}
