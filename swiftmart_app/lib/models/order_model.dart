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
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAmxKeqOIJ1AYhz8kjYFNz0N-ZLZVni0FUVD0FQiEqbBndt2PtN6pj5QypRbI_PCkMJHapDeG6j_Qp7N_cuptk_DeCyyhxFdqo2zFO4Jwn-BTzkjLZ3yDjrnILhLytPhFQpZy8CekH7gvDU3MV74P5vDg1KXnQkhkWDnTmjrDJRaWhihwxTLOlpSC73PxlXfQZhonNakwwQAuegqg8a9IWiqdQzZLxgkHT88Zp2VUKiPY9Qc9Hkzq63Kj6CsuVLjtcSpLJuODleGm5F',
    ),
    OrderModel(
      id:              '#SM-9104',
      productName:     'Emerald Mechanical Deck',
      price:           89.50,
      date:            'Nov 02, 2023',
      status:          OrderStatus.shipped,
      productImageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCqAK2GXdn902XVqhjhd7twZPS4gS2pRT-a2YykCsuiWfm04HY6OxsTOIOZagBDEyRQa0Q0hi3vO_ivzYV9zRRTDAOIVrg-TsKwXib02CDnVBEIqpEA2CwIb1TTs15BZzRdaMNm_60gJ3rOh2sfLIkmCGONAwuOYx0UMSSvDMQW1qz4s89535C83dOqK9DyisDpjaTrbsfz762xDEczV0CP5XV-FAujahyEysTYY1pJct9T7jl1xFCYMiouXyTzv7bEh4s5f-0oUT4W',
    ),
    OrderModel(
      id:              '#SM-7721',
      productName:     'SwiftGlass S24',
      price:           999.00,
      date:            'Today, 10:24 AM',
      status:          OrderStatus.processing,
      productImageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuA2SQBuQcTsfSecmSWObAfLcglI0wwNbH7meNXIE_ZJ8fJiWxkikFAsEkb50W5otv3kRWbPc0UgzGg1ijkigxuc4xCgyQzwZaOlndlUWrMa1zZXLTRHFoLoUIq5cc7yUWbNdkPgHV5H14GFz73vbuV-_zJVzIuT-PC0MBFeyNaOcPC_TlOkXhevB8Pt1SxFPB6OokPslz4fdkQOaUqmwFF4vo2PrdvLLMaX0f9IjKfpBPpYNM735-iVigQRz7qQ-oPry3JM-URlVwRY',
    ),
    OrderModel(
      id:              '#SM-5509',
      productName:     'Tempo Fit Watch',
      price:           245.00,
      date:            'Sep 15, 2023',
      status:          OrderStatus.delivered,
      productImageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCBJB2n6zWfhfANoQFhws7xU5IRjXWdtZHDsOkqImwv9GnAggIzN0AH-n0Sbg0VVX2bjYjE0E2YkzjSygqyV5uR8oaH4Wfyyb5_v9W4e1arWGwegvDdjvXg21kDPEi9obfujN-AuEcUnZcEnfSDwccL0YJ1dcCRlj1pZAcQrKAZZNrdFQIiWPqR_WqzjXFtyDvpGehwMrOucSiaKBYmSWjdo33A-7np2GZRNZqH_o5q1vc0dFgA8VmbEL5VDwO5qgGDsAN80u-8wGg_',
    ),
  ];

  @override
  String toString() =>
      'OrderModel(id: $id, product: $productName, status: ${status.name})';
}