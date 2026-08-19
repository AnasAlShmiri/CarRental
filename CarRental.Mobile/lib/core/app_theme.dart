import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// سمة التطبيق — نفس الهوية البصرية للوحة التحكم (أزرق #1A73E8 وخلفية فاتحة).
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF1A73E8);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF006E2C);
  static const Color warning = Color(0xFF8A5A00);
  static const Color danger = Color(0xFFBA1A1A);

  static ThemeData light = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: primary,
    brightness: Brightness.light,
    scaffoldBackgroundColor: background,
    fontFamily: GoogleFonts.tajawal().fontFamily,
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      foregroundColor: Color(0xFF111827),
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: const CardThemeData(
      color: surface,
      elevation: 1,
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      indicatorColor: Color(0xFFE8F1FE),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      ),
    ),
  );
}
