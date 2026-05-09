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
  final String category;    // e.g. "RUNNING SHOES", "TECH", "AUDIO"
  final double price;
  final String imageUrl;    // hero / primary image

  // ── Product detail specific ───────────────────────────────────
  final List<String> thumbnailUrls; // thumbnail carousel
  final String description;
  final String weight;              // e.g. "198g (Ultra-Light)"
  final String energyReturn;        // e.g. "89% Efficiency"
  final List<String> sizes;         // e.g. ["8","9","10","11","12"]
  final List<String> features;      // e.g. ["Breathable","Waterproof","Recycled"]

  // ── Inventory (admin_screen) ──────────────────────────────────
  final int stock;

  // ── User state ────────────────────────────────────────────────
  final bool isFavourite;

  const ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
    this.thumbnailUrls = const [],
    this.description   = '',
    this.weight        = '',
    this.energyReturn  = '',
    this.sizes         = const ['8', '9', '10', '11', '12'],
    this.features      = const [],
    this.stock         = 0,
    this.isFavourite   = false,
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
  }) {
    return ProductModel(
      id:            id            ?? this.id,
      name:          name          ?? this.name,
      category:      category      ?? this.category,
      price:         price         ?? this.price,
      imageUrl:      imageUrl      ?? this.imageUrl,
      thumbnailUrls: thumbnailUrls ?? this.thumbnailUrls,
      description:   description   ?? this.description,
      weight:        weight        ?? this.weight,
      energyReturn:  energyReturn  ?? this.energyReturn,
      sizes:         sizes         ?? this.sizes,
      features:      features      ?? this.features,
      stock:         stock         ?? this.stock,
      isFavourite:   isFavourite   ?? this.isFavourite,
    );
  }

  // ── toJson ───────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'id':            id,
    'name':          name,
    'category':      category,
    'price':         price,
    'imageUrl':      imageUrl,
    'thumbnailUrls': thumbnailUrls,
    'description':   description,
    'weight':        weight,
    'energyReturn':  energyReturn,
    'sizes':         sizes,
    'features':      features,
    'stock':         stock,
    'isFavourite':   isFavourite,
  };

  // ── fromJson ─────────────────────────────────────────────────
  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
    id:            json['id']           as String,
    name:          json['name']         as String,
    category:      json['category']     as String,
    price:         (json['price']       as num).toDouble(),
    imageUrl:      json['imageUrl']     as String,
    thumbnailUrls: List<String>.from(json['thumbnailUrls'] ?? []),
    description:   json['description']  as String? ?? '',
    weight:        json['weight']       as String? ?? '',
    energyReturn:  json['energyReturn'] as String? ?? '',
    sizes:         List<String>.from(json['sizes'] ?? ['8','9','10','11','12']),
    features:      List<String>.from(json['features'] ?? []),
    stock:         (json['stock']       as num?)?.toInt() ?? 0,
    isFavourite:   json['isFavourite']  as bool? ?? false,
  );

  // ── Seed product — matches home_screen UI exactly ─────────────
  static const seed = ProductModel(
    id:          'prd_001',
    name:        'SwiftAir Max Ultra Pro',
    category:    'RUNNING SHOES',
    price:       189.00,
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuDeWXxAH0SBAFL7bLD-75T-42ZYO_U7_xCldg30xYnkvOHYInm8FtZwRbcC9AcuCXzrziIGNqBGqcisLDSymrfz11oVuErx3kCleqv-HvJ-bFSOCBHeF5GLyao7YCHzKmRAwArWHQZ7Zl2HH4kHpP6Zwc1Qq-PHk-NPo3vBYMXe2_y5T1_Bg7-JNaxQm7U3hGjBrxRFnksRHlimIbmdmphUfRpIL_8FqVfaT6N_8Wss691hBNq0hLDfGR14qS6SuYGfWG4kbI8BRg5n',
    thumbnailUrls: [
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCiBpzZ8cP67DDz5RdVl69PPsvHzdtF3Bo4Q-JLZdQqMRrqyWNyyeYxY36lvx_MelGf5J-H-IsvXg0UvH8aQQqByoOO9PH_6O4nL536eWsy9qtJl1_UlgjNKnLypf47kMnbG6SymegXhLmholhi3eRakWn5d0_kkL3-utGIlWuLRRtAmo-dN3cFKt6IE2rQ89yh3yNACsvcfZujdm40Z5xfZQ3Y5usZCil1M60vgVOs6iObH9zYFb0fx_kzPAEQn36nHyZFSfXCJCg1',
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDbLl9byrQs3aYZqQDQDNnyx4Z8FPQVOm70bH2KjpgmtomPM_WVciD3WVWHyErOyldgFOAdZM-ormmhJQpWvGsrBCpWfclqMIvZQvnVNvMMQtjxqVuHJ_ZyXoGJcnfR_zIZjN-fivRvxgAoWt-vk6_qQ4DLTX9caaxrtCo3kVDPjvuNhFRra_DUV28puuMLZlf4kqlcKAD61Oh7oGyKZdtoTgaD1f2wFSabkLI9EYK9ERALV7GlIs_MbkVTMZIwiTw-FY1K1WflhPgL',
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCtou0wBNB125_qzlT9Hhm2KOifpm6wWOUjUIriI7_cDJgwDAnJI0sJSMpOrd7m7t3MTVZl2dT7UuuI3zMYsSXUWGCD3oYN8xzzs1cb3s-2n9pRXKE2blBkrxiQFdiKeEK4aOk2-ZhBuPrc5bTv3_6G-NjJAiXV32nDds1O4347bObutjqjmkJ9AH_mUqV7LQvXZ50yzOnHNf8zuAT5G36Jw5vZbQMx1YX9ECqHVq6itMpUIcPGcKGXDpnQw5I4fsmtSKKRYoMFZYOX',
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDxwwQFMNdJ4H6R87PdeC93J43HFQjzdchc-AEyqR6PKzvpG2cojFYq-DxXZTeiTf3YomhBZqnPCoSN8A-2FIhEWHQ0HVzdUb93VKS-uLoOWm2CTRZMVV4cFe95pa7WPYIeh36MTNFKDbpcKHwpvMJkG7_Lp1QXN4vESEF12ZfmzeJlQPJ2pKQRjrodQUzpOWfU5VlHgCwMgONv7qHhNjtlMo9r2MxK1irep2Y1v-PhLvMrPqAqF3678QjbjnnJaZVQyrNxjgWwGQqW',
    ],
    description:
        'Designed for maximum propulsion and elite cushioning. The Ultra Pro features '
        'our proprietary SwiftGrip™ outsole and reactive carbon-fiber plates for '
        'your fastest runs ever.',
    weight:       '198g (Ultra-Light)',
    energyReturn: '89% Efficiency',
    sizes:        ['8', '9', '10', '11', '12'],
    features:     ['Breathable', 'Waterproof', 'Recycled'],
    stock:        47,
    isFavourite:  true,
  );

  @override
  String toString() =>
      'ProductModel(id: $id, name: $name, price: \$$price)';
}