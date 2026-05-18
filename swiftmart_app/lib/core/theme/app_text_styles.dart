import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // ── Display / Hero ────────────────────────────────────────────
  // Used for "SwiftMart" hero title on splash
  static const display = TextStyle(
    fontFamily: 'Inter',
    fontSize: 56,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.12, // -0.02em at 56px
    color: AppColors.textMain,
  );

  // ── Headline ─────────────────────────────────────────────────
  // Used for screen-level section headings (28px / headline-md = 1.75rem)
  static const headline = TextStyle(
    fontFamily: 'Inter',
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.56,
    color: AppColors.textMain,
  );

  // ── Title ─────────────────────────────────────────────────────
  // Used for card-level titles, product names
  static const title = TextStyle(
    fontFamily: 'Inter',
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textMain,
  );

  // ── Body ──────────────────────────────────────────────────────
  // Standard reading text (body-md = 0.875rem ≈ 14px)
  static const body = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
    height: 1.5,
  );

  // ── Body Medium ───────────────────────────────────────────────
  // Slightly larger body for descriptions
  static const bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
    height: 1.5,
  );

  // ── Label ─────────────────────────────────────────────────────
  // Always UPPERCASE + tracked — used as "technical metadata"
  // (label-md = 0.75rem = 12px, +0.05em spacing)
  static const label = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,  // ~0.1em at 12px
    color: AppColors.onSurfaceVariant,
  );

  // ── Label Small ───────────────────────────────────────────────
  // For the smallest tracking text (10px / badge labels / nav items)
  static const labelSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 2.0,
    color: AppColors.onSurfaceVariant,
  );

  // ── Input Hint ────────────────────────────────────────────────
  static const inputHint = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    color: AppColors.outlineVariant,
    fontWeight: FontWeight.w500,
  );

  // ── Input Value ───────────────────────────────────────────────
  static const inputValue = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    color: AppColors.onSurface,
    fontWeight: FontWeight.w500,
  );

  // ── CTA Button ───────────────────────────────────────────────
  static const ctaButton = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w900,
    color: Color(0xFF04342C), // Dark forest text on gradient
    letterSpacing: -0.3,
  );

  // ── Nav Item Label ────────────────────────────────────────────
  static const navLabel = TextStyle(
    fontFamily: 'Inter',
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.5,
  );
}