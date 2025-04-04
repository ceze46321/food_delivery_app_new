import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../main.dart' show primaryColor, textColor, accentColor;
import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _password = '';
  String _role = 'customer'; // Default and only option
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _acceptTerms = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate() || !_acceptTerms) {
      if (!_acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please accept the terms and conditions'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    _formKey.currentState!.save();
    debugPrint(
        'Registering: name: $_name, email: $_email, password: $_password, role: $_role');
    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthProvider>(context, listen: false).register(
        _name,
        _email,
        _password,
        _role,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful'),
            backgroundColor: accentColor,
          ),
        );
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage;
        if (e.toString().contains('Registration failed:')) {
          try {
            final errorJson =
                json.decode(e.toString().split('Registration failed: ')[1]);
            if (errorJson['error'] != null &&
                errorJson['error']
                    .toString()
                    .contains('email already exists')) {
              errorMessage =
                  'This email is already registered. Please use a different email or log in.';
            } else {
              errorMessage = errorJson['error'] ?? 'Registration failed: $e';
            }
          } catch (_) {
            errorMessage = 'Registration failed: $e';
          }
        } else {
          errorMessage = 'An unexpected error occurred. Please try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () =>
                  ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          ),
        );
        setState(() => _isLoading = false);
        _animationController
            .reverse()
            .then((_) => _animationController.forward());
      }
    }
  }

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Terms and Conditions',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: textColor)),
        content: SingleChildScrollView(
          child: Text(
            '''
Welcome to Can I Buy You A Meal! By signing up, you agree to:

1. **Usage**: Use the app for lawful purposes only.
2. **Account**: Keep your credentials secure; you’re responsible for all activity.
3. **Roles**: Your role (Customer, Merchant, Dasher) defines your permissions.
4. **Payments**: Transactions are processed securely; refunds follow our policy.
5. **Liability**: We’re not liable for third-party service issues.

Full terms at canibuyyouameal.com/terms.
            ''',
            style: GoogleFonts.poppins(
                fontSize: 14, color: textColor.withOpacity(0.8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close',
                style: GoogleFonts.poppins(color: const Color(0xFFEF2A39))),
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
        title: Text('Privacy Policy',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: textColor)),
        content: SingleChildScrollView(
          child: Text(
            '''
At Can I Buy You A Meal, your privacy matters:

1. **Data Collection**: We collect name, email, and role for account creation.
2. **Usage**: Data is used to provide and improve services.
3. **Security**: Your info is encrypted and stored securely.
4. **Sharing**: Limited to service providers as needed.
5. **Rights**: Contact support@canibuyyouameal.com to manage your data.

Full policy at canibuyyouameal.com/privacy.
            ''',
            style: GoogleFonts.poppins(
                fontSize: 14, color: textColor.withOpacity(0.8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close',
                style: GoogleFonts.poppins(color: const Color(0xFFEF2A39))),
          ),
        ],
      ),
    );
  }

  void _showGoogleComingSoonPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Google Sign-Up Coming Soon!',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'This feature is under development. Please use your email and password to sign up for now.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: textColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xFFEF2A39),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Animate(
                          effects: const [
                            FadeEffect(duration: Duration(milliseconds: 800)),
                            ScaleEffect()
                          ],
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  'https://i.imgur.com/Qse69mz.png',
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: double.infinity,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF2A39)
                                          .withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.fastfood,
                                        size: 100, color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Can I Buy You A Meal',
                                style: GoogleFonts.poppins(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                  shadows: [
                                    Shadow(
                                        color: Colors.black.withOpacity(0.4),
                                        blurRadius: 8)
                                  ],
                                ),
                              ),
                              Text(
                                'Join the Flavor Journey',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: Colors.white.withOpacity(0.9),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Create Account',
                                    style: GoogleFonts.poppins(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Join CanIbuyYouAmeal Express today!',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: textColor.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  TextFormField(
                                    decoration: InputDecoration(
                                      labelText: 'Name',
                                      labelStyle: GoogleFonts.poppins(
                                          color: textColor.withOpacity(0.7)),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      prefixIcon: const Icon(Icons.person,
                                          color: Color(0xFFEF2A39)),
                                    ),
                                    validator: (value) => value!.isEmpty
                                        ? 'Name is required'
                                        : null,
                                    onSaved: (value) => _name = value!,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      labelStyle: GoogleFonts.poppins(
                                          color: textColor.withOpacity(0.7)),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      prefixIcon: const Icon(Icons.email,
                                          color: Color(0xFFEF2A39)),
                                    ),
                                    validator: (value) =>
                                        value!.isEmpty || !value.contains('@')
                                            ? 'Valid email required'
                                            : null,
                                    onSaved: (value) => _email = value!,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      labelStyle: GoogleFonts.poppins(
                                          color: textColor.withOpacity(0.7)),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      prefixIcon: const Icon(Icons.lock,
                                          color: Color(0xFFEF2A39)),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: const Color(0xFFEF2A39),
                                        ),
                                        onPressed: () => setState(() =>
                                            _obscurePassword =
                                                !_obscurePassword),
                                      ),
                                    ),
                                    obscureText: _obscurePassword,
                                    validator: (value) => value!.length < 6
                                        ? 'Password must be 6+ characters'
                                        : null,
                                    onSaved: (value) => _password = value!,
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                    value: _role,
                                    decoration: InputDecoration(
                                      labelText: 'Role',
                                      labelStyle: GoogleFonts.poppins(
                                          color: textColor.withOpacity(0.7)),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      prefixIcon: const Icon(
                                          Icons.person_outline,
                                          color: Color(0xFFEF2A39)),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'customer',
                                          child: Text('Customer')),
                                    ],
                                    onChanged:
                                        null, // Disable dropdown since there's only one option
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF2A39)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: const Color(0xFFEF2A39),
                                          width: 1),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Want to be a Dasher or Restaurant Owner?',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFFEF2A39),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Sign up as a customer first! You can upgrade your role to Dasher or Restaurant Owner from your profile later.',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: textColor.withOpacity(0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ).animate().fadeIn(duration: 600.ms),
                                  const SizedBox(height: 16),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Checkbox(
                                        value: _acceptTerms,
                                        onChanged: (value) => setState(
                                            () => _acceptTerms = value!),
                                        activeColor: const Color(0xFFEF2A39),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: _showTermsAndConditions,
                                          child: Text(
                                            'I agree to the Terms and Conditions',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: const Color(0xFFEF2A39),
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  _isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                              color: Color(0xFFEF2A39)))
                                      : SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: _register,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFFEF2A39),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12)),
                                              elevation: 4,
                                            ),
                                            child: Text(
                                              'Sign Up',
                                              style: GoogleFonts.poppins(
                                                fontSize: 18,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ).animate().slideY(
                                              begin: 0.2,
                                              end: 0.0,
                                              duration: 400.ms),
                                        ),
                                  const SizedBox(height: 20),
                                  Center(
                                    child: Text(
                                      'or',
                                      style: GoogleFonts.poppins(
                                          color: textColor.withOpacity(0.7)),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  GestureDetector(
                                    onTap: _showGoogleComingSoonPopup,
                                    child: Container(
                                      width: double.infinity,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: const Color(0xFFEF2A39),
                                            width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.2),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Sign Up with Google',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            color: const Color(0xFFEF2A39),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ).animate().slideY(
                                      begin: 0.2, end: 0.0, duration: 400.ms),
                                  const SizedBox(height: 16),
                                  Center(
                                    child: TextButton(
                                      onPressed: () =>
                                          Navigator.pushReplacementNamed(
                                              context, '/'),
                                      child: Text(
                                        'Already have an account? Login',
                                        style: GoogleFonts.poppins(
                                            color: const Color(0xFFEF2A39)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 24.0),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _showTermsAndConditions,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF2A39).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFEF2A39), width: 1),
                        ),
                        child: Text(
                          'Terms',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFFEF2A39),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTap: _showPrivacyPolicy,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF2A39).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFEF2A39), width: 1),
                        ),
                        child: Text(
                          'Privacy',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFFEF2A39),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
                  ],
                ),
              ),
            ],
          ),
        ],
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
