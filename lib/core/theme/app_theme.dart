import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;

import 'app_colors.dart';
import 'app_radii.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Backward compatibility wrappers (existing imports use these names).
class AppRadius {
  AppRadius._();
  static const double card = AppRadii.md;
  static const double input = AppRadii.md;
  static const double button = AppRadii.sm;
}

class AppInsets {
  AppInsets._();
  static const double cardSpacing = AppSpacing.md;
  static const EdgeInsets cardMargin = EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm);
  static const double screenPadding = AppSpacing.xl;
  static const double sectionSpacing = AppSpacing.xxl;
  static const double listItemSpacing = AppSpacing.md;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const primary = AppColors.brand;
    const secondary = AppColors.accent;
    const surface = AppColors.bg;
    const error = AppColors.error;

    final colorScheme = ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFFBE7D3),
      secondary: secondary,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerLow: AppColors.surface,
      surfaceContainerHighest: AppColors.surfaceAlt,
      error: error,
      onError: Colors.white,
      outline: AppColors.stroke,
    );

    final textTheme = AppTextStyles.build(ThemeData.light().textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1.5,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: BorderSide(color: AppColors.stroke.withValues(alpha: 0.45)),
        ),
        margin: AppInsets.cardMargin,
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.stroke.withValues(alpha: 0.55),
        thickness: 0.8,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: AppColors.surface,
        shadowColor: Colors.black12,
        indicatorColor: const Color(0xFFF7DFC8),
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700);
          }
          return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500);
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 2,
        shape: StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.brandStrong, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondary,
          side: BorderSide(color: secondary.withValues(alpha: 0.5)),
          minimumSize: const Size.fromHeight(46),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
        side: BorderSide(color: AppColors.stroke.withValues(alpha: 0.7)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      scaffoldBackgroundColor: surface,
    );
  }

  static ThemeData get dark {
    const primary = AppColors.brandStrong;
    const secondary = AppColors.accent;
    const surface = AppColors.darkBg;
    const error = AppColors.error;

    final colorScheme = ColorScheme.dark(
      primary: primary,
      onPrimary: Colors.black87,
      primaryContainer: const Color(0xFF62452E),
      secondary: secondary,
      onSecondary: Colors.black87,
      surface: surface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerLow: AppColors.darkSurface,
      surfaceContainerHighest: AppColors.darkSurfaceAlt,
      error: error,
      onError: Colors.white,
      outline: AppColors.darkStroke,
    );

    final textTheme = AppTextStyles.build(ThemeData.dark().textTheme).apply(
      bodyColor: AppColors.darkTextPrimary,
      displayColor: AppColors.darkTextPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.24)),
        ),
        margin: AppInsets.cardMargin,
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withValues(alpha: 0.35),
        thickness: 0.8,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
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
          borderSide: const BorderSide(color: AppColors.brandStrong, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black87,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondary,
          side: const BorderSide(color: secondary),
          minimumSize: const Size.fromHeight(46),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
      ),
      scaffoldBackgroundColor: surface,
    );
  }
}

