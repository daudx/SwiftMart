import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/app_constant.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import 'auth_service.dart'; // re-exports ServiceResult

/// Manages the shopping cart using Cloud Firestore.
///
/// Firestore structure:
///   users/{uid}/cart/{productId_size}   → CartItemModel document
///
/// The document key is "{productId}_{selectedSize}" — deterministic
/// so adding the same product+size twice increments quantity rather
/// than duplicating.
///
/// Local mirror:
///   _items is kept in sync with Firestore. All reads come from the
///   mirror (instant). All writes go to both mirror + Firestore
///   (optimistic UI — screen updates immediately, Firestore catches up).
///
/// Stepper increment/decrement stay synchronous for instant UI
/// feedback. The Firestore write happens in the background via
/// _syncItem() which does not block the UI.
///
/// Screens that use this (zero changes needed):
///   - cart_screen        → items, addItem(), removeItem(),
///                          increment(), decrement(), subtotal,
///                          grandTotal, applyPromoCode()
///   - home_screen        → addItem()
///   - shop_screen        → addItem()
///   - product_screen     → addItem()
///   - swiftbot screens   → addItem()
class CartService {
  // ── Singleton ─────────────────────────────────────────────────
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  // ── Firebase instances ─────────────────────────────────────────
  final FirebaseFirestore _db   = FirebaseFirestore.instance;
  final FirebaseAuth      _auth = FirebaseAuth.instance;

  // ── Local mirror ───────────────────────────────────────────────
  // Populated on first loadCart() call and kept in sync with writes.
  final List<CartItemModel> _items = [];
  bool _loaded = false; // true once Firestore has been read at least once

  // ── Tax ───────────────────────────────────────────────────────
  static const double _taxAmount = AppConstants.cartTaxAmount;

