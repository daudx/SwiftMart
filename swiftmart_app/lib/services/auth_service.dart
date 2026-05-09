import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constant.dart';
import '../models/user_model.dart';
import 'cart_service.dart';

/// Result wrapper — every service method returns this.
/// Screens check [success] first, then read [data] or show [error].
/// This class is unchanged — screens need zero modification.
class ServiceResult<T> {
  final bool    success;
  final T?      data;
  final String? error;

  const ServiceResult.ok(this.data)
      : success = true,
        error   = null;

  const ServiceResult.fail(this.error)
      : success = false,
        data    = null;
}

/// Handles all authentication for SwiftMart using Firebase Auth
/// and Cloud Firestore.
///
/// Architecture:
///   - Firebase Auth  → manages credentials (email/password, tokens,
///                      session persistence across app restarts)
///   - Cloud Firestore → stores user profile data (name, phone,
///                      avatarUrl, stats) at users/{uid}
///
/// The singleton pattern is preserved so all screens share one
/// instance — same interface as the in-memory version.
///
/// Screens that use this (zero changes needed in any screen):
///   - login_screen    → login()
///   - register_screen → register()
///   - profile_screen  → currentUser, logout(), updateProfile()
///   - splash_screen   → authStateChanges stream (replaces isLoggedIn)
class AuthService {
  // ── Singleton ─────────────────────────────────────────────────
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // ── Firebase instances ────────────────────────────────────────
  final FirebaseAuth      _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db   = FirebaseFirestore.instance;

  // ── Cached user ───────────────────────────────────────────────
  // Populated after login/register and restored from Firestore
  // when authStateChanges fires on app restart.
  UserModel? _currentUser;

  // ── Public getters ────────────────────────────────────────────
  UserModel? get currentUser => _currentUser;

  /// True if Firebase has a signed-in user right now.
  /// Used by splash_screen as a synchronous fallback check.
  bool get isLoggedIn => _auth.currentUser != null;

  // ── authStateChanges ──────────────────────────────────────────
  /// Stream that emits whenever auth state changes:
  ///   - null  → user signed out
  ///   - User  → user signed in (session restored or new login)
  ///
  /// Used by splash_screen to navigate without a timer race condition.
  /// Firebase persists the session across cold starts automatically.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── login ─────────────────────────────────────────────────────
  /// Signs in with email + password via Firebase Auth,
  /// then loads the user profile from Firestore.
  ///
  /// Screen usage (unchanged):
  ///   final result = await AuthService().login(email: e, password: p);
  ///   if (result.success) Navigator.pushReplacementNamed(context, AppRoutes.home);
  ///   else _showError(result.error);
  Future<ServiceResult<UserModel>> login({
    required String email,
    required String password,
  }) async {
    // ── Client-side validation (same as before) ───────────────
    final e = email.trim();
    final p = password.trim();

    if (e.isEmpty || p.isEmpty) {
      return const ServiceResult.fail('Email and password are required.');
    }
    if (!_isValidEmail(e)) {
      return const ServiceResult.fail('Please enter a valid email address.');
    }
    if (p.length < 6) {
      return const ServiceResult.fail('Password must be at least 6 characters.');
    }

    try {
      // ── Firebase Auth sign-in ─────────────────────────────
      final credential = await _auth.signInWithEmailAndPassword(
        email:    e,
        password: p,
      );

      // ── Load profile from Firestore ───────────────────────
      _currentUser = await _fetchUserProfile(credential.user!.uid);
      return ServiceResult.ok(_currentUser);

    } on FirebaseAuthException catch (ex) {
      return ServiceResult.fail(_authErrorMessage(ex.code));
    } catch (ex) {
      return ServiceResult.fail('Login failed. Please try again.');
    }
  }

  // ── register ──────────────────────────────────────────────────
  /// Creates a Firebase Auth account, writes a UserModel document
  /// to Firestore at users/{uid}, then caches the user locally.
  ///
  /// Screen usage (unchanged):
  ///   final result = await AuthService().register(name: n, email: e, ...);
  ///   if (result.success) Navigator.pushReplacementNamed(context, AppRoutes.home);
  Future<ServiceResult<UserModel>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    // ── Client-side validation ────────────────────────────────
    if (name.trim().isEmpty) {
      return const ServiceResult.fail('Full name is required.');
    }
    if (!_isValidEmail(email.trim())) {
      return const ServiceResult.fail('Please enter a valid email address.');
    }
    if (phone.trim().isEmpty) {
      return const ServiceResult.fail('Phone number is required.');
    }
    if (password.trim().length < 6) {
      return const ServiceResult.fail('Password must be at least 6 characters.');
    }

