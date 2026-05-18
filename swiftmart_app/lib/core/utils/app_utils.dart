import 'package:flutter/material.dart';

/// Shared utility functions used across screens and services.
/// Pure functions only — no state, no side effects.
///
/// Firebase-ready: all formatting helpers used by Firestore
/// timestamp conversions will live here so screens never
/// contain raw DateTime logic.
class AppUtils {
  AppUtils._();

  // ── Time & Date ───────────────────────────────────────────────

  /// "10:24 AM" — used in order dates and chat timestamps.
  static String formatTime(DateTime dt) {
    final hour = dt.hour == 0
        ? 12
        : dt.hour > 12
        ? dt.hour - 12
        : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// "Oct 24, 2023" — used in order history date rows.
  static String formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  /// "Today, 10:24 AM" or "Oct 24, 2023".
  /// Firebase: pass `timestamp.toDate()` from a Firestore document.
  static String formatOrderDate(DateTime dt) {
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    return isToday ? 'Today, ${formatTime(dt)}' : formatDate(dt);
  }

  // ── Currency ──────────────────────────────────────────────────

  /// "\$189.00" — consistent price formatting across all screens.
  static String formatPrice(double amount) => '\$${amount.toStringAsFixed(2)}';

  // ── Strings ───────────────────────────────────────────────────

  /// Capitalises the first letter of each word.
  static String toTitleCase(String text) {
    return text
        .split(' ')
        .map((w) {
          if (w.isEmpty) return w;
          return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  /// Truncates to [maxLength] chars and appends "…".
  static String truncate(String text, int maxLength) {
    return text.length <= maxLength ? text : '${text.substring(0, maxLength)}…';
  }

  // ── Validation ────────────────────────────────────────────────

  /// Basic email format check.
  static bool isValidEmail(String email) =>
      RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(email.trim());

  /// Minimum 6 characters.
  static bool isValidPassword(String password) => password.trim().length >= 6;

  /// Non-empty name.
  static bool isValidName(String name) => name.trim().isNotEmpty;

  /// Non-empty phone (basic check — Firebase validation will be stricter).
  static bool isValidPhone(String phone) => phone.trim().length >= 6;

  // ── UI helpers ────────────────────────────────────────────────

  /// Shows a branded floating SnackBar. Clears previous ones first.
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          // Colour is driven by the global snackBarTheme in main.dart
        ),
      );
  }

  /// Shows a branded confirmation dialog.
  /// Returns `true` if confirmed, `false` if cancelled or dismissed.
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String body,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E2D27),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFFE1F5EE),
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        content: Text(
          body,
          style: const TextStyle(
            color: Color(0xFFBDCAC0),
            fontFamily: 'Inter',
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              cancelLabel,
              style: const TextStyle(
                color: Color(0xFFBDCAC0),
                fontFamily: 'Inter',
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmLabel,
              style: TextStyle(
                color: isDestructive
                    ? const Color(0xFFFFB4AB) // error red
                    : const Color(0xFF00E29C), // tertiary teal
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Shows a branded bottom sheet with a title and list of actions.
  /// Firebase: useful for showing dynamic options from Firestore data.
  static Future<T?> showActionSheet<T>(
    BuildContext context, {
    required String title,
    required List<SheetAction<T>> actions,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: const Color(0xFF1E2D27),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF3E4942),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE1F5EE),
                ),
              ),
            ),
            // Actions
            ...actions.map(
              (a) => ListTile(
                leading: Icon(
                  a.icon,
                  color: a.isDestructive
                      ? const Color(0xFFFFB4AB)
                      : const Color(0xFF6DDBA9),
                ),
                title: Text(
                  a.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: a.isDestructive
                        ? const Color(0xFFFFB4AB)
                        : const Color(0xFFE1F5EE),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => Navigator.pop(context, a.value),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Navigation helpers ────────────────────────────────────────

  /// Maps a [BottomNav] tab index to a named route.
  /// Returns `null` for tabs that don't navigate (e.g. current tab).
  static String? routeForNavIndex(int index) {
    const map = <int, String>{
      0: '/home',
      1: '/shop',
      2: '/swiftbot',
      3: '/cart',
      4: '/profile',
    };
    return map[index];
  }

  // ── Firebase helpers (stubs — populated in next phase) ────────

  /// Generates a unique product ID for Firestore documents.
  /// Firebase: replace with `FirebaseFirestore.instance.collection('products').doc().id`
  static String generateId(String prefix) =>
      '${prefix}_${DateTime.now().millisecondsSinceEpoch}';
}

/// Action item for [AppUtils.showActionSheet].
class _SheetAction<T> {
  final IconData icon;
  final String label;
  final T value;
  final bool isDestructive;

  const _SheetAction({
    required this.icon,
    required this.label,
    required this.value,
    this.isDestructive = false,
  });
}

/// Public factory constructor so callers can build sheet actions.
class SheetAction<T> extends _SheetAction<T> {
  const SheetAction({
    required super.icon,
    required super.label,
    required super.value,
    super.isDestructive,
  });
}
