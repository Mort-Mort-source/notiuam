import 'package:flutter/material.dart';

class NotiuamColors {
  static const orange = Color(0xFFE85D04);
  static const orangeDark = Color(0xFFB84700);
  static const orangeLight = Color(0xFFF48C06);
  static const charcoal = Color(0xFF2B2B2B);
  static const cream = Color(0xFFFAFAF7);
  static const creamAlt = Color(0xFFF2EFE9);
  static const success = Color(0xFF2A9D8F);
  static const danger = Color(0xFFD62828);
  static const info = Color(0xFF457B9D);
}

class NotiuamTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: NotiuamColors.orange,
        primary: NotiuamColors.orange,
        secondary: NotiuamColors.orangeLight,
        surface: NotiuamColors.cream,
        error: NotiuamColors.danger,
        brightness: Brightness.light,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: NotiuamColors.cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: NotiuamColors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: NotiuamColors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: NotiuamColors.charcoal,
          side: const BorderSide(color: NotiuamColors.orange, width: 1.4),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: NotiuamColors.orange, width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: NotiuamColors.orange.withValues(alpha: 0.12),
        labelStyle: const TextStyle(
            color: NotiuamColors.orangeDark, fontWeight: FontWeight.w600),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: NotiuamColors.orange.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: NotiuamColors.charcoal,
        displayColor: NotiuamColors.charcoal,
      ),
      dividerTheme: DividerThemeData(color: Colors.grey.shade200, thickness: 1),
    );
  }
}