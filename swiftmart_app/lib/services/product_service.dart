import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/app_constant.dart';
import '../models/product_model.dart';
import 'auth_service.dart'; // re-exports ServiceResult

/// Manages the SwiftMart product catalogue using Cloud Firestore.
///
/// Architecture:
///   products/{id}                      → full product document
///   users/{uid}/favourites/{productId} → favourite flag per user
///
/// Every public method has the same signature as the in-memory
/// version — zero screen changes required.
///
/// Local cache:
///   _cache holds the last-fetched product list so the shop
///   screen renders instantly on repeat visits. Cache is
///   invalidated whenever admin writes (add/update/delete).
///
/// Firebase-ready comments show the exact Firestore operation
/// each method performs.
class ProductService {
  // ── Singleton ─────────────────────────────────────────────────
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  // ── Firebase instances ─────────────────────────────────────────
  final FirebaseFirestore _db   = FirebaseFirestore.instance;
  final FirebaseAuth      _auth = FirebaseAuth.instance;

  // ── Local read-through cache ───────────────────────────────────
  // Populated on first getAllProducts() call.
  // Cleared whenever a write operation changes the catalogue.
  List<ProductModel>? _cache;

  // ── Convenience refs ──────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection(AppConstants.colProducts);

  DocumentReference<Map<String, dynamic>> _productDoc(String id) =>
      _products.doc(id);

  CollectionReference<Map<String, dynamic>> _favourites(String uid) =>
      _db.collection(AppConstants.colUsers)
         .doc(uid)
         .collection('favourites');

  // ══════════════════════════════════════════════════════════════
  // READ OPERATIONS
  // ══════════════════════════════════════════════════════════════

  // ── getAllProducts ────────────────────────────────────────────
  /// Firestore: collection('products').orderBy('name').get()
  ///
  /// Returns the full catalogue, merging the user's favourite flags
  /// so isFavourite is accurate per-user.
  Future<ServiceResult<List<ProductModel>>> getAllProducts() async {
    try {
      // Return cache if available
      if (_cache != null) {
        return ServiceResult.ok(List.unmodifiable(_cache!));
      }

      // Fetch all products ordered alphabetically
      final snapshot = await _products
          .orderBy('name')
          .get();

      final raw = snapshot.docs
          .map((d) => ProductModel.fromJson({...d.data(), 'id': d.id}))
          .toList();

      // Merge favourite flags for the current user
      final merged = await _mergeFavourites(raw);
      _cache = merged;

      return ServiceResult.ok(List.unmodifiable(_cache!));

    } on FirebaseException catch (e) {
      return ServiceResult.fail(_firestoreError(e));
    } catch (e) {
      return ServiceResult.fail('Failed to load products.');
    }
  }

  // ── getByCategory ─────────────────────────────────────────────
  /// Firestore: collection('products')
  ///              .where('category', isEqualTo: category)
  ///              .orderBy('name')
  ///              .get()
  Future<ServiceResult<List<ProductModel>>> getByCategory(
      String category) async {
    try {
      if (category == 'ALL') return getAllProducts();

      final snapshot = await _products
          .where('category', isEqualTo: category)
          .orderBy('name')
          .get();

      final raw = snapshot.docs
          .map((d) => ProductModel.fromJson({...d.data(), 'id': d.id}))
          .toList();

      final merged = await _mergeFavourites(raw);
      return ServiceResult.ok(merged);

    } on FirebaseException catch (e) {
      return ServiceResult.fail(_firestoreError(e));
    } catch (e) {
      return ServiceResult.fail('Failed to load category.');
    }
  }

  // ── getProductById ────────────────────────────────────────────
  /// Firestore: doc('products', id).get()
  Future<ServiceResult<ProductModel>> getProductById(String id) async {
    try {
      // Check cache first for instant response
      if (_cache != null) {
        final cached = _cache!.where((p) => p.id == id).toList();
        if (cached.isNotEmpty) return ServiceResult.ok(cached.first);
      }

      final doc = await _productDoc(id).get();
      if (!doc.exists || doc.data() == null) {
        return ServiceResult.fail('Product not found.');
      }

      final product = ProductModel.fromJson({...doc.data()!, 'id': doc.id});
      final merged  = await _mergeFavourites([product]);
      return ServiceResult.ok(merged.first);

    } on FirebaseException catch (e) {
      return ServiceResult.fail(_firestoreError(e));
    } catch (e) {
      return ServiceResult.fail('Failed to load product.');
    }
  }

  // ── searchProducts ────────────────────────────────────────────
  /// Client-side filter on cached/fetched products.
  /// For production with large catalogues: replace with Algolia
  /// or Firestore full-text search extension.
  Future<ServiceResult<List<ProductModel>>> searchProducts(
      String query) async {
    try {
      // Ensure catalogue is loaded
      final allResult = await getAllProducts();
      if (!allResult.success) return allResult;

      if (query.trim().isEmpty) return allResult;

      final q = query.toLowerCase().trim();
      final results = allResult.data!
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q))
          .toList();

