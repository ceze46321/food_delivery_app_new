import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../main.dart' show textColor, accentColor;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'create_grocery_product_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
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
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
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
      debugPrint('Error fetching restaurants: $e');
      String errorMessage;
      if (e.toString().contains('401') ||
          e.toString().contains('unauthorized')) {
        errorMessage = 'Authentication failed. Please log in again.';
      } else if (e.toString().contains('network') ||
          e.toString().contains('timeout')) {
        errorMessage =
            'Network error. Please check your connection and try again.';
      } else {
        errorMessage = 'Failed to load restaurants. Please try again later.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
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
          groceries = fetchedGroceries
              .expand((grocery) {
                final items = grocery['items'] as List<dynamic>? ?? [];
                return items.map((item) => {
                      'id': grocery['id']?.toString() ?? 'unknown',
                      'name': item['name']?.toString() ?? 'Unnamed',
                      'price': (item['price'] as num?)?.toDouble() ?? 0.0,
                      'image': item['image']?.toString(),
                    });
              })
              .take(5)
              .toList();
          isLoadingGroceries = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching groceries: $e');
      String errorMessage;
      if (e.toString().contains('401') ||
          e.toString().contains('unauthorized')) {
        errorMessage = 'Authentication failed. Please log in again.';
      } else if (e.toString().contains('network') ||
          e.toString().contains('timeout')) {
        errorMessage =
            'Network error. Please check your connection and try again.';
      } else {
        errorMessage = 'Failed to load groceries. Please try again later.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
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
      6: '/admin-login',
    };
    if (index != 0 && routes.containsKey(index)) {
      Navigator.pushReplacementNamed(context, routes[index]!);
    }
  }

  void _showTermsAndConditions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: Colors.white,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Terms and Conditions',
                    style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFFEF2A39)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to CanIbuyYouAmeal Express! By using this app, you agree to the following terms:',
                        style: GoogleFonts.poppins(
                            fontSize: 16, color: textColor.withOpacity(0.9)),
                      ),
                      const SizedBox(height: 12),
                      _buildPolicyItem(
                          '1. Usage', 'Use the app for lawful purposes only.'),
                      _buildPolicyItem('2. Account',
                          'Keep your credentials secure; you’re responsible for all activity.'),
                      _buildPolicyItem('3. Roles',
                          'Your role (Customer, Merchant, Dasher) defines your permissions.'),
                      _buildPolicyItem('4. Payments',
                          'Transactions are processed securely; refunds follow our policy.'),
                      _buildPolicyItem('5. Liability',
                          'We’re not liable for third-party service issues.'),
                      const SizedBox(height: 16),
                      Text(
                        'For full terms, visit canibuyyouameal.com/terms.',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFFEF2A39),
                            decoration: TextDecoration.underline),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF2A39),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Got It',
                    style:
                        GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicy() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: Colors.white,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Privacy Policy',
                    style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFFEF2A39)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'At CanIbuyYouAmeal Express, your privacy is our priority:',
                        style: GoogleFonts.poppins(
                            fontSize: 16, color: textColor.withOpacity(0.9)),
                      ),
                      const SizedBox(height: 12),
                      _buildPolicyItem('1. Data Collection',
                          'We collect name, email, and role for account creation.'),
                      _buildPolicyItem('2. Usage',
                          'Data is used to provide and improve services.'),
                      _buildPolicyItem('3. Security',
                          'Your info is encrypted and stored securely.'),
                      _buildPolicyItem('4. Sharing',
                          'Limited to service providers as needed.'),
                      _buildPolicyItem('5. Rights',
                          'Contact support@canibuyyouameal.com to manage your data.'),
                      const SizedBox(height: 16),
                      Text(
                        'For full policy, visit canibuyyouameal.com/privacy.',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFFEF2A39),
                            decoration: TextDecoration.underline),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF2A39),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Understood',
                    style:
                        GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicyItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ',
              style: GoogleFonts.poppins(
                  fontSize: 16, color: const Color(0xFFEF2A39))),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                      text: '$title: ',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  TextSpan(
                      text: description,
                      style: GoogleFonts.poppins(
                          fontSize: 16, color: textColor.withOpacity(0.8))),
                ],
              ),
            ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

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
          Positioned.fill(child: CustomPaint(painter: SubtleTexturePainter())),
          Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: isLargeScreen ? 350.0 : 300.0,
                      floating: false,
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        titlePadding:
                            const EdgeInsets.only(left: 16, bottom: 16),
                        title: Text(
                          'Welcome, $userName!',
                          style: GoogleFonts.poppins(
                            fontSize: isLargeScreen ? 32 : 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 4,
                                  offset: const Offset(2, 2))
                            ],
                          ),
                        ),
                        background: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(16)),
                          child: Image.network(
                            'https://i.imgur.com/Qse69mz.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: const Color(0xFFEF2A39).withOpacity(0.8),
                              child: const Icon(Icons.fastfood,
                                  size: 100, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      backgroundColor: const Color(0xFFEF2A39),
                      elevation: 8,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.person, color: Colors.white),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/dashboard'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.account_circle,
                              color: Colors.white),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/profile'),
                        ),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Padding(
                          padding: EdgeInsets.all(isLargeScreen ? 30.0 : 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Can I Buy You A Meal',
                                style: GoogleFonts.poppins(
                                  fontSize: isLargeScreen ? 40 : 36,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                'Your Nigerian Food Adventure Awaits',
                                style: GoogleFonts.poppins(
                                  fontSize: isLargeScreen ? 20 : 18,
                                  color: textColor.withOpacity(0.8),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Role: $userRole',
                                style: GoogleFonts.poppins(
                                    fontSize: isLargeScreen ? 16 : 14,
                                    color: Colors.white),
                              ),
                              const SizedBox(height: 30),
                              Text(
                                'Why Choose Us?',
                                style: GoogleFonts.poppins(
                                    fontSize: isLargeScreen ? 26 : 24,
                                    fontWeight: FontWeight.bold,
                                    color: textColor),
                              ),
                              const SizedBox(height: 16),
                              StaggeredGrid.count(
                                crossAxisCount: isLargeScreen ? 4 : 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                children: [
                                  _buildFeatureTile(
                                      Icons.local_dining,
                                      'Authentic Taste',
                                      'Savor Nigeria’s finest dishes.'),
                                  _buildFeatureTile(
                                      Icons.flash_on,
                                      'Fast Delivery',
                                      'Food at your door in minutes.'),
                                  _buildFeatureTile(
                                      Icons.verified,
                                      'Trusted Service',
                                      'Reliable every time.'),
                                  _buildFeatureTile(Icons.people, 'Community',
                                      'Support local vendors.'),
                                ],
                              ),
                              const SizedBox(height: 30),
                              Text(
                                'Featured Restaurants',
                                style: GoogleFonts.poppins(
                                    fontSize: isLargeScreen ? 26 : 24,
                                    fontWeight: FontWeight.bold,
                                    color: textColor),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: isLargeScreen ? 250 : 220,
                                child: isLoadingRestaurants
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Color(0xFFEF2A39))))
                                    : restaurants.isEmpty
                                        ? Center(
                                            child: Text('No restaurants yet',
                                                style: GoogleFonts.poppins(
                                                    color: textColor
                                                        .withOpacity(0.7))))
                                        : ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: restaurants.length,
                                            itemBuilder: (context, index) =>
                                                _buildRestaurantCard(
                                                    restaurants[index],
                                                    isLargeScreen),
                                          ),
                              ),
                              const SizedBox(height: 30),
                              Text(
                                'Top Dishes',
                                style: GoogleFonts.poppins(
                                    fontSize: isLargeScreen ? 26 : 24,
                                    fontWeight: FontWeight.bold,
                                    color: textColor),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: isLargeScreen ? 200 : 180,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    _buildDishCard(
                                        'Jollof Rice',
                                        'https://images.ctfassets.net/trvmqu12jq2l/6FV4Opt7wUyR91t2FXyOIr/f32972fce10fc87585e831b334ea17ef/header.jpg?q=70&w=1208&h=1080&f=faces&fit=fill',
                                        'Spicy & Savory',
                                        isLargeScreen),
                                    _buildDishCard(
                                        'Pounded Yam',
                                        'https://s3-media0.fl.yelpcdn.com/bphoto/4x8-Rjfell2DBqbrHSbCsg/348s.jpg',
                                        'With Egusi Soup',
                                        isLargeScreen),
                                    _buildDishCard(
                                        'Suya',
                                        'https://assets.simpleviewinc.com/grandrapidsdamsub/image/upload/c_fill,f_jpg,g_xy_center,h_1200,q_95,w_900,x_4752,y_3168/v1/cms_resources/clients/grandrapids/042_3_16212_jpeg_af93ea51-3de2-404e-b5c4-21aa68737022.jpg',
                                        'Grilled Perfection',
                                        isLargeScreen),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 30),
                              Text(
                                'Featured Groceries',
                                style: GoogleFonts.poppins(
                                    fontSize: isLargeScreen ? 26 : 24,
                                    fontWeight: FontWeight.bold,
                                    color: textColor),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: isLargeScreen ? 230 : 200,
                                child: isLoadingGroceries
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Color(0xFFEF2A39))))
                                    : groceries.isEmpty
                                        ? Center(
                                            child: Text('No groceries yet',
                                                style: GoogleFonts.poppins(
                                                    color: textColor
                                                        .withOpacity(0.7))))
                                        : ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: groceries.length,
                                            itemBuilder: (context, index) =>
                                                _buildGroceryCard(
                                                    groceries[index],
                                                    isLargeScreen),
                                          ),
                              ),
                              const SizedBox(height: 30),
                              Text(
                                'What Our Users Say',
                                style: GoogleFonts.poppins(
                                    fontSize: isLargeScreen ? 26 : 24,
                                    fontWeight: FontWeight.bold,
                                    color: textColor),
                              ),
                              const SizedBox(height: 16),
                              _buildTestimonialCarousel(isLargeScreen),
                              const SizedBox(height: 16),
                              Center(
                                child: ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/reviews'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEF2A39),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: isLargeScreen ? 32 : 24,
                                        vertical: isLargeScreen ? 16 : 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  child: Text(
                                    'See All Reviews',
                                    style: GoogleFonts.poppins(
                                        fontSize: isLargeScreen ? 18 : 16,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                              Text(
                                'Quick Actions',
                                style: GoogleFonts.poppins(
                                    fontSize: isLargeScreen ? 26 : 24,
                                    fontWeight: FontWeight.bold,
                                    color: textColor),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: isLargeScreen ? 20 : 16,
                                runSpacing: isLargeScreen ? 20 : 16,
                                alignment: WrapAlignment.center,
                                children: [
                                  _buildActionButton(
                                      context,
                                      'Order Now',
                                      Icons.fastfood,
                                      () => Navigator.pushNamed(
                                          context, '/restaurants'),
                                      isLargeScreen),
                                  _buildActionButton(
                                      context,
                                      'Track Order',
                                      Icons.local_shipping,
                                      () => Navigator.pushNamed(
                                          context, '/orders'),
                                      isLargeScreen),
                                  _buildActionButton(
                                      context,
                                      'Groceries',
                                      Icons.local_grocery_store,
                                      () => Navigator.pushNamed(
                                          context, '/groceries'),
                                      isLargeScreen),
                                  if (auth.isRestaurantOwner)
                                    _buildActionButton(
                                        context,
                                        'Create Grocery Product',
                                        Icons.add_circle, () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const CreateGroceryProductScreen()));
                                    }, isLargeScreen),
                                  if (userRole == 'owner' ||
                                      userRole == 'restaurant_owner')
                                    _buildActionButton(
                                        context,
                                        'Add Restaurant',
                                        Icons.store,
                                        () => Navigator.pushNamed(
                                                context, '/add-restaurant')
                                            .then((_) => _fetchRestaurants()),
                                        isLargeScreen),
                                  if (userRole == 'dasher')
                                    _buildActionButton(
                                        context,
                                        'Deliver',
                                        Icons.directions_bike,
                                        () => Navigator.pushNamed(
                                            context, '/dashers'),
                                        isLargeScreen),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        color: const Color(0xFFEF2A39).withOpacity(0.1),
                        padding: EdgeInsets.all(isLargeScreen ? 30.0 : 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Explore More',
                              style: GoogleFonts.poppins(
                                fontSize: isLargeScreen ? 28 : 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 20),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: isLargeScreen
                                  ? 3
                                  : screenWidth < 400
                                      ? 1
                                      : 2,
                              crossAxisSpacing: isLargeScreen ? 20 : 16,
                              mainAxisSpacing: isLargeScreen ? 20 : 16,
                              childAspectRatio: isLargeScreen ? 1.2 : 1.5,
                              children: [
                                _buildExploreCard(
                                  context,
                                  'Restaurants',
                                  'Discover the best Nigerian eateries near you.',
                                  Icons.restaurant,
                                  Colors.orangeAccent,
                                  () => Navigator.pushNamed(
                                      context, '/restaurants'),
                                  isLargeScreen,
                                ),
                                _buildExploreCard(
                                  context,
                                  'Orders',
                                  'Track your food and grocery orders in real-time.',
                                  Icons.shopping_cart,
                                  Colors.blueAccent,
                                  () => Navigator.pushNamed(context, '/orders'),
                                  isLargeScreen,
                                ),
                                _buildExploreCard(
                                  context,
                                  'Logistics',
                                  'Join our delivery team or track logistics.',
                                  Icons.local_shipping,
                                  Colors.greenAccent,
                                  () => Navigator.pushNamed(
                                      context, '/logistics'),
                                  isLargeScreen,
                                ),
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
                padding: EdgeInsets.symmetric(
                  vertical: screenWidth > 600 ? 20.0 : 12.0,
                  horizontal: screenWidth > 600 ? 32.0 : 16.0,
                ),
                color: Colors.white.withOpacity(0.9),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: screenWidth > 600
                      ? 40
                      : screenWidth > 400
                          ? 20
                          : 10,
                  runSpacing: 10,
                  children: [
                    GestureDetector(
                      onTap: _showTermsAndConditions,
                      child: Container(
                        constraints: BoxConstraints(
                          minWidth: screenWidth < 400 ? 100 : 120,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth > 600 ? 16 : 12,
                          vertical: screenWidth > 600 ? 10 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF2A39).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFEF2A39),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Terms',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFEF2A39),
                            fontSize: screenWidth > 600
                                ? 16
                                : screenWidth > 400
                                    ? 14
                                    : 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _showPrivacyPolicy,
                      child: Container(
                        constraints: BoxConstraints(
                          minWidth: screenWidth < 400 ? 100 : 120,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth > 600 ? 16 : 12,
                          vertical: screenWidth > 600 ? 10 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF2A39).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFEF2A39),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Privacy',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFEF2A39),
                            fontSize: screenWidth > 600
                                ? 16
                                : screenWidth > 400
                                    ? 14
                                    : 12,
                            fontWeight: FontWeight.w600,
                          ),
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
          BottomNavigationBarItem(
              icon: Icon(Icons.restaurant), label: 'Restaurants'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Owner'),
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_bike), label: 'Dasher'),
          BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFEF2A39),
        unselectedItemColor: textColor.withOpacity(0.6),
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        backgroundColor: Colors.white,
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
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: const Color(0xFFEF2A39)),
          const SizedBox(height: 8),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          Text(
            description,
            style: GoogleFonts.poppins(
                fontSize: 12, color: textColor.withOpacity(0.7)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(dynamic restaurant, bool isLargeScreen) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/restaurants'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 16),
        width: isLargeScreen ? 200 : 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                restaurant['image'] ??
                    'https://images.ctfassets.net/trvmqu12jq2l/6FV4Opt7wUyR91t2FXyOIr/f32972fce10fc87585e831b334ea17ef/header.jpg?q=70&w=1208&h=1080&f=faces&fit=fill',
                height: isLargeScreen ? 140 : 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error, size: 120, color: Colors.red),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant['name'] ?? 'Unnamed',
                    style: GoogleFonts.poppins(
                        fontSize: isLargeScreen ? 18 : 16,
                        fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    restaurant['address'] ?? 'Unknown',
                    style: GoogleFonts.poppins(
                        fontSize: isLargeScreen ? 14 : 12,
                        color: textColor.withOpacity(0.6)),
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

  Widget _buildDishCard(
      String name, String imageUrl, String description, bool isLargeScreen) {
    return Card(
      margin: const EdgeInsets.only(right: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: isLargeScreen ? 160 : 140,
        child: Column(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                imageUrl,
                height: isLargeScreen ? 120 : 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error, size: 100, color: Colors.red),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(name,
                      style: GoogleFonts.poppins(
                          fontSize: isLargeScreen ? 16 : 14,
                          fontWeight: FontWeight.bold)),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                        fontSize: isLargeScreen ? 12 : 10,
                        color: textColor.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroceryCard(Map<String, dynamic> grocery, bool isLargeScreen) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/groceries'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 16),
        width: isLargeScreen ? 200 : 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                grocery['image'] ?? 'https://via.placeholder.com/160x120',
                height: isLargeScreen ? 140 : 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error, size: 120, color: Colors.red),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grocery['name'] ?? 'Unnamed',
                    style: GoogleFonts.poppins(
                        fontSize: isLargeScreen ? 18 : 16,
                        fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '₦${grocery['price']?.toStringAsFixed(2) ?? 'N/A'}',
                    style: GoogleFonts.poppins(
                        fontSize: isLargeScreen ? 14 : 12,
                        color: textColor.withOpacity(0.6)),
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

  Widget _buildTestimonialCarousel(bool isLargeScreen) {
    final testimonials = [
      {
        'name': 'Aisha',
        'text': 'Fastest delivery I’ve ever experienced!',
        'rating': 5
      },
      {'name': 'Tunde', 'text': 'The jollof rice is to die for.', 'rating': 4},
      {
        'name': 'Chioma',
        'text': 'Love supporting local businesses.',
        'rating': 5
      },
    ];
    return SizedBox(
      height: isLargeScreen ? 140 : 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: testimonials.length,
        itemBuilder: (context, index) {
          final testimonial = testimonials[index];
          return Container(
            width: isLargeScreen ? 300 : 250,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 6)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(
                      testimonial['rating'] as int,
                      (i) => const Icon(Icons.star,
                          size: 16, color: Colors.amber)),
                ),
                const SizedBox(height: 8),
                Text(
                  '"${testimonial['text']}"',
                  style: GoogleFonts.poppins(
                      fontSize: isLargeScreen ? 16 : 14,
                      fontStyle: FontStyle.italic),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '- ${testimonial['name']}',
                  style: GoogleFonts.poppins(
                      fontSize: isLargeScreen ? 14 : 12,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon,
      VoidCallback onPressed, bool isLargeScreen) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFEF2A39),
        padding: EdgeInsets.symmetric(
            vertical: isLargeScreen ? 20 : 16,
            horizontal: isLargeScreen ? 24 : 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      child: Column(
        children: [
          Icon(icon, size: isLargeScreen ? 36 : 32, color: Colors.white),
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: isLargeScreen ? 16 : 14, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildExploreCard(
      BuildContext context,
      String title,
      String description,
      IconData icon,
      Color color,
      VoidCallback onTap,
      bool isLargeScreen) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: isLargeScreen ? 30 : 24,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, size: isLargeScreen ? 32 : 24, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                  fontSize: isLargeScreen ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.poppins(
                  fontSize: isLargeScreen ? 14 : 12,
                  color: textColor.withOpacity(0.7)),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
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
