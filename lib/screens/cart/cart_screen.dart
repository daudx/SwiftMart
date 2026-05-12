import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/utils/app_utils.dart';
import '../../routes/app_routes.dart';
import '../../services/cart_service.dart';
import '../../services/order_service.dart';
import '../../widgets/bottom_nav.dart';
import '../../core/utils/responsive_layout.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  int  _navIndex  = 3;
  bool _isLoading = false;

  final _cart   = CartService();
  final _orders = OrderService();

  // In cart_screen.dart — add to initState():
@override
void initState() {
  super.initState();
  // ── Load cart from Firestore on screen open ──────────────
  CartService().loadCart().then((_) {
    if (mounted) setState(() {});
  });
}

  void _handleBottomNavTap(int index) {
    if (index == _navIndex) return;
    switch (index) {
      case 0: Navigator.pushReplacementNamed(context, AppRoutes.home);    break;
      case 1: Navigator.pushReplacementNamed(context, AppRoutes.shop);    break;
      case 2: Navigator.pushReplacementNamed(context, AppRoutes.swiftBot); break;
      case 4: Navigator.pushReplacementNamed(context, AppRoutes.profile); break;
      default: setState(() => _navIndex = index);
    }
  }

  Future<void> _checkout() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final result = await _orders.placeOrder();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully! 🎉'),
          backgroundColor: AppColors.surfaceContainerHigh,
          behavior: SnackBarBehavior.floating));
      Navigator.pushReplacementNamed(context, AppRoutes.orders);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Checkout failed.'),
          backgroundColor: AppColors.surfaceContainerHigh,
          behavior: SnackBarBehavior.floating));
    }
  }

  // ── E4: Swipe-to-delete ───────────────────────────────────────
  Future<void> _removeItem(int index) async {
    final name = _cart.items[index].product.name;
    await _cart.removeItem(index);
    if (!mounted) return;
    setState(() {});
    AppUtils.showSnackBar(context, '$name removed from cart.');
  }

  @override
  Widget build(BuildContext context) {
    final items      = _cart.items;
    final subtotal   = _cart.subtotal;
    final tax        = _cart.tax;
    final grandTotal = _cart.grandTotal;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerHigh,
      body: ResponsiveLayout(
        child: Stack(
          children: [
            CustomScrollView(
              scrollBehavior: _NoScrollbar(),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 72)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildSectionHeader(items.length),
                      const SizedBox(height: 32),
                      _buildCartItems(),
                      const SizedBox(height: 40),
                      _buildPromoRow(),
                      const SizedBox(height: 40),
                      _buildOrderSummary(subtotal, tax, grandTotal),
                      const SizedBox(height: 120),
                    ]),
                  ),
                ),
              ],
            ),
            Positioned(top: 0, left: 0, right: 0, child: _buildAppBar()),
            Positioned(bottom: 0, left: 0, right: 0,
              child: BottomNav(
                  currentIndex: _navIndex, onTap: _handleBottomNavTap)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.of(context).padding.top + 16, 24, 16),
      decoration: const BoxDecoration(
        color: AppColors.background, boxShadow: AppShadows.raised),
      child: Row(children: [
        GestureDetector(onTap: () {},
            child: const Icon(Icons.menu, color: AppColors.primary, size: 26)),
        const SizedBox(width: 16),
        const Text('SwiftMart',
          style: TextStyle(fontFamily: 'Inter', fontSize: 24,
              fontWeight: FontWeight.w900, letterSpacing: -0.96,
              color: AppColors.primary)),
        const Spacer(),
        GestureDetector(onTap: () {},
            child: const Icon(Icons.notifications_outlined,
                color: AppColors.primary, size: 26)),
      ]),
    );
  }

  Widget _buildSectionHeader(int count) {
    return Text('Shopping Items ($count)',
      style: const TextStyle(fontFamily: 'Inter', fontSize: 28,
          fontWeight: FontWeight.bold, letterSpacing: -0.56,
          color: AppColors.primary, height: 1.2));
  }

  // ── E4: Items list with Dismissible swipe-to-delete ───────────
  Widget _buildCartItems() {
    final items = _cart.items;
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.shopping_cart_outlined,
                color: AppColors.outlineVariant, size: 56),
            const SizedBox(height: 16),
            const Text('Your cart is empty.',
              style: TextStyle(fontFamily: 'Inter', fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.pushReplacementNamed(
                  context, AppRoutes.shop),
              child: const Text('Start shopping →',
                style: TextStyle(fontFamily: 'Inter', fontSize: 14,
                    fontWeight: FontWeight.bold, color: AppColors.tertiary)),
            ),
          ]),
        ),
      );
    }

    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        return Padding(
          padding: EdgeInsets.only(
              bottom: index < items.length - 1 ? 24 : 0),
          // ── E4: Dismissible — swipe left to delete ────────
          child: Dismissible(
            key: ValueKey('${item.product.id}_${item.selectedSize}'),
            direction: DismissDirection.endToStart,
            // Red delete background revealed on swipe
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.30))),
              child: const Icon(Icons.delete_outline,
                  color: AppColors.error, size: 28),
            ),
            // Confirm before removing
            confirmDismiss: (_) async {
              return await AppUtils.showConfirmDialog(
                context,
                title:        'Remove Item',
                body:         'Remove "${item.product.name}" from your cart?',
                confirmLabel: 'Remove',
                isDestructive: true,
              );
            },
            onDismissed: (_) => _removeItem(index),
            child: _buildCartCard(index),
          ),
        );
      }),
    );
  }

  Widget _buildCartCard(int index) {
    final item = _cart.items[index];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.raised),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 80, height: 80,
            child: Image.network(item.product.imageUrl, fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: AppColors.surfaceContainerLowest,
                child: const Icon(Icons.image_outlined,
                    color: AppColors.outlineVariant, size: 32))),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.product.name,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface, height: 1.2)),
              const SizedBox(height: 4),
              Text(item.selectedSize,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14,
                    color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppUtils.formatPrice(item.product.price),
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.tertiary)),
                  _buildQtyStepper(index),
                ],
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildQtyStepper(int index) {
    final qty = _cart.items[index].quantity;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
        boxShadow: AppShadows.pressed),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(
          onTap: () { _cart.decrement(index); setState(() {}); },
          behavior: HitTestBehavior.opaque,
          child: const Padding(padding: EdgeInsets.all(4),
            child: Icon(Icons.remove, size: 14, color: AppColors.secondary))),
        const SizedBox(width: 8),
        SizedBox(width: 16,
          child: Text('$qty', textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 14,
                fontWeight: FontWeight.bold, color: AppColors.onSurface))),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () { _cart.increment(index); setState(() {}); },
          behavior: HitTestBehavior.opaque,
          child: const Padding(padding: EdgeInsets.all(4),
            child: Icon(Icons.add, size: 14, color: AppColors.secondary))),
      ]),
    );
  }

  Widget _buildPromoRow() {
    return GestureDetector(
      onTap: () => _showPromoDialog(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.raised),
        child: const Row(children: [
          Icon(Icons.sell_outlined, color: AppColors.secondary, size: 24),
          SizedBox(width: 12),
          Expanded(child: Text('Apply Promo Code',
            style: TextStyle(fontFamily: 'Inter', fontSize: 14,
                fontWeight: FontWeight.w500, color: AppColors.onSurface))),
          Icon(Icons.chevron_right, color: AppColors.primary, size: 24),
        ]),
      ),
    );
  }

  void _showPromoDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Promo Code',
          style: TextStyle(color: AppColors.onSurface, fontFamily: 'Inter',
              fontWeight: FontWeight.bold)),
        content: TextField(controller: controller,
          style: const TextStyle(color: AppColors.onSurface, fontFamily: 'Inter'),
          decoration: const InputDecoration(
            hintText: 'e.g. SWIFT10 or LAUNCH20',
            hintStyle: TextStyle(color: AppColors.outlineVariant,
                fontFamily: 'Inter'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
              style: TextStyle(color: AppColors.onSurfaceVariant,
                  fontFamily: 'Inter'))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await _cart.applyPromoCode(controller.text);
              if (!mounted) return;
              AppUtils.showSnackBar(context, result.success
                ? 'Discount of \$${result.data!.toStringAsFixed(2)} applied! 🎉'
                : result.error ?? 'Invalid code.');
            },
            child: const Text('Apply',
              style: TextStyle(color: AppColors.tertiary, fontFamily: 'Inter',
                  fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(double subtotal, double tax, double grandTotal) {
    return Column(children: [
      _buildSummaryRow('SUBTOTAL', '\$${subtotal.toStringAsFixed(2)}'),
      const SizedBox(height: 16),
      _buildSummaryRow('SHIPPING', 'Free'),
      const SizedBox(height: 16),
      _buildSummaryRow('TAXES', '\$${tax.toStringAsFixed(2)}'),
      const SizedBox(height: 16),
      Container(height: 1,
          color: AppColors.outlineVariant.withValues(alpha: 0.20)),
      const SizedBox(height: 16),
      _buildTotalRow(grandTotal),
    ]);
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 10,
            fontWeight: FontWeight.bold, letterSpacing: 1.5,
            color: AppColors.onSurfaceVariant)),
        Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 14,
            fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildTotalRow(double grandTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('TOTAL AMOUNT',
            style: TextStyle(fontFamily: 'Inter', fontSize: 10,
                fontWeight: FontWeight.bold, letterSpacing: 1.5,
                color: AppColors.secondary)),
          const SizedBox(height: 4),
          Text('\$${grandTotal.toStringAsFixed(2)}',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 30,
                fontWeight: FontWeight.w900, letterSpacing: -1.2,
                color: AppColors.onSurface)),
        ]),
        _buildCheckoutButton(),
      ],
    );
  }

  Widget _buildCheckoutButton() {
    return GestureDetector(
      onTap: _checkout,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.ctaGradientStart, AppColors.ctaGradientEnd],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.raised),
        child: Material(color: Colors.transparent,
          child: InkWell(onTap: _checkout,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: _isLoading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2,
                        color: Color(0xFF04342C)))
                : const Text('PROCEED TO\nCHECKOUT',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 10,
                        fontWeight: FontWeight.bold, letterSpacing: 1.5,
                        color: Color(0xFF04342C), height: 1.5)),
            ),
          )),
      ),
    );
  }
}

class _NoScrollbar extends ScrollBehavior {
  @override
  Widget buildScrollbar(BuildContext context, Widget child,
      ScrollableDetails details) => child;
}