import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../auth_provider.dart';
import '../main.dart' show primaryColor, textColor, accentColor, secondaryColor;
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'https://www.googleapis.com/auth/userinfo.profile'],
  );

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
    _checkExistingToken();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _checkExistingToken() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.loadToken();
    if (authProvider.token != null && mounted) {
      debugPrint(
          'Existing token found: ${authProvider.token}, Role: ${authProvider.role}');
      if (authProvider.role == 'restaurant_owner') {
        debugPrint('Navigating to /restaurant-owner');
        Navigator.pushReplacementNamed(context, '/restaurant-owner');
      } else {
        debugPrint('Navigating to /home');
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final response = await authProvider.login(_email, _password);
        debugPrint('Login Response: $response');
        final role = response['user']['role'] ?? 'customer';
        final token = response['token'];
        if (token != null) {
          await ApiService().setToken(token);
          debugPrint('Token set in ApiService: $token');
        } else {
          debugPrint('No token in response');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome, $role!', style: GoogleFonts.poppins()),
              backgroundColor: accentColor,
              duration: const Duration(seconds: 2),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 500));
          if (role == 'restaurant_owner') {
            debugPrint('Navigating to /restaurant-owner for role: $role');
            Navigator.pushReplacementNamed(context, '/restaurant-owner');
          } else {
            debugPrint('Navigating to /home for role: $role');
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      } catch (e) {
        debugPrint('Login error: $e');
        String errorMessage;
        if (e.toString().contains('401') || e.toString().contains('invalid')) {
          errorMessage = 'Invalid email or password. Please try again.';
        } else if (e.toString().contains('network') ||
            e.toString().contains('timeout')) {
          errorMessage =
              'Network error. Please check your connection and try again.';
        } else {
          errorMessage =
              'An unexpected error occurred. Please try again later.';
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
          setState(() => _isLoading = false);
          _animationController
              .reverse()
              .then((_) => _animationController.forward());
        }
      }
    }
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
            Image.network(
              'https://static-00.iconduck.com/assets.00/google-icon-2048x673-w3o7skkh.png',
              height: 60,
              errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.g_mobiledata,
                  size: 60,
                  color: Color(0xFFEF2A39)),
            ),
            const SizedBox(height: 16),
            Text(
              'Google Sign-In Coming Soon!',
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'This feature is under development. Please use your email and password to log in for now.',
              style: GoogleFonts.poppins(
                  fontSize: 14, color: textColor.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: const Color(0xFFEF2A39),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
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
            'Welcome to Can I Buy You A Meal Express! By signing in, you agree to:\n\n'
            '1. **Usage**: Use the app for food orders, logistics, and groceries.\n'
            '2. **Privacy**: We protect your data—see our policy at canibuyyouameal.com/privacy.\n'
            '3. **Roles**: Choose Customer, Merchant, or Dasher roles.\n'
            '4. **Payments**: Secure transactions, no refunds after delivery.\n'
            '5. **Support**: Contact support@canibuyyouameal.com.\n\n'
            'Full terms at canibuyyouameal.com/terms.',
            style: GoogleFonts.poppins(
                fontSize: 14, color: textColor.withOpacity(0.8)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Got it',
                  style: GoogleFonts.poppins(color: primaryColor))),
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
            'At Can I Buy You A Meal Express, your privacy matters:\n\n'
            '1. **Data Collection**: Email, name, and location for service delivery.\n'
            '2. **Usage**: Data improves your experience.\n'
            '3. **Security**: Encrypted storage and secure payments.\n'
            '4. **Sharing**: Only with necessary partners.\n'
            '5. **Rights**: Opt-out or delete data via support@canibuyyouameal.com.\n\n'
            'Full policy at canibuyyouameal.com/privacy.',
            style: GoogleFonts.poppins(
                fontSize: 14, color: textColor.withOpacity(0.8)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Understood',
                  style: GoogleFonts.poppins(color: primaryColor))),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final TextEditingController emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reset Password',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your email to reset your password.',
                style: GoogleFonts.poppins(fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.email),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Reset link sent (coming soon)!',
                        style: GoogleFonts.poppins()),
                    backgroundColor: accentColor),
              );
              Navigator.pop(context);
            },
            child:
                Text('Send', style: GoogleFonts.poppins(color: primaryColor)),
          ),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildBenefitIcon(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(text,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
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
                  Colors.white.withOpacity(0.95)
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: SubtleTexturePainter())),
          Column(
            children: [
              Expanded(
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 20, horizontal: 10),
                          decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16)),
                          child: Animate(
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
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      width: double.infinity,
                                      height: 200,
                                      decoration: BoxDecoration(
                                          color: const Color(0xFFEF2A39)
                                              .withOpacity(0.8),
                                          borderRadius:
                                              BorderRadius.circular(16)),
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
                                  'Fresh Nigerian Flavors',
                                  style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      color: Colors.white.withOpacity(0.9),
                                      fontStyle: FontStyle.italic),
                                ),
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  child: Text(
                                    'Savor the taste of Nigeria with fast, delicious food delivery!',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.8)),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 60,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: [
                                      _buildBenefitIcon(
                                          Icons.local_dining, 'Local Flavors'),
                                      const SizedBox(width: 16),
                                      _buildBenefitIcon(
                                          Icons.flash_on, 'Fast Delivery'),
                                      const SizedBox(width: 16),
                                      _buildBenefitIcon(
                                          Icons.star, 'Top Rated'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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
                                    offset: const Offset(0, 8))
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Welcome Back',
                                      style: GoogleFonts.poppins(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: textColor)),
                                  const SizedBox(height: 8),
                                  Text('Sign in to continue',
                                      style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: textColor.withOpacity(0.7))),
                                  const SizedBox(height: 24),
                                  TextFormField(
                                    focusNode: _emailFocus,
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      hintText: 'you@example.com',
                                      labelStyle: GoogleFonts.poppins(
                                          color: textColor.withOpacity(0.7)),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide.none),
                                      prefixIcon: const Icon(Icons.email,
                                          color: Color(0xFFEF2A39)),
                                    ),
                                    validator: (value) =>
                                        value!.isEmpty || !value.contains('@')
                                            ? 'Valid email required'
                                            : null,
                                    onSaved: (value) => _email = value!,
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) =>
                                        FocusScope.of(context)
                                            .requestFocus(_passwordFocus),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    focusNode: _passwordFocus,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      labelStyle: GoogleFonts.poppins(
                                          color: textColor.withOpacity(0.7)),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide.none),
                                      prefixIcon: const Icon(Icons.lock,
                                          color: Color(0xFFEF2A39)),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: const Color(0xFFEF2A39)),
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
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _submit(),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton(
                                        onPressed: _showForgotPasswordDialog,
                                        child: Text('Forgot Password?',
                                            style: GoogleFonts.poppins(
                                                color: const Color(0xFFEF2A39),
                                                fontSize: 12)),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pushNamed(
                                            context, '/signup'),
                                        child: Text('Sign Up',
                                            style: GoogleFonts.poppins(
                                                color: const Color(0xFFEF2A39),
                                                fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  _isLoading
                                      ? const Center(
                                          child: SpinKitThreeBounce(
                                              color: Color(0xFFEF2A39),
                                              size: 30))
                                      : ElevatedButton(
                                          onPressed: _submit,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFFEF2A39),
                                            minimumSize:
                                                const Size(double.infinity, 56),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            elevation: 4,
                                          ),
                                          child: Text('Sign In',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 18,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600)),
                                        ).animate().slideY(
                                          begin: 0.2,
                                          end: 0.0,
                                          duration: 400.ms),
                                  const SizedBox(height: 20),
                                  Center(
                                      child: Text('or',
                                          style: GoogleFonts.poppins(
                                              color:
                                                  textColor.withOpacity(0.7)))),
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
                                              color:
                                                  Colors.grey.withOpacity(0.2),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4))
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Continue with Google',
                                          style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              color: const Color(0xFFEF2A39),
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                  ).animate().slideY(
                                      begin: 0.2, end: 0.0, duration: 400.ms),
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
                        child: Text('Terms',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFFEF2A39),
                                fontWeight: FontWeight.w600)),
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
                        child: Text('Privacy',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFFEF2A39),
                                fontWeight: FontWeight.w600)),
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
