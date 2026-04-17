import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0F1115);
  static const surface = Color(0xFF161A23);
  static const surfaceAlt = Color(0xFF1A1F2B);
  static const border = Color(0xFF2A3140);
  static const borderSoft = Color(0xFF242B38);

  static const primary = Color(0xFF16A34A);

  static const success = Color(0xFF22C55E);
  static const danger = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF94A3B8);

  static const textPrimary = Colors.white;
  static const textSecondary = Colors.white70;
  static const textDangerSoft = Color(0xFFFCA5A5);
}

class AppRadius {
  static const double sm = 12;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 20;
  static const double pill = 999;
}

class AppSpacing {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 14;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
}

class AppStyles {
  static RoundedRectangleBorder cardShape({
    double radius = AppRadius.xl,
    Color borderColor = AppColors.borderSoft,
  }) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor),
    );
  }

  static OutlineInputBorder inputBorder({
    Color borderColor = AppColors.border,
    double radius = AppRadius.md,
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(
        color: borderColor,
        width: width,
      ),
    );
  }
}