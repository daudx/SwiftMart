import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/utils/app_utils.dart';
import '../../models/order_model.dart';
import '../../routes/app_routes.dart';
import '../../services/order_service.dart';
import '../../widgets/bottom_nav.dart';
import '../../core/utils/responsive_layout.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  int _navIndex = 4;
  bool _isSearching = false;

  // Real-time Firestore stream — reflects admin status changes instantly
  Stream<List<OrderModel>>? _ordersStream;
  List<OrderModel> _allOrders = [];
  List<OrderModel> _filteredOrders = [];

  final _orderService = OrderService();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _initStream();
  }

  void _initStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _ordersStream = FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => OrderModel.fromJson({...d.data(), 'id': d.id}))
              .toList(),
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Live search on streamed orders ────────────────────────────
  void _onSearchChanged() {
    final q = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredOrders = q.isEmpty
          ? _allOrders
          : _allOrders
                .where(
                  (o) =>
                      o.id.toLowerCase().contains(q) ||
                      o.productName.toLowerCase().contains(q) ||
                      o.status.name.toLowerCase().contains(q),
                )
                .toList();
    });
  }

  void _applyStream(List<OrderModel> orders) {
    _allOrders = orders;
    final q = _searchController.text.toLowerCase().trim();
    _filteredOrders = q.isEmpty
        ? _allOrders
        : _allOrders
              .where(
                (o) =>
                    o.id.toLowerCase().contains(q) ||
                    o.productName.toLowerCase().contains(q) ||
                    o.status.name.toLowerCase().contains(q),
              )
              .toList();
  }

  void _handleBottomNavTap(int index) {
    if (index == _navIndex) return;
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.home);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, AppRoutes.shop);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRoutes.swiftBot);
        break;
      case 3:
        Navigator.pushReplacementNamed(context, AppRoutes.cart);
        break;
      default:
        setState(() => _navIndex = index);
    }
  }

  Future<void> _reorder(OrderModel order) async {
    await _orderService.reorderItem(order);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${order.productName} added to cart!'),
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pushReplacementNamed(context, AppRoutes.cart);
  }

  // ── E2: Order detail bottom sheet ────────────────────────────
  void _showOrderDetails(OrderModel order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title + order ID
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order Details',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  order.id,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Product image + name
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    order.productImageUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 72,
                      height: 72,
                      color: AppColors.surfaceContainerLowest,
                      child: const Icon(
                        Icons.image_outlined,
                        color: AppColors.outlineVariant,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.productName,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppUtils.formatPrice(order.price),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.tertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Detail rows
            _buildDetailRow('Date', order.date),
            _buildDetailRow('Status', order.status.name.toUpperCase()),
            _buildDetailRow('Amount', AppUtils.formatPrice(order.price)),

            const SizedBox(height: 24),

            // Reorder CTA
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _reorder(order);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.ctaGradientStart,
                      AppColors.ctaGradientEnd,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: AppShadows.raised,
                ),
                child: const Center(
                  child: Text(
                    'Reorder This Item',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    final content = ResponsiveLayout(
      maxWidth: 1400,
      child: StreamBuilder<List<OrderModel>>(
        stream: _ordersStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _applyStream(snapshot.data!));
            });
          }
          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 72)),

                  // ── E2: Search bar (shown when searching) ─────
                  if (_isSearching)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: AppShadows.pressed,
                          ),
                          child: Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 16),
                                child: Icon(
                                  Icons.search,
                                  color: AppColors.onSurfaceVariant,
                                  size: 20,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    color: AppColors.onSurface,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Search orders…',
                                    hintStyle: TextStyle(
                                      fontFamily: 'Inter',
                                      color: AppColors.onSurfaceVariant
                                          .withValues(alpha: 0.5),
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() {
                                    _isSearching = false;
                                    _filteredOrders = _allOrders;
                                  });
                                },
                                child: const Padding(
                                  padding: EdgeInsets.only(right: 12),
                                  child: Icon(
                                    Icons.close,
                                    color: AppColors.onSurfaceVariant,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildSectionHeader(),
                        const SizedBox(height: 32),
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            _allOrders.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        else if (_filteredOrders.isEmpty)
                          _buildEmptyState()
                        else
                          ..._filteredOrders.asMap().entries.map((entry) {
                            final isLast =
                                entry.key == _filteredOrders.length - 1;
                            return Padding(
                              padding: EdgeInsets.only(bottom: isLast ? 0 : 32),
                              child: _buildOrderCard(entry.value),
                            );
                          }),
                        const SizedBox(height: 200),
                      ]),
                    ),
                  ),
                ],
              ),
              Positioned(top: 0, left: 0, right: 0, child: _buildAppBar()),
              Positioned(
                bottom: isMobile ? 96 : 24,
                left: 24,
                right: 24,
                child: _buildSwiftBotBanner(),
              ),
            ],
          );
        },
      ),
    );

    if (isMobile) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            content,
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: BottomNav(
                currentIndex: _navIndex,
                onTap: _handleBottomNavTap,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          BottomNav(currentIndex: _navIndex, onTap: _handleBottomNavTap),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 16,
        24,
        16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        boxShadow: AppShadows.raised,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, AppRoutes.home);
              }
            },
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Order History',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.36,
                color: AppColors.onSurface,
              ),
            ),
          ),
          // ── E2: WIRED — search icon toggles search bar ────
          GestureDetector(
            onTap: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
                _filteredOrders = _allOrders;
              }
            }),
            child: Icon(
              _isSearching ? Icons.search_off : Icons.search,
              color: _isSearching ? AppColors.tertiary : AppColors.primary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Past Transactions',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.48,
            color: AppColors.onSurface,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(999),
            boxShadow: AppShadows.pressed,
          ),
          child: Text(
            '${_filteredOrders.length} ORDERS',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.outlineVariant,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No orders match your search.'
                  : 'No orders yet.',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.raised,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTopRow(order),
          const SizedBox(height: 16),
          _buildDateRow(order.date),
          const SizedBox(height: 24),
          _buildProductRow(order),
          const SizedBox(height: 32),
          _buildActionButtons(order),
        ],
      ),
    );
  }

  Widget _buildCardTopRow(OrderModel order) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          order.id,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.60),
          ),
        ),
        _buildStatusBadge(order.status),
      ],
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    final config = _statusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: config.bgColor.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: config.dotColor,
              shape: BoxShape.circle,
              boxShadow: config.dotGlow
                  ? [
                      BoxShadow(
                        color: config.dotColor.withValues(alpha: 0.70),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
              color: config.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(String date) {
    return Row(
      children: [
        const Icon(
          Icons.calendar_today_outlined,
          size: 16,
          color: AppColors.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          date,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildProductRow(OrderModel order) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppShadows.pressed,
                  ),
                  child: Image.network(
                    order.productImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.surfaceContainerLowest,
                      child: const Icon(
                        Icons.image_outlined,
                        color: AppColors.outlineVariant,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.productName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Tap to view details',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Text(
          AppUtils.formatPrice(order.price),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.tertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    final bool isShipped = order.status == OrderStatus.shipped;
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.replay,
            label: 'Reorder',
            onTap: () => _reorder(order),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: isShipped
              ? _buildActionButton(
                  icon: Icons.local_shipping_outlined,
                  label: 'Track',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tracking coming soon.'),
                      backgroundColor: AppColors.surfaceContainerHigh,
                      behavior: SnackBarBehavior.floating,
                    ),
                  ),
                )
              // ── E2: WIRED — Details opens order detail sheet ──
              : _buildActionButton(
                  icon: Icons.receipt_long_outlined,
                  label: 'Details',
                  onTap: () => _showOrderDetails(order),
                ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppShadows.raised,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwiftBotBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.raised,
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryContainer.withValues(alpha: 0.30),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.chat_bubble,
              color: AppColors.onPrimaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEED HELP?',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Talk to SwiftBot about your deliveries.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.swiftBot),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.ctaGradientStart,
                    AppColors.ctaGradientEnd,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.swiftBot,
                  ),
                  borderRadius: BorderRadius.circular(999),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Ask Bot',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF04342C),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

_StatusConfig _statusConfig(OrderStatus status) {
  switch (status) {
    case OrderStatus.delivered:
      return _StatusConfig(
        label: 'Delivered',
        textColor: AppColors.tertiary,
        dotColor: AppColors.tertiary,
        bgColor: AppColors.primaryContainer,
        dotGlow: true,
      );
    case OrderStatus.shipped:
      return _StatusConfig(
        label: 'Shipped',
        textColor: AppColors.secondary,
        dotColor: AppColors.secondary,
        bgColor: const Color(0xFF015432),
        dotGlow: false,
      );
    case OrderStatus.processing:
      return _StatusConfig(
        label: 'Processing',
        textColor: AppColors.error,
        dotColor: AppColors.error,
        bgColor: const Color(0xFF93000A),
        dotGlow: false,
      );
    case OrderStatus.cancelled:
      return _StatusConfig(
        label: 'Cancelled',
        textColor: Colors.grey,
        dotColor: Colors.grey,
        bgColor: const Color(0xFF2A2A2A),
        dotGlow: false,
      );
  }
}

class _StatusConfig {
  final String label;
  final Color textColor, dotColor, bgColor;
  final bool dotGlow;
  const _StatusConfig({
    required this.label,
    required this.textColor,
    required this.dotColor,
    required this.bgColor,
    required this.dotGlow,
  });
}
