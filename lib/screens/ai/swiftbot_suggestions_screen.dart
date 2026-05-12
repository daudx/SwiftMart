import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/utils/app_utils.dart';
import '../../models/product_model.dart';
import '../../routes/app_routes.dart';
import '../../services/ai_service.dart';
import '../../services/cart_service.dart';
import '../../widgets/bottom_nav.dart';

class SwiftBotSuggestionsScreen extends StatefulWidget {
  const SwiftBotSuggestionsScreen({super.key});

  @override
  State<SwiftBotSuggestionsScreen> createState() =>
      _SwiftBotSuggestionsScreenState();
}

class _SwiftBotSuggestionsScreenState extends State<SwiftBotSuggestionsScreen> {
  int _navIndex = 2;
  bool _isThinking = false;
  List<ProductModel> _products = [];
  bool _loadingProducts = true;

  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _ai = AiService();
  final _cart = CartService();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // Seed product data matching the UI
  static const List<_SeedProduct> _seedProducts = [
    _SeedProduct(
      name: 'SwiftStep Pro Runner',
      price: 89.99,
      imageUrl:
          'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800&q=80',
    ),
    _SeedProduct(
      name: 'AeroMax Lite',
      price: 74.99,
      imageUrl:
          'https://images.unsplash.com/photo-1606107557195-0e29a4b5b4aa?w=800&q=80',
    ),
    _SeedProduct(
      name: 'TrailBlaze X',
      price: 99.00,
      imageUrl:
          'https://images.unsplash.com/photo-1608231387042-66d1773070a5?w=800&q=80',
    ),
  ];

  static const List<String> _quickChips = [
    'View Details',
    'Add to Cart',
    'Compare All',
    'Back to Search',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── WIRED: send to AiService ──────────────────────────────────
  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isThinking) return;
    _inputController.clear();
    setState(() => _isThinking = true);

    await _ai.sendMessage(text);

