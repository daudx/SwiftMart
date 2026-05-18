/// Represents the authenticated SwiftMart user.
///
/// Used by:
///   - login_screen    (auth response)
///   - register_screen (registration payload)
///   - profile_screen  (display + stats)
class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String avatarUrl;

  // ── Profile stats (profile_screen hero section) ───────────────
  final int ordersCount;
  final int wishlistCount;
  final int reviewsCount;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.address = '',
    required this.avatarUrl,
    this.ordersCount   = 0,
    this.wishlistCount = 0,
    this.reviewsCount  = 0,
  });

  // ── copyWith ─────────────────────────────────────────────────
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? avatarUrl,
    int? ordersCount,
    int? wishlistCount,
    int? reviewsCount,
  }) {
    return UserModel(
      id:             id             ?? this.id,
      name:           name           ?? this.name,
      email:          email          ?? this.email,
      phone:          phone          ?? this.phone,
      address:        address        ?? this.address,
      avatarUrl:      avatarUrl      ?? this.avatarUrl,
      ordersCount:    ordersCount    ?? this.ordersCount,
      wishlistCount:  wishlistCount  ?? this.wishlistCount,
      reviewsCount:   reviewsCount   ?? this.reviewsCount,
    );
  }

  // ── toJson ───────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'id':             id,
    'name':           name,
    'email':          email,
    'phone':          phone,
    'address':        address,
    'avatarUrl':      avatarUrl,
    'ordersCount':    ordersCount,
    'wishlistCount':  wishlistCount,
    'reviewsCount':   reviewsCount,
  };

  // ── fromJson ─────────────────────────────────────────────────
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id:             json['id']            as String,
    name:           json['name']          as String,
    email:          json['email']         as String,
    phone:          json['phone']         as String,
    address:        json['address']       as String? ?? '',
    avatarUrl:      json['avatarUrl']     as String,
    ordersCount:    (json['ordersCount']   as num?)?.toInt()  ?? 0,
    wishlistCount:  (json['wishlistCount'] as num?)?.toInt()  ?? 0,
    reviewsCount:   (json['reviewsCount']  as num?)?.toInt()  ?? 0,
  );

  // ── Seed user matching profile_screen UI ──────────────────────
  static const seed = UserModel(
    id:            'usr_001',
    name:          'daudx',
    email:         'daud@example.com',
    phone:         '+1 (555) 000-0000',
    address:       '123 SwiftMart Ave, NY 10001',
    avatarUrl:
        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=800&q=80',
    ordersCount:   24,
    wishlistCount: 12,
    reviewsCount:  8,
  );

  @override
  String toString() =>
      'UserModel(id: $id, name: $name, email: $email, address: $address)';
}