import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart' show primaryColor, textColor, accentColor;
import '../auth_provider.dart';
import 'restaurant_screen.dart';

class CreateGroceryProductScreen extends StatefulWidget {
  const CreateGroceryProductScreen({super.key});

  @override
  State<CreateGroceryProductScreen> createState() => _CreateGroceryProductScreenState();
}

class _CreateGroceryProductScreenState extends State<CreateGroceryProductScreen> {
  static const Color doorDashRed = Color(0xFFEF2A39);
  static const Color doorDashGrey = Color(0xFF757575);
  static const Color doorDashLightGrey = Color(0xFFF5F5F5);
  static const Color doorDashWhite = Colors.white;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _groceryProducts = [];
  int _selectedIndex = 2; // Default to Groceries tab

  @override
  void initState() {
    super.initState();
    _fetchGroceryProducts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _fetchGroceryProducts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final products = await authProvider.fetchGroceryProducts();
      if (mounted) {
        setState(() {
          _groceryProducts = products;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching products: $e', style: GoogleFonts.poppins(color: doorDashWhite)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    if (!authProvider.isRestaurantOwner) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Only restaurant owners can add products', style: GoogleFonts.poppins(color: doorDashWhite)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = [
        {
          'name': _nameController.text.trim(),
          'price': double.parse(_priceController.text.trim()),
          'quantity': int.parse(_quantityController.text.trim()),
          'image': _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
        }
      ];
      debugPrint('Submitting payload: $payload');
      await authProvider.createGrocery(payload);
      await _fetchGroceryProducts(); // Refresh list after adding
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product added successfully', style: GoogleFonts.poppins(color: doorDashWhite)),
            backgroundColor: doorDashRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
      _nameController.clear();
      _priceController.clear();
      _quantityController.clear();
      _imageUrlController.clear();
    } catch (e) {
      debugPrint('Error adding product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding product: $e', style: GoogleFonts.poppins(color: doorDashWhite)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteProduct(String productId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Delete Product', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)),
        content: Text('Are you sure you want to delete this product?', style: GoogleFonts.poppins(color: doorDashGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: doorDashRed)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Delete', style: GoogleFonts.poppins(color: doorDashWhite)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await authProvider.deleteGroceryProduct(productId);
      await _fetchGroceryProducts(); // Refresh list after deletion
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product deleted successfully', style: GoogleFonts.poppins(color: doorDashWhite)),
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
            content: Text('Error deleting product: $e', style: GoogleFonts.poppins(color: doorDashWhite)),
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
    final routes = {
      0: '/home',
      1: '/restaurants',
      2: '/groceries',
      3: '/orders',
      4: '/profile',
      5: '/restaurant-owner',
    };
    if (index != 2 && routes.containsKey(index)) { // 2 is Groceries
      if (index == 1) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RestaurantScreen()));
      } else {
        Navigator.pushReplacementNamed(context, routes[index]!);
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
          'Manage Grocery Products',
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Add New Product'),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        label: 'Product Name',
                        validator: (value) => value!.isEmpty ? 'Enter product name' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _priceController,
                        label: 'Price (₦)',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) => value!.isEmpty || double.tryParse(value) == null || double.parse(value) <= 0
                            ? 'Enter a valid price'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _quantityController,
                        label: 'Quantity Available',
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty || int.tryParse(value) == null || int.parse(value) < 0
                            ? 'Enter a valid quantity'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _imageUrlController,
                        label: 'Image URL (Optional)',
                        isOptional: true,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                _buildSectionTitle('Your Products'),
                const SizedBox(height: 16),
                _groceryProducts.isEmpty
                    ? Center(
                        child: Text(
                          'No products yet',
                          style: GoogleFonts.poppins(fontSize: 16, color: doorDashGrey),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _groceryProducts.length,
                        itemBuilder: (context, index) {
                          final grocery = _groceryProducts[index];
                          final items = grocery['items'] as List<dynamic>? ?? [];
                          return items.isNotEmpty
                              ? _buildProductCard(items[0], grocery['id'].toString())
                              : const SizedBox.shrink();
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSubmitting ? null : _submitProduct,
        backgroundColor: doorDashRed,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        label: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: doorDashWhite, strokeWidth: 2),
              )
            : Text(
                'Add Product',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: doorDashWhite,
                ),
              ),
        icon: const Icon(Icons.add, color: doorDashWhite),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool isOptional = false,
  }) {
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
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: doorDashGrey,
            fontSize: 14,
          ),
          hintStyle: GoogleFonts.poppins(
            color: doorDashGrey.withOpacity(0.5),
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: true,
          fillColor: doorDashWhite,
        ),
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildProductCard(dynamic item, String productId) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
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
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name']?.toString() ?? 'Unnamed',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  Text(
                    'Price: ₦${item['price']?.toStringAsFixed(2) ?? 'N/A'}',
                    style: GoogleFonts.poppins(fontSize: 14, color: doorDashGrey),
                  ),
                  Text(
                    'Quantity: ${item['quantity']?.toString() ?? 'N/A'}',
                    style: GoogleFonts.poppins(fontSize: 14, color: doorDashGrey),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _deleteProduct(productId),
            ),
          ],
        ),
      ),
    );
  }
}