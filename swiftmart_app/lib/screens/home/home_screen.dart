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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int  _navIndex          = 0;
  int  _selectedSizeIndex = 2;
  int  _selectedThumbIndex = 0;
  bool _isAddingToCart    = false;
  bool _isLoading         = true;

  // ── Services ──────────────────────────────────────────────────
  final _productService = ProductService();
  final _cartService    = CartService();

  // ── Product loaded from ProductService ────────────────────────
  ProductModel? _product;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── WIRED: load featured product from ProductService ──────────
  Future<void> _loadProduct() async {
    final result = await _productService.getProductById('prd_001');
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) _product = result.data;
    });
  }

  // ── WIRED: Add to Cart calls CartService ──────────────────────
  Future<void> _addToCart() async {
    if (_product == null || _isAddingToCart) return;
    setState(() => _isAddingToCart = true);

    final size = _product!.sizes.isNotEmpty
        ? _product!.sizes[_selectedSizeIndex]
        : 'One Size';

    await _cartService.addItem(product: _product!, selectedSize: size);

    if (!mounted) return;
    setState(() => _isAddingToCart = false);

    AppUtils.showSnackBar(
      context,
      '${_product!.name} (Size $size) added to cart! 🛍️',
    );
  }

  // ── WIRED: Favourite toggle ───────────────────────────────────
  Future<void> _toggleFavourite() async {
    if (_product == null) return;
    final result = await _productService.toggleFavourite(_product!.id);
    if (mounted && result.success) {
      setState(() => _product = result.data);
    }
  }

  // ── WIRED: Bottom nav with Shop tab now navigating ────────────
  void _handleBottomNavTap(int index) {
    if (index == _navIndex) return;
    switch (index) {
      case 1: Navigator.pushReplacementNamed(context, AppRoutes.shop);    break;
      case 2: Navigator.pushReplacementNamed(context, AppRoutes.swiftBot); break;
      case 3: Navigator.pushReplacementNamed(context, AppRoutes.cart);    break;
      case 4: Navigator.pushReplacementNamed(context, AppRoutes.profile); break;
      default: setState(() => _navIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Scrollable content — with Scrollbar ───────────
          Scrollbar(
            controller: _scrollController,
            child: CustomScrollView(
              controller: _scrollController,
              scrollBehavior: _NoScrollbarBehavior(),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
                if (_isLoading)
                  const SliverToBoxAdapter(child: _LoadingState())
                else if (_product == null)
                  const SliverToBoxAdapter(child: _ErrorState())
                else ...[
                  SliverToBoxAdapter(child: _buildHeroSection()),
                  SliverToBoxAdapter(child: _buildInfoSection()),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 200)),
              ],
            ),
          ),

          // ── Sticky AppBar ─────────────────────────────────
          Positioned(top: 0, left: 0, right: 0,
              child: _buildAppBar()),

          // ── Add to Cart CTA ───────────────────────────────
          if (_product != null)
            Positioned(
              bottom: 96, left: 24, right: 24,
              child: _buildAddToCartButton(),
            ),

          // ── Bottom Navigation ─────────────────────────────
          Positioned(bottom: 0, left: 0, right: 0,
            child: BottomNav(
              currentIndex: _navIndex,
              onTap: _handleBottomNavTap,
            ),
          ),
        ],
      ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.of(context).padding.top + 16, 24, 16),
      decoration: const BoxDecoration(
        color: AppColors.background,
        boxShadow: AppShadows.raised,
      ),
      child: Row(
        children: [
          // ── WIRED: menu navigates to admin ────────────────
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.admin),
            child: const Icon(Icons.menu,
                color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 16),
          const Text('SwiftMart',
            style: TextStyle(fontFamily: 'Inter', fontSize: 24,
                fontWeight: FontWeight.w900, letterSpacing: -0.96,
                color: AppColors.primary)),
          const Spacer(),
          // ── Cart badge ────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.cart),
            child: Stack(
              children: [
                const Icon(Icons.shopping_cart_outlined,
                    color: AppColors.primary, size: 26),
                if (_cartService.itemCount > 0)
                  Positioned(
                    right: 0, top: 0,
                    child: Container(
                      width: 14, height: 14,
                      decoration: const BoxDecoration(
                        color: AppColors.tertiary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${_cartService.itemCount}',
                          style: const TextStyle(fontFamily: 'Inter',
                              fontSize: 8, fontWeight: FontWeight.w900,
                              color: AppColors.onPrimaryContainer)),
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
  Widget _buildHeroSection() {
    final p = _product!;
    final images = [p.imageUrl, ...p.thumbnailUrls];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Column(
        children: [
          // Main hero image
          SwiftNeumorphicContainer(
            type: NeumorphicType.raised,
            borderRadius: 32,
            padding: const EdgeInsets.all(32),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      images[_selectedThumbIndex],
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(Icons.image_not_supported_outlined,
                            color: AppColors.outlineVariant, size: 64)),
                    ),
                  ),
                ),
                // ── WIRED: favourite toggle ───────────────
                Positioned(
                  top: 0, right: 0,
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
                        color: AppColors.tertiary, size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Thumbnails — tapping changes hero image
          if (images.length > 1)
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                itemCount: images.length,
                separatorBuilder: (_, _) => const SizedBox(width: 16),
                itemBuilder: (_, i) {
                  final isActive = i == _selectedThumbIndex;
                  return GestureDetector(
                    // ── WIRED: tapping thumbnail changes hero ─
                    onTap: () => setState(() => _selectedThumbIndex = i),
                    child: Opacity(
                      opacity: isActive ? 1.0 : 0.6,
                      child: SwiftNeumorphicContainer(
                        type: isActive
                            ? NeumorphicType.pressed
                            : NeumorphicType.raised,
                        borderRadius: 16,
                        padding: const EdgeInsets.all(8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            images[i],
                            width: 64, height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: AppColors.surfaceContainerLowest,
                              width: 64, height: 64),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ── Info section ─────────────────────────────────────────────
  Widget _buildInfoSection() {
    final p = _product!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductHeader(p),
          const SizedBox(height: 32),
          _buildOverviewCard(p),
          const SizedBox(height: 32),
          _buildSpecGrid(p),
          if (p.sizes.isNotEmpty) ...[
            const SizedBox(height: 40),
            _buildSizeSelector(p),
          ],
          const SizedBox(height: 32),
          if (p.features.isNotEmpty) _buildFeaturesRow(p),
        ],
      ),
    );
  }

  // ── Product header ───────────────────────────────────────────
  Widget _buildProductHeader(ProductModel p) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.category,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 10,
                    fontWeight: FontWeight.w900, letterSpacing: 2.0,
                    color: AppColors.secondary)),
              const SizedBox(height: 4),
              Text(p.name,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 30,
                    fontWeight: FontWeight.w800, letterSpacing: -0.6,
                    color: AppColors.onSurface, height: 1.0)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Text(AppUtils.formatPrice(p.price),
          style: const TextStyle(fontFamily: 'Inter', fontSize: 24,
              fontWeight: FontWeight.bold, color: AppColors.tertiary)),
      ],
    );
  }

  // ── Overview card ────────────────────────────────────────────
  Widget _buildOverviewCard(ProductModel p) {
    return SwiftNeumorphicContainer(
      type: NeumorphicType.raised,
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Product Overview',
            style: TextStyle(fontFamily: 'Inter', fontSize: 14,
                fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 12),
          Text(p.description.isEmpty
              ? 'No description available.' : p.description,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 14,
                color: AppColors.onSurfaceVariant, height: 1.6)),
        ],
      ),
    );
  }

  // ── Spec grid ────────────────────────────────────────────────
  Widget _buildSpecGrid(ProductModel p) {
    return Row(
      children: [
        if (p.weight.isNotEmpty)
          Expanded(child: _buildSpecCard(
              Icons.monitor_weight_outlined, 'WEIGHT', p.weight)),
        if (p.weight.isNotEmpty && p.energyReturn.isNotEmpty)
          const SizedBox(width: 24),
        if (p.energyReturn.isNotEmpty)
          Expanded(child: _buildSpecCard(
              Icons.bolt, 'ENERGY RETURN', p.energyReturn)),
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
          Row(children: [
            Icon(icon, color: AppColors.tertiary, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(label,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.outlineVariant))),
          ]),
          const SizedBox(height: 8),
          Text(value,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 14,
                fontWeight: FontWeight.bold, color: AppColors.onSurface)),
        ],
      ),
    );
  }

  // ── Size selector ────────────────────────────────────────────
  Widget _buildSizeSelector(ProductModel p) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('SELECT SIZE',
              style: TextStyle(fontFamily: 'Inter', fontSize: 10,
                  fontWeight: FontWeight.bold, letterSpacing: 1.5,
                  color: AppColors.secondary)),
            GestureDetector(
              onTap: () {},
              child: const Text('SIZE GUIDE',
                style: TextStyle(fontFamily: 'Inter', fontSize: 10,
                    fontWeight: FontWeight.bold, color: AppColors.tertiary,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.tertiary)),
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
            itemBuilder: (_, index) {
              final isSelected = index == _selectedSizeIndex;
              return GestureDetector(
                onTap: () => setState(() => _selectedSizeIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.surfaceContainerLowest
                        : AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? AppShadows.pressed : AppShadows.raised,
                    border: isSelected ? Border.all(
                      color: AppColors.tertiary.withValues(alpha: 0.20),
                    ) : null,
                  ),
                  child: Center(
                    child: Text(p.sizes[index],
                      style: TextStyle(fontFamily: 'Inter', fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w900 : FontWeight.w700,
                          color: isSelected
                              ? AppColors.tertiary : AppColors.onSurface)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Features row ─────────────────────────────────────────────
  Widget _buildFeaturesRow(ProductModel p) {
    return SwiftNeumorphicContainer(
      type: NeumorphicType.raised,
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: p.features.take(3).map((f) => _FeatureItem(
          icon: _featureIcon(f),
          label: f,
        )).toList(),
      ),
    );
  }

  // ── Add to Cart CTA ──────────────────────────────────────────
  Widget _buildAddToCartButton() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.ctaGradientStart, AppColors.ctaGradientEnd],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: AppShadows.raised,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // ── WIRED: adds product + selected size to CartService
          onTap: _addToCart,
          borderRadius: BorderRadius.circular(999),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isAddingToCart)
                const SizedBox(width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5,
                      color: AppColors.onPrimaryContainer))
              else ...[
                const Icon(Icons.shopping_bag,
                    color: AppColors.onPrimaryContainer, size: 24),
                const SizedBox(width: 12),
                const Text('Add to Cart',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 18,
                      fontWeight: FontWeight.w900, letterSpacing: -0.36,
                      color: AppColors.onPrimaryContainer)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Feature icon helper ───────────────────────────────────────
  IconData _featureIcon(String label) {
    final l = label.toLowerCase();
    if (l.contains('breath'))  return Icons.air;
    if (l.contains('water'))   return Icons.water_drop_outlined;
    if (l.contains('recycle')) return Icons.eco_outlined;
    if (l.contains('light'))   return Icons.bolt;
    if (l.contains('grip'))    return Icons.pan_tool_alt_outlined;
    if (l.contains('foam'))    return Icons.layers_outlined;
    if (l.contains('organic')) return Icons.eco_outlined;
    return Icons.verified_outlined;
  }
}

// ── Loading state ─────────────────────────────────────────────
class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(64),
      child: Center(child: CircularProgressIndicator(
          color: AppColors.primary)),
    );
  }
}

// ── Error state ───────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  const _ErrorState();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(48),
      child: Center(
        child: Text('Featured product not found.',
          style: TextStyle(fontFamily: 'Inter',
              color: AppColors.onSurfaceVariant)),
      ),
    );
  }
}

// ── Feature item ─────────────────────────────────────────────
class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _FeatureItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 8),
        Text(label,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurfaceVariant)),
      ],
    );
  }
}

class _NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(BuildContext context, Widget child,
      ScrollableDetails details) => child;
}