  // ── Firestore cart collection ref ─────────────────────────────
  CollectionReference<Map<String, dynamic>>? get _cartRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _db
        .collection(AppConstants.colUsers)
        .doc(uid)
        .collection(AppConstants.colCart);
  }

  // ── Deterministic document key ─────────────────────────────────
  // "{productId}_{selectedSize}" — e.g. "prd_001_10"
  // Firestore document IDs cannot contain '/' so size strings
  // like "XL" or "One Size" are safe. Spaces are replaced with '_'.
  String _cartKey(String productId, String size) =>
      '${productId}_${size.replaceAll(' ', '_')}';

  // ════════════════════════════════════════════════════════════
  // GETTERS — read from local mirror, always instant
  // ════════════════════════════════════════════════════════════

  List<CartItemModel> get items     => List.unmodifiable(_items);
  int    get itemCount              => _items.fold(0, (s, i) => s + i.quantity);
  bool   get isEmpty                => _items.isEmpty;
  double get subtotal               => _items.fold(0.0, (s, i) => s + i.total);
  double get tax                    => _taxAmount;
  double get grandTotal             => subtotal + _taxAmount;

  // ════════════════════════════════════════════════════════════
  // LOAD — call once when the cart screen or app starts
  // ════════════════════════════════════════════════════════════

  /// Loads the user's cart from Firestore into the local mirror.
  ///
  /// Called automatically by addItem() if the cart hasn't been
  /// loaded yet — screens do not need to call this explicitly.
  ///
  /// Firestore: users/{uid}/cart.get()
  Future<void> loadCart() async {
    if (_loaded) return;
    final ref = _cartRef;
    if (ref == null) return; // not logged in

    try {
      final snap = await ref.get();
      _items.clear();
      for (final doc in snap.docs) {
        try {
          _items.add(CartItemModel.fromJson(doc.data()));
        } catch (_) {
          // Skip malformed documents silently
        }
      }
      _loaded = true;
    } catch (_) {
      // Firestore unavailable — _items stays empty, will retry next call
    }
  }

  // ════════════════════════════════════════════════════════════
  // WRITE OPERATIONS
  // ════════════════════════════════════════════════════════════

  // ── addItem ───────────────────────────────────────────────────
  /// Adds a product to the cart. If the same product+size exists,
  /// increments quantity. Writes to both mirror and Firestore.
  ///
  /// Screen usage (unchanged):
  ///   CartService().addItem(product: p, selectedSize: size);
  Future<ServiceResult<CartItemModel>> addItem({
    required ProductModel product,
    required String selectedSize,
    int quantity = 1,
  }) async {
    // Ensure cart is loaded before mutating
    await loadCart();

    final key      = _cartKey(product.id, selectedSize);
    final existing = _items.indexWhere(
      (i) => i.product.id == product.id && i.selectedSize == selectedSize,
    );

    CartItemModel item;

    if (existing != -1) {
      // ── Already in cart — bump quantity ──────────────────
      _items[existing].quantity += quantity;
      item = _items[existing];
    } else {
      // ── New item ──────────────────────────────────────────
      item = CartItemModel(
        product:      product,
        selectedSize: selectedSize,
        quantity:     quantity,
      );
      _items.add(item);
    }

    // Write to Firestore in background — don't await in UI path
    _syncItem(key, item);

    return ServiceResult.ok(item);
  }

  // ── removeItem ────────────────────────────────────────────────
  /// Removes a line item by its list index.
  /// Deletes the Firestore document for this item.
  ///
  /// Screen usage (unchanged):
  ///   CartService().removeItem(index);
  Future<ServiceResult<bool>> removeItem(int index) async {
    if (index < 0 || index >= _items.length) {
      return ServiceResult.fail('Invalid cart index.');
    }

    final item = _items[index];
    final key  = _cartKey(item.product.id, item.selectedSize);

    // Update mirror immediately
    _items.removeAt(index);

    // Delete from Firestore in background
    _deleteItem(key);

    return const ServiceResult.ok(true);
  }

  // ── updateQuantity ────────────────────────────────────────────
  /// Sets quantity directly. Removes item if quantity drops to 0.
  ///
  /// Screen usage (unchanged):
  ///   CartService().updateQuantity(index, newQty);
  Future<ServiceResult<CartItemModel?>> updateQuantity(
      int index, int quantity) async {
    if (index < 0 || index >= _items.length) {
      return ServiceResult.fail('Invalid cart index.');
    }

    if (quantity <= 0) {
      await removeItem(index);
      return const ServiceResult.ok(null);
    }

    _items[index].quantity = quantity;
    final item = _items[index];
    final key  = _cartKey(item.product.id, item.selectedSize);
    _syncItem(key, item);

    return ServiceResult.ok(item);
  }

  // ── increment ────────────────────────────────────────────────
  /// Synchronous — updates mirror immediately for instant UI.
  /// Firestore write happens in background via _syncItem().
  ///
  /// Screen usage (unchanged — called without await):
  ///   _cart.increment(index); setState(() {});
  void increment(int index) {
    if (index < 0 || index >= _items.length) return;
    _items[index].quantity++;
    final item = _items[index];
    _syncItem(_cartKey(item.product.id, item.selectedSize), item);
  }

  // ── decrement ─────────────────────────────────────────────────
  /// Synchronous — updates mirror immediately for instant UI.
  /// Removes item from both mirror and Firestore if quantity hits 0.
  ///
  /// Screen usage (unchanged — called without await):
  ///   _cart.decrement(index); setState(() {});
  void decrement(int index) {
    if (index < 0 || index >= _items.length) return;
    if (_items[index].quantity > 1) {
      _items[index].quantity--;
      final item = _items[index];
      _syncItem(_cartKey(item.product.id, item.selectedSize), item);
    } else {
      // Quantity would hit 0 — remove the item entirely
      final item = _items[index];
      final key  = _cartKey(item.product.id, item.selectedSize);
      _items.removeAt(index);
      _deleteItem(key);
    }
  }

  // ── clearCart ─────────────────────────────────────────────────
  /// Empties the cart locally and deletes all Firestore documents.
  /// Called by OrderService.placeOrder() after checkout.
  ///
  /// Screen usage (unchanged — called by OrderService internally).
  Future<void> clearCart() async {
    final ref = _cartRef;
    _items.clear();
    _loaded = false;

    if (ref == null) return;

    try {
      // Batch delete all cart documents
      final snap  = await ref.get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (_) {
      // If batch fails, Firestore will be out of sync.
      // Next loadCart() will re-read and fix it.
    }
  }

  // ── applyPromoCode ────────────────────────────────────────────
  /// Validates a promo code and returns the discount amount.
  /// Codes are defined in AppConstants.promoCodes.
  ///
  /// Screen usage (unchanged):
  ///   final result = await _cart.applyPromoCode(code);
  Future<ServiceResult<double>> applyPromoCode(String code) async {
    // Ensure totals are loaded before calculating discount
    await loadCart();

    final discount = AppConstants.promoCodes[code.trim().toUpperCase()];
    if (discount == null) {
      return ServiceResult.fail(AppConstants.errInvalidPromo);
    }
    return ServiceResult.ok(subtotal * discount);
  }

  // ── invalidateCart ────────────────────────────────────────────
  /// Forces next loadCart() to re-fetch from Firestore.
  /// Call this after logout so the next user starts fresh.
  void invalidateCart() {
    _items.clear();
    _loaded = false;
  }

  // ════════════════════════════════════════════════════════════
  // PRIVATE — Firestore background writes
  // ════════════════════════════════════════════════════════════

  /// Writes or updates a cart item document.
  /// Fire-and-forget — does not block the UI.
  void _syncItem(String key, CartItemModel item) {
    final ref = _cartRef;
    if (ref == null) return;
    // toJson() embeds the full product snapshot so the cart
    // renders correctly even if product prices change later.
    ref.doc(key).set(item.toJson(), SetOptions(merge: false)).catchError((_) {
      // Silent fail — item is still in local mirror,
      // will re-sync on next explicit save or app restart.
    });
  }

  /// Deletes a cart item document. Fire-and-forget.
  void _deleteItem(String key) {
    _cartRef?.doc(key).delete().catchError((_) {});
  }
}