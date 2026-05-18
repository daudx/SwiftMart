import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/constants/app_constant.dart';
import 'core/theme/app_colors.dart';
import 'routes/app_routes.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/orders/order_history_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/ai/swiftbot_screen.dart';
import 'screens/ai/swiftbot_suggestions_screen.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/product/product_screen.dart';
import 'screens/home/shop_screen.dart';

void main() async {
  // ── Required before any async work in main ─────────────────
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase initialization ───────────────────────────────
  // Must complete before runApp so all Firebase services are
  // ready by the time any screen tries to use them.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor:                    Colors.transparent,
      statusBarBrightness:               Brightness.dark,
      statusBarIconBrightness:           Brightness.light,
      systemNavigationBarColor:          AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const SwiftMartApp());
}

class SwiftMartApp extends StatelessWidget {
  const SwiftMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:                      AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme:                      _buildTheme(),
      initialRoute:               AppRoutes.splash,
      routes: {
        // ── Auth ────────────────────────────────────────────
        AppRoutes.splash:   (_) => const SplashScreen(),
        AppRoutes.login:    (_) => const LoginScreen(),
        AppRoutes.register: (_) => const RegisterScreen(),

        // ── Main tabs ────────────────────────────────────────
        AppRoutes.home:    (_) => const HomeScreen(),
        AppRoutes.shop:    (_) => const ShopScreen(),
        AppRoutes.cart:    (_) => const CartScreen(),
        AppRoutes.profile: (_) => const ProfileScreen(),

        // ── Secondary screens ─────────────────────────────────
        AppRoutes.orders:          (_) => const OrderHistoryScreen(),
        AppRoutes.swiftBot:        (_) => const SwiftBotScreen(),
        AppRoutes.swiftBotSuggest: (_) => const SwiftBotSuggestionsScreen(),
        AppRoutes.admin:           (_) => const AdminScreen(),
        AppRoutes.product:         (_) => const ProductScreen(),
      },
    );
  }

  ThemeData _buildTheme() {
    final base = ColorScheme.dark(
      brightness:         Brightness.dark,
      primary:            AppColors.primary,
      onPrimary:          AppColors.onPrimary,
      primaryContainer:   AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary:          AppColors.secondary,
      tertiary:           AppColors.tertiary,
      surface:            AppColors.background,
      onSurface:          AppColors.onSurface,
      onSurfaceVariant:   AppColors.onSurfaceVariant,
      outline:            AppColors.outline,
      outlineVariant:     AppColors.outlineVariant,
      error:              AppColors.error,
      shadow:             AppColors.shadowDark,
    );

    return ThemeData(
      colorScheme:             base,
      useMaterial3:            true,
      fontFamily:              'Inter',
      scaffoldBackgroundColor: AppColors.background,
      canvasColor:             AppColors.background,

      appBarTheme: const AppBarTheme(
        backgroundColor:        AppColors.background,
        foregroundColor:        AppColors.primary,
        elevation:              0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor:          Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      textSelectionTheme: const TextSelectionThemeData(
        cursorColor:          AppColors.tertiary,
        selectionColor:       Color(0x3300E29C),
        selectionHandleColor: AppColors.tertiary,
      ),

      inputDecorationTheme: const InputDecorationTheme(
        border:    InputBorder.none,
        filled:    false,
        hintStyle: TextStyle(
          color:      AppColors.outlineVariant,
          fontFamily: 'Inter',
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceContainerHigh,
        contentTextStyle: const TextStyle(
          color:      AppColors.onSurface,
          fontFamily: 'Inter',
          fontSize:   14,
        ),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
        },
      ),

      splashColor:    AppColors.tertiary.withValues(alpha: 0.08),
      highlightColor: AppColors.primary.withValues(alpha: 0.05),
      splashFactory:  InkRipple.splashFactory,

      dividerTheme: const DividerThemeData(
        color:     AppColors.outlineVariant,
        thickness: 1,
        space:     0,
      ),

      iconTheme: const IconThemeData(
        color: AppColors.onSurfaceVariant,
        size:  24,
      ),
    );
  }
}