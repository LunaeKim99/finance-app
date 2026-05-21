import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_radius.dart';

class AppTheme {
  AppTheme._();

  // --- Backward-compatible legacy constants (used by old screens) ---
  @Deprecated('Use AppColors.primary instead')
  static const primaryGreen = AppColors.primary;
  @Deprecated('Use AppColors.primaryContainer instead')
  static const lightGreen = AppColors.primaryContainer;
  @Deprecated('Use AppColors.secondaryContainer instead')
  static const lightRed = AppColors.secondaryContainer;
  @Deprecated('Use AppColors.surfaceContainerHighest instead')
  static const cardBorder = AppColors.surfaceContainerHighest;
  @Deprecated('Use AppColors.onSurface instead')
  static const textPrimary = AppColors.onSurface;
  @Deprecated('Use AppColors.onSurfaceVariant instead')
  static const textSecondary = AppColors.onSurfaceVariant;
  @Deprecated('Use Color(0xFF121212)')
  static const Color darkBackground = Color(0xFF121212);
  @Deprecated('Use Color(0xFF1E1E1E)')
  static const Color darkCard = Color(0xFF1E1E1E);
  @Deprecated('Use Color(0xFF2C2C2C)')
  static const Color darkCardBorder = Color(0xFF2C2C2C);
  @Deprecated('Use Color(0xFFE0E0E0)')
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  @Deprecated('Use Color(0xFF9E9E9E)')
  static const Color darkTextSecondary = Color(0xFF9E9E9E);
  @Deprecated('Use AppColors.primaryFixedDim instead')
  static const darkGreen = AppColors.primaryFixedDim;
  @Deprecated('Use AppColors.secondaryFixedDim instead')
  static const darkRed = AppColors.secondaryFixedDim;

  @Deprecated('Use AppRadius.xlRadius instead')
  static const cardRadius = AppRadius.xlRadius;
  @Deprecated('Use AppRadius.mdRadius instead')
  static const buttonRadius = AppRadius.mdRadius;
  @Deprecated('Use AppRadius.fullRadius instead')
  static const pillRadius = AppRadius.fullRadius;

  @Deprecated('Use EdgeInsets.all(AppSpacing.md) instead')
  static const pagePadding = EdgeInsets.all(16.0);
  @Deprecated('Use EdgeInsets.symmetric(horizontal: 12, vertical: 10)')
  static const cardPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 10);

  @Deprecated('Use AppShadows.level1 instead')
  static final cardShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.05),
    blurRadius: 8,
    offset: const Offset(0, 2),
  );

  @Deprecated('Use Theme.of(context).cardTheme.color')
  static Color cardColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E1E1E)
          : AppColors.surfaceContainerLowest;

  @Deprecated('Use AppColors.outlineVariant')
  static Color cardBorderColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2C2C2C)
          : AppColors.surfaceContainerHighest;

  @Deprecated('Use AppColors.primary')
  static Color incomeColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.primaryFixedDim
          : AppColors.primary;

  @Deprecated('Use AppColors.secondary')
  static Color expenseColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.secondaryFixedDim
          : AppColors.secondary;

  @Deprecated('Use AppColors.onSurface')
  static Color textPrimaryColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFE0E0E0)
          : AppColors.onSurface;

  @Deprecated('Use AppColors.onSurfaceVariant')
  static Color textSecondaryColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF9E9E9E)
          : AppColors.onSurfaceVariant;
  // --- end legacy ---

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        inverseSurface: AppColors.inverseSurface,
        inversePrimary: AppColors.inversePrimary,
        surfaceTint: AppColors.surfaceTint,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: AppTypography.textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTypography.headlineSm.copyWith(color: AppColors.onSurface),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.xlRadius,
          side: const BorderSide(color: AppColors.surfaceContainerHighest, width: 0.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.bodySm.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary);
          }
          return AppTypography.bodySm.copyWith(fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant);
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceContainerHighest,
        thickness: 0.5,
        space: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: const BorderSide(color: AppColors.surfaceContainerHighest),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
          textStyle: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
          textStyle: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainer,
        labelStyle: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.fullRadius),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
      ),
      platform: TargetPlatform.android,
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary:              AppColorsDark.primary,
        onPrimary:            AppColorsDark.onPrimary,
        primaryContainer:     AppColorsDark.primaryContainer,
        onPrimaryContainer:   AppColorsDark.onPrimaryContainer,
        secondary:            AppColorsDark.secondary,
        onSecondary:          AppColorsDark.onSecondary,
        secondaryContainer:   AppColorsDark.secondaryContainer,
        onSecondaryContainer: AppColorsDark.onSecondaryContainer,
        tertiary:             AppColorsDark.tertiary,
        onTertiary:           AppColorsDark.onTertiary,
        tertiaryContainer:    AppColorsDark.tertiaryContainer,
        onTertiaryContainer:  AppColorsDark.onTertiaryContainer,
        error:                AppColorsDark.error,
        onError:              AppColorsDark.onError,
        errorContainer:       AppColorsDark.errorContainer,
        onErrorContainer:     AppColorsDark.onErrorContainer,
        surface:              AppColorsDark.surface,
        onSurface:            AppColorsDark.onSurface,
        onSurfaceVariant:     AppColorsDark.onSurfaceVariant,
        outline:              AppColorsDark.outline,
        outlineVariant:       AppColorsDark.outlineVariant,
        inverseSurface:       AppColorsDark.inverseSurface,
        onInverseSurface:     AppColorsDark.inverseOnSurface,
        inversePrimary:       AppColorsDark.inversePrimary,
        surfaceTint:          AppColorsDark.surfaceTint,
      ),
      scaffoldBackgroundColor: AppColorsDark.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColorsDark.surface,
        foregroundColor: AppColorsDark.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTypography.headlineSm.copyWith(color: AppColorsDark.onSurface),
      ),
      cardTheme: CardThemeData(
        color: AppColorsDark.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.xlRadius,
          side: BorderSide(color: AppColorsDark.outlineVariant, width: 0.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColorsDark.surface,
        indicatorColor: AppColorsDark.primary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.bodySm.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColorsDark.primary,
            );
          }
          return AppTypography.bodySm.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColorsDark.onSurfaceVariant,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColorsDark.outlineVariant,
        thickness: 0.5,
        space: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsDark.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: AppColorsDark.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: AppColorsDark.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsDark.primary,
          foregroundColor: AppColorsDark.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
          textStyle: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorsDark.primary,
          side: BorderSide(color: AppColorsDark.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
          textStyle: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColorsDark.surfaceContainer,
        labelStyle: AppTypography.bodySm.copyWith(color: AppColorsDark.onSurfaceVariant),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.fullRadius),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
      ),
      platform: TargetPlatform.android,
    );
  }
}
