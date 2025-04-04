import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../auth_provider.dart';
import '../main.dart' show textColor;
import 'package:flutter_animate/flutter_animate.dart';
import 'restaurant_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _deliveryLocationController = TextEditingController();
  String? _selectedRole;
  bool _isLoading = false;
  String? _errorMessage;
  int _selectedIndex = 4;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  static const Color doorDashRed = Color(0xFFEF2A39);
  static const Color doorDashGrey = Color(0xFF757575);
  static const Color doorDashLightGrey = Color(0xFFF5F5F5);
  static const Color doorDashWhite = Colors.white;

  static const List<String> _roleOptions = [
    'customer',
    'dasher',
    'restaurant_owner'
  ];

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _nameController.text = auth.name ?? '';
    _emailController.text = auth.email ?? '';
    _phoneController.text = auth.phone ?? '';
    _vehicleController.text = auth.vehicle ?? '';
    _deliveryLocationController.text = auth.deliveryLocation ?? '';
    _selectedRole = auth.role ?? 'customer';
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _getProfile(); // Fetch profile on init
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _vehicleController.dispose();
    _deliveryLocationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _getProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isLoggedIn) {
        throw Exception('Not authenticated. Please log in.');
      }
      debugPrint('Fetching profile with token: ${authProvider.token}');
      await authProvider.getProfile();
      if (mounted) {
        setState(() {
          _nameController.text = authProvider.name ?? '';
          _emailController.text = authProvider.email ?? '';
          _phoneController.text = authProvider.phone ?? '';
          _vehicleController.text = authProvider.vehicle ?? '';
          _deliveryLocationController.text =
              authProvider.deliveryLocation ?? '';
          _selectedRole = authProvider.role ?? 'customer';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile refreshed successfully',
                style: GoogleFonts.poppins(color: doorDashWhite)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching profile: $e\n$stackTrace');
      String errorMessage;
      if (e.toString().contains('401') ||
          e.toString().contains('unauthorized') ||
          e.toString().contains('Session expired')) {
        errorMessage = 'Authentication failed. Please log in again.';
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else if (e.toString().contains('network') ||
          e.toString().contains('timeout')) {
        errorMessage =
            'Network error. Please check your connection and try again.';
      } else {
        errorMessage = 'Failed to load profile: $e';
      }
      if (mounted) setState(() => _errorMessage = errorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Name and email are required',
              style: GoogleFonts.poppins(color: doorDashWhite)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.updateProfile(
        _nameController.text,
        _emailController.text,
        role: _selectedRole,
        phone: _phoneController.text,
        vehicle: _vehicleController.text,
        deliveryLocation: _deliveryLocationController.text,
      );
      if (mounted) {
        setState(() {
          _nameController.text = authProvider.name ?? '';
          _emailController.text = authProvider.email ?? '';
          _phoneController.text = authProvider.phone ?? '';
          _vehicleController.text = authProvider.vehicle ?? '';
          _deliveryLocationController.text =
              authProvider.deliveryLocation ?? '';
          _selectedRole = authProvider.role ?? 'customer';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully',
                style: GoogleFonts.poppins(color: doorDashWhite)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error updating profile: $e\n$stackTrace');
      String errorMessage;
      if (e.toString().contains('401') ||
          e.toString().contains('unauthorized')) {
        errorMessage = 'Authentication failed. Please log in again.';
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else if (e.toString().contains('network') ||
          e.toString().contains('timeout')) {
        errorMessage =
            'Network error. Please check your connection and try again.';
      } else {
        errorMessage = 'Failed to update profile: $e';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage,
                style: GoogleFonts.poppins(color: doorDashWhite)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Confirm Logout',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: textColor)),
        content: Text('Are you sure you want to log out?',
            style: GoogleFonts.poppins(color: doorDashGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('Cancel', style: GoogleFonts.poppins(color: doorDashGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: doorDashRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Logout',
                style: GoogleFonts.poppins(color: doorDashWhite)),
          ),
        ],
      ).animate().scale(duration: 200.ms),
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged out successfully',
                style: GoogleFonts.poppins(color: doorDashWhite)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error logging out: $e\n$stackTrace');
      String errorMessage;
      if (e.toString().contains('401') ||
          e.toString().contains('unauthorized')) {
        errorMessage = 'Authentication error during logout. Please try again.';
      } else if (e.toString().contains('network') ||
          e.toString().contains('timeout')) {
        errorMessage =
            'Network error. Please check your connection and try again.';
      } else {
        errorMessage = 'Failed to log out: $e';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage,
                style: GoogleFonts.poppins(color: doorDashWhite)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    if (index != 4 && routes.containsKey(index)) {
      if (index == 1) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const RestaurantScreen()));
      } else {
        Navigator.pushReplacementNamed(context, routes[index]!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: doorDashLightGrey,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
              fontSize: screenWidth > 600 ? 22 : 20,
              fontWeight: FontWeight.w600,
              color: doorDashWhite),
        ),
        backgroundColor: doorDashRed,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [doorDashRed, doorDashRed.withOpacity(0.8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: doorDashWhite),
            onPressed: _isLoading ? null : _getProfile,
            tooltip: 'Refresh Profile',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: SpinKitFadingCircle(
                      color: doorDashRed, size: screenWidth > 600 ? 60 : 50)
                  .animate()
                  .fadeIn())
          : RefreshIndicator(
              onRefresh: _getProfile,
              color: doorDashRed,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(screenWidth > 600 ? 24 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: screenWidth > 600 ? 60 : 50,
                            backgroundColor: doorDashRed.withOpacity(0.1),
                            child: Text(
                              auth.name?.substring(0, 1).toUpperCase() ?? 'U',
                              style: GoogleFonts.poppins(
                                fontSize: screenWidth > 600 ? 40 : 36,
                                color: doorDashRed,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            auth.name ?? 'User',
                            style: GoogleFonts.poppins(
                              fontSize: screenWidth > 600 ? 28 : 24,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          Text(
                            _selectedRole?.capitalize() ?? 'Customer',
                            style: GoogleFonts.poppins(
                                fontSize: screenWidth > 600 ? 18 : 16,
                                color: doorDashGrey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (_errorMessage != null)
                      Center(
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline,
                                size: 60, color: doorDashRed),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: doorDashRed,
                                  fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    // Profile Form
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: doorDashWhite,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Name',
                              labelStyle: GoogleFonts.poppins(
                                  color: doorDashGrey, fontSize: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: doorDashRed, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            style: GoogleFonts.poppins(color: textColor),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: GoogleFonts.poppins(
                                  color: doorDashGrey, fontSize: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: doorDashRed, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            style: GoogleFonts.poppins(color: textColor),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: 'Phone',
                              labelStyle: GoogleFonts.poppins(
                                  color: doorDashGrey, fontSize: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: doorDashRed, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            style: GoogleFonts.poppins(color: textColor),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _vehicleController,
                            decoration: InputDecoration(
                              labelText: 'Vehicle (Optional)',
                              labelStyle: GoogleFonts.poppins(
                                  color: doorDashGrey, fontSize: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: doorDashRed, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            style: GoogleFonts.poppins(color: textColor),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _deliveryLocationController,
                            decoration: InputDecoration(
                              labelText: 'Delivery Location (Optional)',
                              labelStyle: GoogleFonts.poppins(
                                  color: doorDashGrey, fontSize: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: doorDashRed, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            style: GoogleFonts.poppins(color: textColor),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedRole,
                            decoration: InputDecoration(
                              labelText: 'Role',
                              labelStyle: GoogleFonts.poppins(
                                  color: doorDashGrey, fontSize: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: doorDashRed, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: _roleOptions.map((String role) {
                              return DropdownMenuItem<String>(
                                value: role,
                                child: Text(role.capitalize(),
                                    style:
                                        GoogleFonts.poppins(color: textColor)),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedRole = newValue;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Update Profile Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: doorDashRed,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Update Profile',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: doorDashWhite,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _logout,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: doorDashRed, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Logout',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: doorDashRed,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.restaurant), label: 'Restaurants'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_grocery_store), label: 'Groceries'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: doorDashRed,
        unselectedItemColor: doorDashGrey,
        onTap: _onItemTapped,
        backgroundColor: doorDashWhite,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
