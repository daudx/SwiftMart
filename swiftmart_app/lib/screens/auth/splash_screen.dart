import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Progress bar animation — runs independently of auth check
  double _progress = 0.0;

  late final AnimationController _progressController;
  late final Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // ── Animate progress bar 0 → 1 over 2.5 seconds ──────────
    // Gives Firebase auth check time to complete gracefully.
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _progressAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
        )..addListener(() {
          setState(() => _progress = _progressAnimation.value);
        });

    _progressController.forward();

    // ── Firebase auth state check ─────────────────────────────
    // authStateChanges() emits immediately on first listen:
    //   - null  → no session → go to Login
    //   - User  → session exists → restore profile → go to Home
    //
    // We wait for both the animation AND the auth check before
    // navigating so the splash screen always shows for at least
    // the full animation duration.
    Future.wait<dynamic>([
      // Wait for animation to finish (2.5 seconds)
      _progressController.forward(),
      // Wait for auth state — first emission is always instant
      AuthService().authStateChanges.first,
    ]).then((results) async {
      if (!mounted) return;

      // results[1] is the User? from authStateChanges
      final user = results[1];

      if (user != null) {
        // ── Session exists — restore Firestore profile ────────
        await AuthService().restoreSession(user.uid);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        // ── No session — go to login ──────────────────────────
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color splashBg = AppColors.surfaceContainerHigh;

    return Scaffold(
      backgroundColor: splashBg,
      body: Stack(
        children: [
          // ── Background decorative orbs ─────────────────────
          Positioned(
            top: -96,
            left: -96,
            child: _buildOrb(
              256,
              AppColors.primaryContainer.withValues(alpha: 0.03),
            ),
          ),
          Positioned(
            bottom: -96,
            right: -96,
            child: _buildOrb(320, AppColors.tertiary.withValues(alpha: 0.05)),
          ),

          // ── Main content ───────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox.shrink(),
                  Column(
                    children: [
                      _buildLogoOrb(splashBg),
                      const SizedBox(height: 48),
                      _buildBranding(),
                    ],
                  ),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Logo orb ─────────────────────────────────────────────────
  Widget _buildLogoOrb(Color bg) {
    return Container(
      width: 128,
      height: 128,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: AppShadows.raisedHero,
      ),
      child: const Icon(
        Icons.shopping_cart,
        size: 72,
        color: AppColors.onSurface,
      ),
    );
  }

  // ── Branding ──────────────────────────────────────────────────
  Widget _buildBranding() {
    return Column(
      children: [
        const Text(
          'SwiftMart',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.12,
            color: AppColors.onSurface,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            children: [
              TextSpan(
                text: 'Shop fast. ',
                style: TextStyle(color: AppColors.onSurface),
              ),
              TextSpan(
                text: 'Shop smart.',
                style: TextStyle(color: AppColors.primaryContainer),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Footer (progress bar + security badge) ────────────────────
  Widget _buildFooter() {
    return Column(
      children: [
        _buildProgressSection(),
        const SizedBox(height: 32),
        _buildSecurityBadge(),
      ],
    );
  }

  // ── Progress section ──────────────────────────────────────────
  Widget _buildProgressSection() {
    final int percent = (_progress * 100).clamp(0, 100).toInt();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'INITIALIZING',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(999),
            boxShadow: AppShadows.pressed,
          ),
          padding: const EdgeInsets.all(2),
          child: AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 100),
            widthFactor: _progress.clamp(0.0, 1.0),
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.ctaGradientEnd,
                    AppColors.ctaGradientStart,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: AppShadows.progressGlow,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Security badge ────────────────────────────────────────────
  Widget _buildSecurityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user, size: 14, color: AppColors.outlineVariant),
          SizedBox(width: 8),
          Text(
            'SECURE RETAIL',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: AppColors.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ── Decorative orb ────────────────────────────────────────────
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
