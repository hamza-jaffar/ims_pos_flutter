import 'package:flutter/material.dart';

class AppColors {
  // This class is not meant to be instantiated or extended.
  AppColors._();

  // --- Brand / Primary Colors ---
  static const Color primary = Color(0xFFFF9F43); // Main Orange
  static const Color primaryLight = Color(0xFFFFF4E8);
  static const Color primaryDark = Color(0xFFE68A2E);

  // --- Neutral & Grays Scale ---
  static const Color textMain = Color(
    0xFF1B2559,
  ); // Dark blue-gray for main headings
  static const Color textSecondary = Color(
    0xFF687588,
  ); // Muted gray for body text
  static const Color border = Color(
    0xFFE2E8F0,
  ); // Light gray for dividers/borders
  static const Color background = Color(0xFFF8FAFC); // Main app background
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // --- Semantic State Colors ---

  // Success (Green)
  static const Color success = Color(0xFF28C76F);
  static const Color successLight = Color(0xFFEAFAF1);

  // Danger / Error (Red)
  static const Color danger = Color(0xFFEA5455);
  static const Color dangerLight = Color(0xFFFCEAEA);

  // Warning (Yellow/Gold)
  static const Color warning = Color(0xFFFF9F43);
  static const Color warningLight = Color(0xFFFFF5EC);

  // Info (Blue)
  static const Color info = Color(0xFF00CFE8);
  static const Color infoLight = Color(0xFFE6FAFC);

  // --- Extended Palette (As featured in DreamsPOS design) ---
  static const Color purple = Color(0xFF7367F0);
  static const Color purpleLight = Color(0xFFEEEFFD);

  static const Color darkBlue = Color(0xFF4B566A);
  static const Color lightBlue = Color(0xFF56CCF2);
}
