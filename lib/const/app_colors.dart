import 'package:flutter/material.dart';

class AppColors {
  // This class is not meant to be instantiated or extended.
  AppColors._();

  // --- Brand / Primary Colors (Ergonomic Blue & Slate) ---
  // Replaced all orange tones with a calm, deep corporate indigo/blue
  // and a soothing slate blue-gray. Very friendly for 8-hour shifts.
  static const Color primary = Color.fromARGB(255, 46, 47, 48); // Soft Tech Blue (Highly readable, zero eye strain)
  static const Color primaryLight = Color(
    0xFFEFF6FF,
  ); // Clean, airy ice-blue tint
  static const Color primaryDark = Color.fromARGB(255, 8, 21, 56);

  // --- Neutral & Grays Scale (Anti-Glare Palette) ---
  static const Color textMain = Color(
    0xFF1E293B,
  ); // Deep charcoal slate (much softer than pure black)
  static const Color textSecondary = Color(
    0xFF64748B,
  ); // Muted slate gray for secondary labels
  static const Color border = Color(0xFFE2E8F0); // Subtle dividing lines
  static const Color background = Color(
    0xFFF8FAFC,
  ); // Clean slate background to reduce screen glare
  static const Color white = Color(
    0xFFFFFFFF,
  ); // Card surfaces and input fields
  static const Color black = Color(0xFF0F172A);

  // --- Semantic State Colors (Subdued & Calming Alert Profile) ---

  // Success (Sage Emerald)
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);

  // Danger / Error (Soft Crimson)
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFEE2E2);

  // Warning (Muted Amber / Ochre Gold)
  // Replaced warning orange with a deep, safe mustard gold that signals warning without looking orange
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);

  // Info (Calming Teal)
  static const Color info = Color(0xFF06B6D4);
  static const Color infoLight = Color(0xFFCFFAFE);

  // --- Extended Palette (Balanced Accent Track) ---
  static const Color purple = Color(0xFF6366F1); // Soft Indigo
  static const Color purpleLight = Color(0xFFE0E7FF);

  static const Color darkBlue = Color(0xFF475569); // Steel Blue-Gray
  static const Color lightBlue = Color(0xFF38BDF8); // Refreshing Sky Blue
}
