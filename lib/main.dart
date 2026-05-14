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
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── Product Seed — All categories, 2+ products each ───────
  // Uses set() (no merge) to force-overwrite and clean stale fields.
  // Image URLs: verified popular Unsplash photos only.
  try {
    final products = {
      // ── CLOTHES (5 products) ────────────────────────────────
      'prd_001': {
        'id': 'prd_001',
        'name': 'Urban Luxe Hoodie',
        'category': 'CLOTHES',
        'price': 85.00,
        'stock': 50,
        'imageUrl': 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=800&q=80&fit=crop',
        'description': 'Premium heavyweight hoodie with minimalist design. Built for comfort and style.',
        'rating': 4.8,
        'reviewsCount': 124,
        'isFeatured': true,
      },
      'prd_003': {
        'id': 'prd_003',
        'name': 'Swift Performance Tee',
        'category': 'CLOTHES',
        'price': 39.99,
        'stock': 100,
        'imageUrl': 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=800&q=80&fit=crop',
        'description': 'Ultra-lightweight performance tee with moisture-wicking fabric for all-day comfort.',
        'rating': 4.5,
        'reviewsCount': 210,
        'isFeatured': false,
      },
      'prd_009': {
        'id': 'prd_009',
        'name': 'Emerald Track Jacket',
        'category': 'CLOTHES',
        'price': 119.00,
        'stock': 40,
        'imageUrl': 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=800&q=80&fit=crop',
        'description': 'Slim-fit track jacket in premium recycled polyester. Ready for the streets or the gym.',
        'rating': 4.5,
        'reviewsCount': 77,
        'isFeatured': true,
      },
      'prd_011': {
        'id': 'prd_011',
        'name': 'Compression Shorts Pro',
        'category': 'CLOTHES',
        'price': 54.00,
        'stock': 75,
        'imageUrl': 'https://images.unsplash.com/photo-1506629082955-511b1aa562c8?w=800&q=80&fit=crop',
        'description': 'High-compression performance shorts with 4-way stretch and muscle support.',
        'rating': 4.6,
        'reviewsCount': 201,
        'isFeatured': false,
      },
      'prd_016': {
        'id': 'prd_016',
        'name': 'Midnight Cargo Pants',
        'category': 'CLOTHES',
        'price': 95.00,
        'stock': 35,
        'imageUrl': 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=800&q=80&fit=crop',
        'description': 'Tactical cargo pants with water-resistant finish and ergonomic pocket layout.',
        'rating': 4.7,
        'reviewsCount': 56,
        'isFeatured': false,
      },

      // ── AUDIO (5 products) ──────────────────────────────────
      'prd_002': {
        'id': 'prd_002',
        'name': 'Sonic Pro Over-Ear',
        'category': 'AUDIO',
        'price': 199.00,
        'stock': 30,
        'imageUrl': 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&q=80&fit=crop',
        'description': 'Studio-grade over-ear headphones with deep bass and noise isolation.',
        'rating': 4.7,
        'reviewsCount': 89,
        'isFeatured': true,
      },
      'prd_006': {
        'id': 'prd_006',
        'name': 'Nova Pulse ANC Buds',
        'category': 'AUDIO',
        'price': 189.50,
        'stock': 25,
        'imageUrl': 'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=800&q=80&fit=crop',
        'description': 'Active noise-cancelling earbuds with 30hr battery life and crystal-clear call quality.',
        'rating': 4.6,
        'reviewsCount': 98,
        'isFeatured': true,
      },
      'prd_017': {
        'id': 'prd_017',
        'name': 'Titan Beam Speaker',
        'category': 'AUDIO',
        'price': 129.00,
        'stock': 45,
        'imageUrl': 'https://images.unsplash.com/photo-1589003020683-95634f5a18be?w=800&q=80&fit=crop',
        'description': 'Portable Bluetooth speaker with 360-degree sound and waterproof IPX7 rating.',
        'rating': 4.8,
        'reviewsCount': 142,
        'isFeatured': false,
      },
      'prd_018': {
        'id': 'prd_018',
        'name': 'Vintage Vinyl Deck',
        'category': 'AUDIO',
        'price': 349.00,
        'stock': 10,
        'imageUrl': 'https://images.unsplash.com/photo-1603048588665-791ca8aea617?w=800&q=80&fit=crop',
        'description': 'High-fidelity turntable with built-in preamp and carbon fiber tonearm.',
        'rating': 4.9,
        'reviewsCount': 24,
        'isFeatured': false,
      },
      'prd_019': {
        'id': 'prd_019',
        'name': 'Streamer Mic Pro',
        'category': 'AUDIO',
        'price': 159.00,
        'stock': 20,
        'imageUrl': 'https://images.unsplash.com/photo-1590602847861-f357a9332bbc?w=800&q=80&fit=crop',
        'description': 'Professional condenser microphone for streaming, podcasting, and studio recording.',
        'rating': 4.7,
        'reviewsCount': 83,
        'isFeatured': false,
      },

      // ── FITNESS (5 products) ────────────────────────────────
      'prd_004': {
        'id': 'prd_004',
        'name': 'Resistance Band Set',
        'category': 'FITNESS',
        'price': 32.00,
        'stock': 85,
        'imageUrl': 'https://images.unsplash.com/photo-1517963879433-6ad2b056d712?w=800&q=80&fit=crop',
        'description': '5-piece resistance band set with varying tension levels for full-body workouts.',
        'rating': 4.6,
        'reviewsCount': 175,
        'isFeatured': false,
      },
      'prd_008': {
        'id': 'prd_008',
        'name': 'Iron Grip Dumbbells',
        'category': 'FITNESS',
        'price': 45.00,
        'stock': 15,
        'imageUrl': 'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5?w=800&q=80&fit=crop',
        'description': 'Cast-iron dumbbells with ergonomic knurled grip. Available in 5-30kg pairs.',
        'rating': 4.8,
        'reviewsCount': 44,
        'isFeatured': false,
      },
      'prd_020': {
        'id': 'prd_020',
        'name': 'Zen Flow Yoga Mat',
        'category': 'FITNESS',
        'price': 55.00,
        'stock': 60,
        'imageUrl': 'https://images.unsplash.com/photo-1592432678899-906d40705021?w=800&q=80&fit=crop',
        'description': 'Eco-friendly TPE mat with alignment lines and extra cushioning for joints.',
        'rating': 4.7,
        'reviewsCount': 112,
        'isFeatured': false,
      },
      'prd_021': {
        'id': 'prd_021',
        'name': 'Power Kettlebell 16kg',
        'category': 'FITNESS',
        'price': 89.00,
        'stock': 25,
        'imageUrl': 'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?w=800&q=80&fit=crop',
        'description': 'Competition-standard kettlebell with powder-coated finish for superior grip.',
        'rating': 4.9,
        'reviewsCount': 37,
        'isFeatured': false,
      },
      'prd_022': {
        'id': 'prd_022',
        'name': 'Sonic Jump Rope',
        'category': 'FITNESS',
        'price': 24.00,
        'stock': 120,
        'imageUrl': 'https://images.unsplash.com/photo-1598289431512-b97b0917a63e?w=800&q=80&fit=crop',
        'description': 'High-speed cable rope with ball bearings for smooth, rapid rotation.',
        'rating': 4.5,
        'reviewsCount': 156,
        'isFeatured': false,
      },

      // ── LABEL (5 products) ──────────────────────────────────
      'prd_005': {
        'id': 'prd_005',
        'name': 'Prestige Ceramic Flask',
        'category': 'LABEL',
        'price': 36.00,
        'stock': 40,
        'imageUrl': 'https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=800&q=80&fit=crop',
        'description': 'Vacuum-insulated ceramic flask keeps drinks hot 12 hrs, cold 24 hrs.',
        'rating': 4.9,
        'reviewsCount': 63,
        'isFeatured': false,
      },
      'prd_010': {
        'id': 'prd_010',
        'name': 'Emerald Canvas Tote',
        'category': 'LABEL',
        'price': 44.00,
        'stock': 120,
        'imageUrl': 'https://images.unsplash.com/photo-1544816155-12df9643f363?w=800&q=80&fit=crop',
        'description': 'Eco-friendly heavy-duty canvas tote with padded shoulder strap. 20L capacity.',
        'rating': 4.4,
        'reviewsCount': 139,
        'isFeatured': false,
      },
      'prd_023': {
        'id': 'prd_023',
        'name': 'Minimalist Planner',
        'category': 'LABEL',
        'price': 29.00,
        'stock': 80,
        'imageUrl': 'https://images.unsplash.com/photo-1531346878377-a5be20888e57?w=800&q=80&fit=crop',
        'description': 'Premium 120gsm paper planner with soft-touch cover and lay-flat binding.',
        'rating': 4.8,
        'reviewsCount': 94,
        'isFeatured': false,
      },
      'prd_024': {
        'id': 'prd_024',
        'name': 'Matte Ceramic Mug',
        'category': 'LABEL',
        'price': 18.00,
        'stock': 150,
        'imageUrl': 'https://images.unsplash.com/photo-1514228742587-6b1558fcca3d?w=800&q=80&fit=crop',
        'description': 'Hand-crafted ceramic mug with ergonomic handle and stone-matte finish.',
        'rating': 4.7,
        'reviewsCount': 210,
        'isFeatured': false,
      },
      'prd_025': {
        'id': 'prd_025',
        'name': 'Sleek Fountain Pen',
        'category': 'LABEL',
        'price': 42.00,
        'stock': 50,
        'imageUrl': 'https://images.unsplash.com/photo-1583485088034-697b5bc54ccd?w=800&q=80&fit=crop',
        'description': 'Modern fountain pen with stainless steel nib and weighted balanced body.',
        'rating': 4.9,
        'reviewsCount': 41,
        'isFeatured': false,
      },

      // ── TECH (5 products) ───────────────────────────────────
      'prd_012': {
        'id': 'prd_012',
        'name': 'Onyx Chronograph',
        'category': 'TECH',
        'price': 299.00,
        'stock': 12,
        'imageUrl': 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800&q=80&fit=crop',
        'description': 'Precision Swiss-movement chronograph with sapphire crystal glass and steel case.',
        'rating': 4.9,
        'reviewsCount': 38,
        'isFeatured': true,
      },
      'prd_015': {
        'id': 'prd_015',
        'name': 'UltraTab Pro 12',
        'category': 'TECH',
        'price': 599.00,
        'stock': 18,
        'imageUrl': 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800&q=80&fit=crop',
        'description': 'Slim 12-inch productivity tablet with OLED display, stylus support, and 16GB RAM.',
        'rating': 4.7,
        'reviewsCount': 95,
        'isFeatured': true,
      },
      'prd_026': {
        'id': 'prd_026',
        'name': 'Mechanical Key Pro',
        'category': 'TECH',
        'price': 149.00,
        'stock': 30,
        'imageUrl': 'https://images.unsplash.com/photo-1511467687858-23d96c32e4ae?w=800&q=80&fit=crop',
        'description': '75% layout mechanical keyboard with hot-swappable switches and RGB lighting.',
        'rating': 4.8,
        'reviewsCount': 67,
        'isFeatured': false,
      },
      'prd_027': {
        'id': 'prd_027',
        'name': 'Precision Mouse Air',
        'category': 'TECH',
        'price': 79.00,
        'stock': 55,
        'imageUrl': 'https://images.unsplash.com/photo-1527864550417-7fd91fc51a46?w=800&q=80&fit=crop',
        'description': 'Ultralight wireless mouse with 20K DPI sensor and 80hr battery life.',
        'rating': 4.6,
        'reviewsCount': 124,
        'isFeatured': false,
      },
      'prd_028': {
        'id': 'prd_028',
        'name': 'Nano Display Monitor',
        'category': 'TECH',
        'price': 449.00,
        'stock': 15,
        'imageUrl': 'https://images.unsplash.com/photo-1527443224154-c4a3942d3acf?w=800&q=80&fit=crop',
        'description': '27-inch 4K IPS display with 99% sRGB coverage and USB-C power delivery.',
        'rating': 4.7,
        'reviewsCount': 29,
        'isFeatured': false,
      },

      // ── SHOES (5 products) ──────────────────────────────────
      'prd_013': {
        'id': 'prd_013',
        'name': 'SwiftAir Runner Pro',
        'category': 'SHOES',
        'price': 149.99,
        'stock': 60,
        'imageUrl': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800&q=80&fit=crop',
        'description': 'Lightweight running shoe with ReactFoam cushioning and breathable knit upper.',
        'rating': 4.8,
        'reviewsCount': 312,
        'isFeatured': true,
      },
      'prd_014': {
        'id': 'prd_014',
        'name': 'Stealth Trail Runner',
        'category': 'SHOES',
        'price': 129.00,
        'stock': 45,
        'imageUrl': 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=800&q=80&fit=crop',
        'description': 'All-terrain trail shoe with rugged outsole, ankle support, and weather-resistant upper.',
        'rating': 4.6,
        'reviewsCount': 187,
        'isFeatured': false,
      },
      'prd_029': {
        'id': 'prd_029',
        'name': 'Retro Street Sneaker',
        'category': 'SHOES',
        'price': 110.00,
        'stock': 70,
        'imageUrl': 'https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77?w=800&q=80&fit=crop',
        'description': 'Classic high-top silhouette with suede overlays and vintage rubber cupsole.',
        'rating': 4.7,
        'reviewsCount': 245,
        'isFeatured': false,
      },
      'prd_030': {
        'id': 'prd_030',
        'name': 'Onyx Desert Boot',
        'category': 'SHOES',
        'price': 165.00,
        'stock': 30,
        'imageUrl': 'https://images.unsplash.com/photo-1520639889313-72721fa011e0?w=800&q=80&fit=crop',
        'description': 'Hand-stitched leather boots with crepe sole and moisture-wicking lining.',
        'rating': 4.8,
        'reviewsCount': 52,
        'isFeatured': false,
      },
      'prd_031': {
        'id': 'prd_031',
        'name': 'Alpine Cloud Sandal',
        'category': 'SHOES',
        'price': 65.00,
        'stock': 90,
        'imageUrl': 'https://images.unsplash.com/photo-1603487742131-4160ec999306?w=800&q=80&fit=crop',
        'description': 'Ultra-soft recovered foam sandals with adjustable straps for recovery and lifestyle.',
        'rating': 4.5,
        'reviewsCount': 128,
        'isFeatured': false,
      },
    };

    final coll = FirebaseFirestore.instance.collection('products');
    for (final entry in products.entries) {
      await coll.doc(entry.key).set(entry.value);
    }
    // Remove discontinued products
    await coll.doc('prd_007').delete();
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
      initialRoute: AppRoutes.splash,
      onGenerateRoute: (settings) {
        final routes = <String, WidgetBuilder>{
          AppRoutes.splash:   (_) => const SplashScreen(),
          AppRoutes.login:    (_) => const LoginScreen(),
          AppRoutes.register: (_) => const RegisterScreen(),
          AppRoutes.home:     (_) => const HomeScreen(),
          AppRoutes.cart:     (_) => const CartScreen(),
          AppRoutes.profile:  (_) => const ProfileScreen(),
          AppRoutes.orders:   (_) => const OrderHistoryScreen(),
          AppRoutes.swiftBot: (_) => const SwiftBotScreen(),
          AppRoutes.swiftBotSuggest: (_) => const SwiftBotSuggestionsScreen(),
          AppRoutes.admin:    (_) => const AdminScreen(),
        };

        if (settings.name == AppRoutes.shop) {
          final category = settings.arguments as String?;
          return MaterialPageRoute(
            builder: (_) => ShopScreen(initialCategory: category),
            settings: settings,
          );
        }

        if (settings.name == AppRoutes.product) {
          return MaterialPageRoute(
            builder: (_) => const ProductScreen(),
            settings: settings,
          );
        }

        final builder = routes[settings.name];
        if (builder != null) {
          return MaterialPageRoute(
            builder: builder,
            settings: settings,
          );
        }

        return null;
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