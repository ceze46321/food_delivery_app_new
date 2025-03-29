import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../main.dart' show textColor, accentColor;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'create_grocery_product_screen.dart';
// Added import for CustomerReviewScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<dynamic> restaurants = [];
  List<Map<String, dynamic>> groceries = [];
  bool isLoadingRestaurants = true;
  bool isLoadingGroceries = true;
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _fetchRestaurants();
    _fetchGroceries();
    _animationController.forward();
  }

  Future<void> _fetchRestaurants() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final fetchedRestaurants = await auth.getRestaurants();
      if (mounted) {
        setState(() {
          restaurants = fetchedRestaurants.take(10).toList();
          isLoadingRestaurants = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching restaurants: $e'), backgroundColor: Colors.red));
        setState(() => isLoadingRestaurants = false);
      }
    }
  }

  Future<void> _fetchGroceries() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final fetchedGroceries = await auth.fetchGroceryProducts();
      if (mounted) {
        setState(() {
          groceries = fetchedGroceries.expand((grocery) {
            final items = grocery['items'] as List<dynamic>? ?? [];
            return items.map((item) => {
                  'id': grocery['id']?.toString() ?? 'unknown',
                  'name': item['name']?.toString() ?? 'Unnamed',
                  'price': (item['price'] as num?)?.toDouble() ?? 0.0,
                  'image': item['image']?.toString(),
                });
          }).take(5).toList(); // Limit to 5 groceries
          isLoadingGroceries = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching groceries: $e'), backgroundColor: Colors.red));
        setState(() => isLoadingGroceries = false);
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    final routes = {
      0: '/home',
      1: '/restaurants',
      2: '/orders',
      3: '/profile',
      4: '/restaurant-owner',
      5: '/dashers',
    };
    if (index != 0 && routes.containsKey(index)) {
      Navigator.pushReplacementNamed(context, routes[index]!);
    }
  }

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Terms and Conditions', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)),
        content: SingleChildScrollView(
          child: Text(
            '''
Welcome to CanIbuyYouAmeal Express! By using this app, you agree to:

1. **Usage**: Use the app for lawful purposes only.
2. **Account**: Keep your credentials secure; you’re responsible for all activity.
3. **Roles**: Your role (Customer, Merchant, Dasher) defines your permissions.
4. **Payments**: Transactions are processed securely; refunds follow our policy.
5. **Liability**: We’re not liable for third-party service issues.

Full terms at chiwexpress.com/terms.
            ''',
            style: GoogleFonts.poppins(fontSize: 14, color: textColor.withOpacity(0.8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.poppins(color: const Color(0xFFEF2A39))),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Privacy Policy', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)),
        content: SingleChildScrollView(
          child: Text(
            '''
At CanIbuyYouAmeal Express, your privacy matters:

1. **Data Collection**: We collect name, email, and role for account creation.
2. **Usage**: Data is used to provide and improve services.
3. **Security**: Your info is encrypted and stored securely.
4. **Sharing**: Limited to service providers as needed.
5. **Rights**: Contact support@chiwexpress.com to manage your data.

Full policy at chiwexpress.com/privacy.
            ''',
            style: GoogleFonts.poppins(fontSize: 14, color: textColor.withOpacity(0.8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.poppins(color: const Color(0xFFEF2A39))),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final userName = auth.name ?? 'Foodie';
    final userRole = auth.role ?? 'Visitor';
    print('HomeScreen - Role: ${auth.role}, IsRestaurantOwner: ${auth.isRestaurantOwner}');

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFEF2A39),
                  const Color(0xFFD81B23).withOpacity(0.9),
                  Colors.white.withOpacity(0.95),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: SubtleTexturePainter(),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 300.0,
                      floating: false,
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                        title: Text(
                          'Welcome, $userName!',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4, offset: const Offset(2, 2)),
                            ],
                          ),
                        ),
                        background: ClipRRect(
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                          child: Image.network(
                            'https://i.imgur.com/Qse69mz.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFFEF2A39).withOpacity(0.8),
                              child: const Icon(Icons.fastfood, size: 100, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      backgroundColor: const Color(0xFFEF2A39),
                      elevation: 8,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.person, color: Colors.white),
                          onPressed: () => Navigator.pushNamed(context, '/dashboard'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.account_circle, color: Colors.white),
                          onPressed: () => Navigator.pushNamed(context, '/profile'),
                        ),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Can I Buy You A Meal',
                                style: GoogleFonts.poppins(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                'Your Nigerian Food Adventure Awaits',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: textColor.withOpacity(0.8),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Role: $userRole',
                                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
                              ),
                              const SizedBox(height: 30),
                              Text(
                                'Why Can I Buy You A Meal?',
                                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                              ),
                              const SizedBox(height: 16),
                              StaggeredGrid.count(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                children: [
                                  _buildFeatureTile(Icons.local_dining, 'Authentic Taste', 'Savor Nigeria’s finest dishes.'),
                                  _buildFeatureTile(Icons.flash_on, 'Fast Delivery', 'Food at your door in minutes.'),
                                  _buildFeatureTile(Icons.verified, 'Trusted Service', 'Reliable every time.'),
                                  _buildFeatureTile(Icons.people, 'Community', 'Support local vendors.'),
                                ],
                              ),
                              const SizedBox(height: 30),
                              Text(
                                'Featured Restaurants',
                                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 220,
                                child: isLoadingRestaurants
                                    ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF2A39))))
                                    : restaurants.isEmpty
                                        ? Center(
                                            child: Text(
                                              'No restaurants yet',
                                              style: GoogleFonts.poppins(color: textColor.withOpacity(0.7)),
                                            ),
                                          )
                                        : ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: restaurants.length,
                                            itemBuilder: (context, index) => _buildRestaurantCard(restaurants[index]),
                                          ),
                              ),
                              const SizedBox(height: 30),
                              Text(
                                'Top Dishes',
                                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 180,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    _buildDishCard('Jollof Rice', 'https://images.ctfassets.net/trvmqu12jq2l/6FV4Opt7wUyR91t2FXyOIr/f32972fce10fc87585e831b334ea17ef/header.jpg?q=70&w=1208&h=1080&f=faces&fit=fill', 'Spicy & Savory'),
                                    _buildDishCard('Pounded Yam', 'https://s3-media0.fl.yelpcdn.com/bphoto/4x8-Rjfell2DBqbrHSbCsg/348s.jpg', 'With Egusi Soup'),
                                    _buildDishCard('Suya', 'https://assets.simpleviewinc.com/grandrapidsdamsub/image/upload/c_fill,f_jpg,g_xy_center,h_1200,q_95,w_900,x_4752,y_3168/v1/cms_resources/clients/grandrapids/042_3_16212_jpeg_af93ea51-3de2-404e-b5c4-21aa68737022.jpg', 'Grilled Perfection'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 30),
                              Text(
                                'Featured Groceries',
                                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 200,
                                child: isLoadingGroceries
                                    ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF2A39))))
                                    : groceries.isEmpty
                                        ? Center(
                                            child: Text(
                                              'No groceries yet',
                                              style: GoogleFonts.poppins(color: textColor.withOpacity(0.7)),
                                            ),
                                          )
                                        : ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: groceries.length,
                                            itemBuilder: (context, index) => _buildGroceryCard(groceries[index]),
                                          ),
                              ),
                              const SizedBox(height: 30),
                              Text(
                                'What Our Users Say',
                                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                              ),
                              const SizedBox(height: 16),
                              _buildTestimonialCarousel(),
                              const SizedBox(height: 16),
                              Center(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pushNamed(context, '/reviews'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEF2A39),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Text(
                                    'See All Reviews',
                                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                              Text(
                                'Quick Actions',
                                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                alignment: WrapAlignment.center,
                                children: [
                                  _buildActionButton(context, 'Order Now', Icons.fastfood, () => Navigator.pushNamed(context, '/restaurants')),
                                  _buildActionButton(context, 'Track Order', Icons.local_shipping, () => Navigator.pushNamed(context, '/orders')),
                                  _buildActionButton(context, 'Groceries', Icons.local_grocery_store, () => Navigator.pushNamed(context, '/groceries')),
                                  
                                  if (auth.isRestaurantOwner)
                                    _buildActionButton(context, 'Create Grocery Product', Icons.add_circle, () {
                                      print('Navigating to CreateGroceryProductScreen from Home');
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroceryProductScreen()));
                                    }),
                                  if (userRole == 'owner' || userRole == 'restaurant_owner')
                                    _buildActionButton(context, 'Add Restaurant', Icons.store, () => Navigator.pushNamed(context, '/add-restaurant').then((_) => _fetchRestaurants())),
                                  if (userRole == 'dasher')
                                    _buildActionButton(context, 'Deliver', Icons.directions_bike, () => Navigator.pushNamed(context, '/dashers')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        color: const Color(0xFFEF2A39).withOpacity(0.05),
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Text(
                              'Explore More',
                              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildFooterButton(context, 'Restaurants', () => Navigator.pushNamed(context, '/restaurants')),
                                _buildFooterButton(context, 'Orders', () => Navigator.pushNamed(context, '/orders')),
                                _buildFooterButton(context, 'Logistics', () => Navigator.pushNamed(context, '/logistics')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                color: Colors.white.withOpacity(0.9),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _showTermsAndConditions,
                      child: Text(
                        'Terms',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFEF2A39),
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                    GestureDetector(
                      onTap: _showPrivacyPolicy,
                      child: Text(
                        'Privacy',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFEF2A39),
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Restaurants'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Owner'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_bike), label: 'Dasher'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFEF2A39),
        unselectedItemColor: textColor.withOpacity(0.6),
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/restaurants'),
        backgroundColor: const Color(0xFFEF2A39),
        tooltip: 'Order Now',
        child: const Icon(Icons.fastfood, color: Colors.white),
      ),
    );
  }

  Widget _buildFeatureTile(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: const Color(0xFFEF2A39)),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          Text(
            description,
            style: GoogleFonts.poppins(fontSize: 12, color: textColor.withOpacity(0.7)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(dynamic restaurant) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/restaurants'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 16),
        width: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                restaurant['image'] ?? 'https://images.ctfassets.net/trvmqu12jq2l/6FV4Opt7wUyR91t2FXyOIr/f32972fce10fc87585e831b334ea17ef/header.jpg?q=70&w=1208&h=1080&f=faces&fit=fill',
                height: 120,
                width: 160,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, size: 120, color: Colors.red),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant['name'] ?? 'Unnamed',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    restaurant['address'] ?? 'Unknown',
                    style: GoogleFonts.poppins(fontSize: 12, color: textColor.withOpacity(0.6)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDishCard(String name, String imageUrl, String description) {
    return Card(
      margin: const EdgeInsets.only(right: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 140,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(imageUrl, height: 100, width: 140, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(
                    description,
                    style: GoogleFonts.poppins(fontSize: 10, color: textColor.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroceryCard(Map<String, dynamic> grocery) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/groceries'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 16),
        width: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                grocery['image'] ?? 'https://via.placeholder.com/160x120', // Fallback image
                height: 120,
                width: 160,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, size: 120, color: Colors.red),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grocery['name'] ?? 'Unnamed',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '₦${grocery['price']?.toStringAsFixed(2) ?? 'N/A'}',
                    style: GoogleFonts.poppins(fontSize: 12, color: textColor.withOpacity(0.6)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestimonialCarousel() {
    final testimonials = [
      {'name': 'Aisha', 'text': 'Fastest delivery I’ve ever experienced!', 'rating': 5},
      {'name': 'Tunde', 'text': 'The jollof rice is to die for.', 'rating': 4},
      {'name': 'Chioma', 'text': 'Love supporting local businesses.', 'rating': 5},
    ];
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: testimonials.length,
        itemBuilder: (context, index) {
          final testimonial = testimonials[index];
          return Container(
            width: 250,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 6)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(testimonial['rating'] as int, (i) => const Icon(Icons.star, size: 16, color: Colors.amber)),
                ),
                const SizedBox(height: 8),
                Text(
                  '"${testimonial['text']}"',
                  style: GoogleFonts.poppins(fontSize: 14, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 4),
                Text(
                  '- ${testimonial['name']}',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFEF2A39),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.white),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.poppins(fontSize: 14, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildFooterButton(BuildContext context, String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFEF2A39),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label, style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
    );
  }
}

class SubtleTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    for (double i = 0; i < size.width; i += 100) {
      for (double j = 0; j < size.height; j += 100) {
        canvas.drawCircle(Offset(i, j), 4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}