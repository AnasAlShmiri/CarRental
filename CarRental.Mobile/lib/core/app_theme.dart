import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// هوية CarRental الفاخرة: Midnight Navy + Champagne Gold + Ivory.
class AppTheme {
  AppTheme._();

  static const midnight = Color(0xFF09111F);
  static const navy = Color(0xFF111D31);
  static const navySoft = Color(0xFF17243A);
  static const primary = Color(0xFFC69A5B);
  static const primaryLight = Color(0xFFE5C58E);
  static const background = Color(0xFFF7F5F0);
  static const surface = Color(0xFFFFFEFB);
  static const ink = Color(0xFF172033);
  static const muted = Color(0xFF7C8491);
  static const border = Color(0xFFE9E4DA);
  static const success = Color(0xFF3F8F75);
  static const warning = Color(0xFFB37A3E);
  static const danger = Color(0xFFB85C5C);

  static const radiusLarge = 26.0;
  static const radiusMedium = 18.0;

  static ThemeData get light {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    final textTheme = GoogleFonts.tajawalTextTheme(base.textTheme).apply(
      bodyColor: ink,
      displayColor: ink,
    );
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: midnight,
        secondary: primaryLight,
        onSecondary: midnight,
        surface: surface,
        onSurface: ink,
        error: danger,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: const BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFBFAF7),
        labelStyle: const TextStyle(color: muted, fontWeight: FontWeight.w600),
        hintStyle: const TextStyle(color: Color(0xFFA8ADB5)),
        prefixIconColor: muted,
        suffixIconColor: muted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primary, width: 1.4)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: danger)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: midnight,
          foregroundColor: primaryLight,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: midnight,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: midnight,
        indicatorColor: primary,
        elevation: 0,
        height: 76,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(color: states.contains(WidgetState.selected) ? midnight : const Color(0xA8FFFFFF), fontSize: 11, fontWeight: FontWeight.w800)),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(color: states.contains(WidgetState.selected) ? midnight : const Color(0xA8FFFFFF))),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: midnight,
        disabledColor: background,
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        labelStyle: const TextStyle(color: ink, fontSize: 11, fontWeight: FontWeight.w700),
        secondaryLabelStyle: const TextStyle(color: primaryLight, fontSize: 11, fontWeight: FontWeight.w800),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: midnight, foregroundColor: primaryLight, elevation: 4),
      snackBarTheme: SnackBarThemeData(backgroundColor: midnight, contentTextStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), behavior: SnackBarBehavior.floating),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder(), TargetPlatform.iOS: CupertinoPageTransitionsBuilder()}),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: surface, modalBackgroundColor: surface, showDragHandle: true),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
    );
  }

  static const luxuryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [midnight, navy, navySoft],
  );

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary, Color(0xFFA8783E)],
  );
}
