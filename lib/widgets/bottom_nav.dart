import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// Navigation item descriptor — keeps the widget data-driven.
class _NavItem {
  final IconData icon;
  final IconData iconActive; // filled variant
  final String label;

  const _NavItem({
    required this.icon,
    required this.iconActive,
    required this.label,
  });
}

/// The five nav destinations, in order.
const List<_NavItem> _navItems = [
  _NavItem(icon: Icons.home_outlined, iconActive: Icons.home, label: 'HOME'),
  _NavItem(
    icon: Icons.storefront_outlined,
    iconActive: Icons.storefront,
    label: 'SHOP',
  ),
  _NavItem(
    icon: Icons.smart_toy_outlined,
    iconActive: Icons.smart_toy,
    label: 'SWIFTBOT',
  ),
  _NavItem(
    icon: Icons.shopping_cart_outlined,
    iconActive: Icons.shopping_cart,
    label: 'CART',
  ),
  _NavItem(
    icon: Icons.person_outline,
    iconActive: Icons.person,
    label: 'PROFILE',
  ),
];

/// SwiftMart persistent bottom navigation bar.
///
/// Matches the Emerald Tactile Interface spec exactly:
/// - Container: background (#071611), rounded-top 32px, neumorphic raised shadow
/// - Inactive items: muted text, no background, no shadow
/// - Active item: neumorphic PRESSED inset, teal (#04E8A0), rounded-2xl (16px)
///
/// Usage:
/// ```dart
/// BottomNav(
///   currentIndex: 3, // Cart
///   onTap: (index) => setState(() => _index = index),
/// )
/// ```
class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktopRail = constraints.maxWidth >= 600;

        if (!isDesktopRail) {
          return Container(
            // pt-2 pb-6 px-4  →  top:8 bottom:24 horizontal:16
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            decoration: const BoxDecoration(
              color: AppColors.background,
              // rounded-t-[32px]
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              // nav uses 15px blur — slightly larger than standard card shadow
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowDark,
                  offset: Offset(5, 5),
                  blurRadius: 15,
                ),
                BoxShadow(
                  color: Color(0xFF2E4A38),
                  offset: Offset(-5, -5),
                  blurRadius: 15,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                _navItems.length,
                (index) => _buildItem(index),
              ),
            ),
          );
        }

        return Container(
          width: 96,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.horizontal(right: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowDark,
                offset: Offset(5, 5),
                blurRadius: 15,
              ),
              BoxShadow(
                color: Color(0xFF2E4A38),
                offset: Offset(-5, -5),
                blurRadius: 15,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _navItems.length,
              (index) => Padding(
                padding: EdgeInsets.only(
                  bottom: index == _navItems.length - 1 ? 0 : 12,
                ),
                child: _buildItem(index, isDesktopRail: true),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItem(int index, {bool isDesktopRail = false}) {
    final item = _navItems[index];
    final bool isActive = index == currentIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        // p-3 → 12px all sides
        padding: EdgeInsets.all(isDesktopRail ? 10 : 12),
        width: isDesktopRail ? 80 : null,
        decoration: isActive
            ? const BoxDecoration(
                // Active: bg-[#071611] (background, not surfaceHigh)
                color: AppColors.background,
                // rounded-2xl → 16px
                borderRadius: BorderRadius.all(Radius.circular(16)),
                // Inset shadow — both dark and light halves
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowDark,
                    offset: Offset(4, 4),
                    blurRadius: 10,
                    blurStyle: BlurStyle.inner,
                  ),
                  BoxShadow(
                    color: Color(0xFF2E4A38),
                    offset: Offset(-4, -4),
                    blurRadius: 10,
                    blurStyle: BlurStyle.inner,
                  ),
                ],
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Filled icon when active, outlined when inactive
            Icon(
              isActive ? item.iconActive : item.icon,
              color: isActive ? AppColors.tertiary : AppColors.textSecondary,
              size: isDesktopRail ? 24 : 26,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: AppTextStyles.navLabel.copyWith(
                color: isActive ? AppColors.tertiary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
