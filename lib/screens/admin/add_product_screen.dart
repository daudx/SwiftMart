import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _imgUrlCtrl = TextEditingController();
  File? _imageFile;
  String _selectedCategory = 'TECH';
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.productData != null) {
      _nameCtrl.text = widget.productData!['name'] ?? '';
      _priceCtrl.text = widget.productData!['price']?.toString() ?? '';
      _descCtrl.text = widget.productData!['description'] ?? '';
      _imgUrlCtrl.text = widget.productData!['imageUrl'] ?? '';
      _selectedCategory = widget.productData!['categoryId'] ?? 'TECH';
      if (!AppConstants.productCategories.contains(_selectedCategory)) {
        _selectedCategory = AppConstants.productCategories[1];
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _imgUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_imageFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('product_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(_imageFile!);
        final url = await ref.getDownloadURL();
        _imgUrlCtrl.text = url;
      }

      final productData = {
        'name': _nameCtrl.text.trim(),
        'price': double.tryParse(_priceCtrl.text.trim()) ?? 0.0,
        'description': _descCtrl.text.trim(),
        'imageUrl': _imgUrlCtrl.text.trim(),
        'categoryId': _selectedCategory,
        'rating': widget.productData?['rating'] ?? 5.0,
        'reviewsCount': widget.productData?['reviewsCount'] ?? 0,
        'isFeatured': widget.productData?['isFeatured'] ?? false,
      };

      if (widget.productId == null) {
        productData['id'] = FirebaseFirestore.instance
            .collection('products')
            .doc()
            .id;
        await FirebaseFirestore.instance
            .collection('products')
            .doc(productData['id'] as String)
            .set(productData);
      } else {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.productId)
            .update(productData);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Product saved successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving product: \$e')));
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
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: ResponsiveLayout(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(
                  'Product Name',
                  _nameCtrl,
                  'Enter product name',
                ),
                const SizedBox(height: 16),
                _buildTextField('Price', _priceCtrl, '0.00', isNumber: true),
                const SizedBox(height: 16),
                _buildTextField(
                  'Description',
                  _descCtrl,
                  'Product description',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Text(
                  'PRODUCT IMAGE',
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppShadows.pressed,
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity),
                          )
                        : (_imgUrlCtrl.text.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(_imgUrlCtrl.text, fit: BoxFit.cover, width: double.infinity),
                              )
                            : const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo, color: AppColors.primary, size: 40),
                                    SizedBox(height: 8),
                                    Text('Tap to upload image', style: TextStyle(color: AppColors.onSurfaceVariant)),
                                  ],
                                ),
                              )),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Category',
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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
                      dropdownColor: AppColors.surfaceContainerHigh,
                      value: _selectedCategory,
                      isExpanded: true,
                      style: const TextStyle(color: AppColors.onSurface),
                      items: AppConstants.productCategories
                          .where((c) => c != 'ALL')
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null)
                          setState(() => _selectedCategory = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.onPrimary,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Product',
                          style: TextStyle(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.bold,
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
          child: TextFormField(
            controller: controller,
            keyboardType: isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            maxLines: maxLines,
            style: const TextStyle(color: AppColors.onSurface),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.outlineVariant),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Required' : null,
          ),
        ),
      ],
    );
  }
}
