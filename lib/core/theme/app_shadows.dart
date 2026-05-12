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
  static const Color _dark = AppColors.shadowDark;
  static const Color _light = Color(
    0x663B5E47,
  ); // Softer, semi-transparent highlight

  // ─────────────────────────────────────────────────────────────
  // RAISED — standard
  // Used on: cards, buttons, social chips, thumbnails, feature rows
  // ─────────────────────────────────────────────────────────────
  static const List<BoxShadow> raised = [
    BoxShadow(
      color: _dark,
      offset: Offset(8, 8),
      blurRadius: 20, // Increased blur for a softer lift
      spreadRadius: 1, // Slight spread to ground it
    ),
    BoxShadow(
      color: _light,
      offset: Offset(-4, -4), // Tighter offset on the top-left highlight
      blurRadius: 16,
    ),
  ];

  // ─────────────────────────────────────────────────────────────
  // RAISED HERO — large
  // Used on: splash screen logo orb only
  // ─────────────────────────────────────────────────────────────
  static const List<BoxShadow> raisedHero = [
    BoxShadow(
      color: _dark,
      offset: Offset(12, 12),
      blurRadius: 24,
      spreadRadius: 2,
    ),
    BoxShadow(color: _light, offset: Offset(-8, -8), blurRadius: 20),
  ];

  // ─────────────────────────────────────────────────────────────
  // RAISED SMALL — tight
  // Used on: badge icon circles, small chips
  // ─────────────────────────────────────────────────────────────
  static const List<BoxShadow> raisedSmall = [
    BoxShadow(color: _dark, offset: Offset(4, 4), blurRadius: 10),
    BoxShadow(color: _light, offset: Offset(-2, -2), blurRadius: 8),
  ];

  // ─────────────────────────────────────────────────────────────
  // PRESSED — inset
  // Used on: active/selected states, form input fields,
  //          active nav item, selected size buttons, spec cards
  // ─────────────────────────────────────────────────────────────
  static const List<BoxShadow> pressed = [
    BoxShadow(
      color: _dark,
      offset: Offset(4, 4),
      blurRadius: 8,
      blurStyle: BlurStyle.inner,
    ),
    BoxShadow(
      // Using a darker inner highlight so it actually looks sunken
      color: Color(0x33000000),
      offset: Offset(-4, -4),
      blurRadius: 8,
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
