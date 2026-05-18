/// Central configuration constants for SwiftMart.
///
/// Single source of truth — no magic strings or numbers anywhere else.
///
/// Firebase-ready: collection names, document field keys, and
/// storage paths all live here so renaming never touches screen code.
class AppConstants {
  AppConstants._();

  // ── App identity ──────────────────────────────────────────────
  static const String appName    = 'SwiftMart';
  static const String appVersion = '2.4.0';
  static const String appTagline = 'Shop fast. Shop smart.';

  // ── Anthropic / SwiftBot ──────────────────────────────────────
  // Replace with your real key via --dart-define or flutter_dotenv.
  // NEVER commit a real key to source control.
  static const String geminiApiKey = 'AIzaSyDl1plaInovZ_9WKRyzSvSIYJhcmfhYSoA';
 static const String geminiModel = 'gemini-1.5-flash';
  static const int    geminiMaxTokens = 1024;

  // ── Firebase collection names (used in next phase) ────────────
  static const String colUsers    = 'users';
  static const String colProducts = 'products';
  static const String colOrders   = 'orders';
  static const String colCart     = 'cart';
  static const String colMessages = 'messages';

  // ── Firebase Storage paths ────────────────────────────────────
  static const String storageAvatars  = 'avatars';
  static const String storageProducts = 'product_images';

  // ── Product categories ────────────────────────────────────────
  // Used in filter chips, admin dropdowns, and Firestore queries.
  static const List<String> productCategories = [
    'ALL',
    'SHOES',
    'TECH',
    'AUDIO',
    'CLOTHES',
    'FITNESS',
    'LABEL',
  ];

  // ── Cart ──────────────────────────────────────────────────────
  static const double cartTaxAmount = 12.45;
  static const int    cartMaxQty    = 99;

  // ── Promo codes ───────────────────────────────────────────────
  // Firebase: move to a Firestore 'promo_codes' collection.
  static const Map<String, double> promoCodes = {
    'SWIFT10':  0.10, // 10% off
    'LAUNCH20': 0.20, // 20% off
    'STUDENT15': 0.15, // 15% off
  };

  // ── Pagination ────────────────────────────────────────────────
  // Firebase: used as the `limit` in Firestore paginated queries.
  static const int pageSize = 12; // products per page in shop screen

  // ── Animation durations ───────────────────────────────────────
  static const Duration durationFast   = Duration(milliseconds: 180);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow   = Duration(milliseconds: 500);

  // ── Simulated network delays (removed in Firebase phase) ──────
  static const Duration delayShort  = Duration(milliseconds: 200);
  static const Duration delayMedium = Duration(milliseconds: 600);
  static const Duration delayLong   = Duration(milliseconds: 900);

  // ── Layout ────────────────────────────────────────────────────
  static const double maxContentWidth = 448.0;  // max-w-md
  static const double navBarHeight    = 96.0;
  static const double appBarHeight    = 72.0;

  // ── Border radii ─────────────────────────────────────────────
  static const double radiusSm   = 6.0;    // rounded-md
  static const double radiusMd   = 12.0;   // rounded-xl
  static const double radiusLg   = 16.0;   // rounded-2xl
  static const double radiusXl   = 24.0;   // rounded-3xl
  static const double radius2xl  = 32.0;   // rounded-[32px]
  static const double radiusFull = 999.0;  // rounded-full

  // ── Default product sizes ─────────────────────────────────────
  static const List<String> shoeSizes      = ['7', '8', '9', '10', '11', '12'];
  static const List<String> clothesSizes   = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  static const List<String> genericSizes   = ['One Size'];

  // ── Error messages ────────────────────────────────────────────
  static const String errRequired    = 'This field is required.';
  static const String errEmail       = 'Please enter a valid email address.';
  static const String errPassword    = 'Password must be at least 6 characters.';
  static const String errNetwork     = 'Connection error. Please try again.';
  static const String errUnknown     = 'Something went wrong. Please try again.';
  static const String errEmptyCart   = 'Your cart is empty.';
  static const String errInvalidPromo = 'Invalid promo code.';
}