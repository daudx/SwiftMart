import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../core/utils/responsive_layout.dart'; // Add this import

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _fromRegistration = false; // true when arriving from register
  bool _isAdminLogin = false; // true when Admin role is selected

  @override
  void initState() {
    super.initState();
    // Read route argument — set by register_screen on success
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['fromRegistration'] == true) {
        setState(() => _fromRegistration = true);
        // Show success banner after frame renders
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(
                  Icons.check_circle_outline,
                  color: AppColors.tertiary,
                  size: 18,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Account created! Please sign in with your credentials.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.surfaceContainerHigh,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_isLoading) return;

    final emailFieldContent = _emailController.text.trim();

    // Admin validation
    if (_isAdminLogin && emailFieldContent != 'daudx6192@gmail.com') {
      _showError('Invalid Admin credentials.');
      return;
    }

    // Customer validation
    if (!_isAdminLogin && emailFieldContent == 'daudx6192@gmail.com') {
      _showError('Please use the Admin login portal.');
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService().login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      if (_isAdminLogin) {
        Navigator.pushReplacementNamed(context, AppRoutes.admin);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } else {
      _showError(result.error ?? 'Login failed.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Forgot password — sends a real Firebase reset email ───────
  void _showForgotDialog() {
    final resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Reset Password',
          style: TextStyle(
            color: AppColors.onSurface,
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: TextStyle(
                color: AppColors.onSurfaceVariant,
                fontFamily: 'Inter',
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppShadows.pressed,
              ),
              child: TextField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.onSurface,
                ),
                decoration: const InputDecoration(
                  hintText: 'name@example.com',
                  hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.outlineVariant,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.onSurfaceVariant,
                fontFamily: 'Inter',
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              Navigator.pop(context);
              if (email.isEmpty) return;
              if (email.toLowerCase() == 'daudx6192@gmail.com') {
                _showError('Admin password reset is disabled.');
                return;
              }
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: email,
                );
                if (!mounted) return;
                _showError('Reset link sent to $email. Check your inbox.');
              } on FirebaseAuthException catch (e) {
                if (!mounted) return;
                _showError(
                  e.code == 'user-not-found'
                      ? 'No account found with that email.'
                      : 'Failed to send reset email. Please try again.',
                );
              }
            },
            child: const Text(
              'Send Reset Link',
              style: TextStyle(
                color: AppColors.tertiary,
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
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
      backgroundColor: AppColors.background,
      body: ResponsiveLayout(
        // Wrap the main body
        child: SingleChildScrollView(
          child: Column(children: [_buildHeader(), _buildBody()]),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 40),
      decoration: BoxDecoration(
        color: AppColors.ctaGradientEnd,
        boxShadow: AppShadows.raised,
      ),
      child: Column(
        children: [
          Container(
            width: 128,
            height: 128,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
              boxShadow: AppShadows.raised,
            ),
            child: Icon(
              _isAdminLogin ? Icons.admin_panel_settings : Icons.shopping_cart,
              size: 72,
              color: AppColors.onSurface,
            ),
          ),
          // ── Greeting changes based on where user came from ────
          Text(
            _fromRegistration
                ? 'Account Created! 🎉'
                : (_isAdminLogin ? 'Admin Portal' : 'Welcome back!'),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.44,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _fromRegistration
                ? 'Sign in with your new credentials to get started.'
                : (_isAdminLogin
                      ? 'Log in to access your dashboard'
                      : 'Log in to continue your swift shopping journey'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xCCFFFFFF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRoleSelector(),
          const SizedBox(height: 24),
          _buildEmailField(),
          const SizedBox(height: 24),
          _buildPasswordField(),
          const SizedBox(height: 32),
          _buildSignInButton(),
          if (!_isAdminLogin) ...[
            const SizedBox(height: 32),
            _buildDivider(),
            const SizedBox(height: 16),
            _buildSocialButtons(),
            const SizedBox(height: 32),
            _buildFooterLink(),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isAdminLogin = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isAdminLogin
                      ? AppColors.surfaceContainerHigh
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !_isAdminLogin ? AppShadows.raised : null,
                ),
                child: Center(
                  child: Text(
                    'Customer',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: !_isAdminLogin
                          ? AppColors.tertiary
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isAdminLogin = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isAdminLogin
                      ? AppColors.surfaceContainerHigh
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isAdminLogin ? AppShadows.raised : null,
                ),
                child: Center(
                  child: Text(
                    'Admin',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _isAdminLogin
                          ? AppColors.tertiary
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Email Address'),
        const SizedBox(height: 8),
        _buildInputContainer(
          child: Row(
            children: [
              const Icon(
                Icons.mail_outline,
                size: 22,
                color: AppColors.outlineVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppColors.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'name@example.com',
                    hintStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: AppColors.outlineVariant.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel('Password'),
            GestureDetector(
              onTap: _showForgotDialog,
              child: const Text(
                'FORGOT?',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: AppColors.tertiary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildInputContainer(
          child: Row(
            children: [
              const Icon(
                Icons.lock_outline,
                size: 22,
                color: AppColors.outlineVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onSubmitted: (_) => _signIn(),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppColors.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: AppColors.outlineVariant.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                child: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 22,
                  color: AppColors.outlineVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.pressed,
      ),
      child: child,
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildSignInButton() {
    return GestureDetector(
      onTap: _signIn,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.ctaGradientStart, AppColors.ctaGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: AppShadows.raised,
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF04342C),
                  ),
                )
              : const Text(
                  'Sign In',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF04342C),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.20),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR CONTINUE WITH',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppColors.outlineVariant,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.20),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(child: _buildSocialButton(isGoogle: true)),
        const SizedBox(width: 16),
        Expanded(child: _buildSocialButton(isGoogle: false)),
      ],
    );
  }

  Widget _buildSocialButton({required bool isGoogle}) {
    return GestureDetector(
      onTap: () => _showError(
        '${isGoogle ? 'Google' : 'Facebook'} sign-in coming soon.',
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.raised,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isGoogle)
              const Text(
                'G',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF4285F4),
                ),
              )
            else
              const Icon(Icons.facebook, size: 22, color: Color(0xFF1877F2)),
            const SizedBox(width: 8),
            Text(
              isGoogle ? 'Google' : 'Facebook',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterLink() {
    return Center(
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppColors.onSurfaceVariant,
          ),
          children: [
            const TextSpan(text: 'New to SwiftMart? '),
            WidgetSpan(
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.register),
                child: const Text(
                  'Register Now',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.tertiary,
                    decoration: TextDecoration.underline,
                    decorationThickness: 2,
                    decorationColor: AppColors.tertiary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrb(double size, Color color) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
