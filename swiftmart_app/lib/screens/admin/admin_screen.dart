import 'package:flutter/material.dart';
import '../../core/constants/app_constant.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/utils/app_utils.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isLoading = true;
  List<ProductModel> _products = [];

  // ── WIRED: uses ProductService ────────────────────────────────
  final _productService = ProductService();

  // ── Metric values derived from product list ───────────────────
  int get _totalProducts => _products.length;
  int get _lowStockCount =>
      _products.where((p) => p.stock > 0 && p.stock <= 10).length;
  double get _totalRevenue => _products.fold(0, (s, p) => s + p.price);

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // ── WIRED: load from ProductService ──────────────────────────
  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final result = await _productService.getAllProducts();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) _products = List.of(result.data ?? []);
    });
  }

  // ── WIRED: delete with confirmation ──────────────────────────
  Future<void> _handleDelete(ProductModel p) async {
    final confirmed = await AppUtils.showConfirmDialog(
      context,
      title: 'Delete Product',
      body: 'Remove "${p.name}" from the catalogue? This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    final result = await _productService.deleteProduct(p.id);
    if (!mounted) return;

    if (result.success) {
      setState(() => _products.removeWhere((x) => x.id == p.id));
      AppUtils.showSnackBar(context, '${p.name} deleted.');
    } else {
      AppUtils.showSnackBar(context, result.error ?? AppConstants.errUnknown);
    }
  }

  // ── WIRED: edit bottom sheet ──────────────────────────────────
  Future<void> _handleEdit(ProductModel p) async {
    final updated = await _showEditSheet(p);
    if (updated == null || !mounted) return;

    final result = await _productService.updateProduct(updated);
    if (!mounted) return;

    if (result.success) {
      final idx = _products.indexWhere((x) => x.id == updated.id);
      if (idx != -1) setState(() => _products[idx] = result.data!);
      AppUtils.showSnackBar(context, '${updated.name} updated.');
    } else {
      AppUtils.showSnackBar(context, result.error ?? AppConstants.errUnknown);
    }
  }

  // ── WIRED: add product bottom sheet ──────────────────────────
  Future<void> _handleAdd() async {
    final product = await _showAddSheet();
    if (product == null || !mounted) return;

    final result = await _productService.addProduct(product);
    if (!mounted) return;

    if (result.success) {
      setState(() => _products.add(result.data!));
      AppUtils.showSnackBar(context, '${product.name} added to catalogue.');
    } else {
      AppUtils.showSnackBar(context, result.error ?? AppConstants.errUnknown);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        scrollBehavior: _NoScrollbar(),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _AppBarDelegate(context),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildStoreHeader(),
                const SizedBox(height: 32),
                _buildMetricCards(),
                const SizedBox(height: 32),
                _buildAlertBanner(),
                const SizedBox(height: 32),
                _buildProductsHeader(),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else
                  ..._products.asMap().entries.map(
                    (e) => Padding(
                      padding: EdgeInsets.only(
                        bottom: e.key < _products.length - 1 ? 16 : 0,
                      ),
                      child: _buildProductRow(e.value),
                    ),
                  ),
                const SizedBox(height: 16),
                // ── WIRED: Add button ─────────────────────
                _buildAddProductButton(),
                const SizedBox(height: 48),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Store header ─────────────────────────────────────────────
  Widget _buildStoreHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Store Overview',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.tertiary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.tertiary.withValues(alpha: 0.70),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Systems Online  •  Last updated 2m ago',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Metric cards — now driven by real data ────────────────────
  Widget _buildMetricCards() {
    final metrics = [
      _MetricData(
        icon: Icons.inventory_2_outlined,
        label: 'PRODUCTS',
        value: '$_totalProducts',
        badge: '+$_totalProducts',
        hasBorderLeft: false,
      ),
      _MetricData(
        icon: Icons.warning_amber_outlined,
        label: 'LOW STOCK',
        value: '$_lowStockCount',
        badge: _lowStockCount > 0 ? 'Alert' : 'OK',
        hasBorderLeft: false,
      ),
      _MetricData(
        icon: Icons.payments_outlined,
        label: 'CATALOGUE VALUE',
        value: '\$${(_totalRevenue / 1000).toStringAsFixed(1)}k',
        badge: 'Live',
        hasBorderLeft: true,
      ),
    ];

    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemCount: metrics.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (_, i) => _buildMetricCard(metrics[i]),
      ),
    );
  }

  Widget _buildMetricCard(_MetricData data) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.raised,
        border: data.hasBorderLeft
            ? Border(
                left: BorderSide(
                  color: AppColors.tertiary.withValues(alpha: 0.20),
                  width: 4,
                ),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: AppColors.onSurfaceVariant, size: 20),
          const SizedBox(height: 12),
          Text(
            data.label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.onSurface,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0x4D064E3B),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              data.badge,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.tertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Alert banner — dynamic based on low stock count ───────────
  Widget _buildAlertBanner() {
    final hasAlert = _lowStockCount > 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hasAlert
            ? const Color(0xFF2D2007)
            : AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.raised,
        border: Border(
          left: BorderSide(
            color: hasAlert ? const Color(0xFFFFA000) : AppColors.primary,
            width: 4,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hasAlert ? Icons.warning_outlined : Icons.check_circle_outline,
            color: hasAlert ? const Color(0xFFFFA000) : AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasAlert ? 'INVENTORY ALERT' : 'STOCK HEALTHY',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: hasAlert
                        ? const Color(0xFFFFA000)
                        : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasAlert
                      ? '$_lowStockCount products are below safety stock threshold. Replenish soon to avoid lost sales.'
                      : 'All products are well-stocked. No action required.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppColors.onSurface.withValues(alpha: 0.90),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Products header — live item count ─────────────────────────
  Widget _buildProductsHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Manage Products',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.48,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_products.length} ITEMS TOTAL',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ── Product row — WIRED edit + delete ────────────────────────
  Widget _buildProductRow(ProductModel p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.raised,
        // Red tint if low stock
        border: p.stock <= 5 && p.stock > 0
            ? Border.all(
                color: AppColors.error.withValues(alpha: 0.20),
                width: 1,
              )
            : null,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppShadows.pressed,
              ),
              child: Image.network(
                p.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.surfaceContainerLowest,
                  child: const Icon(
                    Icons.image_outlined,
                    color: AppColors.outlineVariant,
                    size: 22,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
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
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.35,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppUtils.truncate(p.name, 22),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      AppUtils.formatPrice(p.price),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.tertiary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${p.stock} in stock',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: p.stock <= 5
                            ? AppColors.error
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              // ── WIRED: Edit button ────────────────────────
              _buildIconBtn(
                Icons.edit_outlined,
                AppColors.onSurfaceVariant,
                () => _handleEdit(p),
              ),
              const SizedBox(width: 8),
              // ── WIRED: Delete button ──────────────────────
              _buildIconBtn(
                Icons.delete_outline,
                AppColors.error,
                () => _handleDelete(p),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  // ── WIRED: Add product button ─────────────────────────────────
  Widget _buildAddProductButton() {
    return GestureDetector(
      onTap: _handleAdd,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.onSurface, width: 2),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: AppColors.onSurface,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              '+ ADD NEW PRODUCT',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Replace _showEditSheet() ──────────────────────────────────
  Future<ProductModel?> _showEditSheet(ProductModel p) async {
    final nameCtrl = TextEditingController(text: p.name);
    final priceCtrl = TextEditingController(text: p.price.toString());
    final stockCtrl = TextEditingController(text: p.stock.toString());
    final imageUrlCtrl = TextEditingController(text: p.imageUrl);
    String category = p.category;

    final result = await showModalBottomSheet<ProductModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ProductFormSheet(
        title: 'Edit Product',
        nameCtrl: nameCtrl,
        priceCtrl: priceCtrl,
        stockCtrl: stockCtrl,
        imageUrlCtrl: imageUrlCtrl,
        category: category,
        onSave: (cat) {
          final price = double.tryParse(priceCtrl.text) ?? p.price;
          final stock = int.tryParse(stockCtrl.text) ?? p.stock;
          Navigator.pop(
            ctx,
            p.copyWith(
              name: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
              price: price,
              stock: stock,
              category: cat,
              imageUrl: imageUrlCtrl.text.trim().isEmpty
                  ? null
                  : imageUrlCtrl.text.trim(),
            ),
          );
        },
      ),
    );

    nameCtrl.dispose();
    priceCtrl.dispose();
    stockCtrl.dispose();
    imageUrlCtrl.dispose();
    return result;
  }

  // ── Replace _showAddSheet() ───────────────────────────────────
  Future<ProductModel?> _showAddSheet() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    final imageUrlCtrl = TextEditingController();

    final result = await showModalBottomSheet<ProductModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ProductFormSheet(
        title: 'Add New Product',
        nameCtrl: nameCtrl,
        priceCtrl: priceCtrl,
        stockCtrl: stockCtrl,
        imageUrlCtrl: imageUrlCtrl,
        category: AppConstants.productCategories[1],
        onSave: (cat) {
          final name = nameCtrl.text.trim();
          final price = double.tryParse(priceCtrl.text) ?? 0.0;
          final stock = int.tryParse(stockCtrl.text) ?? 0;
          if (name.isEmpty || price <= 0) return;
          Navigator.pop(
            ctx,
            ProductModel(
              id: AppUtils.generateId('prd'),
              name: name,
              category: cat,
              price: price,
              imageUrl: imageUrlCtrl.text.trim(),
              stock: stock,
            ),
          );
        },
      ),
    );

    nameCtrl.dispose();
    priceCtrl.dispose();
    stockCtrl.dispose();
    imageUrlCtrl.dispose();
    return result;
  }
}

// ── Replace _ProductFormSheet completely ──────────────────────
class _ProductFormSheet extends StatefulWidget {
  final String title;
  final TextEditingController nameCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController stockCtrl;
  final TextEditingController imageUrlCtrl;
  final String category;
  final void Function(String category) onSave;

  const _ProductFormSheet({
    required this.title,
    required this.nameCtrl,
    required this.priceCtrl,
    required this.stockCtrl,
    required this.imageUrlCtrl,
    required this.category,
    required this.onSave,
  });

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  late String _category;

  @override
  void initState() {
    super.initState();
    _category = widget.category;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
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
          Text(
            widget.title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 24),

          // Image URL preview — shows a live preview of the URL
          if (widget.imageUrlCtrl.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.imageUrlCtrl.text,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 120,
                    color: AppColors.surfaceContainerLow,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.outlineVariant,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Product Name
          _buildField('Product Name', widget.nameCtrl, TextInputType.text),
          const SizedBox(height: 16),

          // Price
          _buildField(
            'Price (\$)',
            widget.priceCtrl,
            const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),

          // Stock
          _buildField('Stock', widget.stockCtrl, TextInputType.number),
          const SizedBox(height: 16),

          // Image URL — paste any image URL from the web
          _buildField('Image URL', widget.imageUrlCtrl, TextInputType.url),
          const SizedBox(height: 8),
          const Text(
            'Paste any image URL from the web (e.g. from Google Images → '
            'right-click image → Copy image address)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppColors.outlineVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Category dropdown
          const Text(
            'CATEGORY',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppShadows.pressed,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _category,
                dropdownColor: AppColors.surfaceContainerHigh,
                isExpanded: true,
                items: AppConstants.productCategories
                    .where((c) => c != 'ALL')
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                          c,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Save
          GestureDetector(
            onTap: () => widget.onSave(_category),
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
                  'Save',
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
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    TextInputType type,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppShadows.pressed,
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: type,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.onSurface,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Metric data ───────────────────────────────────────────────
class _MetricData {
  final IconData icon;
  final String label, value, badge;
  final bool hasBorderLeft;
  const _MetricData({
    required this.icon,
    required this.label,
    required this.value,
    required this.badge,
    required this.hasBorderLeft,
  });
}

// ── AppBar delegate ───────────────────────────────────────────
class _AppBarDelegate extends SliverPersistentHeaderDelegate {
  final BuildContext context;
  _AppBarDelegate(this.context);

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;
  double get _height => MediaQuery.of(context).padding.top + 64;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
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
                onTap: () => Navigator.maybePop(context),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Admin Dashboard',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.4,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {},
                child: const Icon(
                  Icons.settings_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.raised,
                  border: Border.all(
                    color: AppColors.primaryContainer,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuBCJVH551Zfh9qJ_TJ9UsBqUCB7sxpyJbPqDlbnUwPVYy4WaCy_OmGiVPmYkhg9rUADbokq3BuNkOUkRpDYVLVTb5UgvS6l4xpoXmqvXQqefH4rypPMEq_z7875y1tzHy3hIsZjzDX-g6gHXTkAj1zu3xtd4P66Fi6WbsqAnZQZvA6czrrhWjkGpUFfz98vABtv2H47Sst8KeuKUOinH1ZGNMif0FHvjZDLXiJKBEnnVpVS2IZmYpOrmVDgvRY-dJTwHTScN-c7i2vt',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.surfaceContainerHigh,
                      child: const Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_AppBarDelegate old) => false;
}

class _NoScrollbar extends ScrollBehavior {
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
