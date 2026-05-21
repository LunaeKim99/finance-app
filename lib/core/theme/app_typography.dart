import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextTheme get textTheme {
    return TextTheme(
      displayLarge: GoogleFonts.hankenGrotesk(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 44 / 36,
        letterSpacing: -0.03,
      ),
      displayMedium: GoogleFonts.hankenGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 34 / 28,
      ),
      displaySmall: GoogleFonts.hankenGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
        letterSpacing: -0.01,
      ),
      headlineLarge: GoogleFonts.hankenGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 40 / 32,
        letterSpacing: -0.02,
      ),
      headlineMedium: GoogleFonts.hankenGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
        letterSpacing: -0.01,
      ),
      headlineSmall: GoogleFonts.hankenGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
      ),
      titleLarge: GoogleFonts.hankenGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 26 / 18,
      ),
      titleMedium: GoogleFonts.hankenGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 24 / 16,
      ),
      titleSmall: GoogleFonts.hankenGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
      ),
      bodyLarge: GoogleFonts.hankenGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 26 / 18,
      ),
      bodyMedium: GoogleFonts.hankenGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
      ),
      bodySmall: GoogleFonts.hankenGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
      ),
      labelLarge: GoogleFonts.jetBrainsMono(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 20 / 14,
        letterSpacing: 0.05,
      ),
      labelMedium: GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        letterSpacing: 0.05,
      ),
      labelSmall: GoogleFonts.jetBrainsMono(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 14 / 10,
        letterSpacing: 0.05,
      ),
    );
  }

  // Named styles matching DESIGN.md
  static TextStyle get currencyDisplay =>
      GoogleFonts.hankenGrotesk(fontSize: 36, fontWeight: FontWeight.w700, height: 44 / 36, letterSpacing: -0.03);
  static TextStyle get headlineLg =>
      GoogleFonts.hankenGrotesk(fontSize: 32, fontWeight: FontWeight.w700, height: 40 / 32, letterSpacing: -0.02);
  static TextStyle get headlineMd =>
      GoogleFonts.hankenGrotesk(fontSize: 24, fontWeight: FontWeight.w600, height: 32 / 24, letterSpacing: -0.01);
  static TextStyle get headlineSm =>
      GoogleFonts.hankenGrotesk(fontSize: 20, fontWeight: FontWeight.w600, height: 28 / 20);
  static TextStyle get bodyLg =>
      GoogleFonts.hankenGrotesk(fontSize: 18, fontWeight: FontWeight.w400, height: 26 / 18);
  static TextStyle get bodyMd =>
      GoogleFonts.hankenGrotesk(fontSize: 16, fontWeight: FontWeight.w400, height: 24 / 16);
  static TextStyle get bodySm =>
      GoogleFonts.hankenGrotesk(fontSize: 14, fontWeight: FontWeight.w400, height: 20 / 14);
  static TextStyle get labelMono =>
      GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w500, height: 16 / 12, letterSpacing: 0.05);
}
