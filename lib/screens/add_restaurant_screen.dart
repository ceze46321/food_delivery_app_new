import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../auth_provider.dart';
import '../main.dart' show textColor;
import 'package:flutter_animate/flutter_animate.dart';
import 'restaurant_screen.dart'; // Import for navigation

class AddRestaurantScreen extends StatefulWidget {
  const AddRestaurantScreen({super.key});

  @override
  State<AddRestaurantScreen> createState() => _AddRestaurantScreenState();
}

class _AddRestaurantScreenState extends State<AddRestaurantScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _address = '';
  String _state = '';
  String _country = '';
  String _category = 'Restaurant';
  String? _imageUrl;
  final List<Map<String, dynamic>> _menuItems = [];
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _selectedIndex = 5; // Default to "Owner" since this is an owner action

  static const Color doorDashRed = Color(0xFFEF2A39);
  static const Color doorDashGrey = Color(0xFF757575);
  static const Color doorDashLightGrey = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
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
    _animationController.dispose();
    super.dispose();
  }

  void _addMenuItem() {
    setState(() {
      _menuItems.add({'name': '', 'price': 0.0, 'quantity': 1});
    });
  }

  void _removeMenuItem(int index) {
    setState(() {
      _menuItems.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (_menuItems.isEmpty || _menuItems.any((item) => item['name'].isEmpty || item['price'] <= 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Add at least one valid menu item', style: GoogleFonts.poppins()),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      setState(() => _isLoading = true);
      try {
        await Provider.of<AuthProvider>(context, listen: false).addRestaurant(
          _name,
          _address,
          _state,
          _country,
          _category,
          image: _imageUrl,
          menuItems: _menuItems,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Restaurant added successfully!', style: GoogleFonts.poppins(color: Colors.white)),
              backgroundColor: doorDashRed,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add restaurant: $e', style: GoogleFonts.poppins()), backgroundColor: Colors.redAccent),
          );
          setState(() => _isLoading = false);
        }
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
    if (routes.containsKey(index)) {
      if (index == 1) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RestaurantScreen()));
      } else if (index != 5) { // Don't navigate away if already on Owner-related screen
        Navigator.pushReplacementNamed(context, routes[index]!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: doorDashLightGrey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Restaurant',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: doorDashRed,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: SpinKitFadingCircle(color: doorDashRed, size: 50))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                'Restaurant Details',
                                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                label: 'Restaurant Name',
                                icon: Icons.store,
                                validator: (value) => value!.isEmpty ? 'Name required' : null,
                                onSaved: (value) => _name = value!,
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                label: 'Address',
                                icon: Icons.location_on,
                                validator: (value) => value!.isEmpty ? 'Address required' : null,
                                onSaved: (value) => _address = value!,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      label: 'State',
                                      icon: Icons.map,
                                      validator: (value) => value!.isEmpty ? 'State required' : null,
                                      onSaved: (value) => _state = value!,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildTextField(
                                      label: 'Country',
                                      icon: Icons.flag,
                                      validator: (value) => value!.isEmpty ? 'Country required' : null,
                                      onSaved: (value) => _country = value!,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: _category,
                                decoration: _inputDecoration('Category', Icons.category),
                                items: ['Restaurant', 'Fast Food', 'Cafe']
                                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: GoogleFonts.poppins(color: textColor))))
                                    .toList(),
                                onChanged: (value) => setState(() => _category = value!),
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                label: 'Image URL (optional)',
                                icon: Icons.image,
                                validator: (value) => value != null && value.isNotEmpty && !(Uri.tryParse(value)?.isAbsolute ?? false) ? 'Invalid URL' : null,
                                onSaved: (value) => _imageUrl = value?.isEmpty ?? true ? null : value,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Menu Items',
                                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
                                  ),
                                  TextButton(
                                    onPressed: _addMenuItem,
                                    child: Text(
                                      'Add Item',
                                      style: GoogleFonts.poppins(color: doorDashRed, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_menuItems.isEmpty)
                                Center(
                                  child: Text(
                                    'No items added yet',
                                    style: GoogleFonts.poppins(color: doorDashGrey),
                                  ),
                                )
                              else
                                ..._menuItems.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final item = entry.value;
                                  return Animate(
                                    effects: const [FadeEffect(), SlideEffect()],
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: _buildTextField(
                                              label: 'Item Name',
                                              icon: Icons.fastfood,
                                              validator: (value) => value!.isEmpty ? 'Name required' : null,
                                              onChanged: (value) => item['name'] = value,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          SizedBox(
                                            width: 100,
                                            child: _buildTextField(
                                              label: 'Price',
                                              icon: Icons.attach_money,
                                              keyboardType: TextInputType.number,
                                              validator: (value) => value!.isEmpty || double.tryParse(value) == null ? 'Valid price' : null,
                                              onChanged: (value) => item['price'] = double.tryParse(value) ?? 0.0,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                                            onPressed: () => _removeMenuItem(index),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: doorDashRed,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: Text(
                          'Add Restaurant',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ).animate().scale(duration: 300.ms),
                    ),
                  ],
                ),
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
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
    void Function(String)? onChanged,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      decoration: _inputDecoration(label, icon),
      validator: validator,
      onSaved: onSaved,
      onChanged: onChanged,
      keyboardType: keyboardType,
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