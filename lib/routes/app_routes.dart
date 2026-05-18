/// All named route constants for SwiftMart.
///
/// Rules:
///   - Every Navigator.pushNamed call MUST use a constant from here.
///   - Every route registered in main.dart MUST have a constant here.
///   - Firebase-ready: route names double as Firestore analytics
///     screen_view event names.
class AppRoutes {
  AppRoutes._();

  // ── Auth ──────────────────────────────────────────────────────
  static const String splash   = '/';
  static const String login    = '/login';
  static const String register = '/register';

  // ── Main tabs ─────────────────────────────────────────────────
  static const String home    = '/home';
  static const String shop    = '/shop';
  static const String cart    = '/cart';
  static const String profile = '/profile';

  // ── Secondary screens ─────────────────────────────────────────
  static const String product         = '/product';
  static const String orders          = '/orders';
  static const String swiftBot        = '/swiftbot';
  static const String swiftBotSuggest = '/swiftbot/suggestions';
  static const String admin           = '/admin';
}