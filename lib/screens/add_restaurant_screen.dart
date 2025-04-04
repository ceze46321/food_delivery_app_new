import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../auth_provider.dart';
import '../main.dart' show textColor;
import 'restaurant_screen.dart';

class AddRestaurantScreen extends StatefulWidget {
  const AddRestaurantScreen({super.key});

  @override
  State<AddRestaurantScreen> createState() => _AddRestaurantScreenState();
}

class _AddRestaurantScreenState extends State<AddRestaurantScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _imageController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _selectedIndex = 5;
  final List<Map<String, dynamic>> _menuItems = [];
  final List<Map<String, TextEditingController>> _menuControllers = [];

  static const Color doorDashRed = Color(0xFFEF2A39);
  static const Color doorDashGrey = Color(0xFF757575);
  static const Color doorDashLightGrey = Color(0xFFF5F5F5);
  static const Color doorDashWhite = Colors.white;

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
    _nameController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _imageController.dispose();
    for (var controllers in _menuControllers) {
      controllers['name']?.dispose();
      controllers['description']?.dispose();
      controllers['price']?.dispose();
      controllers['image']?.dispose();
    }
    super.dispose();
  }

  void _addMenuItem() {
    setState(() {
      _menuItems.add({
        'name': '',
        'description': '',
        'price': 0.0,
        'image': null,
      });
      _menuControllers.add({
        'name': TextEditingController(),
        'description': TextEditingController(),
        'price': TextEditingController(),
        'image': TextEditingController(),
      });
    });
  }

  void _removeMenuItem(int index) {
    setState(() {
      _menuControllers[index]['name']?.dispose();
      _menuControllers[index]['description']?.dispose();
      _menuControllers[index]['price']?.dispose();
      _menuControllers[index]['image']?.dispose();
      _menuControllers.removeAt(index);
      _menuItems.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      // Populate _menuItems from controllers
      for (int i = 0; i < _menuItems.length; i++) {
        _menuItems[i]['name'] = _menuControllers[i]['name']!.text;
        _menuItems[i]['description'] = _menuControllers[i]['description']!.text;
        _menuItems[i]['price'] =
            double.tryParse(_menuControllers[i]['price']!.text) ?? 0.0;
        _menuItems[i]['image'] = _menuControllers[i]['image']!.text.isEmpty
            ? null
            : _menuControllers[i]['image']!.text;
      }

      if (_menuItems.isEmpty ||
          _menuItems.any((item) =>
              item['name'].isEmpty ||
              item['description'].isEmpty ||
              item['price'] <= 0)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please add at least one valid menu item with a name, description, and price.',
                style: GoogleFonts.poppins(color: doorDashWhite),
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: doorDashWhite,
                onPressed: () =>
                    ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              ),
            ),
          );
        }
        return;
      }

      setState(() => _isLoading = true);
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        debugPrint('Submitting restaurant data:');
        debugPrint('Name: ${_nameController.text}');
        debugPrint('Location: ${_locationController.text}');
        debugPrint('Phone: ${_phoneController.text}');
        debugPrint('Image: ${_imageController.text}');
        debugPrint('Menu Items: $_menuItems');

        await authProvider.addRestaurant(
          _nameController.text,
          _locationController.text,
          _phoneController.text,
          image: _imageController.text.isEmpty ? null : _imageController.text,
          menuItems: _menuItems,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Restaurant added successfully!',
                style: GoogleFonts.poppins(color: doorDashWhite),
              ),
              backgroundColor: doorDashRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e, stackTrace) {
        debugPrint('Error adding restaurant: $e\n$stackTrace');
        String errorMessage = e.toString().replaceFirst('Exception: ', '');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errorMessage,
                style: GoogleFonts.poppins(color: doorDashWhite),
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: doorDashWhite,
                onPressed: () =>
                    ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              ),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _onItemTapped(int index) {
    try {
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
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const RestaurantScreen()));
        } else if (index != 5) {
          Navigator.pushReplacementNamed(context, routes[index]!);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error navigating to route: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Oops! We couldn’t navigate to that page. Please try again.',
              style: GoogleFonts.poppins(color: doorDashWhite),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: doorDashLightGrey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: doorDashWhite),
          onPressed: () {
            try {
              Navigator.pop(context);
            } catch (e, stackTrace) {
              debugPrint('Error navigating back: $e\n$stackTrace');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Oops! We couldn’t go back. Please try again.',
                      style: GoogleFonts.poppins(color: doorDashWhite),
                    ),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
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
          },
        ),
        title: Text(
          'Add Restaurant',
          style: GoogleFonts.poppins(
              fontSize: 22, fontWeight: FontWeight.w600, color: doorDashWhite),
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
      ),
      body: _isLoading
          ? Center(child: SpinKitFadingCircle(color: doorDashRed, size: 60))
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
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        color: doorDashWhite,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Restaurant Details',
                                style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: textColor),
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                label: 'Restaurant Name',
                                icon: Icons.store,
                                validator: (value) =>
                                    value!.isEmpty ? 'Name required' : null,
                                controller: _nameController,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                label: 'Location',
                                icon: Icons.location_on,
                                validator: (value) =>
                                    value!.isEmpty ? 'Location required' : null,
                                controller: _locationController,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                label: 'Customer Care Phone',
                                icon: Icons.phone,
                                keyboardType: TextInputType.phone,
                                validator: (value) =>
                                    value!.isEmpty ? 'Phone required' : null,
                                controller: _phoneController,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Restaurant Image',
                                style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: textColor),
                              ),
                              const SizedBox(height: 8),
                              _buildTextField(
                                label: 'Image URL (optional)',
                                icon: Icons.link,
                                validator: (value) => value != null &&
                                        value.isNotEmpty &&
                                        !(Uri.tryParse(value)?.isAbsolute ??
                                            false)
                                    ? 'Please enter a valid URL'
                                    : null,
                                controller: _imageController,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Note: Image upload from gallery is coming soon! For now, please provide an image URL.',
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: doorDashGrey),
                              ),
                              if (_imageController.text.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        _imageController.text,
                                        height: 150,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                          height: 150,
                                          color: doorDashGrey.withOpacity(0.1),
                                          child: const Center(
                                            child: Icon(Icons.error,
                                                color: Colors.redAccent,
                                                size: 40),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.redAccent),
                                        onPressed: () {
                                          setState(() {
                                            _imageController.clear();
                                          });
                                        },
                                        style: IconButton.styleFrom(
                                          backgroundColor:
                                              doorDashWhite.withOpacity(0.8),
                                          shape: const CircleBorder(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        color: doorDashWhite,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Menu Items',
                                    style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: textColor),
                                  ),
                                  TextButton(
                                    onPressed: _addMenuItem,
                                    child: Text(
                                      'Add Item',
                                      style: GoogleFonts.poppins(
                                          color: doorDashRed,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_menuItems.isEmpty)
                                Center(
                                  child: Text(
                                    'No items added yet',
                                    style: GoogleFonts.poppins(
                                        color: doorDashGrey),
                                  ),
                                )
                              else
                                ..._menuItems.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  return Animate(
                                    effects: const [
                                      FadeEffect(),
                                      SlideEffect()
                                    ],
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildTextField(
                                                  label: 'Item Name',
                                                  icon: Icons.fastfood,
                                                  validator: (value) =>
                                                      value!.isEmpty
                                                          ? 'Name required'
                                                          : null,
                                                  controller:
                                                      _menuControllers[index]
                                                          ['name'],
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              SizedBox(
                                                width: 120,
                                                child: _buildTextField(
                                                  label: 'Price',
                                                  prefixText: '\u20A6 ',
                                                  keyboardType:
                                                      TextInputType.number,
                                                  validator: (value) => value!
                                                              .isEmpty ||
                                                          double.tryParse(
                                                                  value) ==
                                                              null ||
                                                          double.parse(value) <=
                                                              0
                                                      ? 'Valid price required'
                                                      : null,
                                                  controller:
                                                      _menuControllers[index]
                                                          ['price'],
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete,
                                                    color: Colors.redAccent),
                                                onPressed: () =>
                                                    _removeMenuItem(index),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          _buildTextField(
                                            label: 'Description',
                                            icon: Icons.description,
                                            validator: (value) => value!.isEmpty
                                                ? 'Description required'
                                                : null,
                                            controller: _menuControllers[index]
                                                ['description'],
                                          ),
                                          const SizedBox(height: 8),
                                          _buildTextField(
                                            label: 'Item Image URL (optional)',
                                            icon: Icons.image,
                                            validator: (value) =>
                                                value != null &&
                                                        value.isNotEmpty &&
                                                        !(Uri.tryParse(value)
                                                                ?.isAbsolute ??
                                                            false)
                                                    ? 'Please enter a valid URL'
                                                    : null,
                                            controller: _menuControllers[index]
                                                ['image'],
                                          ),
                                          if (_menuControllers[index]['image']!
                                              .text
                                              .isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: Image.network(
                                                    _menuControllers[index]
                                                            ['image']!
                                                        .text,
                                                    height: 100,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context,
                                                            error,
                                                            stackTrace) =>
                                                        Container(
                                                      height: 100,
                                                      color: doorDashGrey
                                                          .withOpacity(0.1),
                                                      child: const Center(
                                                        child: Icon(Icons.error,
                                                            color: Colors
                                                                .redAccent,
                                                            size: 30),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 4,
                                                  right: 4,
                                                  child: IconButton(
                                                    icon: const Icon(
                                                        Icons.close,
                                                        color: Colors.redAccent,
                                                        size: 20),
                                                    onPressed: () {
                                                      setState(() {
                                                        _menuControllers[index]
                                                                ['image']!
                                                            .clear();
                                                      });
                                                    },
                                                    style: IconButton.styleFrom(
                                                      backgroundColor:
                                                          doorDashWhite
                                                              .withOpacity(0.8),
                                                      shape:
                                                          const CircleBorder(),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
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
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        child: Text(
                          'Add Restaurant',
                          style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: doorDashWhite),
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
        unselectedItemColor: doorDashGrey,
        backgroundColor: doorDashWhite,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(),
        elevation: 8,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    IconData? icon,
    String? prefixText,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
    void Function(String)? onChanged,
    TextInputType? keyboardType,
    TextEditingController? controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: _inputDecoration(label, icon, prefixText),
        validator: validator,
        onSaved: onSaved,
        onChanged: onChanged,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(color: textColor),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData? icon,
      [String? prefixText]) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: doorDashGrey),
      prefixIcon: icon != null ? Icon(icon, color: doorDashRed) : null,
      prefixText: prefixText,
      prefixStyle: GoogleFonts.poppins(color: textColor),
      filled: true,
      fillColor: doorDashWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
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
