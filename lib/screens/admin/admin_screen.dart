import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/utils/responsive_layout.dart';
import '../../routes/app_routes.dart';
import 'add_product_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  void _updateOrderStatus(String docId, String newStatus) {
    FirebaseFirestore.instance.collection('orders').doc(docId).update({
      'status': newStatus,
    });
  }

  void _deleteProduct(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: const Text(
          'Delete Product?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('products')
                  .doc(docId)
                  .delete();
              Navigator.pop(ctx);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
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
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
            onPressed: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.login),
          ),
          title: const Text(
            'Admin Dashboard',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppColors.background,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: AppColors.primary),
              onPressed: () {},
            ),
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                backgroundColor: AppColors.surfaceContainerHigh,
                child: Icon(Icons.person, color: Colors.white),
              ),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.onSurfaceVariant,
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
              Tab(icon: Icon(Icons.list_alt), text: 'Orders'),
            ],
          ),
        ),
        body: ResponsiveLayout(
          child: TabBarView(
            children: [
              // TAB 1: STORE OVERVIEW & PRODUCT MANAGEMENT
              _buildDashboardTab(context),

              // TAB 2: ORDER MANAGEMENT
              _buildOrderManagementTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardTab(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final products = snapshot.data?.docs ?? [];
        final itemsTotal = products.length;

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Store Overview',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'SYSTEMS ONLINE • LIVE',
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'PRODUCTS',
                    itemsTotal.toString(),
                    Icons.inventory_2,
                    '+13%',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'ORDERS',
                    'Live',
                    Icons.shopping_cart,
                    'Active',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2211),
                border: const Border(
                  left: BorderSide(color: Colors.orange, width: 4),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'INVENTORY ALERT\nSome products are missing prices or descriptions. Update soon.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Manage Products\n$itemsTotal ITEMS TOTAL',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ...products.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _buildProductListItem(
                context,
                docId: doc.id,
                name: data['name'] ?? 'Unknown Item',
                price: data['price']?.toString() ?? '0.00',
                category: data['categoryId'] ?? 'PROD',
                stock: 10,
                data: data,
              );
            }),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddProductScreen()),
                );
              },
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              label: const Text(
                'ADD NEW PRODUCT',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceContainerLowest,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.surfaceContainerHigh),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    String badge,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.raisedSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.onSurfaceVariant, size: 20),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withOpacity(0.2),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductListItem(
    BuildContext context, {
    required String docId,
    required String name,
    required String price,
    required String category,
    required int stock,
    required Map<String, dynamic> data,
  }) {
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
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.image, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Text(
                      '\$$price',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$stock in stock',
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.edit,
              color: AppColors.onSurfaceVariant,
              size: 20,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddProductScreen(
                    productId: docId,
                    productData: data,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
              size: 20,
            ),
            onPressed: () => _deleteProduct(context, docId),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderManagementTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No orders found. Place an order first!',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final orders = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index].data() as Map<String, dynamic>;
            final docId = orders[index].id;
            final currentStatus = order['status'] ?? 'processing';
            final total = order['totalAmount'] ?? 0.0;

            return Card(
              color: AppColors.surfaceContainerLow,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(
                  'Order ID: ${docId.substring(0, 8)}...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Total: \$${total.toStringAsFixed(2)}\nStatus: ${currentStatus.toUpperCase()}',
                  style: const TextStyle(color: AppColors.onSurfaceVariant),
                ),
                trailing: DropdownButton<String>(
                  dropdownColor: AppColors.surfaceContainerHigh,
                  value: currentStatus,
                  style: const TextStyle(color: AppColors.primary),
                  items: const [
                    DropdownMenuItem(value: 'processing', child: Text('Processing')),
                    DropdownMenuItem(value: 'shipped', child: Text('Shipped')),
                    DropdownMenuItem(value: 'delivered', child: Text('Delivered')),
                  ],
                  onChanged: (newStatus) {
                    if (newStatus != null) _updateOrderStatus(docId, newStatus);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

