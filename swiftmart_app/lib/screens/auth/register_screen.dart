import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _phoneController    = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading       = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final result = await AuthService().register(
      name:     _nameController.text,
      email:    _emailController.text,
      phone:    _phoneController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      // ── Sign out immediately after registration ─────────────
      // Firebase auto-signs-in on createUserWithEmailAndPassword.
      // We sign out so the user must consciously enter their
      // credentials on the login screen — standard auth UX.
      await AuthService().logout();

      if (!mounted) return;

      // ── Navigate to Login with success flag ─────────────────
      // The login screen reads this argument and shows a
      // "Account created! Please sign in." success banner.
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.login,
        arguments: {'fromRegistration': true},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.error ?? 'Registration failed.'),
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -MediaQuery.of(context).size.height * 0.25,
            right: -MediaQuery.of(context).size.width * 0.5,
            child: _buildOrb(500,
                AppColors.primaryContainer.withValues(alpha: 0.05)),
          ),
          Positioned(
            bottom: -MediaQuery.of(context).size.height * 0.25,
            left: -MediaQuery.of(context).size.width * 0.25,
            child: _buildOrb(400,
                const Color(0xFF00A571).withValues(alpha: 0.05)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 128),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448),
                  child: Column(
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: 32),
                      _buildFormSection(),
                      const SizedBox(height: 32),
                      _buildFeatureBadges(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.ctaGradientEnd,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppShadows.raised),
      child: const Column(
        children: [
          Text('SwiftMart',
            style: TextStyle(fontFamily: 'Inter', fontSize: 30,
                fontWeight: FontWeight.w900, letterSpacing: -1.2,
                color: AppColors.onPrimaryContainer)),
          SizedBox(height: 8),
          Text('CREATE ACCOUNT',
            style: TextStyle(fontFamily: 'Inter', fontSize: 14,
                fontWeight: FontWeight.bold, letterSpacing: 2.0,
                color: AppColors.onPrimaryFixedVariant)),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppShadows.raised),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildField(label: 'Full Name', icon: Icons.person_outline,
              hint: 'John Doe', controller: _nameController,
              keyboardType: TextInputType.name),
          const SizedBox(height: 24),
          _buildField(label: 'Email Address', icon: Icons.mail_outline,
              hint: 'john@swiftmart.com', controller: _emailController,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 24),
          _buildField(label: 'Phone Number', icon: Icons.call_outlined,
              hint: '+1 (555) 000-0000', controller: _phoneController,
              keyboardType: TextInputType.phone),
          const SizedBox(height: 24),
          _buildPasswordField(),
          const SizedBox(height: 16),
          _buildCreateButton(),
          const SizedBox(height: 16),
          _buildFooterLink(),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        _buildInputContainer(
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14,
                      fontWeight: FontWeight.w500, color: AppColors.onSurface),
                  decoration: const InputDecoration(
                    border: InputBorder.none, isDense: true,
                    contentPadding: EdgeInsets.zero),
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
        _buildLabel('Secure Password'),
        const SizedBox(height: 8),
        _buildInputContainer(
          child: Row(
            children: [
              const Icon(Icons.lock_outline, size: 20, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onSubmitted: (_) => _createAccount(),
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14,
                      fontWeight: FontWeight.w500, color: AppColors.onSurface),
                  decoration: const InputDecoration(
                    hintText: '••••••••',
                    hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.outlineVariant),
                    border: InputBorder.none, isDense: true,
                    contentPadding: EdgeInsets.zero),
                ),
              ),
              GestureDetector(
                onTap: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                child: Icon(
                  _obscurePassword ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20, color: AppColors.outlineVariant),
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
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.pressed),
      child: child,
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(text.toUpperCase(),
        style: const TextStyle(fontFamily: 'Inter', fontSize: 10,
            fontWeight: FontWeight.w700, letterSpacing: 1.5,
            color: AppColors.onSurfaceVariant)),
    );
  }

  Widget _buildCreateButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.ctaGradientStart, AppColors.ctaGradientEnd],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(999),
        boxShadow: AppShadows.raised),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _createAccount,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2,
                          color: Color(0xFF04342C)))
                  : const Text('Create Account',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 18,
                          fontWeight: FontWeight.w900, letterSpacing: -0.36,
                          color: AppColors.onPrimary)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterLink() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Already a member? ',
            style: TextStyle(fontFamily: 'Inter', fontSize: 14,
                color: AppColors.onSurfaceVariant)),
          GestureDetector(
            onTap: () => Navigator.pushReplacementNamed(
                context, AppRoutes.login),
            child: const Text('Log In',
              style: TextStyle(fontFamily: 'Inter', fontSize: 14,
                  fontWeight: FontWeight.bold, color: AppColors.tertiary)),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBadges() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _FeatureBadge(icon: Icons.verified_user,
              color: AppColors.badgeSecure, label: 'SECURE'),
          _FeatureBadge(icon: Icons.bolt,
              color: AppColors.badgeFast, label: 'FAST'),
          _FeatureBadge(icon: Icons.psychology,
              color: AppColors.badgeSmart, label: 'SMART'),
        ],
      ),
    );
  }

  Widget _buildOrb(double size, Color color) {
    return IgnorePointer(
      child: Container(width: size, height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   label;
  const _FeatureBadge(
      {required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh, shape: BoxShape.circle,
            boxShadow: AppShadows.raised),
          child: Icon(icon, size: 28, color: color),
        ),
        const SizedBox(height: 8),
        Text(label,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 9,
              fontWeight: FontWeight.w900, letterSpacing: 1.8,
              color: AppColors.onSurfaceVariant)),
      ],
    );
  }
}