      return ServiceResult.ok(results);

    } catch (e) {
      return ServiceResult.fail('Search failed.');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // FAVOURITE OPERATIONS
  // ══════════════════════════════════════════════════════════════

  // ── toggleFavourite ───────────────────────────────────────────
  /// Firestore:
  ///   Add:    users/{uid}/favourites/{productId}.set({productId, addedAt})
  ///   Remove: users/{uid}/favourites/{productId}.delete()
  ///
  /// isFavourite is stored per-user, never on the product document.
  /// This means different users have independent favourite lists.
  Future<ServiceResult<ProductModel>> toggleFavourite(String id) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return ServiceResult.fail('Please log in to save favourites.');
    }

    try {
      final favDoc = _favourites(uid).doc(id);
      final snap   = await favDoc.get();
      final isNowFavourite = !snap.exists;

      if (isNowFavourite) {
        await favDoc.set({
          'productId': id,
          'addedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await favDoc.delete();
      }

      // Update cache so UI reflects immediately without re-fetch
      if (_cache != null) {
        final idx = _cache!.indexWhere((p) => p.id == id);
        if (idx != -1) {
          _cache![idx] = _cache![idx].copyWith(isFavourite: isNowFavourite);
          return ServiceResult.ok(_cache![idx]);
        }
      }

      // Cache miss — fetch the product and return with updated flag
      final productResult = await getProductById(id);
      if (!productResult.success) return productResult;
      return ServiceResult.ok(
          productResult.data!.copyWith(isFavourite: isNowFavourite));

    } on FirebaseException catch (e) {
      return ServiceResult.fail(_firestoreError(e));
    } catch (e) {
      return ServiceResult.fail('Failed to update favourite.');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // ADMIN WRITE OPERATIONS
  // ══════════════════════════════════════════════════════════════

  // ── addProduct ────────────────────────────────────────────────
  /// Firestore: collection('products').doc(product.id).set(data)
  ///
  /// Uses the product's own id as the document ID so admin edits
  /// in the Firestore console are predictable.
  Future<ServiceResult<ProductModel>> addProduct(
      ProductModel product) async {
    try {
      // Generate a Firestore document ID if not set
      final docRef = product.id.isEmpty
          ? _products.doc()           // auto-generated ID
          : _products.doc(product.id);

      final withId = product.id.isEmpty
          ? product.copyWith(id: docRef.id)
          : product;

      // toJson() excludes isFavourite — it's per-user, not on product
      final data = withId.toJson()..remove('isFavourite');
      await docRef.set(data);

      _cache = null; // invalidate cache so next read is fresh
      return ServiceResult.ok(withId);

    } on FirebaseException catch (e) {
      return ServiceResult.fail(_firestoreError(e));
    } catch (e) {
      return ServiceResult.fail('Failed to add product.');
    }
  }

  // ── updateProduct ─────────────────────────────────────────────
  /// Firestore: doc('products', id).update(fields)
  Future<ServiceResult<ProductModel>> updateProduct(
      ProductModel updated) async {
    try {
      final data = updated.toJson()..remove('isFavourite');
      await _productDoc(updated.id).update(data);

      // Patch cache entry without invalidating the whole list
      if (_cache != null) {
        final idx = _cache!.indexWhere((p) => p.id == updated.id);
        if (idx != -1) {
          // Preserve the isFavourite flag that was in cache
          final wasFavourite = _cache![idx].isFavourite;
          _cache![idx] = updated.copyWith(isFavourite: wasFavourite);
        }
      }

      return ServiceResult.ok(updated);

    } on FirebaseException catch (e) {
      return ServiceResult.fail(_firestoreError(e));
    } catch (e) {
      return ServiceResult.fail('Failed to update product.');
    }
  }

  // ── deleteProduct ─────────────────────────────────────────────
  /// Firestore: doc('products', id).delete()
  Future<ServiceResult<bool>> deleteProduct(String id) async {
    try {
      await _productDoc(id).delete();

      // Remove from cache immediately
      _cache?.removeWhere((p) => p.id == id);
      return const ServiceResult.ok(true);

    } on FirebaseException catch (e) {
      return ServiceResult.fail(_firestoreError(e));
    } catch (e) {
      return ServiceResult.fail('Failed to delete product.');
    }
  }

  // ── invalidateCache ───────────────────────────────────────────
  /// Forces the next getAllProducts() call to fetch fresh from Firestore.
  /// Call this after any external write (e.g. Firebase Console edits).
  void invalidateCache() => _cache = null;

  // ══════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ══════════════════════════════════════════════════════════════

  // ── _mergeFavourites ──────────────────────────────────────────
  /// Fetches the current user's favourite IDs and stamps
  /// isFavourite on each ProductModel in the list.
  ///
  /// Firestore: users/{uid}/favourites.get()
  /// If user is not logged in, isFavourite stays false for all.
  Future<List<ProductModel>> _mergeFavourites(
      List<ProductModel> products) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return products;

    try {
      final favSnap = await _favourites(uid).get();
      final favIds  = favSnap.docs.map((d) => d.id).toSet();

      return products
          .map((p) => p.copyWith(isFavourite: favIds.contains(p.id)))
          .toList();
    } catch (_) {
      // If favourites fetch fails, return products without flags
      return products;
    }
  }

  // ── _firestoreError ───────────────────────────────────────────
  String _firestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Access denied. Please check your permissions.';
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again.';
      case 'not-found':
        return 'Product not found.';
      case 'deadline-exceeded':
        return 'Request timed out. Please check your connection.';
      default:
        return 'Database error. Please try again.';
    }
  }
}