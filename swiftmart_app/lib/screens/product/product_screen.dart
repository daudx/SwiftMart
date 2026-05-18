import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/utils/app_utils.dart';
import '../../models/product_model.dart';
import '../../routes/app_routes.dart';
import '../../services/cart_service.dart';
import '../../services/product_service.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/neumorphic_container.dart';

/// Full product detail screen.
///
/// Accepts a [ProductModel] via Navigator arguments:
///   Navigator.pushNamed(context, AppRoutes.product, arguments: product)
///
/// Firebase-ready: replace the passed model with a Firestore stream
/// so the screen stays live — price changes and stock updates
/// reflect instantly without re-navigating.
class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final int _navIndex = 0;
  int _selectedSizeIndex = 0;
  int _selectedThumbIndex = 0;
  bool _isAddingToCart = false;

  final _scrollController = ScrollController();
  final _cart = CartService();
  final _product = ProductService();

  // Product is passed as a route argument
  ProductModel? _p;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _p = ModalRoute.of(context)?.settings.arguments as ProductModel?;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleNavTap(int index) {
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
      case 4:
        Navigator.pushReplacementNamed(context, AppRoutes.profile);
        break;
    }
  }

  Future<void> _addToCart() async {
    if (_p == null || _isAddingToCart) return;
    setState(() => _isAddingToCart = true);

    final size = _p!.sizes.isNotEmpty
        ? _p!.sizes[_selectedSizeIndex]
        : 'One Size';

    await _cart.addItem(product: _p!, selectedSize: size);

    if (!mounted) return;
    setState(() => _isAddingToCart = false);

    AppUtils.showSnackBar(
      context,
      '${_p!.name} (Size $size) added to cart! 🛍️',
    );
  }

  Future<void> _toggleFavourite() async {
    if (_p == null) return;
    final result = await _product.toggleFavourite(_p!.id);
    if (mounted && result.success) {
      setState(() => _p = result.data);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Guard: if no product passed, go back
    if (_p == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.onSurfaceVariant,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Product not found.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  'Go back',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.tertiary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final p = _p!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Scrollable content ──────────────────────────
          CustomScrollView(
            controller: _scrollController,
            scrollBehavior: _NoScrollbar(),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
              SliverToBoxAdapter(child: _buildHeroSection(p)),
              SliverToBoxAdapter(child: _buildInfoSection(p)),
              const SliverToBoxAdapter(child: SizedBox(height: 200)),
            ],
          ),

          // ── Sticky AppBar ────────────────────────────────
          Positioned(top: 0, left: 0, right: 0, child: _buildAppBar(p)),

          // ── Add to Cart CTA ──────────────────────────────
          Positioned(
            bottom: 96,
            left: 24,
            right: 24,
            child: _buildAddToCartButton(p),
          ),

          // ── Bottom Navigation ────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNav(currentIndex: _navIndex, onTap: _handleNavTap),
          ),
        ],
      ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────
  Widget _buildAppBar(ProductModel p) {
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
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'SwiftMart',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.96,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.cart),
            child: Stack(
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  color: AppColors.primary,
                  size: 26,
                ),
                // Cart badge
                if (_cart.itemCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: AppColors.tertiary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${_cart.itemCount}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: AppColors.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero image section ────────────────────────────────────────
  Widget _buildHeroSection(ProductModel p) {
    final images = [p.imageUrl, ...p.thumbnailUrls];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        children: [
          // Main hero image
          SwiftNeumorphicContainer(
            type: NeumorphicType.raised,
            borderRadius: 32,
            padding: const EdgeInsets.all(32),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  // Product image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      images[_selectedThumbIndex],
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.outlineVariant,
                          size: 64,
                        ),
                      ),
                    ),
                  ),
                  // Favourite button
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _toggleFavourite,
                      child: SwiftNeumorphicContainer(
                        type: NeumorphicType.raised,
                        borderRadius: 999,
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          p.isFavourite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: AppColors.tertiary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Thumbnail strip
          if (images.length > 1)
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                itemCount: images.length,
                separatorBuilder: (_, _) => const SizedBox(width: 16),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => setState(() => _selectedThumbIndex = i),
                  child: Opacity(
                    opacity: i == _selectedThumbIndex ? 1.0 : 0.6,
                    child: SwiftNeumorphicContainer(
                      type: i == _selectedThumbIndex
                          ? NeumorphicType.pressed
                          : NeumorphicType.raised,
                      borderRadius: 16,
                      padding: const EdgeInsets.all(8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          images[i],
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: AppColors.surfaceContainerLowest,
                            width: 64,
                            height: 64,
                          ),
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

  // ── Info section ─────────────────────────────────────────────
  Widget _buildInfoSection(ProductModel p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductHeader(p),
          const SizedBox(height: 32),
          _buildOverviewCard(p),
          const SizedBox(height: 32),
          _buildSpecGrid(p),
          if (p.sizes.isNotEmpty && p.sizes.first != 'One Size') ...[
            const SizedBox(height: 40),
            _buildSizeSelector(p),
          ],
          const SizedBox(height: 32),
          if (p.features.isNotEmpty) _buildFeaturesRow(p),
        ],
      ),
    );
  }

  Widget _buildProductHeader(ProductModel p) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.category,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                p.name,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: AppColors.onSurface,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Text(
          AppUtils.formatPrice(p.price),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.tertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(ProductModel p) {
    return SwiftNeumorphicContainer(
      type: NeumorphicType.raised,
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Overview',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            p.description.isEmpty ? 'No description available.' : p.description,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecGrid(ProductModel p) {
    return Row(
      children: [
        if (p.weight.isNotEmpty)
          Expanded(
            child: _buildSpecCard(
              Icons.monitor_weight_outlined,
              'WEIGHT',
              p.weight,
            ),
          ),
        if (p.weight.isNotEmpty && p.energyReturn.isNotEmpty)
          const SizedBox(width: 24),
        if (p.energyReturn.isNotEmpty)
          Expanded(
            child: _buildSpecCard(Icons.bolt, 'PERFORMANCE', p.energyReturn),
          ),
      ],
    );
  }

  Widget _buildSpecCard(IconData icon, String label, String value) {
    return SwiftNeumorphicContainer(
      type: NeumorphicType.pressed,
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.tertiary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.outlineVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeSelector(ProductModel p) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SELECT SIZE',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: AppColors.secondary,
              ),
            ),
            GestureDetector(
              onTap: () => _showSizeGuide(p),
              child: const Text(
                'SIZE GUIDE',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.tertiary,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.tertiary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            itemCount: p.sizes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final isSelected = i == _selectedSizeIndex;
              return GestureDetector(
                onTap: () => setState(() => _selectedSizeIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.surfaceContainerLowest
                        : AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? AppShadows.pressed
                        : AppShadows.raised,
                    border: isSelected
                        ? Border.all(
                            color: AppColors.tertiary.withValues(alpha: 0.20),
                          )
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      p.sizes[i],
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w900
                            : FontWeight.w700,
                        color: isSelected
                            ? AppColors.tertiary
                            : AppColors.onSurface,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesRow(ProductModel p) {
    return SwiftNeumorphicContainer(
      type: NeumorphicType.raised,
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: p.features
            .take(3)
            .map((f) => _FeatureItem(label: f))
            .toList(),
      ),
    );
  }

  // ── Add to Cart CTA ──────────────────────────────────────────
  Widget _buildAddToCartButton(ProductModel p) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.ctaGradientStart, AppColors.ctaGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: AppShadows.raised,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _addToCart,
          borderRadius: BorderRadius.circular(999),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isAddingToCart)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.onPrimaryContainer,
                  ),
                )
              else ...[
                const Icon(
                  Icons.shopping_bag,
                  color: AppColors.onPrimaryContainer,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  p.stock <= 0 ? 'Out of Stock' : 'Add to Cart',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.36,
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showSizeGuide(ProductModel p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const Text(
              'Size Guide',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ...p.sizes.map(
              (s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Standard fit',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.onSurfaceVariant,
                      ),
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

// ── Feature item ─────────────────────────────────────────────
class _FeatureItem extends StatelessWidget {
  final String label;
  const _FeatureItem({required this.label});

  static IconData _iconFor(String label) {
    final l = label.toLowerCase();
    if (l.contains('breath')) return Icons.air;
    if (l.contains('water')) return Icons.water_drop_outlined;
    if (l.contains('recycle')) return Icons.eco_outlined;
    if (l.contains('light')) return Icons.bolt;
    if (l.contains('grip')) return Icons.pan_tool_alt_outlined;
    if (l.contains('foam')) return Icons.layers_outlined;
    if (l.contains('arch')) return Icons.architecture;
    if (l.contains('organic')) return Icons.eco_outlined;
    if (l.contains('wash')) return Icons.local_laundry_service_outlined;
    if (l.contains('gps')) return Icons.gps_fixed;
    if (l.contains('heart')) return Icons.favorite_border;
    if (l.contains('anc') || l.contains('noise')) {
      return Icons.noise_control_off;
    }
    if (l.contains('rfid')) return Icons.credit_card_off_outlined;
    if (l.contains('latex')) return Icons.fitness_center;
    return Icons.verified_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_iconFor(label), color: AppColors.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _NoScrollbar extends ScrollBehavior {
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
