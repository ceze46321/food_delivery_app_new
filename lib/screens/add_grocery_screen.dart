import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart' show primaryColor, textColor, accentColor;
import '../auth_provider.dart';

class AddGroceryScreen extends StatefulWidget {
  const AddGroceryScreen({super.key});

  @override
  State<AddGroceryScreen> createState() => _AddGroceryScreenState();
}

class _AddGroceryScreenState extends State<AddGroceryScreen> {
  static const Color doorDashRed = Color(0xFFEF2A39);
  static const Color doorDashGrey = Color(0xFF757575);
  static const Color doorDashLightGrey = Color(0xFFF5F5F5);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  List<Map<String, dynamic>> items = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
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
    }
  }

  double _calculateTotal() {
    return items.fold(0, (sum, item) => sum + (item['quantity'] * item['price']));
  }

  Future<void> _submitOrder() async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'items': items,
        'total_amount': _calculateTotal(),
        'status': 'pending',
      };
      await authProvider.apiService.post('/grocery', payload);
      await authProvider.fetchUserGroceries(); // Refresh user groceries
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order added successfully'), backgroundColor: doorDashRed),
      );
      Navigator.pop(context); // Return to previous screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: doorDashLightGrey,
      appBar: AppBar(
        title: Text('Add Grocery Order', style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
        backgroundColor: primaryColor, // Use main.dart primaryColor
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Form to Add Item
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Item',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Item Name',
                          labelStyle: GoogleFonts.poppins(color: doorDashGrey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) => value!.isEmpty ? 'Enter item name' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Quantity',
                                labelStyle: GoogleFonts.poppins(color: doorDashGrey),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) => value!.isEmpty || int.tryParse(value) == null || int.parse(value) <= 0
                                  ? 'Enter valid quantity'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Price (₦)',
                                labelStyle: GoogleFonts.poppins(color: doorDashGrey),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) => value!.isEmpty || double.tryParse(value) == null || double.parse(value) < 0
                                  ? 'Enter valid price'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _addItem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor, // Use main.dart accentColor
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('Add Item', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Items List
            if (items.isNotEmpty)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Items (${items.length})',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
                      ),
                      const SizedBox(height: 12),
                      ...items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0), // Fixed typo: 'bottom'
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item['name']} (x${item['quantity']})',
                                    style: GoogleFonts.poppins(fontSize: 14, color: textColor),
                                  ),
                                ),
                                Text(
                                  '₦${(item['quantity'] * item['price']).toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: doorDashGrey),
                                ),
                              ],
                            ),
                          )),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
                          ),
                          Text(
                            '₦${_calculateTotal().toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Submit Button
            if (items.isNotEmpty)
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor, // Use main.dart primaryColor
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Submit Order', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
              ),
          ],
        ),
      ),
    );
  }
}