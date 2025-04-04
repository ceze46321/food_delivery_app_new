import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../auth_provider.dart';
import '../main.dart' show textColor, accentColor;
import 'package:flutter_animate/flutter_animate.dart';

class OrderScreen extends StatefulWidget {
  final String? orderId;
  final String? initialStatus;

  const OrderScreen({super.key, this.orderId, this.initialStatus});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  static const Color doorDashRed = Color(0xFFEF2A39);
  static const Color doorDashGrey = Color(0xFF757575);
  static const Color doorDashLightGrey = Color(0xFFF5F5F5);
  static const Color doorDashWhite = Colors.white;

  List<dynamic> orders = [];
  bool isLoading = true;
  String? _errorMessage;
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    if (widget.initialStatus != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.initialStatus == 'completed'
                    ? 'Payment successful! Your order is on the way!'
                    : widget.initialStatus == 'cancelled'
                        ? 'Payment cancelled. Try again?'
                        : 'Payment failed. Please retry.',
                style: GoogleFonts.poppins(color: doorDashWhite),
              ),
              backgroundColor: widget.initialStatus == 'completed'
                  ? doorDashRed
                  : Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    }
  }

  Future<void> _fetchOrders() async {
    setState(() {
      isLoading = true;
      _errorMessage = null;
    });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (!auth.isLoggedIn) {
        throw Exception('Not authenticated. Please log in.');
      }
      final fetchedOrders = await auth.getOrders();
      if (mounted) {
        setState(() {
          orders = fetchedOrders ?? [];
          isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching orders: $e\n$stackTrace');
      String message;
      if (e.toString().contains('401') ||
          e.toString().contains('unauthorized')) {
        message = 'Authentication failed. Please log in again.';
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else if (e.toString().contains('network') ||
          e.toString().contains('timeout')) {
        message = 'Network error. Please check your connection and try again.';
      } else if (e.toString().contains('404')) {
        message = 'Orders not found. Start by placing an order!';
      } else if (e.toString().contains('503')) {
        message = 'Service temporarily unavailable. Please try again later.';
      } else {
        message = 'Failed to load orders: $e';
      }
      if (mounted) setState(() => _errorMessage = message);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Cancel Order',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: textColor)),
        content: Text('Are you sure you want to cancel this order?',
            style: GoogleFonts.poppins(color: doorDashGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No', style: GoogleFonts.poppins(color: doorDashGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child:
                Text('Yes', style: GoogleFonts.poppins(color: doorDashWhite)),
          ),
        ],
      ).animate().scale(duration: 200.ms),
    );
    if (confirm != true) return;

    setState(() => isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.cancelOrder(orderId);
      await _fetchOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order cancelled successfully',
                style: GoogleFonts.poppins(color: doorDashWhite)),
            backgroundColor: doorDashRed,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error cancelling order: $e\n$stackTrace');
      String message;
      if (e.toString().contains('401') ||
          e.toString().contains('unauthorized')) {
        message = 'Authentication failed. Please log in again.';
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else if (e.toString().contains('network') ||
          e.toString().contains('timeout')) {
        message = 'Network error. Please check your connection and try again.';
      } else if (e.toString().contains('404')) {
        message = 'Order not found. It may have been removed.';
      } else if (e.toString().contains('403')) {
        message = 'You are not authorized to cancel this order.';
      } else if (e.toString().contains('503')) {
        message = 'Service temporarily unavailable. Please try again later.';
      } else {
        message = 'Failed to cancel order: $e';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(message, style: GoogleFonts.poppins(color: doorDashWhite)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _onItemTapped(int index) {
    try {
      setState(() => _selectedIndex = index);
      final routes = {
        0: '/home',
        1: '/restaurants',
        2: null, // Current screen
        3: '/orders',
        4: '/profile',
        5: '/restaurant-owner',
      };
      if (index != 2 && routes.containsKey(index) && routes[index] != null) {
        Navigator.pushReplacementNamed(context, routes[index]!);
      }
    } catch (e, stackTrace) {
      debugPrint('Navigation error: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to navigate. Please try again.',
                style: GoogleFonts.poppins(color: doorDashWhite)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom +
        80.0; // Adjust for BottomNavigationBar

    return Scaffold(
      backgroundColor: doorDashLightGrey,
      appBar: AppBar(
        backgroundColor: doorDashRed,
        elevation: 0,
        title: Text(
          'My Orders',
          style: GoogleFonts.poppins(
              fontSize: screenWidth > 600 ? 24 : 22,
              fontWeight: FontWeight.w600,
              color: doorDashWhite),
        ),
        centerTitle: true,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios, color: doorDashWhite, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
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
            onPressed: isLoading ? null : _fetchOrders,
            tooltip: 'Refresh Orders',
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? Center(
                child: SpinKitFadingCircle(
                        color: doorDashRed, size: screenWidth > 600 ? 60 : 50)
                    .animate()
                    .fadeIn())
            : RefreshIndicator(
                onRefresh: _fetchOrders,
                color: doorDashRed,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: screenWidth > 600 ? 24 : 16,
                      right: screenWidth > 600 ? 24 : 16,
                      top: 20,
                      bottom: bottomPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Orders',
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth > 600 ? 28 : 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_errorMessage != null)
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline,
                                    size: 60, color: doorDashRed),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage!,
                                  style: GoogleFonts.poppins(
                                      fontSize: screenWidth > 600 ? 18 : 16,
                                      color: doorDashGrey),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _fetchOrders,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: doorDashRed,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                  ),
                                  child: Text(
                                    'Retry',
                                    style: GoogleFonts.poppins(
                                        fontSize: screenWidth > 600 ? 16 : 14,
                                        color: doorDashWhite),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (orders.isEmpty)
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.fastfood,
                                    size: 80, color: doorDashGrey),
                                const SizedBox(height: 16),
                                Text(
                                  'No Orders Yet',
                                  style: GoogleFonts.poppins(
                                      fontSize: screenWidth > 600 ? 20 : 18,
                                      fontWeight: FontWeight.w500,
                                      color: doorDashGrey),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Order some delicious food now!',
                                  style: GoogleFonts.poppins(
                                      fontSize: screenWidth > 600 ? 16 : 14,
                                      color: doorDashGrey),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pushReplacementNamed(
                                          context, '/restaurants'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: doorDashRed,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                  ),
                                  child: Text(
                                    'Browse Restaurants',
                                    style: GoogleFonts.poppins(
                                        fontSize: screenWidth > 600 ? 16 : 14,
                                        color: doorDashWhite),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              final isHighlighted = widget.orderId != null &&
                                  order['id']?.toString() == widget.orderId;
                              return _buildOrderCard(order, isHighlighted)
                                  .animate()
                                  .fadeIn(
                                      duration: 300.ms,
                                      delay: (index * 100).ms);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.restaurant), label: 'Restaurants'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_grocery_store), label: 'Groceries'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Owner'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: doorDashRed,
        unselectedItemColor: doorDashGrey.withOpacity(0.6),
        backgroundColor: doorDashWhite,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.poppins(
            fontSize: screenWidth > 600 ? 14 : 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            GoogleFonts.poppins(fontSize: screenWidth > 600 ? 14 : 12),
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildOrderCard(dynamic order, bool isHighlighted) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isHighlighted
            ? const BorderSide(color: doorDashRed, width: 2)
            : BorderSide.none,
      ),
      color: doorDashWhite,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: EdgeInsets.all(screenWidth > 600 ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.fastfood, size: 24, color: doorDashRed),
                    const SizedBox(width: 8),
                    Text(
                      'Order #${order['id']?.toString() ?? 'N/A'}',
                      style: GoogleFonts.poppins(
                          fontSize: screenWidth > 600 ? 20 : 18,
                          fontWeight: FontWeight.bold,
                          color: textColor),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                        order['status']?.toString() ?? 'unknown'),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    order['status']?.toString().capitalize() ?? 'Unknown',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: doorDashWhite,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ${order['total']?.toString() ?? 'N/A'} Naira',
                  style: GoogleFonts.poppins(
                      fontSize: screenWidth > 600 ? 18 : 16, color: textColor),
                ),
                Text(
                  'Items: ${order['items']?.length?.toString() ?? 'N/A'}',
                  style: GoogleFonts.poppins(
                      fontSize: screenWidth > 600 ? 16 : 14,
                      color: doorDashGrey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tracking: ${order['tracking_number']?.toString() ?? 'Pending'}',
              style: GoogleFonts.poppins(
                  fontSize: screenWidth > 600 ? 16 : 14, color: doorDashGrey),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (order['status']?.toString().toLowerCase() == 'pending')
                  TextButton(
                    onPressed: () =>
                        _cancelOrder(order['id']?.toString() ?? ''),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    try {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TrackingScreen(
                            trackingNumber:
                                order['tracking_number']?.toString() ?? '',
                          ),
                        ),
                      );
                    } catch (e, stackTrace) {
                      debugPrint(
                          'Navigation error to TrackingScreen: $e\n$stackTrace');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to open tracking. Please try again.',
                            style: GoogleFonts.poppins(color: doorDashWhite),
                          ),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: doorDashRed,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(
                        horizontal: screenWidth > 600 ? 20 : 16, vertical: 10),
                  ),
                  child: Text(
                    'Track',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: doorDashWhite,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_transit':
        return Colors.blueAccent;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return doorDashGrey;
    }
  }
}

class TrackingScreen extends StatefulWidget {
  final String trackingNumber;
  const TrackingScreen({super.key, required this.trackingNumber});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  static const Color doorDashRed = Color(0xFFEF2A39);
  static const Color doorDashGrey = Color(0xFF757575);
  static const Color doorDashLightGrey = Color(0xFFF5F5F5);
  static const Color doorDashWhite = Colors.white;

  Map<String, dynamic>? trackingData;
  bool isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.trackingNumber.isNotEmpty) {
      _fetchTracking();
    } else {
      setState(() {
        isLoading = false;
        trackingData = null;
        _errorMessage = 'No tracking number provided.';
      });
    }
  }

  Future<void> _fetchTracking() async {
    setState(() {
      isLoading = true;
      _errorMessage = null;
    });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (!auth.isLoggedIn) {
        throw Exception('Not authenticated. Please log in.');
      }
      final data = await auth.getOrderTracking(widget.trackingNumber);
      if (mounted) {
        setState(() {
          trackingData = data;
          isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching tracking data: $e\n$stackTrace');
      String message;
      if (e.toString().contains('401') ||
          e.toString().contains('unauthorized')) {
        message = 'Authentication failed. Please log in again.';
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else if (e.toString().contains('network') ||
          e.toString().contains('timeout')) {
        message = 'Network error. Please check your connection and try again.';
      } else if (e.toString().contains('404')) {
        message = 'Tracking information not found for this order.';
      } else if (e.toString().contains('503')) {
        message = 'Service temporarily unavailable. Please try again later.';
      } else {
        message = 'Failed to load tracking data: $e';
      }
      if (mounted) setState(() => _errorMessage = message);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 20.0;

    return Scaffold(
      backgroundColor: doorDashLightGrey,
      appBar: AppBar(
        backgroundColor: doorDashRed,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios, color: doorDashWhite, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Track Order #${widget.trackingNumber.isNotEmpty ? widget.trackingNumber : 'N/A'}',
          style: GoogleFonts.poppins(
              fontSize: screenWidth > 600 ? 24 : 22,
              fontWeight: FontWeight.w600,
              color: doorDashWhite),
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
          IconButton(
            icon: const Icon(Icons.refresh, color: doorDashWhite),
            onPressed: isLoading ? null : _fetchTracking,
            tooltip: 'Refresh Tracking',
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? Center(
                child: SpinKitFadingCircle(
                        color: doorDashRed, size: screenWidth > 600 ? 60 : 50)
                    .animate()
                    .fadeIn())
            : RefreshIndicator(
                onRefresh: _fetchTracking,
                color: doorDashRed,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: screenWidth > 600 ? 24 : 16,
                    right: screenWidth > 600 ? 24 : 16,
                    top: 20,
                    bottom: bottomPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tracking Details',
                        style: GoogleFonts.poppins(
                            fontSize: screenWidth > 600 ? 28 : 24,
                            fontWeight: FontWeight.bold,
                            color: textColor),
                      ),
                      const SizedBox(height: 20),
                      if (_errorMessage != null)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 60, color: doorDashRed),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: GoogleFonts.poppins(
                                    fontSize: screenWidth > 600 ? 18 : 16,
                                    color: doorDashGrey),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _fetchTracking,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: doorDashRed,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                ),
                                child: Text(
                                  'Retry',
                                  style: GoogleFonts.poppins(
                                      fontSize: screenWidth > 600 ? 16 : 14,
                                      color: doorDashWhite),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (trackingData == null)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.local_shipping,
                                  size: 80, color: doorDashGrey),
                              const SizedBox(height: 16),
                              Text(
                                'Tracking Not Available Yet',
                                style: GoogleFonts.poppins(
                                    fontSize: screenWidth > 600 ? 20 : 18,
                                    fontWeight: FontWeight.w500,
                                    color: doorDashGrey),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your order is being prepared. Check back soon!',
                                style: GoogleFonts.poppins(
                                    fontSize: screenWidth > 600 ? 16 : 14,
                                    color: doorDashGrey),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: doorDashRed, width: 2),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                ),
                                child: Text(
                                  'Back to Orders',
                                  style: GoogleFonts.poppins(
                                      fontSize: screenWidth > 600 ? 16 : 14,
                                      color: doorDashRed),
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        _buildTrackingTimeline()
                            .animate()
                            .fadeIn(duration: 300.ms),
                        const SizedBox(height: 24),
                        Container(
                          height: screenWidth > 600 ? 300 : 250,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: doorDashWhite,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Opacity(
                                opacity: 0.1,
                                child: Icon(Icons.map,
                                    size: screenWidth > 600 ? 120 : 100,
                                    color: doorDashRed),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Live Map Coming Soon',
                                    style: GoogleFonts.poppins(
                                        fontSize: screenWidth > 600 ? 20 : 18,
                                        fontWeight: FontWeight.w600,
                                        color: textColor),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Stay tuned for real-time tracking!',
                                    style: GoogleFonts.poppins(
                                        fontSize: screenWidth > 600 ? 16 : 14,
                                        color: doorDashGrey),
                                  ),
                                  const SizedBox(height: 16),
                                  OutlinedButton(
                                    onPressed: _fetchTracking,
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                          color: doorDashRed, width: 2),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                    ),
                                    child: Text(
                                      'Refresh Status',
                                      style: GoogleFonts.poppins(
                                          fontSize: screenWidth > 600 ? 14 : 12,
                                          color: doorDashRed),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ).animate().scale(duration: 300.ms),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTrackingTimeline() {
    final screenWidth = MediaQuery.of(context).size.width;
    final steps = [
      {
        'icon': Icons.local_shipping,
        'title': 'Status',
        'subtitle': trackingData!['status']?.toString().capitalize() ?? 'N/A',
        'isActive': trackingData!['status'] != null
      },
      {
        'icon': Icons.location_on,
        'title': 'Location',
        'subtitle':
            'Lat ${trackingData!['lat']?.toString() ?? 'N/A'}, Lon ${trackingData!['lon']?.toString() ?? 'N/A'}',
        'isActive': trackingData!['lat'] != null && trackingData!['lon'] != null
      },
      {
        'icon': Icons.update,
        'title': 'Last Updated',
        'subtitle': trackingData!['updated_at']?.toString() ?? 'N/A',
        'isActive': trackingData!['updated_at'] != null
      },
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: doorDashWhite,
      child: Padding(
        padding: EdgeInsets.all(screenWidth > 600 ? 20 : 16),
        child: Column(
          children: steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final bool isActive = step['isActive'] as bool? ?? false;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? doorDashRed.withOpacity(0.1)
                            : doorDashGrey.withOpacity(0.1),
                        border: Border.all(
                            color: isActive ? doorDashRed : doorDashGrey,
                            width: 2),
                      ),
                      child: Icon(step['icon'] as IconData?,
                          color: isActive ? doorDashRed : doorDashGrey,
                          size: 24),
                    ),
                    if (index < steps.length - 1)
                      Container(
                        width: 2,
                        height: 40,
                        color: isActive ? doorDashRed : doorDashGrey,
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['title']?.toString() ?? 'N/A',
                        style: GoogleFonts.poppins(
                            fontSize: screenWidth > 600 ? 18 : 16,
                            fontWeight: FontWeight.w600,
                            color: textColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step['subtitle']?.toString() ?? 'N/A',
                        style: GoogleFonts.poppins(
                            fontSize: screenWidth > 600 ? 16 : 14,
                            color: doorDashGrey),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() =>
      "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
}
