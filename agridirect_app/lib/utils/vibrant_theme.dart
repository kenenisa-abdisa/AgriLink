import 'package:flutter/material.dart';

class VibrantTheme {
  // Colors
  static const Color primaryGreen = Color(0xFF1B6B3A);
  static const Color secondaryGreen = Color(0xFF2D8B4E);
  static const Color accentYellow = Color(0xFFFFD700);
  static const Color freshLime = Color(0xFF99CC33);
  static const Color softBackground = Color(0xFFF4F7F5);
  static const Color surfaceWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGrey = Color(0xFF757575);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGreen, secondaryGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient vibrantGradient = LinearGradient(
    colors: [primaryGreen, freshLime],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Shadows
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];

  static List<BoxShadow> vibrantShadow = [
    BoxShadow(
      color: primaryGreen.withValues(alpha: 0.2),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // Decorations
  static BoxDecoration glassDecoration = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.8),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
    boxShadow: softShadow,
  );

  static BoxDecoration cardDecoration = BoxDecoration(
    color: surfaceWhite,
    borderRadius: BorderRadius.circular(16),
    boxShadow: softShadow,
  );
}
