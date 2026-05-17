import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/utils/app_utils.dart';
import '../../models/user_model.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../widgets/bottom_nav.dart';
import '../../core/utils/responsive_layout.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _navIndex = 4;
  int _liveOrdersCount = 0;
  int _liveWishlistCount = 0;

  UserModel get _user => AuthService().currentUser ?? UserModel.seed;

  @override
  void initState() {
    super.initState();
    _loadLiveCounts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh counts every time screen becomes visible
    _loadLiveCounts();
  }

  Future<void> _loadLiveCounts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final ordersSnap = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: uid)
          .get();
      final wishlistSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('favourites')
          .get();
      if (mounted) {
        setState(() {
          _liveOrdersCount = ordersSnap.docs.length;
          _liveWishlistCount = wishlistSnap.docs.length;
        });
      }
    } catch (e) {
      debugPrint('Profile counts error: $e');
    }
  }

  void _handleBottomNavTap(int index) {
    if (index == _navIndex) return;
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.home);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, AppRoutes.shop);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRoutes.swiftBot);
        break;
      case 3:
        Navigator.pushReplacementNamed(context, AppRoutes.cart);
        break;
      default:
        setState(() => _navIndex = index);
    }
  }

  // ── Logout ────────────────────────────────────────────────────
  // ── Replace the existing _logout() method with this ──────────

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log Out',
          style: TextStyle(
            color: AppColors.onSurface,
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(
            color: AppColors.onSurfaceVariant,
            fontFamily: 'Inter',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.onSurfaceVariant,
                fontFamily: 'Inter',
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog first
              await AuthService().logout(); // async now — awaited
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (_) => false,
              );
            },
            child: const Text(
              'Log Out',
              style: TextStyle(
                color: AppColors.error,
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── E1: Edit Profile bottom sheet ─────────────────────────────
  // ── Remove these two imports if you added them in F5 ─────────
  // import 'dart:io';
  // import '../../services/storage_service.dart';

  // ── Replace _showEditProfile() with this version ──────────────
  void _showEditProfile() {
    final user = _user;
    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone);
    final addressCtrl = TextEditingController(text: user.address);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 32,
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
            const Text(
              'Edit Profile',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 24),

            // Full Name
            _buildSheetField('Full Name', nameCtrl, TextInputType.name),
            const SizedBox(height: 16),

            // Phone
            _buildSheetField('Phone Number', phoneCtrl, TextInputType.phone),
            const SizedBox(height: 16),

            // Address
            _buildSheetField(
              'Shipping Address',
              addressCtrl,
              TextInputType.streetAddress,
            ),
            const SizedBox(height: 24),

            // Save button
            GestureDetector(
              onTap: () async {
                Navigator.pop(ctx);
                final result = await AuthService().updateProfile(
                  name: nameCtrl.text.trim().isEmpty
                      ? null
                      : nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim().isEmpty
                      ? null
                      : phoneCtrl.text.trim(),
                  address: addressCtrl.text.trim().isEmpty
                      ? null
                      : addressCtrl.text.trim(),
                );
                nameCtrl.dispose();
                phoneCtrl.dispose();
                addressCtrl.dispose();
                if (!mounted) return;
                if (result.success) {
                  setState(() {});
                  AppUtils.showSnackBar(context, 'Profile updated! ✅');
                } else {
                  AppUtils.showSnackBar(
                    context,
                    result.error ?? 'Update failed.',
                  );
                }
              },
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
                    'Save Changes',
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
      ),
    );
  }

  // ── E1: Notifications info sheet ──────────────────────────────
  void _showNotificationsInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            const Text(
              'Notifications',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            // Notification toggle rows
            ...[
              (
                'Order Updates',
                'Get notified when your order status changes.',
                true,
              ),
              (
                'Flash Deals',
                'Be the first to know about limited offers.',
                true,
              ),
              ('SwiftBot Tips', 'AI shopping tips from SwiftBot.', false),
            ].map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _NotificationToggle(
                  title: item.$1,
                  subtitle: item.$2,
                  initial: item.$3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShippingInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            const Text(
              'Shipping Addresses',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppShadows.pressed,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Default Shipping Address',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _user.address.isEmpty ? 'No address added' : _user.address,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sheet text field helper ───────────────────────────────────
  Widget _buildSheetField(
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    final content = ResponsiveLayout(
      // Keep profile content centered on laptop/desktop by using a tighter
      // max width; mobile layout remains unchanged.
      maxWidth: isMobile ? 1400 : 980,
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 72)),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildHeroSection(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(),
                          const SizedBox(height: 16),
                          _buildSettingsList(),
                          const SizedBox(height: 32),
                          _buildSwiftBotCard(),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(top: 0, left: 0, right: 0, child: _buildAppBar()),
        ],
      ),
    );

    if (isMobile) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            content,
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: BottomNav(
                currentIndex: _navIndex,
                onTap: _handleBottomNavTap,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          BottomNav(currentIndex: _navIndex, onTap: _handleBottomNavTap),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
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
          GestureDetector(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, AppRoutes.home);
              }
            },
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const Text(
            'Profile',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.32,
              color: AppColors.textMain,
            ),
          ),
          GestureDetector(
            // Settings icon → opens edit profile
            onTap: _showEditProfile,
            child: const Icon(
              Icons.settings_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 48),
      decoration: BoxDecoration(
        color: AppColors.ctaGradientEnd,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(48)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 256,
              height: 256,
              decoration: const BoxDecoration(
                color: Color(0x80059572),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatar(),
                const SizedBox(height: 16),
                Text(
                  _user.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.4,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _user.email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8AB8A0),
                  ),
                ),
                const SizedBox(height: 32),
                _buildStatsRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: AppShadows.raised,
            ),
            child: ClipOval(
              child: Image.network(
                _user.avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.surfaceContainerHigh,
                  child: const Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.tertiary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.ctaGradientEnd, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x66036A49),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStat('$_liveOrdersCount', 'ORDERS'),
          _buildStatDivider(),
          _buildStat('$_liveWishlistCount', 'WISHLIST'),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 1.5),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Color(0xFF8AB8A0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() => Container(
    width: 1,
    height: 32,
    color: Colors.white.withValues(alpha: 0.10),
  );

  Widget _buildSectionHeader() {
    return const Text(
      'Account Settings',
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.36,
        color: AppColors.textMain,
      ),
    );
  }

  Widget _buildSettingsList() {
    return Column(
      children: [
        _buildSettingsRow(
          icon: Icons.edit_outlined,
          label: 'Edit Profile',
          onTap: _showEditProfile,
        ),
        const SizedBox(height: 16),
        _buildSettingsRow(
          icon: Icons.shopping_bag_outlined,
          label: 'Order History',
          onTap: () => Navigator.pushNamed(context, AppRoutes.orders),
        ),
        const SizedBox(height: 16),
        _buildSettingsRow(
          icon: Icons.local_shipping_outlined,
          label: 'Track Order',
          onTap: () => Navigator.pushNamed(context, AppRoutes.orders),
        ),
        const SizedBox(height: 16),
        _buildSettingsRow(
          icon: Icons.location_on_outlined,
          label: 'Shipping Addresses',
          onTap: _showShippingInfo,
        ),
        const SizedBox(height: 16),
        _buildSettingsRow(
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          onTap: _showNotificationsInfo,
        ),
        const SizedBox(height: 16),
        _buildLogoutRow(),
      ],
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.raised,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF256C47),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.onSurfaceVariant,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutRow() {
    return GestureDetector(
      onTap: _logout,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.raised,
          border: Border.all(color: Colors.red.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF4A1C1D),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.logout, color: AppColors.error, size: 22),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Logout',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF991B1B), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSwiftBotCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppShadows.raised,
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          const Positioned(
            top: 0,
            right: 0,
            child: Opacity(
              opacity: 0.10,
              child: Icon(
                Icons.smart_toy,
                size: 96,
                color: AppColors.onSurface,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.pressed,
                ),
                child: const Icon(
                  Icons.chat_outlined,
                  color: AppColors.tertiary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Need Help?',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Talk to SwiftBot AI assistant for instant support with your orders.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.swiftBot,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        child: const Text(
                          'Chat',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Notification toggle widget ────────────────────────────────
class _NotificationToggle extends StatefulWidget {
  final String title, subtitle;
  final bool initial;
  const _NotificationToggle({
    required this.title,
    required this.subtitle,
    required this.initial,
  });

  @override
  State<_NotificationToggle> createState() => _NotificationToggleState();
}

class _NotificationToggleState extends State<_NotificationToggle> {
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _enabled = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: _enabled,
          onChanged: (v) => setState(() => _enabled = v),
          activeThumbColor: AppColors.tertiary,
          activeTrackColor: AppColors.primaryContainer,
          inactiveThumbColor: AppColors.outlineVariant,
          inactiveTrackColor: AppColors.surfaceContainerLow,
        ),
      ],
    );
  }
}
