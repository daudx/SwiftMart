import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/utils/responsive_layout.dart';
import 'add_product_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  // ── Update order status ──────────────────────────────────────
  void _updateOrderStatus(String docId, String newStatus) {
    FirebaseFirestore.instance
        .collection('orders')
        .doc(docId)
        .update({'status': newStatus});
  }

  // ── Delete product with confirmation ────────────────────────
  void _deleteProduct(BuildContext context, String docId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Product?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Delete "$name"? This cannot be undone.',
          style: const TextStyle(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('products')
                  .doc(docId)
                  .delete();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"$name" deleted.'),
                  backgroundColor: AppColors.surfaceContainerHigh,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.logout, color: AppColors.primary),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (_) => false,
                );
              }
            },
          ),
          title: const Text(
            'Admin Dashboard',
            style: TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.background,
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.onSurfaceVariant,
            tabs: [
              Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Products'),
              Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Orders'),
            ],
          ),
        ),
        body: ResponsiveLayout(
          child: TabBarView(
            children: [
              _buildProductsTab(context),
              _buildOrdersTab(context),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // TAB 1 — PRODUCTS
  // ════════════════════════════════════════════════════════════

  Widget _buildProductsTab(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}',
                style: const TextStyle(color: AppColors.error)),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                // Header + count
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Product Catalogue',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${docs.length} items',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (docs.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: Text('No products yet. Tap + to add one.',
                          style:
                              TextStyle(color: AppColors.onSurfaceVariant)),
                    ),
                  )
                else
                  ...docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildProductCard(context, doc.id, data);
                  }),
              ],
            ),
            // FAB — Add Product
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton.extended(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddProductScreen()),
                ),
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                icon: const Icon(Icons.add),
                label: const Text('Add Product',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductCard(
      BuildContext context, String docId, Map<String, dynamic> data) {
    final name = data['name'] as String? ?? 'Unnamed';
    final price = (data['price'] as num?)?.toStringAsFixed(2) ?? '0.00';
    final category = (data['category'] as String? ?? 'N/A').toUpperCase();
    final stock = (data['stock'] as num?)?.toInt() ?? 0;
    final imageUrl = data['imageUrl'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.raisedSmall,
      ),
      child: Row(
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 64,
              height: 64,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surfaceContainerLow,
                        child: const Icon(Icons.broken_image,
                            color: AppColors.onSurfaceVariant),
                      ),
                    )
                  : Container(
                      color: AppColors.surfaceContainerLow,
                      child: const Icon(Icons.image_outlined,
                          color: AppColors.onSurfaceVariant),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0),
                ),
                Text(
                  name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('\$$price',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: stock > 0
                            ? AppColors.primaryContainer.withValues(alpha: 0.2)
                            : Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$stock in stock',
                        style: TextStyle(
                            color:
                                stock > 0 ? AppColors.tertiary : Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Edit button
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: AppColors.onSurfaceVariant, size: 20),
            tooltip: 'Edit',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddProductScreen(
                  productId: docId,
                  productData: data,
                ),
              ),
            ),
          ),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.redAccent, size: 20),
            tooltip: 'Delete',
            onPressed: () => _deleteProduct(context, docId, name),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // TAB 2 — ORDERS
  // ════════════════════════════════════════════════════════════

  Widget _buildOrdersTab(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}',
                style: const TextStyle(color: AppColors.error)),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_outlined,
                    color: AppColors.outlineVariant, size: 56),
                SizedBox(height: 16),
                Text('No orders yet.',
                    style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('All Orders',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${docs.length} total',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _buildOrderCard(context, doc.id, data);
            }),
          ],
        );
      },
    );
  }

  Widget _buildOrderCard(
      BuildContext context, String docId, Map<String, dynamic> data) {
    final productName = data['productName'] as String? ?? 'Unknown Product';
    final productImage = data['productImageUrl'] as String? ?? '';
    final total = (data['price'] as num?)?.toDouble() ??
        (data['totalAmount'] as num?)?.toDouble() ??
        0.0;
    final rawStatus = data['status'] as String? ?? 'processing';
    final currentStatus = _validStatus(rawStatus);
    final date = data['date'] as String? ?? 'N/A';

    final statusColors = {
      'processing': Colors.orange,
      'shipped': AppColors.secondary,
      'delivered': AppColors.tertiary,
      'cancelled': Colors.red,
    };
    final statusColor = statusColors[currentStatus] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.raisedSmall,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID + status badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ID: ${docId.length > 12 ? docId.substring(0, 12) : docId}...',
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant
                            .withValues(alpha: 0.7)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text(currentStatus.toUpperCase(),
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Product row
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: productImage.isNotEmpty
                        ? Image.network(productImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                  color: AppColors.surfaceContainerLow,
                                  child: const Icon(Icons.image_outlined,
                                      color:
                                          AppColors.onSurfaceVariant,
                                      size: 24),
                                ))
                        : Container(
                            color: AppColors.surfaceContainerLow,
                            child: const Icon(Icons.shopping_bag_outlined,
                                color: AppColors.onSurfaceVariant,
                                size: 24),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(productName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(date,
                          style: const TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 12)),
                    ],
                  ),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: AppColors.tertiary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.outlineVariant),
            const SizedBox(height: 8),
            // Status changer
            Row(
              children: [
                const Text('Update status:',
                    style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor: AppColors.surfaceContainerHigh,
                      value: currentStatus,
                      isDense: true,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                      items: const [
                        DropdownMenuItem(
                            value: 'processing',
                            child: Text('Processing')),
                        DropdownMenuItem(
                            value: 'shipped',
                            child: Text('Shipped')),
                        DropdownMenuItem(
                            value: 'delivered',
                            child: Text('Delivered')),
                        DropdownMenuItem(
                            value: 'cancelled',
                            child: Text('Cancelled')),
                      ],
                      onChanged: (newStatus) {
                        if (newStatus != null && newStatus != currentStatus) {
                          _updateOrderStatus(docId, newStatus);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Order status → ${newStatus.toUpperCase()}'),
                              backgroundColor:
                                  AppColors.surfaceContainerHigh,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Ensures the status string is always a valid dropdown value.
  String _validStatus(String raw) {
    const valid = ['processing', 'shipped', 'delivered', 'cancelled'];
    return valid.contains(raw.toLowerCase()) ? raw.toLowerCase() : 'processing';
  }
}
