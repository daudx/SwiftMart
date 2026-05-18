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
    avatarUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuB0lZl17OpQJp6SlSyGB_O_n6iripBUN-AMIGKupuuaU5nox0mP4E8a92lro9UvQZtqactMfDktaeEdGmU6jRnPXWLFSqjGPins08qunZhkDYoc01OVOgZGv2pJzyRtJEhIVS_OPVRSEZZfNtIJ1UGs4SB6HaQ1XiNdZRQFIHHb-gQIoNTXUWMb5zfgdX4c9IX_xqFylBTcLoW_rBGKmUX-5jePVM_mJirTl4PMx6lrcoxF6cyv1k0Z81XnObOH2f1bUCLloILV2GPX',
    ordersCount:   24,
    wishlistCount: 12,
    reviewsCount:  8,
  );

  @override
  String toString() =>
      'UserModel(id: $id, name: $name, email: $email)';
}