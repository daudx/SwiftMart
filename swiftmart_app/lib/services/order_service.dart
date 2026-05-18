import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/app_constant.dart';
import '../core/utils/app_utils.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import 'auth_service.dart'; // re-exports ServiceResult
import 'cart_service.dart';

/// Manages order history and placement using Cloud Firestore.
///
/// Firestore structure:
///   orders/{orderId}  → OrderModel + userId + createdAt fields
///
/// Orders are a top-level collection filtered by userId.
/// This lets admin users query all orders regardless of owner.
///
/// placeOrder() uses a Firestore batch write:
///   1. Create one order document per cart item in orders/
///   2. Delete all cart documents in users/{uid}/cart/
/// Both happen atomically — if either fails, neither commits.
///
/// Screens that use this (zero changes needed):
///   - cart_screen          → placeOrder()
///   - order_history_screen → getOrders(), reorderItem()
class OrderService {
  // ── Singleton ─────────────────────────────────────────────────
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  // ── Firebase instances ─────────────────────────────────────────
  final FirebaseFirestore _db   = FirebaseFirestore.instance;
  final FirebaseAuth      _auth = FirebaseAuth.instance;

  // ── Convenience ref ───────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection(AppConstants.colOrders);

  // ════════════════════════════════════════════════════════════
  // READ OPERATIONS
  // ════════════════════════════════════════════════════════════

