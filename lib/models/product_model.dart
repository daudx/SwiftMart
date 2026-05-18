/// Represents a SwiftMart product.
///
/// Used by:
///   - home_screen               (product detail)
///   - cart_item_model           (nested reference)
///   - order_model               (nested reference)
///   - admin_screen              (manage products list)
///   - swiftbot_suggestions_screen (AI-suggested products)
///   - product_card widget       (grid / list cards)
class ProductModel {
  final String id;
  final String name;
  final String category; // e.g. "RUNNING SHOES", "TECH", "AUDIO"
  final double price;
  final String imageUrl; // hero / primary image

  // ── Product detail specific ───────────────────────────────────
  final List<String> thumbnailUrls; // thumbnail carousel
  final String description;
  final String weight; // e.g. "198g (Ultra-Light)"
  final String energyReturn; // e.g. "89% Efficiency"
  final List<String> sizes; // e.g. ["8","9","10","11","12"]
  final List<String> features; // e.g. ["Breathable","Waterproof","Recycled"]

  // ── Inventory (admin_screen) ──────────────────────────────────
  final int stock;

  // ── User state ────────────────────────────────────────────────
  final bool isFavourite;
  final bool isFeatured;

  const ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
    this.thumbnailUrls = const [],
    this.description = '',
    this.weight = '',
    this.energyReturn = '',
    this.sizes = const ['8', '9', '10', '11', '12'],
    this.features = const [],
    this.stock = 0,
    this.isFavourite = false,
    this.isFeatured = false,
  });

  // ── copyWith ─────────────────────────────────────────────────
  ProductModel copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    String? imageUrl,
    List<String>? thumbnailUrls,
    String? description,
    String? weight,
    String? energyReturn,
    List<String>? sizes,
    List<String>? features,
    int? stock,
    bool? isFavourite,
    bool? isFeatured,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrls: thumbnailUrls ?? this.thumbnailUrls,
      description: description ?? this.description,
      weight: weight ?? this.weight,
      energyReturn: energyReturn ?? this.energyReturn,
      sizes: sizes ?? this.sizes,
      features: features ?? this.features,
      stock: stock ?? this.stock,
      isFavourite: isFavourite ?? this.isFavourite,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }

  // ── toJson ───────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'price': price,
    'imageUrl': imageUrl,
    'thumbnailUrls': thumbnailUrls,
    'description': description,
    'weight': weight,
    'energyReturn': energyReturn,
    'sizes': sizes,
    'features': features,
    'stock': stock,
    'isFavourite': isFavourite,
    'isFeatured': isFeatured,
  };

  // ── fromJson ─────────────────────────────────────────────────
  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
    id: json['id'] as String,
    name: json['name'] as String,
    category: json['category'] as String,
    price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
    imageUrl: json['imageUrl']?.toString() ?? '',
    thumbnailUrls:
        (json['thumbnailUrls'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    description: json['description']?.toString() ?? '',
    weight: json['weight']?.toString() ?? '',
    energyReturn: json['energyReturn']?.toString() ?? '',
    sizes:
        (json['sizes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        ['8', '9', '10', '11', '12'],
    features:
        (json['features'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    stock: int.tryParse(json['stock']?.toString() ?? '0') ?? 0,
    isFavourite: json['isFavourite'] == true || json['isFavourite'] == 'true',
    isFeatured: json['isFeatured'] == true || json['isFeatured'] == 'true',
  );

  // ── Seed product — matches home_screen UI exactly ─────────────
  static const seed = ProductModel(
    id: 'prd_001',
    name: 'SwiftAir Max Ultra Pro',
    category: 'RUNNING SHOES',
    price: 189.00,
    imageUrl:
        'https://images.unsplash.com/photo-1606107557195-0e29a4b5b4aa?w=800&q=80',
    thumbnailUrls: [
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800&q=80',
      'https://images.unsplash.com/photo-1608231387042-66d1773070a5?w=800&q=80',
      'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=800&q=80',
      'https://images.unsplash.com/photo-1511556532299-8f662fc26c06?w=800&q=80',
    ],
    description:
        'Designed for maximum propulsion and elite cushioning. The Ultra Pro features '
        'our proprietary SwiftGrip™ outsole and reactive carbon-fiber plates for '
        'your fastest runs ever.',
    weight: '198g (Ultra-Light)',
    energyReturn: '89% Efficiency',
    sizes: ['8', '9', '10', '11', '12'],
    features: ['Breathable', 'Waterproof', 'Recycled'],
    stock: 47,
    isFavourite: true,
  );

  @override
  String toString() => 'ProductModel(id: $id, name: $name, price: \$$price)';
}
