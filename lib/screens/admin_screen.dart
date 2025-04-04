import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../auth_provider.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  static const Color doorDashRed = Color(0xFFEF2A39);
  static const Color warmCoral = Color(0xFFFF7043);
  static const Color deepBrown = Color(0xFF3E2723);
  static const Color lightGray = Color(0xFFF5F5F5);

  // Controllers for email
  final _emailSubjectController = TextEditingController();
  final _emailMessageController = TextEditingController();

  // Cached futures
  late Future<List<dynamic>> _usersFuture;
  late Future<List<dynamic>> _restaurantsFuture;
  late Future<List<dynamic>> _groceriesFuture;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _usersFuture = authProvider.fetchAllUsers();
    _restaurantsFuture = authProvider.getRestaurants();
    _groceriesFuture = authProvider.fetchGroceryProducts();
  }

  @override
  void dispose() {
    _emailSubjectController.dispose();
    _emailMessageController.dispose();
    super.dispose();
  }

  // Launch URL for phone or email
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  // Show email dialog
  Future<void> _showEmailDialog(BuildContext context, AuthProvider authProvider,
      {String? userId, List<String>? userIds}) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          userId != null ? 'Send Email' : 'Send Bulk Email',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, color: doorDashRed),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _emailSubjectController,
              decoration: InputDecoration(
                labelText: 'Subject',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailMessageController,
              decoration: InputDecoration(
                labelText: 'Message',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Cancel', style: GoogleFonts.poppins(color: doorDashRed)),
          ),
          ElevatedButton(
            onPressed: () async {
              final subject = _emailSubjectController.text.trim();
              final message = _emailMessageController.text.trim();
              if (subject.isEmpty || message.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields')),
                );
                return;
              }
              try {
                if (userId != null) {
                  await authProvider.sendAdminEmail(subject, message, userId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email sent successfully')),
                  );
                } else if (userIds != null) {
                  for (var id in userIds) {
                    await authProvider.sendAdminEmail(subject, message, id);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Bulk emails sent successfully')),
                  );
                }
                Navigator.pop(context);
                _emailSubjectController.clear();
                _emailMessageController.clear();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Failed to send email: $e'),
                      backgroundColor: Colors.redAccent),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: warmCoral,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child:
                Text('Send', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Refresh data
  void _refreshData(AuthProvider authProvider) {
    setState(() {
      _usersFuture = authProvider.fetchAllUsers();
      _restaurantsFuture = authProvider.getRestaurants();
      _groceriesFuture = authProvider.fetchGroceryProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAdmin) {
      return Scaffold(
        body: Center(
          child: Text(
            'Unauthorized Access',
            style: GoogleFonts.poppins(fontSize: 24, color: deepBrown),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        title: Text('Admin Dashboard',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: doorDashRed,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await authProvider.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${authProvider.name ?? "Admin"}!',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: deepBrown,
              ),
            ),
            const SizedBox(height: 24),

            // Users Section
            _buildSectionTitle('Users'),
            FutureBuilder<List<dynamic>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: doorDashRed));
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}',
                      style: GoogleFonts.poppins(color: Colors.red));
                }
                final users = snapshot.data ?? [];
                return Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 300,
                        childAspectRatio: 1.3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  user['name'] ?? 'Unnamed',
                                  style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      _launchUrl('mailto:${user['email']}'),
                                  child: Text(
                                    'Email: ${user['email'] ?? 'N/A'}',
                                    style: GoogleFonts.poppins(
                                        fontSize: 14, color: Colors.blue),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      _launchUrl('tel:${user['phone']}'),
                                  child: Text(
                                    'Phone: ${user['phone'] ?? 'N/A'}',
                                    style: GoogleFonts.poppins(
                                        fontSize: 14, color: Colors.blue),
                                  ),
                                ),
                                Text('Role: ${user['role'] ?? 'N/A'}',
                                    style: GoogleFonts.poppins(fontSize: 14)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => _showEmailDialog(
                                          context, authProvider,
                                          userId: user['id'].toString()),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: warmCoral,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                      ),
                                      child: Text('Email',
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.white)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _showEmailDialog(context, authProvider,
                          userIds:
                              users.map((u) => u['id'].toString()).toList()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: warmCoral,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Send Bulk Email',
                          style: GoogleFonts.poppins(
                              fontSize: 16, color: Colors.white)),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // Restaurants Section
            _buildSectionTitle('Restaurants'),
            FutureBuilder<List<dynamic>>(
              future: _restaurantsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: doorDashRed));
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}',
                      style: GoogleFonts.poppins(color: Colors.red));
                }
                final restaurants = snapshot.data ?? [];
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: restaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = restaurants[index];
                    final menuItems =
                        restaurant['menu_items'] as List<dynamic>? ?? [];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              restaurant['name'] ?? 'Unnamed',
                              style: GoogleFonts.poppins(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: menuItems.length,
                                itemBuilder: (context, menuIndex) {
                                  final menu = menuItems[menuIndex];
                                  final controller = TextEditingController(
                                      text: menu['price']?.toString() ?? '0');
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            menu['name'] ?? 'Item',
                                            style: GoogleFonts.poppins(
                                                fontSize: 14),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 80,
                                          child: TextField(
                                            controller: controller,
                                            keyboardType:
                                                TextInputType.numberWithOptions(
                                                    decimal: true),
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8)),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8),
                                            ),
                                            style: GoogleFonts.poppins(
                                                fontSize: 14),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () async {
                                            final price = double.tryParse(
                                                controller.text);
                                            if (price != null && price >= 0) {
                                              try {
                                                await authProvider
                                                    .updateMenuPrice(
                                                        menu['id'].toString(),
                                                        price);
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'Menu price updated')),
                                                );
                                                _refreshData(authProvider);
                                              } catch (e) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content:
                                                          Text('Error: $e'),
                                                      backgroundColor:
                                                          Colors.redAccent),
                                                );
                                              }
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: warmCoral,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                          ),
                                          child: Text('Save',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 32),

            // Groceries Section
            _buildSectionTitle('Groceries'),
            FutureBuilder<List<dynamic>>(
              future: _groceriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: doorDashRed));
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}',
                      style: GoogleFonts.poppins(color: Colors.red));
                }
                final groceries = snapshot.data ?? [];
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: groceries.length,
                  itemBuilder: (context, index) {
                    final grocery = groceries[index];
                    final items = grocery['items'] as List<dynamic>? ?? [];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Grocery #${grocery['id']}',
                              style: GoogleFonts.poppins(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: items.length,
                                itemBuilder: (context, itemIndex) {
                                  final item = items[itemIndex];
                                  final controller = TextEditingController(
                                      text: item['price']?.toString() ?? '0');
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['name'] ?? 'Item',
                                            style: GoogleFonts.poppins(
                                                fontSize: 14),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 80,
                                          child: TextField(
                                            controller: controller,
                                            keyboardType:
                                                TextInputType.numberWithOptions(
                                                    decimal: true),
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8)),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8),
                                            ),
                                            style: GoogleFonts.poppins(
                                                fontSize: 14),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () async {
                                            final price = double.tryParse(
                                                controller.text);
                                            if (price != null && price >= 0) {
                                              try {
                                                await authProvider
                                                    .updateGroceryItemPrice(
                                                  grocery['id'].toString(),
                                                  price,
                                                  itemIndex: itemIndex,
                                                );
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'Grocery price updated')),
                                                );
                                                _refreshData(authProvider);
                                              } catch (e) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content:
                                                          Text('Error: $e'),
                                                      backgroundColor:
                                                          Colors.redAccent),
                                                );
                                              }
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: warmCoral,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                          ),
                                          child: Text('Save',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
            fontSize: 22, fontWeight: FontWeight.w600, color: deepBrown),
      ),
    );
  }
}
