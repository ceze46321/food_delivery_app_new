import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../main.dart' show primaryColor, textColor, accentColor;
import '../auth_provider.dart';

class AddGroceryScreen extends StatefulWidget {
  const AddGroceryScreen({super.key});

  @override
  State<AddGroceryScreen> createState() => _AddGroceryScreenState();
}

class _AddGroceryScreenState extends State<AddGroceryScreen>
    with SingleTickerProviderStateMixin {
  static const Color doorDashRed = Color(0xFFEF2A39);
  static const Color doorDashGrey = Color(0xFF757575);
  static const Color doorDashLightGrey = Color(0xFFF5F5F5);
  static const Color doorDashWhite = Colors.white;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  List<Map<String, dynamic>> items = [];
  bool _isSubmitting = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _addItem() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        items.add({
          'name': _nameController.text.trim(),
          'quantity': int.parse(_quantityController.text.trim()),
          'price': double.parse(_priceController.text.trim()),
        });
        _nameController.clear();
        _quantityController.clear();
        _priceController.clear();
      });
      _showSnackBar('Item added to list', doorDashRed);
    }
  }

  double _calculateTotal() {
    return items.fold(
        0, (sum, item) => sum + (item['quantity'] * item['price']));
  }

  Future<void> _submitOrder() async {
    if (items.isEmpty) {
      _showSnackBar('Add at least one item', Colors.redAccent);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      _showSnackBar('Please log in to submit', Colors.redAccent);
      Navigator.pushNamed(context, '/login');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final groceryItems = items
          .map((item) => ({
                'name': item['name'],
                'quantity': item['quantity'],
                'price': item['price'],
              }))
          .toList();

      await authProvider.createGrocery(groceryItems);
      await authProvider.fetchUserGroceries(); // Refresh user groceries
      if (mounted) {
        _showSnackBar('Order added successfully', doorDashRed);
        Navigator.pop(context);
      }
    } catch (e, stackTrace) {
      debugPrint('Submit order error: $e\n$stackTrace');
      if (mounted) {
        _showSnackBar('Error: $e', Colors.redAccent);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
    });
    _showSnackBar('Item removed', doorDashRed);
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: GoogleFonts.poppins(color: doorDashWhite)),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: doorDashLightGrey,
      appBar: AppBar(
        title: Text(
          'Add Grocery Order',
          style: GoogleFonts.poppins(
            color: doorDashWhite,
            fontSize: screenWidth > 600 ? 22 : 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: doorDashRed,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios, color: doorDashWhite, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [doorDashRed, doorDashRed.withOpacity(0.8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Form to Add Item
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              color: doorDashWhite,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Item',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth > 600 ? 20 : 18,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _nameController,
                        label: 'Item Name',
                        hint: 'e.g., Apples',
                        validator: (value) =>
                            value!.isEmpty ? 'Enter item name' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _quantityController,
                              label: 'Quantity',
                              hint: 'e.g., 5',
                              keyboardType: TextInputType.number,
                              validator: (value) => value!.isEmpty ||
                                      int.tryParse(value) == null ||
                                      int.parse(value) <= 0
                                  ? 'Enter valid quantity'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _priceController,
                              label: 'Price (₦)',
                              hint: 'e.g., 100.00',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              validator: (value) => value!.isEmpty ||
                                      double.tryParse(value) == null ||
                                      double.parse(value) < 0
                                  ? 'Enter valid price'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _addItem,
                        child: Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accentColor,
                                accentColor.withOpacity(0.9)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Add Item',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: doorDashWhite,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Items List
            if (items.isNotEmpty)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                color: doorDashWhite,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Items (${items.length})',
                            style: GoogleFonts.poppins(
                              fontSize: screenWidth > 600 ? 20 : 18,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: doorDashRed),
                            onPressed: () => setState(() => items.clear()),
                            tooltip: 'Clear All',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item['name']} (x${item['quantity']})',
                                    style: GoogleFonts.poppins(
                                        fontSize: 14, color: textColor),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '₦${(item['quantity'] * item['price']).toStringAsFixed(2)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: doorDashGrey,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle,
                                          color: doorDashRed, size: 20),
                                      onPressed: () => _removeItem(index),
                                      tooltip: 'Remove Item',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: GoogleFonts.poppins(
                              fontSize: screenWidth > 600 ? 18 : 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          Text(
                            '₦${_calculateTotal().toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: screenWidth > 600 ? 20 : 18,
                              fontWeight: FontWeight.bold,
                              color: doorDashRed,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            // Submit Button
            if (items.isNotEmpty)
              GestureDetector(
                onTap: _isSubmitting ? null : _submitOrder,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [doorDashRed, doorDashRed.withOpacity(0.9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: doorDashRed.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isSubmitting
                        ? FadeTransition(
                            opacity: _fadeAnimation,
                            child: const CircularProgressIndicator(
                                color: doorDashWhite),
                          )
                        : Text(
                            'Submit Order',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: doorDashWhite,
                            ),
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.poppins(color: doorDashGrey, fontSize: 14),
          hintStyle: GoogleFonts.poppins(color: doorDashGrey.withOpacity(0.6)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: true,
          fillColor: doorDashWhite,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
        style: GoogleFonts.poppins(fontSize: 16, color: textColor),
        validator: validator,
      ),
    );
  }
}
