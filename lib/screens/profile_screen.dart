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

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(); // Added phone controller
  final _vehicleController = TextEditingController(); // Added vehicle controller
  final _deliveryLocationController = TextEditingController(); // Added delivery location controller
  String? _selectedRole;
  bool _isLoading = false;
  int _selectedIndex = 4;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  static const Color doorDashRed = Color(0xFFEF2A39);
  static const Color doorDashGrey = Color(0xFF757575);
  static const Color doorDashLightGrey = Color(0xFFF5F5F5);

  static const List<String> _roleOptions = ['customer', 'dasher', 'restaurant_owner'];

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _nameController.text = auth.name ?? '';
    _emailController.text = auth.email ?? '';
    _phoneController.text = auth.phone ?? ''; // Initialize phone
    _vehicleController.text = auth.vehicle ?? ''; // Initialize vehicle
    _deliveryLocationController.text = auth.deliveryLocation ?? ''; // Initialize delivery location
    _selectedRole = auth.role ?? 'customer';
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose(); // Dispose phone controller
    _vehicleController.dispose(); // Dispose vehicle controller
    _deliveryLocationController.dispose(); // Dispose delivery location controller
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _getProfile() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.getProfile();
      if (mounted) {
        _nameController.text = authProvider.name ?? '';
        _emailController.text = authProvider.email ?? '';
        _phoneController.text = authProvider.phone ?? ''; // Update phone
        _vehicleController.text = authProvider.vehicle ?? ''; // Update vehicle
        _deliveryLocationController.text = authProvider.deliveryLocation ?? ''; // Update delivery location
        _selectedRole = authProvider.role ?? 'customer';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile refreshed!', style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: doorDashRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.poppins()), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Name and email required', style: GoogleFonts.poppins()), backgroundColor: Colors.redAccent),
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
        phone: _phoneController.text, // Pass phone
        vehicle: _vehicleController.text, // Pass vehicle
        deliveryLocation: _deliveryLocationController.text, // Pass delivery location
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated!', style: GoogleFonts.poppins(color: Colors.white)), backgroundColor: doorDashRed),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.poppins()), backgroundColor: Colors.redAccent),
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
        title: Text('Confirm Logout', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: textColor)),
        content: Text('Are you sure you want to log out?', style: GoogleFonts.poppins(color: doorDashGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: doorDashGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: doorDashRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Logout', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (mounted) Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.poppins()), backgroundColor: Colors.redAccent),
        );
        setState(() => _isLoading = false);
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
    if (index != 4 && routes.containsKey(index)) {
      if (index == 1) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RestaurantScreen()));
      } else {
        Navigator.pushReplacementNamed(context, routes[index]!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: doorDashLightGrey,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: doorDashRed,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _getProfile,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: SpinKitFadingCircle(color: doorDashRed, size: 50))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: doorDashRed.withOpacity(0.1),
                          child: Text(
                            auth.name?.substring(0, 1).toUpperCase() ?? 'U',
                            style: GoogleFonts.poppins(fontSize: 36, color: doorDashRed, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          auth.name ?? 'User',
                          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600, color: textColor),
                        ),
                        Text(
                          _selectedRole ?? 'customer',
                          style: GoogleFonts.poppins(fontSize: 16, color: doorDashGrey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Details',
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _nameController,
                              label: 'Name',
                              icon: Icons.person,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.email,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _phoneController,
                              label: 'Phone',
                              icon: Icons.phone,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _vehicleController,
                              label: 'Vehicle',
                              icon: Icons.directions_car,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _deliveryLocationController,
                              label: 'Delivery Location',
                              icon: Icons.location_on,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _selectedRole,
                              decoration: _inputDecoration('Role', Icons.security),
                              items: _roleOptions
                                  .map((role) => DropdownMenuItem(
                                        value: role,
                                        child: Text(role.capitalize(), style: GoogleFonts.poppins(color: textColor)),
                                      ))
                                  .toList(),
                              onChanged: (value) => setState(() => _selectedRole = value),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        ElevatedButton(
                          onPressed: _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: doorDashRed,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: Text(
                            'Update Profile',
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ).animate().scale(duration: 300.ms),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _logout,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: doorDashRed, width: 2),
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            'Logout',
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: doorDashRed),
                          ),
                        ).animate().scale(duration: 300.ms),
                      ],
                    ),
                  ),
                ],
              ),
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
        currentIndex: _selectedIndex,
        selectedItemColor: doorDashRed,
        unselectedItemColor: doorDashGrey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(),
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      decoration: _inputDecoration(label, icon),
      style: GoogleFonts.poppins(color: textColor),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: doorDashGrey),
      prefixIcon: Icon(icon, color: doorDashRed),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: doorDashGrey.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: doorDashGrey.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: doorDashRed),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}