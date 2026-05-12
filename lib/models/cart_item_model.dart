import 'product_model.dart';

/// A single line item in the shopping cart.
///
/// Used by:
///   - cart_screen   (list of items, quantity stepper, totals)
///   - cart_service  (add / remove / update)
class CartItemModel {
  final ProductModel product;
  final String selectedSize;    // chosen size from product.sizes
  int quantity;                 // mutable — stepper increments/decrements

  CartItemModel({
    required this.product,
    required this.selectedSize,
    this.quantity = 1,
  });

  // ── Computed total for this line item ─────────────────────────
  double get total => product.price * quantity;

  // ── copyWith ─────────────────────────────────────────────────
  CartItemModel copyWith({
    ProductModel? product,
    String? selectedSize,
    int? quantity,
  }) {
    return CartItemModel(
      product:      product      ?? this.product,
      selectedSize: selectedSize ?? this.selectedSize,
      quantity:     quantity     ?? this.quantity,
    );
  }

  // ── toJson ───────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'product':      product.toJson(),
    'selectedSize': selectedSize,
    'quantity':     quantity,
  };

  // ── fromJson ─────────────────────────────────────────────────
  factory CartItemModel.fromJson(Map<String, dynamic> json) => CartItemModel(
    product:      ProductModel.fromJson(
                    json['product'] as Map<String, dynamic>),
    selectedSize: json['selectedSize'] as String,
    quantity:     (json['quantity'] as num).toInt(),
  );

  // ── Seed items — match cart_screen UI exactly ─────────────────
  static List<CartItemModel> get seedItems => [
    CartItemModel(
      product: ProductModel(
        id:        'prd_002',
        name:      'AeroFlow Runner',
        category:  'SHOES',
        price:     124.00,
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCnsX9ojFQlRjipOx_bEMPfD-OFdv4XDtM12sHZafbBUuUJNSzDRQnt47eHaoPoEacr7DDNH0kEvebRp7uiN7wJv71oKag3mfV6cLRBj4qWFLvuwUqG5ezOZDCsIJVt6U_CATaaOfFsuVyiT5VpK30xPGf7pIfjNTGnmW9-LaMQT2TiLvkw08PV25NrX72zG749IgNMBmyegzBrBU9X9Gvb2njXArAXB5Tv6n1Wq7Y5iFQmXiUvaQtB8HksnRJHmSJTgi_LGiCphkT2',
        stock:     30,
      ),
      selectedSize: 'Emerald / Size 42',
      quantity:     1,
    ),
    CartItemModel(
      product: ProductModel(
        id:        'prd_003',
        name:      'Onyx Chronograph',
        category:  'TECH',
        price:     299.00,
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuB3xk0V8Gu8mwI5OwWllcsYA_aNmI3AFwueAzhlvZFOb9_KTOxDq8EXR-gLiofI7jruA2w3U9oZULTf08rjN-p2Ff4K-RlXl7bJWMNbNXJx9iU4tjoVtm-ujzlkLjm1B7_-q4Z-Ukx0xLLPugzZRZBFKlAk1zsdj1FzWK0mIu99Prn7qfSxuGTgGWbKJw1ECZNl9ejroWjtPKkd3awW5smy0RWNalahywLcpXGlWLkn0OYYM2LvFL2PSO9J1IaB17L2U10E2az0O7Ha',
        stock:     12,
      ),
      selectedSize: 'Midnight Edition',
      quantity:     1,
    ),
    CartItemModel(
      product: ProductModel(
        id:        'prd_004',
        name:      'Nova Pulse ANC',
        category:  'AUDIO',
        price:     189.50,
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDWo_XW3SM_cBO8ijPwOeOnMTEBFndG94vmxxCFj3mVHz1E0ru6tQSu9DZlWD8FnV-hB0LHhTZ_i_EGH88jpqwKBth7TMdn5JuNGAXGW_VDBA39Z3wMwPu8uNx1t76f_hIY45Tn_znitn0TW4MatO5LGqg5JaDxB6lGtxDNKoaZ48toByPLvWfB8sZf7wS8WV1ZtN5Zt0VF0DPOoUT5O_M3EHZ9mYEkMFJmZ_aFSnSnTjHi7FDEl_oCHDf1g-sgk_',
        stock:     8,
      ),
      selectedSize: 'Obsidian Black',
      quantity:     2,
    ),
  ];

  @override
  String toString() =>
      'CartItemModel(${product.name} × $quantity @ \$${product.price})';
}