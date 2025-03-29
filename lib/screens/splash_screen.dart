import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../main.dart' show textColor;

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/login');
    });

    // DoorDash-inspired colors
    const Color doorDashRed = Color(0xFFEF2A39);
    const Color doorDashLightGrey = Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: doorDashLightGrey, // Light grey background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.delivery_dining, // More relevant to food delivery
              size: 100,
              color: doorDashRed, // Red icon
            ),
            const SizedBox(height: 16),
            Text(
              'CanIBuyYouAMeal', // Your app name
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w600, // Slightly less bold than w700
                color: textColor, // Primary text color from main.dart
                letterSpacing: 1.2, // Slight spacing for elegance
              ),
            ),
            const SizedBox(height: 24),
            SpinKitFadingCircle(
              color: doorDashRed, // Red spinner
              size: 50.0,
            ),
          ],
        ),
      ),
    );
  }
}