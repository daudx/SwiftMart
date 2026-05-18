import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Shadow system for SwiftMart's Emerald Tactile Interface.
///
/// Three physical states:
///   [raised]   → element pushes toward the user  (convex)
///   [pressed]  → element is sunken / active       (concave / inset)
///   [flat]     → no elevation                    (zero depth)
///
/// Two raised size variants:
///   [raised]      → standard  (5px) — used on cards, buttons, inputs
///   [raisedHero]  → large     (8px) — used on splash logo orb only
///   [raisedSmall] → tight     (3px) — used on badge icons, small chips
class AppShadows {
  // ── Dark anchor: the "ground shadow" ─────────────────────────
  // Simulates light coming from the top-left corner.
  // shadowDark (#0a1610) pools at the bottom-right.
  static const Color _dark  = AppColors.shadowDark;         // #0A1610
  static const Color _light = Color(0xFF2E4A38);            // top-left highlight

  // ─────────────────────────────────────────────────────────────
  // RAISED — standard (5 px)
  // Used on: cards, buttons, social chips, thumbnails, feature rows
  // ─────────────────────────────────────────────────────────────
  static const List<BoxShadow> raised = [
    BoxShadow(
      color: _dark,
      offset: Offset(5, 5),
      blurRadius: 12,
    ),
    BoxShadow(
      color: _light,
      offset: Offset(-5, -5),
      blurRadius: 12,
    ),
  ];

  // ─────────────────────────────────────────────────────────────
  // RAISED HERO — large (8 px)
  // Used on: splash screen logo orb only
  // ─────────────────────────────────────────────────────────────
  static const List<BoxShadow> raisedHero = [
    BoxShadow(
      color: _dark,
      offset: Offset(8, 8),
      blurRadius: 16,
    ),
    BoxShadow(
      color: _light,
      offset: Offset(-8, -8),
      blurRadius: 16,
    ),
  ];

  // ─────────────────────────────────────────────────────────────
  // RAISED SMALL — tight (3 px)
  // Used on: badge icon circles, small chips
  // ─────────────────────────────────────────────────────────────
  static const List<BoxShadow> raisedSmall = [
    BoxShadow(
      color: _dark,
      offset: Offset(3, 3),
      blurRadius: 8,
    ),
    BoxShadow(
      color: _light,
      offset: Offset(-3, -3),
      blurRadius: 8,
    ),
  ];

  // ─────────────────────────────────────────────────────────────
  // PRESSED — inset (4 px)
  // Used on: active/selected states, form input fields,
  //          active nav item, selected size buttons, spec cards
  // ─────────────────────────────────────────────────────────────
  static const List<BoxShadow> pressed = [
    BoxShadow(
      color: _dark,
      offset: Offset(4, 4),
      blurRadius: 10,
      blurStyle: BlurStyle.inner,
    ),
    BoxShadow(
      color: _light,
      offset: Offset(-4, -4),
      blurRadius: 10,
      blurStyle: BlurStyle.inner,
    ),
  ];

  // ─────────────────────────────────────────────────────────────
  // AMBIENT — diffused floating (for tooltips / overlays)
  // ─────────────────────────────────────────────────────────────
  static const List<BoxShadow> ambient = [
    BoxShadow(
      color: Color(0x80000000), // 50% black
      offset: Offset(0, 10),
      blurRadius: 30,
    ),
  ];

  // ─────────────────────────────────────────────────────────────
  // PROGRESS GLOW — teal glow on gradient fill bar
  // Used on: splash screen progress bar fill
  // ─────────────────────────────────────────────────────────────
  static const List<BoxShadow> progressGlow = [
    BoxShadow(
      color: Color(0x4D04E8A0), // rgba(4,232,160,0.30)
      offset: Offset(0, 0),
      blurRadius: 12,
    ),
  ];

  // ─────────────────────────────────────────────────────────────
  // GLOW — tertiary color bloom (for status orbs, icons)
  // ─────────────────────────────────────────────────────────────
  static List<BoxShadow> glow({
    Color color = AppColors.tertiary,
    double blurRadius = 8,
    double opacity = 0.6,
  }) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        offset: Offset.zero,
        blurRadius: blurRadius,
      ),
    ];
  }

  // ─────────────────────────────────────────────────────────────
  // FLAT — zero shadow (inactive nav items, neutral state)
  // ─────────────────────────────────────────────────────────────
  static const List<BoxShadow> flat = [];
}