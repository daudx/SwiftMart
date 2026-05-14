import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/utils/app_utils.dart';
import '../../core/utils/responsive_layout.dart';
import '../../models/product_model.dart';
import '../../routes/app_routes.dart';
import '../../services/cart_service.dart';
import '../../services/product_service.dart';
import '../../widgets/neumorphic_container.dart';
import '../../widgets/bottom_nav.dart';
import '../../core/constants/app_constant.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  // ── Services ──────────────────────────────────────────────────
  final _productService = ProductService();
  final _cartService = CartService();

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Navigation ────────────────────────────────────────────────


  // ── WIRED: Bottom nav with Shop tab now navigating ────────────
  void _handleBottomNavTap(int index) {
    if (index == _navIndex) return;
    switch (index) {
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
      default:
        setState(() => _navIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ResponsiveLayout(
        child: Stack(
          children: [
            // ── Scrollable Dashboard ──────────────────────────
            CustomScrollView(
              controller: _scrollController,
              scrollBehavior: _NoScrollbarBehavior(),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 100)), // App Bar space

                // ── Section 1: Hero Carousel (Featured) ──────
                _buildHeroCarousel(),

                // ── Section 2: Categories ─────────────────────
                _buildCategorySection(),

                // ── Section 3: Trending Now (Horizontal) ─────
                _buildTrendingSection(),

                // ── Section 4: Recommended for You (Grid) ────
                _buildDiscoveryGridHeader(),
                _buildDiscoveryGrid(),

                const SliverToBoxAdapter(child: SizedBox(height: 120)), // Nav space
              ],
            ),

            // ── Sticky Header ─────────────────────────────────
            Positioned(top: 0, left: 0, right: 0, child: _buildAppBar()),
          ],
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _navIndex,
        onTap: _handleBottomNavTap,
      ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────
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
                if (_cartService.itemCount > 0)
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
                          '${_cartService.itemCount}',
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

  // ── 1. Hero Carousel ────────────────────────────────────────
  Widget _buildHeroCarousel() {
    return SliverToBoxAdapter(
      child: StreamBuilder<List<ProductModel>>(
        stream: _productService.getProductsStream(),
        builder: (context, snapshot) {
          final featured = snapshot.data?.where((p) => p.isFeatured).toList() ?? [];
          if (featured.isEmpty) return const SizedBox.shrink();

          return Container(
            height: 240,
            margin: const EdgeInsets.symmetric(vertical: 16),
            child: PageView.builder(
              itemCount: featured.length > 3 ? 3 : featured.length,
              itemBuilder: (ctx, i) => _buildHeroSlide(featured[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroSlide(ProductModel p) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.product, arguments: p),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: AppShadows.raised,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(p.imageUrl, fit: BoxFit.cover),
              // Dark gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.tertiary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('FEATURED',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black)),
                    ),
                    const SizedBox(height: 8),
                    Text(p.name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                    Text('Premium Quality • Limited Edition',
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 2. Category Shortcuts ────────────────────────────────────
  Widget _buildCategorySection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Text('Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: AppConstants.productCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 20),
              itemBuilder: (ctx, i) {
                final cat = AppConstants.productCategories[i];
                return GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.shop), // Should pass category arg
                  child: Column(
                    children: [
                      SwiftNeumorphicContainer(
                        type: NeumorphicType.raised,
                        borderRadius: 999,
                        padding: const EdgeInsets.all(16),
                        child: Icon(_categoryIcon(cat), color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(cat, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Trending Section ─────────────────────────────────────
  Widget _buildTrendingSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Trending Now',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                Text('See All',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.tertiary)),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: StreamBuilder<List<ProductModel>>(
              stream: _productService.getProductsStream(),
              builder: (context, snapshot) {
                final products = snapshot.data ?? [];
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: products.length > 6 ? 6 : products.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (ctx, i) => _buildTrendingCard(products[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingCard(ProductModel p) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.product, arguments: p),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppShadows.raisedSmall,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image.network(p.imageUrl, fit: BoxFit.cover, width: double.infinity),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(AppUtils.formatPrice(p.price),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.tertiary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 4. Discovery Grid ───────────────────────────────────────
  Widget _buildDiscoveryGridHeader() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 40, 24, 16),
        child: Text('Discover More',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
      ),
    );
  }

  Widget _buildDiscoveryGrid() {
    return StreamBuilder<List<ProductModel>>(
      stream: _productService.getProductsStream(),
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _buildGridCard(products[i]),
              childCount: products.length > 8 ? 8 : products.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridCard(ProductModel p) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.product, arguments: p),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppShadows.raisedSmall,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image.network(p.imageUrl, fit: BoxFit.cover, width: double.infinity),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.category, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.secondary)),
                        Text(p.name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppUtils.formatPrice(p.price),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.tertiary)),
                        Icon(Icons.add_circle, color: AppColors.primary.withValues(alpha: 0.5), size: 20),
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

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'SHOES': return Icons.directions_run;
      case 'TECH': return Icons.devices;
      case 'AUDIO': return Icons.headphones;
      case 'CLOTHES': return Icons.checkroom;
      case 'FITNESS': return Icons.fitness_center;
      case 'LABEL': return Icons.local_offer;
      default: return Icons.apps;
    }
  }
}

// ── Scroll behavior ───────────────────────────────────────────
class _NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
