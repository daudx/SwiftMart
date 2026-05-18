import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shadows.dart';
import '../core/utils/app_utils.dart';
import '../models/product_model.dart';

/// Reusable product card used in grids and carousels.
///
/// Accepts a full [ProductModel] — no more String title/price.
/// Firebase-ready: data comes from ProductService which will be
/// backed by Firestore in the next phase.
///
/// Usage:
/// ```dart
/// ProductCard(
///   product: product,
///   onTap: () => Navigator.pushNamed(context, AppRoutes.product,
///       arguments: product),
///   onAddToCart: () => CartService().addItem(
///       product: product, selectedSize: product.sizes.first),
/// )
/// ```
class ProductCard extends StatelessWidget {
  final ProductModel   product;
  final VoidCallback?  onTap;
  final VoidCallback?  onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.raised,
          border: Border.all(
            color: AppColors.tertiary.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Product image ──────────────────────────────
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20)),
                child: Container(
                  color: AppColors.surfaceContainerLowest,
                  child: Image.network(
                    product.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Center(
                      child: Icon(Icons.image_outlined,
                          color: AppColors.outlineVariant, size: 40),
                    ),
                  ),
                ),
              ),
            ),

            // ── Info section ───────────────────────────────
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0x66064E3B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.category,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),

                        // Product name — truncated to fit 2 lines
                        Text(
                          AppUtils.truncate(product.name, 24),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),

                    // Price + Add to Cart row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Price
                        Text(
                          AppUtils.formatPrice(product.price),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.tertiary,
                          ),
                        ),

                        // Add to Cart mini-button
                        if (onAddToCart != null)
                          GestureDetector(
                            onTap: onAddToCart,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: AppShadows.raisedSmall,
                              ),
                              child: const Icon(
                                Icons.add_shopping_cart_outlined,
                                color: AppColors.tertiary,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}