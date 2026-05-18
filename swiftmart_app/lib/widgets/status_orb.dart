import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class StatusOrb extends StatelessWidget {
  final bool isActive;

  const StatusOrb({super.key, this.isActive = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.tertiary : Colors.red,
        shape: BoxShape.circle,
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: AppColors.tertiary.withValues(alpha: 0.6),
              blurRadius: 6,
            ),
        ],
      ),
    );
  }
}