    if (!mounted) return;
    setState(() => _isThinking = false);
  }

  Future<void> _loadProducts() async {
    final ids =
        ModalRoute.of(context)?.settings.arguments as List<String>? ?? [];

    final result = await _ai.getProductSuggestions(ids);

    if (!mounted) return;

    setState(() {
      _products = result.data ?? [];
      _loadingProducts = false;
    });
  }

  // ── WIRED: nav handler properly navigates ─────────────────────
  void _handleNavTap(int index) {
    if (index == _navIndex) return;
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.home);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, AppRoutes.shop);
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

  // ── WIRED: Add to Cart ────────────────────────────────────────
  Future<void> _addToCart(_SeedProduct sp) async {
    await _cart.addItem(
      product: ProductModel(
        id: 'seed_${sp.name.hashCode}',
        name: sp.name,
        category: 'SHOES',
        price: sp.price,
        imageUrl: sp.imageUrl,
      ),
      selectedSize: 'Default',
    );
    if (!mounted) return;
    AppUtils.showSnackBar(context, '${sp.name} added to cart! 🛍️');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            scrollBehavior: _NoScrollbar(),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildBotBubble('I found these options for you:'),
                    const SizedBox(height: 16),
                    _buildProductCardsRow(),
                    const SizedBox(height: 16),
                    _buildBotBubble(
                      "Tap any to view full details or say 'compare' to see them side by side.",
                      highlightWord: 'compare',
                    ),
                    const SizedBox(height: 32),
                    _buildUserBubble('Show me the SwiftStep Pro.'),
                    const SizedBox(height: 16),
                    _buildQuickChips(),
                    const SizedBox(height: 200),
                  ]),
                ),
              ),
            ],
          ),
          Positioned(top: 0, left: 0, right: 0, child: _buildAppBar()),
          Positioned(bottom: 96, left: 16, right: 16, child: _buildInputBar()),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
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
              const Text(
                'SWIFTBOT',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.36,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
              boxShadow: AppShadows.raised,
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotBubble(String text, {String? highlightWord}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.90,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: AppShadows.raised,
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.10),
          ),
        ),
        child: highlightWord == null
            ? Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.onSurface,
                  height: 1.5,
                ),
              )
            : _buildHighlightedText(text, highlightWord),
      ),
    );
  }

  Widget _buildHighlightedText(String text, String word) {
    final parts = text.split("'$word'");
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: AppColors.onSurface,
          height: 1.5,
        ),
        children: [
          TextSpan(text: parts[0]),
          const TextSpan(text: "'"),
          const TextSpan(
            text: 'compare',
            style: TextStyle(
              color: AppColors.tertiary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const TextSpan(text: "'"),
          if (parts.length > 1) TextSpan(text: parts[1]),
        ],
      ),
    );
  }

  Widget _buildProductCardsRow() {
    if (_loadingProducts) {
      return SizedBox(
        height: 268,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_products.isEmpty) {
      return SizedBox(
        height: 268,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(right: 16, bottom: 16),
          physics: const ClampingScrollPhysics(),
          itemCount: _seedProducts.length,
          separatorBuilder: (_, _) => const SizedBox(width: 16),
          itemBuilder: (_, i) => _buildProductCard(_seedProducts[i]),
        ),
      );
    }

    return SizedBox(
      height: 268,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 16, bottom: 16),
        physics: const ClampingScrollPhysics(),
        itemCount: _products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (_, i) => _buildRealProductCard(_products[i]),
      ),
    );
  }

  Widget _buildProductCard(_SeedProduct sp) {
    return Container(
      width: 256,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.raised,
        border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 128,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppShadows.pressed,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                sp.imageUrl,
                width: double.infinity,
                height: 128,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.surfaceContainerLowest,
                  child: const Icon(
                    Icons.image_outlined,
                    color: AppColors.outlineVariant,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            sp.name,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppUtils.formatPrice(sp.price),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.tertiary,
            ),
          ),
          const SizedBox(height: 12),
          // ── WIRED: Add to Cart ──────────────────────────
          GestureDetector(
            onTap: () => _addToCart(sp),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppShadows.raised,
              ),
              child: const Center(
                child: Text(
                  'ADD TO CART',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppColors.tertiary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealProductCard(ProductModel product) {
    return Container(
      width: 256,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Image.network(product.imageUrl, height: 120),
          const SizedBox(height: 12),

          Text(product.name),

          Text('\$\${product.price}'),
        ],
      ),
    );
  }

  Widget _buildUserBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1AFFFFFF),
              offset: Offset(-2, -2),
              blurRadius: 6,
              blurStyle: BlurStyle.inner,
            ),
            BoxShadow(
              color: AppColors.shadowDark,
              offset: Offset(5, 5),
              blurRadius: 15,
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChips() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _quickChips
          .map(
            (label) => GestureDetector(
              // ── WIRED: chip actions ────────────────────────────
              onTap: () {
                switch (label) {
                  case 'Add to Cart':
                    if (_seedProducts.isNotEmpty) {
                      _addToCart(_seedProducts.first);
                    }
                  case 'Back to Search':
                    Navigator.pushReplacementNamed(context, AppRoutes.swiftBot);
                  case 'View Details':
                    Navigator.pushNamed(context, AppRoutes.shop);
                  default:
                    _inputController.text = label;
                    _sendMessage();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: AppShadows.raised,
                  border: Border.all(
                    color: AppColors.tertiary.withValues(alpha: 0.20),
                  ),
                ),
                child: Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.raised,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(
              Icons.attach_file,
              color: AppColors.onSurfaceVariant,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _inputController,
              onSubmitted: (_) => _sendMessage(),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Ask SwiftBot anything...',
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.50),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // ── WIRED: send button ──────────────────────────
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isThinking
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimaryContainer,
                      ),
                    )
                  : const Icon(
                      Icons.arrow_forward,
                      color: AppColors.onPrimaryContainer,
                      size: 22,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeedProduct {
  final String name, imageUrl;
  final double price;
  const _SeedProduct({
    required this.name,
    required this.price,
    required this.imageUrl,
  });
}

class _NoScrollbar extends ScrollBehavior {
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
