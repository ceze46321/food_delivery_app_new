import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../auth_provider.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  static const Color doorDashRed = Color(0xFFEF2A39);
  static const Color doorDashGrey = Color(0xFF757575);

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
    debugPrint('AdminLoginScreen initialized');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _animationController.dispose();
    debugPrint('AdminLoginScreen disposed');
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    debugPrint('Starting login with email: ${_emailController.text}');

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      debugPrint('Before adminLogin, isAdmin: ${authProvider.isAdmin}');
      await authProvider.adminLogin(
          _emailController.text, _passwordController.text);
      debugPrint('After adminLogin, isAdmin: ${authProvider.isAdmin}');

      if (authProvider.isAdmin) {
        debugPrint('isAdmin is true, redirecting to /admin');
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        debugPrint('isAdmin is false, logging out and showing error');
        await authProvider.logout();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Access Denied: This is not an admin account.',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 2),
            ),
          );
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            debugPrint('Redirecting to /login');
            Navigator.pushReplacementNamed(context, '/login');
          }
        }
      }
    } catch (e) {
      debugPrint('Login failed with error: $e');
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Login Failed: $_errorMessage',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        debugPrint('Login process completed, _isLoading: $_isLoading');
      }
    }
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
                prefixIcon: const Icon(Icons.email, color: doorDashRed),
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
                  backgroundColor: doorDashRed,
                ),
              );
              Navigator.pop(context);
            },
            child: Text('Send', style: GoogleFonts.poppins(color: doorDashRed)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Cancel', style: GoogleFonts.poppins(color: doorDashGrey)),
          ),
        ],
      ),
    );
  }

  void _showAdminTerms() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Admin Terms',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: doorDashRed)),
        content: SingleChildScrollView(
          child: Text(
            'As an admin, you agree to:\n\n'
            '1. **Access**: Use admin tools responsibly.\n'
            '2. **Security**: Protect your credentials.\n'
            '3. **Actions**: Manage users, pricing, and orders per policy.\n'
            '4. **Support**: Contact support@canibuyyouameal.com for issues.\n\n'
            'Full terms at canibuyyouameal.com/admin-terms.',
            style: GoogleFonts.poppins(fontSize: 14, color: doorDashGrey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Accept', style: GoogleFonts.poppins(color: doorDashRed)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive design
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360 || screenHeight < 600;

    return Scaffold(
      resizeToAvoidBottomInset: true, // Allow resizing when keyboard appears
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  doorDashRed,
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
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.06, // 6% of screen width
                    vertical: screenHeight * 0.02, // 2% of screen height
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Header Section
                          Container(
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.03,
                              horizontal: screenWidth * 0.03,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Animate(
                              effects: const [
                                FadeEffect(
                                    duration: Duration(milliseconds: 800)),
                                ScaleEffect(),
                              ],
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.admin_panel_settings,
                                    size: isSmallScreen
                                        ? 80
                                        : screenWidth *
                                            0.2, // 20% of screen width
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Admin Portal',
                                    style: GoogleFonts.poppins(
                                      fontSize: isSmallScreen
                                          ? 28
                                          : screenWidth *
                                              0.09, // Responsive font size
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.4),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    textScaler: const TextScaler.linear(1.0),
                                  ),
                                  Text(
                                    'Can I Buy You A Meal Express',
                                    style: GoogleFonts.poppins(
                                      fontSize: isSmallScreen
                                          ? 14
                                          : screenWidth * 0.045,
                                      color: Colors.white.withOpacity(0.9),
                                      fontStyle: FontStyle.italic,
                                    ),
                                    textScaler: const TextScaler.linear(1.0),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Secure access for administrators only',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: isSmallScreen
                                          ? 12
                                          : screenWidth * 0.035,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                    textScaler: const TextScaler.linear(1.0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.05),
                          // Login Form Section
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Container(
                              padding: EdgeInsets.all(screenWidth * 0.07),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Admin Login',
                                    style: GoogleFonts.poppins(
                                      fontSize: isSmallScreen
                                          ? 22
                                          : screenWidth * 0.065,
                                      fontWeight: FontWeight.bold,
                                      color: doorDashRed,
                                    ),
                                    textScaler: const TextScaler.linear(1.0),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Enter your admin credentials',
                                    style: GoogleFonts.poppins(
                                      fontSize: isSmallScreen
                                          ? 12
                                          : screenWidth * 0.035,
                                      color: doorDashGrey,
                                    ),
                                    textScaler: const TextScaler.linear(1.0),
                                  ),
                                  SizedBox(height: screenHeight * 0.03),
                                  TextField(
                                    controller: _emailController,
                                    focusNode: _emailFocus,
                                    decoration: InputDecoration(
                                      labelText: 'Admin Email',
                                      labelStyle: GoogleFonts.poppins(
                                          color: doorDashGrey),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      prefixIcon: const Icon(Icons.email,
                                          color: doorDashRed),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    onSubmitted: (_) => FocusScope.of(context)
                                        .requestFocus(_passwordFocus),
                                  ),
                                  SizedBox(height: screenHeight * 0.02),
                                  TextField(
                                    controller: _passwordController,
                                    focusNode: _passwordFocus,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      labelStyle: GoogleFonts.poppins(
                                          color: doorDashGrey),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      prefixIcon: const Icon(Icons.lock,
                                          color: doorDashRed),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: doorDashRed,
                                        ),
                                        onPressed: () => setState(() =>
                                            _obscurePassword =
                                                !_obscurePassword),
                                      ),
                                    ),
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) => _login(),
                                  ),
                                  SizedBox(height: screenHeight * 0.015),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton(
                                        onPressed: _showForgotPasswordDialog,
                                        child: Text(
                                          'Forgot Password?',
                                          style: GoogleFonts.poppins(
                                            color: doorDashRed,
                                            fontSize: isSmallScreen
                                                ? 10
                                                : screenWidth * 0.03,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(
                                          'Back to User Login',
                                          style: GoogleFonts.poppins(
                                            color: doorDashGrey,
                                            fontSize: isSmallScreen
                                                ? 10
                                                : screenWidth * 0.03,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_errorMessage != null) ...[
                                    SizedBox(height: screenHeight * 0.02),
                                    Text(
                                      _errorMessage!,
                                      style: GoogleFonts.poppins(
                                        color: Colors.redAccent,
                                        fontSize: isSmallScreen
                                            ? 12
                                            : screenWidth * 0.035,
                                      ),
                                      textScaler: const TextScaler.linear(1.0),
                                    ),
                                  ],
                                  SizedBox(height: screenHeight * 0.025),
                                  _isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                              color: doorDashRed))
                                      : ElevatedButton(
                                          onPressed: _login,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: doorDashRed,
                                            minimumSize: Size(double.infinity,
                                                screenHeight * 0.07),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            elevation: 4,
                                          ),
                                          child: Text(
                                            'Login',
                                            style: GoogleFonts.poppins(
                                              fontSize: isSmallScreen
                                                  ? 16
                                                  : screenWidth * 0.045,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            textScaler:
                                                const TextScaler.linear(1.0),
                                          ),
                                        ).animate().slideY(
                                          begin: 0.2,
                                          end: 0.0,
                                          duration: 400.ms),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Footer Section
                          Container(
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.02,
                              horizontal: screenWidth * 0.06,
                            ),
                            color: Colors.white.withOpacity(0.9),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: _showAdminTerms,
                                  child: Text(
                                    'Admin Terms',
                                    style: GoogleFonts.poppins(
                                      color: doorDashRed,
                                      fontSize: isSmallScreen
                                          ? 12
                                          : screenWidth * 0.035,
                                      decoration: TextDecoration.underline,
                                    ),
                                    textScaler: const TextScaler.linear(1.0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
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
