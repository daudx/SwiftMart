import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/constants/app_constant.dart';

class AddProductScreen extends StatefulWidget {
  final String? productId;
  final Map<String, dynamic>? productData;

  const AddProductScreen({super.key, this.productId, this.productData});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _priceCtrl  = TextEditingController();
  final _stockCtrl  = TextEditingController();
  final _descCtrl   = TextEditingController();
  final _imgUrlCtrl = TextEditingController();

  String _selectedCategory = 'TECH';
  bool   _isLoading        = false;

  // Listener to rebuild image preview as user types
  void _onUrlChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    _imgUrlCtrl.addListener(_onUrlChanged);

    final d = widget.productData;
    if (d != null) {
      _nameCtrl.text  = d['name']?.toString()  ?? '';
      _priceCtrl.text = d['price']?.toString()  ?? '';
      _stockCtrl.text = d['stock']?.toString()  ?? '';
      _descCtrl.text  = d['description']?.toString() ?? '';
      _imgUrlCtrl.text = d['imageUrl']?.toString() ?? '';

      // Support both 'category' and legacy 'categoryId'
      final cat = d['category'] ?? d['categoryId'] ?? 'TECH';
      _selectedCategory = AppConstants.productCategories.contains(cat.toString())
          ? cat.toString()
          : 'TECH';
    }
  }

  @override
  void dispose() {
    _imgUrlCtrl.removeListener(_onUrlChanged);
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _descCtrl.dispose();
    _imgUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final productData = {
        'name':        _nameCtrl.text.trim(),
        'price':       double.tryParse(_priceCtrl.text.trim()) ?? 0.0,
        'stock':       int.tryParse(_stockCtrl.text.trim()) ?? 0,
        'description': _descCtrl.text.trim(),
        'imageUrl':    _imgUrlCtrl.text.trim(),
        'category':    _selectedCategory,   // ← always use 'category'
        'rating':      widget.productData?['rating'] ?? 4.5,
        'reviewsCount': widget.productData?['reviewsCount'] ?? 0,
        'isFeatured':  widget.productData?['isFeatured'] ?? false,
      };

      if (widget.productId == null) {
        // CREATE — auto-generate ID and embed it in the document
        final docRef = FirebaseFirestore.instance.collection('products').doc();
        productData['id'] = docRef.id;
        await docRef.set(productData);
      } else {
        // UPDATE — merge so we don't lose extra fields
        productData['id'] = widget.productId!;
        await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.productId)
            .update(productData);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.productId == null
              ? 'Product added successfully!'
              : 'Product updated successfully!'),
          backgroundColor: AppColors.surfaceContainerHigh,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productId != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Product' : 'Add Product',
          style: const TextStyle(
              color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.primary),
        elevation: 0,
      ),
      body: ResponsiveLayout(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Product Name ─────────────────────────────
                _buildTextField('Product Name', _nameCtrl, 'e.g. Sonic Pro Over-Ear'),
                const SizedBox(height: 16),

                // ── Price + Stock row ───────────────────────
                Row(
                  children: [
                    Expanded(
                        child: _buildTextField('Price (\$)', _priceCtrl, '0.00',
                            isNumber: true)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildTextField('Stock (qty)', _stockCtrl, '0',
                            isNumber: true, isRequired: false)),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Description ─────────────────────────────
                _buildTextField('Description', _descCtrl,
                    'Short product description…',
                    maxLines: 3, isRequired: false),
                const SizedBox(height: 16),

                // ── Category ────────────────────────────────
                _buildLabel('Category'),
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
                      dropdownColor: AppColors.surfaceContainerHigh,
                      value: _selectedCategory,
                      isExpanded: true,
                      style: const TextStyle(
                          color: AppColors.onSurface, fontFamily: 'Inter'),
                      items: AppConstants.productCategories
                          .where((c) => c != 'ALL')
                          .map((c) =>
                              DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Image URL ───────────────────────────────
                _buildTextField('Image URL', _imgUrlCtrl,
                    'https://images.unsplash.com/…',
                    isRequired: false),
                const SizedBox(height: 12),

                // ── Image preview ───────────────────────────
                if (_imgUrlCtrl.text.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 180,
                      child: Image.network(
                        _imgUrlCtrl.text,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (_, child, progress) =>
                            progress == null
                                ? child
                                : const Center(
                                    child: CircularProgressIndicator(
                                        color: AppColors.primary)),
                        errorBuilder: (_, __, ___) => Container(
                          height: 60,
                          color: AppColors.surfaceContainerLow,
                          child: const Center(
                              child: Text('⚠ Invalid image URL',
                                  style: TextStyle(
                                      color: AppColors.error))),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // ── Save button ─────────────────────────────
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: AppColors.onPrimary, strokeWidth: 2))
                      : Text(
                          isEditing ? 'Update Product' : 'Add Product',
                          style: const TextStyle(
                              color: AppColors.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helper widgets ───────────────────────────────────────────

  Widget _buildLabel(String text) => Text(
        text.toUpperCase(),
        style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8),
      );

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    bool isNumber   = false,
    bool isRequired = true,
    int maxLines    = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppShadows.pressed,
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : maxLines > 1
                    ? TextInputType.multiline
                    : TextInputType.text,
            maxLines: maxLines,
            style: const TextStyle(
                color: AppColors.onSurface, fontFamily: 'Inter'),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                  color: AppColors.outlineVariant, fontFamily: 'Inter'),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            validator: isRequired
                ? (value) => (value == null || value.trim().isEmpty)
                    ? 'Required'
                    : null
                : null,
          ),
        ),
      ],
    );
  }
}
