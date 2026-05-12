import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shadows.dart';

/// The three physical depth states every surface can be in.
enum NeumorphicType {
  /// Element pushes toward the user — convex surface.
  raised,

  /// Element is sunken / active — concave / inset surface.
  pressed,

  /// No elevation — sits flush with its parent.
  flat,
}

/// Size variant for the raised shadow.
enum NeumorphicSize {
  /// Standard 5 px — used on cards, buttons, inputs. (default)
  normal,

  /// Large 8 px — used on the splash logo orb only.
  hero,

  /// Tight 3 px — used on badge icon circles, small chips.
  small,
}

/// Core building block for the Emerald Tactile Interface.
///
/// Wrap any widget in this to give it physical depth.
/// The correct background color is automatically chosen based on [type]:
///   - [NeumorphicType.raised] / [NeumorphicType.flat] → surfaceContainerHigh
///   - [NeumorphicType.pressed]                        → surfaceContainerLowest
///
/// Override with [color] when a specific surface tier is needed.
///
/// Usage:
/// ```dart
/// SwiftNeumorphicContainer(
///   type: NeumorphicType.raised,
///   padding: const EdgeInsets.all(20),
///   child: Text('Hello'),
/// )
/// ```
class SwiftNeumorphicContainer extends StatelessWidget {
  final NeumorphicType type;
  final NeumorphicSize size;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? color;

  const SwiftNeumorphicContainer({
    super.key,
    required this.type,
    required this.child,
    this.size = NeumorphicSize.normal,
    this.padding = EdgeInsets.zero,
    this.borderRadius = 16,
    this.color,
  });

  List<BoxShadow> get _shadows {
    switch (type) {
      case NeumorphicType.raised:
        switch (size) {
          case NeumorphicSize.hero:
            return AppShadows.raisedHero;
          case NeumorphicSize.small:
            return AppShadows.raisedSmall;
          case NeumorphicSize.normal:
            return AppShadows.raised;
        }
      case NeumorphicType.pressed:
        return AppShadows.pressed;
      case NeumorphicType.flat:
        return AppShadows.flat;
    }
  }

  Color get _backgroundColor {
    if (color != null) return color!;
    return switch (type) {
      NeumorphicType.pressed => AppColors.surfaceContainerLowest,
      NeumorphicType.raised || NeumorphicType.flat => AppColors.surfaceContainerHigh,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: _shadows,
      ),
      child: child,
    );
  }
}