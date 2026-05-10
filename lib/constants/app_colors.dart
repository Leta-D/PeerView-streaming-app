import 'package:flutter/material.dart';

/// Peer View design tokens inspired by a modern dark neon aesthetic.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF050505);
  static const Color surface = Color(0xFF121212);
  static const Color surfaceElevated = Color(0xFF1A1A1A);
  static const Color surfaceMuted = Color(0xFF222222);

  static const Color primary = Color(0xFFB24BF3);
  static const Color primarySoft = Color(0xFF7C3AED);
  static const Color primaryGlow = Color(0x66B24BF3);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB7A9C8);
  static const Color textMuted = Color(0xFF7A7188);

  static const Color border = Color(0xFF2A2433);
  static const Color borderAccent = Color(0xFF4A2F66);

  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF87171);
  static const Color info = Color(0xFF60A5FA);

  static const Color iconCircle = Color(0xFF1F1A27);

  // Legacy helpers kept for any older call sites during migration.
  static Color lghtdarkblue(double opacity) => background.withValues(alpha: opacity);
  static Color drkerViolet(double opacity) => surface.withValues(alpha: opacity);
  static Color lightViolrt(double opacity) => primarySoft.withValues(alpha: opacity);
  static Color redish(double opacity) => primary.withValues(alpha: opacity);
  static Color yellowish(double opacity) => textSecondary.withValues(alpha: opacity);
}
