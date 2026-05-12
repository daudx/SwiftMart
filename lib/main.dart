import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // ── Database Fix / Seed (One-off) ──────────────────────────────
  try {
    final productsFix = {
      'prd_001': {'id': 'prd_001', 'name': 'Urban Luxe Hoodie', 'category': 'CLOTHES', 'price': 85.00, 'stock': 50, 'imageUrl': 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=800&q=80'},
      'prd_002': {'id': 'prd_002', 'name': 'Sonic Pro Over-Ear', 'category': 'AUDIO', 'price': 199.00, 'stock': 30, 'imageUrl': 'https://images.unsplash.com/photo-1618366712010-f4ae9c647dcb?w=800&q=80'},
      'prd_003': {'id': 'prd_003', 'name': 'Swift Performance Tee', 'category': 'CLOTHES', 'price': 39.99, 'stock': 100, 'imageUrl': 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=800&q=80'},
      'prd_004': {'id': 'prd_004', 'name': 'Resistance Band Set', 'category': 'FITNESS', 'price': 32.00, 'stock': 85, 'imageUrl': 'https://images.unsplash.com/photo-1598266663412-70233486df81?w=800&q=80'},
      'prd_005': {'id': 'prd_005', 'name': 'Prestige Ceramic Flask', 'category': 'LABEL', 'price': 36.00, 'stock': 40, 'imageUrl': 'https://images.unsplash.com/photo-1606168094036-398ec7a30366?w=800&q=80'},
      'prd_006': {'id': 'prd_006', 'name': 'Nova Pulse ANC', 'category': 'AUDIO', 'price': 189.50, 'stock': 25, 'imageUrl': 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&q=80'},
      'prd_007': {'id': 'prd_007', 'name': 'Noir Signature Scent', 'category': 'LABEL', 'price': 72.00, 'stock': 60, 'imageUrl': 'https://images.unsplash.com/photo-1523293115678-d2906211833d?w=800&q=80'},
      'prd_008': {'id': 'prd_008', 'name': 'Iron Grip DBs', 'category': 'FITNESS', 'price': 45.00, 'stock': 15, 'imageUrl': 'https://images.unsplash.com/photo-1638202993928-7267aad84c31?w=800&q=80'},
      'prd_009': {'id': 'prd_009', 'name': 'Emerald Track Jacket', 'category': 'CLOTHES', 'price': 119.00, 'stock': 40, 'imageUrl': 'https://images.unsplash.com/photo-1559551409-dadc959f76b8?w=800&q=80'},
      'prd_010': {'id': 'prd_010', 'name': 'Emerald Canvas Tote', 'category': 'LABEL', 'price': 44.00, 'stock': 120, 'imageUrl': 'https://images.unsplash.com/photo-1544816155-12df9643f363?w=800&q=80'},
      'prd_011': {'id': 'prd_011', 'name': 'Compression Shorts Pro', 'category': 'CLOTHES', 'price': 54.00, 'stock': 75, 'imageUrl': 'https://images.unsplash.com/photo-1533681473426-1ebce7e155bc?w=800&q=80'},
      'prd_012': {'id': 'prd_012', 'name': 'Onyx Chronograph', 'category': 'TECH', 'price': 299.00, 'stock': 12, 'imageUrl': 'https://images.unsplash.com/photo-1524592094714-0f0654e20314?w=800&q=80'},
    };
    final coll = FirebaseFirestore.instance.collection('products');
    for (var entry in productsFix.entries) {
      final docId = entry.key;
      final productData = entry.value;
      await coll.doc(docId).set(productData, SetOptions(merge: true));
    }
  } catch (_) {}

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