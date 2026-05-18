import 'package:flutter/material.dart';
import '../../core/constants/app_constant.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/utils/app_utils.dart';
import '../../core/utils/responsive_layout.dart';
import '../../models/product_model.dart';
import '../../routes/app_routes.dart';
import '../../services/cart_service.dart';
import '../../services/product_service.dart';
import '../../widgets/bottom_nav.dart';

/// Product catalogue / shop listing screen.
class ShopScreen extends StatefulWidget {
  final String? initialCategory;

  const ShopScreen({super.key, this.initialCategory});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final ProductService _productService = ProductService();
  final CartService _cartService = CartService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  int _navIndex = 5;
  late String _selectedCategory;
  bool _isLoading = true;
  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'ALL';
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = ResponsiveLayout(
      child: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: _buildSearchBar(),
                ),
              ),
              SliverToBoxAdapter(child: _buildCategoryChips()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: _buildResultsHeader(),
                ),
              ),
              StreamBuilder<List<ProductModel>>(
                // Always stream the full catalogue and perform category
                // filtering client-side. This avoids mismatches between
                // Firestore category values and our chip constants.
                stream: _productService.getProductsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      _isLoading) {
                    return const SliverToBoxAdapter(child: _LoadingGrid());
                  }

                  if (snapshot.hasError) {
                    return const SliverToBoxAdapter(child: _EmptyState());
                  }

                  _allProducts = snapshot.data ?? [];
                  _isLoading = false;
                  _filteredProducts = _filterProducts(_allProducts);

                  if (_filteredProducts.isEmpty) {
                    return const SliverToBoxAdapter(child: _EmptyState());
                  }

                  return _buildProductGrid();
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          Positioned(top: 0, left: 0, right: 0, child: _buildAppBar()),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: content,
            bottomNavigationBar: BottomNav(
              currentIndex: _navIndex,
              onTap: _handleNavTap,
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Row(
            children: [
              BottomNav(currentIndex: _navIndex, onTap: _handleNavTap),
              Expanded(child: content),
            ],
          ),
        );
      },
    );
  }

  void _handleNavTap(int index) {
    if (index == _navIndex) return;
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.home);
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

  void _applyFilters() {
    if (!mounted) return;
    setState(() {
      _filteredProducts = _filterProducts(_allProducts);
    });
  }

  List<ProductModel> _filterProducts(List<ProductModel> source) {
    final query = _searchController.text.toLowerCase().trim();
    return source.where((p) {
      final matchesCategory =
          _selectedCategory == 'ALL' ||
          p.category.toUpperCase() == _selectedCategory;

      final matchesQuery =
          query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query);

      return matchesCategory && matchesQuery;
    }).toList();
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

  Widget _buildSearchBar() {
    return Container(
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
              size: 22,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Search products…',
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
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
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                _applyFilters();
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
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        physics: const ClampingScrollPhysics(),
        itemCount: AppConstants.productCategories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final cat = AppConstants.productCategories[i];
          final isSelected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => _onCategorySelected(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.surfaceContainerLowest
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(999),
                boxShadow: isSelected ? AppShadows.pressed : AppShadows.raised,
                border: isSelected
                    ? Border.all(
                        color: AppColors.tertiary.withValues(alpha: 0.25),
                      )
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _categoryIcon(cat),
                    size: 14,
                    color: isSelected
                        ? AppColors.tertiary
                        : AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: isSelected
                          ? AppColors.tertiary
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _selectedCategory == 'ALL' ? 'All Products' : _selectedCategory,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
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
            '${_filteredProducts.length} items',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductGrid() {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final crossAxisCount = width >= 1400
            ? 5
            : width >= 1100
            ? 4
            : width >= 750
            ? 3
            : 2;

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: crossAxisCount >= 4 ? 0.72 : 0.65,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) => _buildProductCard(_filteredProducts[i]),
              childCount: _filteredProducts.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductCard(ProductModel p) {
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, AppRoutes.product, arguments: p),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.raised,
          border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Container(
                  color: AppColors.surfaceContainerLowest,
                  child: Image.network(
                    p.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Center(
                      child: Icon(
                        Icons.image_outlined,
                        color: AppColors.outlineVariant,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x66064E3B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            p.category,
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
                        Text(
                          AppUtils.truncate(p.name, 24),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          AppUtils.formatPrice(p.price),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.tertiary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _addToCart(p),
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

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'SHOES':
        return Icons.directions_run;
      case 'TECH':
        return Icons.devices;
      case 'AUDIO':
        return Icons.headphones;
      case 'CLOTHES':
        return Icons.checkroom;
      case 'FITNESS':
        return Icons.fitness_center;
      case 'LABEL':
        return Icons.local_offer;
      default:
        return Icons.apps;
    }
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
      _isLoading = true;
    });
    // Re-apply filters on the current cached list so UI updates immediately.
    _applyFilters();
  }

  Future<void> _addToCart(ProductModel product) async {
    final result = await _cartService.addItem(
      product: product,
      selectedSize: product.sizes.isNotEmpty ? product.sizes.first : 'One Size',
    );

    if (!mounted) return;

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Unable to add to cart.')),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${product.name} added to cart')));
    setState(() {});
  }
}

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(48),
      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off,
              color: AppColors.outlineVariant,
              size: 56,
            ),
            const SizedBox(height: 16),
            const Text(
              'No products found.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try a different category or search term.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.outlineVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
