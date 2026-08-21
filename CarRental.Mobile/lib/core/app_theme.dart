import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// هوية CarRental الموحدة مع لوحة MVC: أزرق عملي، أسطح بيضاء، وخلفية رمادية هادئة.
class AppTheme {
  AppTheme._();

  // MVC design tokens from CarRental.Web/wwwroot/css/site.css.
  static const primary = Color(0xFF1A73E8);
  static const primaryHover = Color(0xFF005BBF);
  static const primaryMuted = Color(0xFFE8F1FE);
  static const primaryLight = primaryMuted;
  static const midnight = Color(0xFF111827);
  static const navy = Color(0xFF374151);
  static const navySoft = Color(0xFF6B7280);
  static const background = Color(0xFFF5F7FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSubtle = Color(0xFFF9FAFB);
  static const ink = Color(0xFF111827);
  static const body = Color(0xFF374151);
  static const muted = Color(0xFF6B7280);
  static const border = Color(0xFFE5E7EB);
  static const borderStrong = Color(0xFFD7DCE4);
  static const success = Color(0xFF00722F);
  static const successSoft = Color(0xFFEAF7EF);
  static const warning = Color(0xFF8A5A00);
  static const warningSoft = Color(0xFFFEF3C7);
  static const danger = Color(0xFFBA1A1A);
  static const dangerSoft = Color(0xFFFEE2E2);

  static const radiusSmall = 8.0;
  static const radiusMedium = 12.0;
  static const radiusLarge = 16.0;

  static ThemeData get light {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    final textTheme = GoogleFonts.tajawalTextTheme(
      base.textTheme,
    ).apply(bodyColor: body, displayColor: ink);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        secondary: primaryHover,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: ink,
        error: danger,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
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
        fillColor: surfaceSubtle,
        labelStyle: const TextStyle(color: body, fontWeight: FontWeight.w700),
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        prefixIconColor: muted,
        suffixIconColor: muted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: danger, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 46),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(double.infinity, 44),
          side: const BorderSide(color: borderStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primaryMuted,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? primary : muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? primary : muted,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primaryMuted,
        disabledColor: background,
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: const TextStyle(
          color: body,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: const TextStyle(
          color: primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        showDragHandle: true,
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
    );
  }

  // Compatibility gradients now use the MVC blue system rather than the old gold/navy theme.
  static const luxuryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryHover],
  );
  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryMuted, Color(0xFFBFD6F7)],
  );
}
