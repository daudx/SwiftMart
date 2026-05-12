/// Order status — drives badge colour and action buttons
/// in order_history_screen.
enum OrderStatus {
  delivered,
  shipped,
  processing,
}

/// A completed or in-progress order in the user's history.
///
/// Used by:
///   - order_history_screen  (list of orders, status badges, actions)
///   - order_service         (place order, fetch history)
class OrderModel {
  final String id;              // e.g. "#SM-8293"
  final String productName;     // denormalised — avoids deep nesting in UI
  final String productImageUrl;
  final double price;           // total paid for this order
  final String date;            // display string e.g. "Oct 24, 2023"
  final OrderStatus status;

  const OrderModel({
    required this.id,
    required this.productName,
    required this.productImageUrl,
    required this.price,
    required this.date,
    required this.status,
  });

  // ── copyWith ─────────────────────────────────────────────────
  OrderModel copyWith({
    String? id,
    String? productName,
    String? productImageUrl,
    double? price,
    String? date,
    OrderStatus? status,
  }) {
    return OrderModel(
      id:               id               ?? this.id,
      productName:      productName      ?? this.productName,
      productImageUrl:  productImageUrl  ?? this.productImageUrl,
      price:            price            ?? this.price,
      date:             date             ?? this.date,
      status:           status           ?? this.status,
    );
  }

  // ── toJson ───────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'id':               id,
    'productName':      productName,
    'productImageUrl':  productImageUrl,
    'price':            price,
    'date':             date,
    'status':           status.name,  // "delivered" / "shipped" / "processing"
  };

  // ── fromJson ─────────────────────────────────────────────────
  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
    id:               json['id']              as String,
    productName:      json['productName']     as String,
    productImageUrl:  json['productImageUrl'] as String,
    price:            (json['price']          as num).toDouble(),
    date:             json['date']            as String,
    status:           OrderStatus.values.firstWhere(
                        (s) => s.name == json['status'],
                        orElse: () => OrderStatus.processing,
                      ),
  );

  // ── Seed orders — match order_history_screen UI exactly ───────
  static const List<OrderModel> seedOrders = [
    OrderModel(
      id:              '#SM-8293',
      productName:     'Quantum Bass Pro',
      price:           129.00,
      date:            'Oct 24, 2023',
      status:          OrderStatus.delivered,
      productImageUrl:
          'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&q=80',
    ),
    OrderModel(
      id:              '#SM-9104',
      productName:     'Emerald Mechanical Deck',
      price:           89.50,
      date:            'Nov 02, 2023',
      status:          OrderStatus.shipped,
      productImageUrl:
          'https://images.unsplash.com/photo-1595225476474-87563907a212?w=800&q=80',
    ),
    OrderModel(
      id:              '#SM-7721',
      productName:     'SwiftGlass S24',
      price:           999.00,
      date:            'Today, 10:24 AM',
      status:          OrderStatus.processing,
      productImageUrl:
          'https://images.unsplash.com/photo-1598327105666-5b89351cb31b?w=800&q=80',
    ),
    OrderModel(
      id:              '#SM-5509',
      productName:     'Tempo Fit Watch',
      price:           245.00,
      date:            'Sep 15, 2023',
      status:          OrderStatus.delivered,
      productImageUrl:
          'https://images.unsplash.com/photo-1508685096489-7aacd43bd3b1?w=800&q=80',
    ),
  ];

  @override
  String toString() =>
      'OrderModel(id: $id, product: $productName, status: ${status.name})';
}