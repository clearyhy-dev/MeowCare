import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design system constants (cat-friendly, warm).
class AppColors {
  AppColors._();

  static const Color warmOrange = Color(0xFFF4A261);
  static const Color softCream = Color(0xFFFFF8E7);
  static const Color deepTeal = Color(0xFF2A9D8F);
  static const Color mutedRed = Color(0xFFE76F51);

  // Dark theme variants (same hue, adjusted)
  static const Color warmOrangeDark = Color(0xFFE8954A);
  static const Color softCreamDark = Color(0xFF2C2A26);
  static const Color deepTealDark = Color(0xFF3DB5A8);
  static const Color mutedRedDark = Color(0xFFE85A3A);
}

class AppRadius {
  AppRadius._();

  static const double card = 16;
  static const double input = 12;
  static const double button = 12;
}

class AppInsets {
  AppInsets._();

  static const double cardSpacing = 14;
  static const EdgeInsets cardMargin = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  /// Horizontal padding for screen edges (lists, content).
  static const double screenPadding = 20;
  /// Vertical spacing between sections (e.g. section title and list).
  static const double sectionSpacing = 24;
  /// Vertical spacing between list items (e.g. between cards).
  static const double listItemSpacing = 12;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const primary = AppColors.warmOrange;
    const secondary = AppColors.deepTeal;
    const surface = AppColors.softCream;
    const error = AppColors.mutedRed;

    final colorScheme = ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primary.withValues(alpha: 0.2),
      secondary: secondary,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: const Color(0xFF1C1917),
      surfaceContainerLow: const Color(0xFFFBF6ED),
      surfaceContainerHighest: const Color(0xFFF5F0E8),
      error: error,
      onError: Colors.white,
      outline: const Color(0xFF78716C),
    );

    final textTheme = GoogleFonts.interTextTheme(
      ThemeData.light().textTheme.copyWith(
            headlineSmall: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600),
            titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
            titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
            bodyLarge: GoogleFonts.inter(fontSize: 16),
            bodyMedium: GoogleFonts.inter(fontSize: 14),
            labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
          ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        margin: AppInsets.cardMargin,
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        elevation: 2,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600);
          }
          return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: Color(0xFFE7E2D9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.deepTeal, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondary,
          side: const BorderSide(color: secondary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
        ),
      ),
      scaffoldBackgroundColor: surface,
    );
  }

  static ThemeData get dark {

    const primary = AppColors.warmOrangeDark;
    const secondary = AppColors.deepTealDark;
    const surface = AppColors.softCreamDark;
    const error = AppColors.mutedRedDark;

    final colorScheme = ColorScheme.dark(
      primary: primary,
      onPrimary: Colors.black87,
      primaryContainer: primary.withValues(alpha: 0.3),
      secondary: secondary,
      onSecondary: Colors.black87,
      surface: surface,
      onSurface: const Color(0xFFF5F0E8),
      surfaceContainerLow: const Color(0xFF35322E),
      surfaceContainerHighest: const Color(0xFF3D3A36),
      error: error,
      onError: Colors.white,
      outline: const Color(0xFFA8A29E),
    );

    final textTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme.copyWith(
            headlineSmall: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600),
            titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
            titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
            bodyLarge: GoogleFonts.inter(fontSize: 16),
            bodyMedium: GoogleFonts.inter(fontSize: 14),
            labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
          ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHighest,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        margin: AppInsets.cardMargin,
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        elevation: 2,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600);
          }
          return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.deepTealDark, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondary,
          side: const BorderSide(color: secondary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
        ),
      ),
      scaffoldBackgroundColor: surface,
    );
  }
}

