import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../auth_provider.dart';
import '../main.dart' show textColor, accentColor;

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
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    if (widget.initialStatus != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
            backgroundColor: widget.initialStatus == 'completed' ? doorDashRed : Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      });
    }
  }

  Future<void> _fetchOrders() async {
    setState(() => isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final fetchedOrders = await auth.getOrders();
      if (mounted) {
        setState(() {
          orders = fetchedOrders;
          isLoading = false;
          if (widget.orderId != null) {
            final matchedOrder = orders.firstWhere(
              (order) => order['id'].toString() == widget.orderId,
              orElse: () => null,
            );
            if (matchedOrder != null) {
              print('Matched order: ${matchedOrder['id']}');
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.poppins(color: doorDashWhite)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Cancel Order', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)),
        content: Text('Are you sure you want to cancel this order?', style: GoogleFonts.poppins(color: doorDashGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No', style: GoogleFonts.poppins(color: doorDashRed)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Yes', style: GoogleFonts.poppins(color: doorDashWhite)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.cancelOrder(orderId);
      await _fetchOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order cancelled successfully', style: GoogleFonts.poppins(color: doorDashWhite)),
            backgroundColor: doorDashRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.poppins(color: doorDashWhite)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: doorDashLightGrey,
      appBar: AppBar(
        backgroundColor: doorDashRed,
        elevation: 0,
        title: Text(
          'My Orders',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: doorDashWhite,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: doorDashWhite, size: 20),
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
      ),
      body: SafeArea(
        child: isLoading
            ? Center(
                child: SpinKitPouringHourGlassRefined(color: doorDashRed, size: 60),
              )
            : orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fastfood, size: 100, color: doorDashGrey.withOpacity(0.3)),
                        const SizedBox(height: 20),
                        Text(
                          'No orders yet',
                          style: GoogleFonts.poppins(fontSize: 20, color: doorDashGrey),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Order some delicious food now!',
                          style: GoogleFonts.poppins(fontSize: 14, color: doorDashGrey.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchOrders,
                    color: doorDashRed,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        final isHighlighted = widget.orderId != null && order['id'].toString() == widget.orderId;
                        return _buildOrderCard(order, isHighlighted);
                      },
                    ),
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
        selectedItemColor: doorDashRed,
        unselectedItemColor: doorDashGrey.withOpacity(0.6),
        backgroundColor: doorDashWhite,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isLoading ? null : _fetchOrders,
        backgroundColor: doorDashRed,
        tooltip: 'Refresh Orders',
        child: const Icon(Icons.refresh, color: doorDashWhite),
      ),
    );
  }

  Widget _buildOrderCard(dynamic order, bool isHighlighted) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrackingScreen(trackingNumber: order['tracking_number'] ?? ''))),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: doorDashWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isHighlighted ? doorDashRed.withOpacity(0.3) : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.fastfood, size: 24, color: doorDashRed),
                      const SizedBox(width: 8),
                      Text(
                        'Order #${order['id']}',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order['status']),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      order['status'],
                      style: GoogleFonts.poppins(fontSize: 12, color: doorDashWhite, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: N${order['total'] ?? 'N/A'}',
                    style: GoogleFonts.poppins(fontSize: 16, color: textColor),
                  ),
                  Text(
                    'Items: ${order['items']?.length ?? 'N/A'}',
                    style: GoogleFonts.poppins(fontSize: 14, color: doorDashGrey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tracking: ${order['tracking_number'] ?? 'Pending'}',
                style: GoogleFonts.poppins(fontSize: 14, color: doorDashGrey),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (order['status'] == 'pending')
                    TextButton(
                      onPressed: () => _cancelOrder(order['id'].toString()),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.redAccent, fontWeight: FontWeight.w600),
                      ),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrackingScreen(trackingNumber: order['tracking_number'] ?? ''))),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: doorDashRed,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: Text(
                      'Track',
                      style: GoogleFonts.poppins(fontSize: 14, color: doorDashWhite, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
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

  @override
  void initState() {
    super.initState();
    if (widget.trackingNumber.isNotEmpty) _fetchTracking();
  }

  Future<void> _fetchTracking() async {
    setState(() => isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      trackingData = await auth.getOrderTracking(widget.trackingNumber);
      if (mounted) setState(() => isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.poppins(color: doorDashWhite)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        setState(() => isLoading = false);
      }
    }
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
          'Track Order #${widget.trackingNumber}',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: doorDashWhite,
          ),
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
      ),
      body: SafeArea(
        child: isLoading
            ? Center(
                child: SpinKitPouringHourGlassRefined(color: doorDashRed, size: 60),
              )
            : trackingData == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_shipping, size: 100, color: doorDashGrey.withOpacity(0.3)),
                        const SizedBox(height: 20),
                        Text(
                          'Tracking not available yet',
                          style: GoogleFonts.poppins(fontSize: 20, color: doorDashGrey),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Check back soon!',
                          style: GoogleFonts.poppins(fontSize: 14, color: doorDashGrey.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Tracking Details'),
                        const SizedBox(height: 16),
                        _buildTrackingTimeline(),
                        const SizedBox(height: 24),
                        Container(
                          height: 250,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: doorDashWhite,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(Icons.map, size: 80, color: doorDashGrey.withOpacity(0.3)),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Map Coming Soon',
                                    style: GoogleFonts.poppins(fontSize: 18, color: doorDashGrey),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Stay tuned for real-time tracking!',
                                    style: GoogleFonts.poppins(fontSize: 12, color: doorDashGrey.withOpacity(0.7)),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }

  Widget _buildTrackingTimeline() {
    final steps = [
      {'icon': Icons.local_shipping, 'title': 'Status', 'subtitle': trackingData!['status'], 'isActive': true},
      {
        'icon': Icons.location_on,
        'title': 'Location',
        'subtitle': 'Lat ${trackingData!['lat'] ?? 'N/A'}, Lon ${trackingData!['lon'] ?? 'N/A'}',
        'isActive': trackingData!['lat'] != null
      },
      {
        'icon': Icons.update,
        'title': 'Last Updated',
        'subtitle': trackingData!['updated_at'] ?? 'N/A',
        'isActive': trackingData!['updated_at'] != null
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: doorDashWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: steps.asMap().entries.map((entry) {
            final step = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: step['isActive'] ? doorDashRed.withOpacity(0.1) : doorDashGrey.withOpacity(0.1),
                      border: Border.all(color: step['isActive'] ? doorDashRed : doorDashGrey, width: 2),
                    ),
                    child: Icon(step['icon'], color: step['isActive'] ? doorDashRed : doorDashGrey, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['title'],
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step['subtitle'],
                          style: GoogleFonts.poppins(fontSize: 14, color: doorDashGrey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}