    try {
      // ── Firebase Auth account creation ────────────────────
      final credential = await _auth.createUserWithEmailAndPassword(
        email:    email.trim(),
        password: password.trim(),
      );

      final uid = credential.user!.uid;

      // ── Build user model ──────────────────────────────────
      final newUser = UserModel(
        id:        uid,
        name:      name.trim(),
        email:     email.trim(),
        phone:     phone.trim(),
        avatarUrl: UserModel.seed.avatarUrl, // default avatar
        ordersCount:   0,
        wishlistCount: 0,
        reviewsCount:  0,
      );

      // ── Write profile to Firestore users/{uid} ────────────
      await _db
          .collection(AppConstants.colUsers)
          .doc(uid)
          .set(newUser.toJson());

      // ── Also update Firebase Auth display name ────────────
      await credential.user!.updateDisplayName(name.trim());

      _currentUser = newUser;
      return ServiceResult.ok(_currentUser);

    } on FirebaseAuthException catch (ex) {
      return ServiceResult.fail(_authErrorMessage(ex.code));
    } catch (ex) {
      return ServiceResult.fail('Registration failed. Please try again.');
    }
  }

  // ── logout ────────────────────────────────────────────────────
  /// Signs out from Firebase Auth and clears the local cache.
  ///
  /// Screen usage (unchanged):
  ///   AuthService().logout();
  ///   Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
     CartService().invalidateCart();
  }

  // ── updateProfile ─────────────────────────────────────────────
  /// Updates the Firestore user document and refreshes the local cache.
  ///
  /// Screen usage (unchanged):
  ///   final result = await AuthService().updateProfile(name: n, phone: p);
  Future<ServiceResult<UserModel>> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const ServiceResult.fail('Not logged in.');
    }

    try {
      // ── Build update map — only changed fields ─────────────
      final updates = <String, dynamic>{};
      if (name      != null && name.trim().isNotEmpty)  updates['name']      = name.trim();
      if (phone     != null && phone.trim().isNotEmpty) updates['phone']     = phone.trim();
      if (avatarUrl != null)                            updates['avatarUrl'] = avatarUrl;

      if (updates.isEmpty) {
        return ServiceResult.ok(_currentUser);
      }

      // ── Firestore partial update ──────────────────────────
      await _db
          .collection(AppConstants.colUsers)
          .doc(uid)
          .update(updates);

      // ── Refresh local cache ───────────────────────────────
      _currentUser = _currentUser?.copyWith(
        name:      name,
        phone:     phone,
        avatarUrl: avatarUrl,
      );

      // ── Also update Firebase Auth display name if name changed
      if (name != null && name.trim().isNotEmpty) {
        await _auth.currentUser!.updateDisplayName(name.trim());
      }

      return ServiceResult.ok(_currentUser);

    } catch (ex) {
      return ServiceResult.fail('Update failed. Please try again.');
    }
  }

  // ── restoreSession ────────────────────────────────────────────
  /// Called by splash_screen when authStateChanges fires with
  /// a non-null user — loads the Firestore profile into cache
  /// so currentUser is populated before any screen reads it.
  Future<void> restoreSession(String uid) async {
    _currentUser ??= await _fetchUserProfile(uid);
  }

  // ── Private: fetch Firestore profile ─────────────────────────
  Future<UserModel?> _fetchUserProfile(String uid) async {
    try {
      final doc = await _db
          .collection(AppConstants.colUsers)
          .doc(uid)
          .get();

      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromJson(doc.data()!);

    } catch (_) {
      // Firestore fetch failed — return null so caller can handle
      return null;
    }
  }

  // ── Private: human-readable Firebase error messages ──────────
  String _authErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  // ── Private: email validation ─────────────────────────────────
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(email);
  }
}