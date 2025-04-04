import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'core/deep_link_handler.dart'; // Import DeepLinkHandler
import 'auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart' as home; // Alias to avoid conflicts
import 'screens/add_restaurant_screen.dart';
import 'screens/restaurant_screen.dart';
import 'screens/restaurant_profile_screen.dart';
import 'screens/restaurant_owner_screen.dart';
import 'screens/order_screen.dart';
import 'screens/my_groceries_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/logistics_screen.dart'; // Added missing import for LogisticsScreen
import 'screens/cart_screen.dart';
import 'screens/grocery_screen.dart';
import 'screens/dasher_screen.dart';
import 'screens/customer_review_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_screen.dart';

const primaryColor = Color(0xFFFF7043); // Warm Coral
const textColor = Color(0xFF3E2723); // Deep Brown
const accentColor = Color(0xFFEF2A39); // DoorDash red
const secondaryColor = Color(0xFFFFCA28); // Soft Gold

Future<void> main() async {
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('Dotenv loaded successfully');
  } catch (e) {
    debugPrint('Error loading .env: $e');
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            debugPrint('Creating AuthProvider');
            final authProvider = AuthProvider();
            authProvider.loadToken();
            return authProvider;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('Building MyApp');
    return DeepLinkHandler(
      child: MaterialApp(
        title: 'CanIbuyYouAmeal Express',
        theme: ThemeData(
          primaryColor: primaryColor,
          scaffoldBackgroundColor: Colors.grey[100],
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.blue,
            accentColor: accentColor,
          ).copyWith(secondary: secondaryColor),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: textColor, fontFamily: 'Poppins'),
            titleLarge: TextStyle(
                color: textColor,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold),
            headlineSmall: TextStyle(
                color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
            labelLarge: TextStyle(color: Colors.white, fontSize: 16),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontFamily: 'Poppins'),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            titleTextStyle: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryColor),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) {
            debugPrint('Navigating to SplashScreen');
            return const SplashScreen();
          },
          '/login': (context) {
            debugPrint('Navigating to LoginScreen');
            return const LoginScreen();
          },
          '/signup': (context) => const SignUpScreen(),
          '/home': (context) {
            debugPrint('Navigating to HomeScreen');
            return const home.HomeScreen();
          },
          '/add-restaurant': (context) => const AddRestaurantScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/orders': (context) {
            final args = ModalRoute.of(context)?.settings.arguments
                as Map<String, dynamic>?;
            final orderId = args?['orderId'] as String?;
            final status = args?['status'] as String?;
            debugPrint(
                'Navigating to OrderScreen with orderId: $orderId, status: $status');
            return OrderScreen(orderId: orderId, initialStatus: status);
          },
          '/my-groceries': (context) {
            final args = ModalRoute.of(context)?.settings.arguments
                as Map<String, dynamic>?;
            final groceryId = args?['groceryId'] as String?;
            final status = args?['status'] as String?;
            debugPrint(
                'Navigating to MyGroceriesScreen with groceryId: $groceryId, status: $status');
            return const MyGroceriesScreen();
          },
          '/dashers': (context) => const DasherScreen(),
          '/logistics': (context) => const LogisticsScreen(),
          '/groceries': (context) {
            final args = ModalRoute.of(context)?.settings.arguments
                as Map<String, dynamic>?;
            final groceryId = args?['groceryId'] as String?;
            final status = args?['status'] as String?;
            debugPrint(
                'Navigating to GroceryScreen with groceryId: $groceryId, status: $status');
            return const GroceryScreen();
          },
          '/restaurants': (context) => const RestaurantScreen(),
          '/restaurant-profile': (context) => const RestaurantProfileScreen(
                restaurant: {
                  'image': 'https://via.placeholder.com/300',
                  'tags': {'name': 'Test Restaurant', 'address': '123 Test St'},
                  'lat': 6.5,
                  'lon': 3.3,
                },
              ),
          '/restaurant-owner': (context) => const RestaurantOwnerScreen(),
          '/cart': (context) {
            debugPrint('Navigating to CartScreen');
            return const CartScreen();
          },
          '/reviews': (context) {
            debugPrint('Navigating to CustomerReviewScreen');
            return const CustomerReviewScreen();
          },
          '/admin-login': (context) {
            debugPrint('Navigating to AdminLoginScreen');
            return const AdminLoginScreen();
          },
          '/admin': (context) {
            debugPrint('Navigating to AdminScreen');
            return const AdminScreen();
          },
        },
        onUnknownRoute: (settings) {
          debugPrint('Unknown route: ${settings.name}');
          return MaterialPageRoute(
              builder: (_) =>
                  const Scaffold(body: Center(child: Text('Route not found'))));
        },
      ),
    );
  }
}
