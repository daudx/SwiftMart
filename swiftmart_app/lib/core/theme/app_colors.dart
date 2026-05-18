import 'package:flutter/material.dart';

class AppColors {
  // ── Primary Palette ────────────────────────────────────────────
  static const primary          = Color(0xFF6DDBA9); // The vibrant core
  static const primaryContainer = Color(0xFF2EA375); // Muted primary

  // ── Secondary & Tertiary ───────────────────────────────────────
  static const secondary        = Color(0xFF8FD6A9); // Functional support
  static const tertiary         = Color(0xFF00E29C); // The "Glow" accent

  // ── Background ────────────────────────────────────────────────
  static const background       = Color(0xFF071611); // The deep abyss

  // ── Surface Tiers (light → dark = raised → recessed) ──────────
  static const surfaceBright          = Color(0xFF2D3C36); // Hover state
  static const surfaceContainerHigh   = Color(0xFF1E2D27); // Raised elements
  static const surfaceContainer       = Color(0xFF14231D); // Neutral container
  static const surfaceContainerLow    = Color(0xFF101E19); // Input backgrounds
  static const surfaceContainerLowest = Color(0xFF03110C); // Deepest recess

  // ── Shortcuts used across widgets ────────────────────────────
  // (kept for backward compatibility with existing code)
  static const surfaceHigh    = surfaceContainerHigh;
  static const surfaceLowest  = surfaceContainerLowest;

  // ── On-Surface Text ───────────────────────────────────────────
  static const onSurface        = Color(0xFFD5E7DD); // Primary readable text
  static const onSurfaceVariant = Color(0xFFBDCAC0); // Secondary/label text
  static const textMain         = Color(0xFFE1F5EE); // Hero text (never pure white)
  static const textSecondary    = Color(0xFFBDCACA); // Body / supporting text

  // ── On-Primary ────────────────────────────────────────────────
  static const onPrimary          = Color(0xFF003824);
  static const onPrimaryContainer = Color(0xFF00311F); // Dark text on green header
  static const onPrimaryFixed     = Color(0xFF002114);
  static const onPrimaryFixedVariant = Color(0xFF005236); // Subtitle on green

  // ── Borders & Outlines ────────────────────────────────────────
  static const outlineVariant = Color(0xFF3E4942); // Ghost border (use at 15% opacity)
  static const outline        = Color(0xFF87948B); // Standard outline

  // ── Semantic / Status ─────────────────────────────────────────
  static const error          = Color(0xFFFFB4AB); // Error / alert orb

  // ── Shadow ────────────────────────────────────────────────────
  static const shadowDark     = Color(0xFF0A1610); // Dark shadow anchor

  // ── CTA Gradient stops ────────────────────────────────────────
  static const ctaGradientStart = Color(0xFF04E8A0);
  static const ctaGradientEnd   = Color(0xFF048E62);

  // ── Feature Badge Colours ────────────────────────────────────
  static const badgeSecure = Color(0xFF04E8A0); // verified_user icon
  static const badgeFast   = Color(0xFFFFB000); // bolt icon
  static const badgeSmart  = Color(0xFFB066FF); // psychology icon
}