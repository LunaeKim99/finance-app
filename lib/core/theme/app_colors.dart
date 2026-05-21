import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const background = Color(0xFFF8FAFC);

  // Surface
  static const surface = Color(0xFFF9F9FC);
  static const surfaceDim = Color(0xFFDADADC);
  static const surfaceBright = Color(0xFFF9F9FC);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF3F3F6);
  static const surfaceContainer = Color(0xFFEEEFF0);
  static const surfaceContainerHigh = Color(0xFFE8E8EA);
  static const surfaceContainerHighest = Color(0xFFE2E2E5);

  // On-Surface
  static const onSurface = Color(0xFF1A1C1E);
  static const onSurfaceVariant = Color(0xFF3F4940);
  static const inverseSurface = Color(0xFF2F3133);
  static const inverseOnSurface = Color(0xFFF0F0F3);

  // Outline
  static const outline = Color(0xFF6F7A6F);
  static const outlineVariant = Color(0xFFBECABD);

  // Primary (Growth Green)
  static const primary = Color(0xFF006A36);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF1D854A);
  static const onPrimaryContainer = Color(0xFFF6FFF4);
  static const inversePrimary = Color(0xFF79DB95);
  static const primaryFixed = Color(0xFF95F7B0);
  static const primaryFixedDim = Color(0xFF79DB95);
  static const onPrimaryFixed = Color(0xFF00210D);
  static const onPrimaryFixedVariant = Color(0xFF005229);

  // Secondary (Coral Rose for expenses)
  static const secondary = Color(0xFFAD3135);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFFD6C6B);
  static const onSecondaryContainer = Color(0xFF6D0010);
  static const secondaryFixed = Color(0xFFFFDAD8);
  static const secondaryFixedDim = Color(0xFFFFB3B0);
  static const onSecondaryFixed = Color(0xFF410006);
  static const onSecondaryFixedVariant = Color(0xFF8B1720);

  // Tertiary (Warm Gold)
  static const tertiary = Color(0xFF765700);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFF956E00);
  static const onTertiaryContainer = Color(0xFFFFFBFF);
  static const tertiaryFixed = Color(0xFFFFDF9F);
  static const tertiaryFixedDim = Color(0xFFF9BD22);
  static const onTertiaryFixed = Color(0xFF261A00);
  static const onTertiaryFixedVariant = Color(0xFF5C4300);

  // Error
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  // Surface tint
  static const surfaceTint = Color(0xFF006D38);
  static const surfaceVariant = Color(0xFFE2E2E5);
  static const onBackground = Color(0xFF1A1C1E);

  // Premium gradient colors
  static const premiumGradientStart = Color(0xFF004523);
  static const premiumGradientMid = Color(0xFF006A36);
  static const premiumGradientEnd = Color(0xFF1D854A);
}

class AppColorsDark {
  AppColorsDark._();

  // Background & Surface (dark)
  static const background             = Color(0xFF0F1110);
  static const surface                = Color(0xFF1A1C1B);
  static const surfaceDim             = Color(0xFF111312);
  static const surfaceBright          = Color(0xFF363A37);
  static const surfaceContainerLowest = Color(0xFF0A0D0B);
  static const surfaceContainerLow    = Color(0xFF181D19);
  static const surfaceContainer       = Color(0xFF1C2120);
  static const surfaceContainerHigh   = Color(0xFF262B27);
  static const surfaceContainerHighest= Color(0xFF303530);

  // On-Surface (dark)
  static const onSurface              = Color(0xFFE1E3E0);
  static const onSurfaceVariant       = Color(0xFFC1CABC);
  static const inverseSurface         = Color(0xFFE1E3E0);
  static const inverseOnSurface       = Color(0xFF2F3133);

  // Outline (dark)
  static const outline                = Color(0xFF8B9488);
  static const outlineVariant         = Color(0xFF3E4A3D);

  // Primary — Growth Green (dark)
  static const primary                = Color(0xFF79DB95);
  static const onPrimary              = Color(0xFF003919);
  static const primaryContainer       = Color(0xFF005229);
  static const onPrimaryContainer     = Color(0xFF95F7B0);
  static const inversePrimary         = Color(0xFF006A36);

  // Secondary — Coral Rose (dark)
  static const secondary              = Color(0xFFFFB3B0);
  static const onSecondary            = Color(0xFF68000F);
  static const secondaryContainer     = Color(0xFF8B1720);
  static const onSecondaryContainer   = Color(0xFFFFDAD8);

  // Tertiary — Warm Gold (dark)
  static const tertiary               = Color(0xFFF9BD22);
  static const onTertiary             = Color(0xFF3F2D00);
  static const tertiaryContainer      = Color(0xFF5C4300);
  static const onTertiaryContainer    = Color(0xFFFFDF9F);

  // Error (dark)
  static const error                  = Color(0xFFFFB4AB);
  static const onError                = Color(0xFF690005);
  static const errorContainer         = Color(0xFF93000A);
  static const onErrorContainer       = Color(0xFFFFDAD6);

  // Misc
  static const surfaceTint            = Color(0xFF79DB95);
  static const surfaceVariant         = Color(0xFF3E4A3D);
  static const onBackground           = Color(0xFFE1E3E0);

  // Premium gradient (dark — slightly lighter green)
  static const premiumGradientStart   = Color(0xFF003919);
  static const premiumGradientMid     = Color(0xFF005229);
  static const premiumGradientEnd     = Color(0xFF006A36);
}