  // ── getOrders ─────────────────────────────────────────────────
  /// Returns all orders for the current user, newest first.
  ///
  /// Firestore:
  ///   collection('orders')
  ///     .where('userId', isEqualTo: uid)
  ///     .orderBy('createdAt', descending: true)
  ///     .get()
  ///
  /// Screen usage (unchanged):
  ///   final result = await OrderService().getOrders();
  ///   if (result.success) setState(() => _orders = result.data!);
  Future<ServiceResult<List<OrderModel>>> getOrders() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return ServiceResult.fail('Please log in to view your orders.');
    }

    try {
      final snap = await _orders
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();

      final list = snap.docs
          .map((d) => OrderModel.fromJson({...d.data(), 'id': d.id}))
          .toList();

      return ServiceResult.ok(list);

    } on FirebaseException catch (e) {
      return ServiceResult.fail(_firestoreError(e));
    } catch (e) {
      return ServiceResult.fail('Failed to load orders.');
    }
  }

  // ── getOrderById ──────────────────────────────────────────────
  /// Firestore: doc('orders', id).get()
  Future<ServiceResult<OrderModel>> getOrderById(String id) async {
    try {
      final doc = await _orders.doc(id).get();
      if (!doc.exists || doc.data() == null) {
        return ServiceResult.fail('Order not found.');
      }
      return ServiceResult.ok(
          OrderModel.fromJson({...doc.data()!, 'id': doc.id}));

    } on FirebaseException catch (e) {
      return ServiceResult.fail(_firestoreError(e));
    } catch (e) {
      return ServiceResult.fail('Failed to load order.');
    }
  }

  // ════════════════════════════════════════════════════════════
  // WRITE OPERATIONS
  // ════════════════════════════════════════════════════════════

  // ── placeOrder ────────────────────────────────────────────────
  /// Converts the cart into orders and clears the cart atomically.
  ///
  /// Firestore batch:
  ///   - For each cart item: orders.doc(autoId).set(orderData)
  ///   - For each cart doc:  users/{uid}/cart/{key}.delete()
  ///
  /// Screen usage (unchanged):
  ///   final result = await OrderService().placeOrder();
  ///   if (result.success) Navigator.pushReplacementNamed(context, AppRoutes.orders);
  Future<ServiceResult<List<OrderModel>>> placeOrder() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return ServiceResult.fail('Please log in to place an order.');
    }

    // Ensure cart is loaded
    await CartService().loadCart();
    final cartItems = CartService().items;

    if (cartItems.isEmpty) {
      return ServiceResult.fail(AppConstants.errEmptyCart);
    }

    try {
      final now        = DateTime.now();
      final batch      = _db.batch();
      final newOrders  = <OrderModel>[];

      // ── 1. Create one order document per cart item ────────
      for (final item in cartItems) {
        final docRef = _orders.doc(); // auto-generated Firestore ID

        final order = OrderModel(
          id:              docRef.id,
          productName:     item.product.name,
          productImageUrl: item.product.imageUrl,
          price:           item.total,
          date:            'Today, ${AppUtils.formatTime(now)}',
          status:          OrderStatus.processing,
        );

        // Build the Firestore document — add userId and createdAt
        // which are not part of OrderModel.toJson() (they are
        // Firestore-specific metadata, not UI fields)
        final data = {
          ...order.toJson(),
          'userId':    uid,
          'createdAt': FieldValue.serverTimestamp(),
        };

        batch.set(docRef, data);
        newOrders.add(order);
      }

      // ── 2. Delete all cart documents in the same batch ────
      final cartRef  = _db
          .collection(AppConstants.colUsers)
          .doc(uid)
          .collection(AppConstants.colCart);

      final cartSnap = await cartRef.get();
      for (final doc in cartSnap.docs) {
        batch.delete(doc.reference);
      }

      // ── 3. Commit both writes atomically ──────────────────
      await batch.commit();

      // Clear local mirror after successful commit
      CartService().invalidateCart();

      return ServiceResult.ok(newOrders);

    } on FirebaseException catch (e) {
      return ServiceResult.fail(_firestoreError(e));
    } catch (e) {
      return ServiceResult.fail('Checkout failed. Please try again.');
    }
  }

  // ── reorderItem ───────────────────────────────────────────────
  /// Re-adds a past order's product to the cart.
  /// Fetches the full product from Firestore for accurate pricing.
  ///
  /// Screen usage (unchanged):
  ///   await OrderService().reorderItem(order);
  ///   Navigator.pushReplacementNamed(context, AppRoutes.cart);
  Future<ServiceResult<bool>> reorderItem(OrderModel order) async {
    try {
      // Fetch the current product from Firestore for live pricing.
      // Falls back to order price if product was deleted.
      ProductModel product;

      // Try to find the product by name in the orders collection —
      // the productName is denormalised so we can do a direct lookup
      final productRef = _db
          .collection(AppConstants.colProducts)
          .where('name', isEqualTo: order.productName)
          .limit(1);

      final snap = await productRef.get();

      if (snap.docs.isNotEmpty) {
        product = ProductModel.fromJson(
            {...snap.docs.first.data(), 'id': snap.docs.first.id});
      } else {
        // Product was deleted — use order snapshot data as fallback
        product = ProductModel(
          id:       order.id,
          name:     order.productName,
          category: '',
          price:    order.price,
          imageUrl: order.productImageUrl,
        );
      }

      await CartService().addItem(
        product:      product,
        selectedSize: 'Default',
      );

      return const ServiceResult.ok(true);

    } on FirebaseException catch (e) {
      return ServiceResult.fail(_firestoreError(e));
    } catch (e) {
      return ServiceResult.fail('Failed to reorder. Please try again.');
    }
  }

  // ── updateOrderStatus ─────────────────────────────────────────
  /// Admin operation — updates the status field on an order document.
  ///
  /// Firestore: doc('orders', id).update({'status': status.name})
  Future<ServiceResult<OrderModel>> updateOrderStatus(
      String id, OrderStatus status) async {
    try {
      await _orders.doc(id).update({'status': status.name});

      // Re-fetch the updated document to return accurate data
      return getOrderById(id);

    } on FirebaseException catch (e) {
      return ServiceResult.fail(_firestoreError(e));
    } catch (e) {
      return ServiceResult.fail('Failed to update order status.');
    }
  }

  // ════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ════════════════════════════════════════════════════════════

  String _firestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Access denied. Please check your permissions.';
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again.';
      case 'not-found':
        return 'Order not found.';
      case 'deadline-exceeded':
        return 'Request timed out. Please check your connection.';
      default:
        return 'Database error. Please try again.';
    }
  }
}