/// Tspace Design System — Theme & Visual Tokens
///
/// Implements the dark-first glassmorphic design system specified in the
/// Mobile UX Design Specification. All color, typography, and shape tokens
/// are centralized here to enforce visual consistency.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralised color palette derived from the UX design tokens.
abstract final class AppColors {
  // ─── Canvas & Surface ───────────────────────────────────────────────
  static const Color canvasDark = Color(0xFF0B0F19);
  static const Color cardDark = Color(0xFF141C2F);
  static const Color cardDarkTranslucent = Color(0xB3141C2F); // 70% opacity
  static const Color borderSubtle = Color(0x14FFFFFF); // 8% white

  // ─── Brand Accents ──────────────────────────────────────────────────
  static const Color accent = Color(0xFF6366F1); // Electric Indigo
  static const Color accentGlow = Color(0x266366F1); // 15% opacity
  static const Color success = Color(0xFF10B981); // Emerald Neon
  static const Color warning = Color(0xFFF59E0B); // Sunset Amber
  static const Color error = Color(0xFFEF4444);

  // ─── Text ───────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textMuted = Color(0xFF64748B); // Slate 500
}

/// Reusable border radius presets.
abstract final class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 999.0;
}

/// Standard spacing & padding scale.
abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Glassmorphic card decoration used throughout the app.
class GlassDecoration {
  GlassDecoration._();

  static BoxDecoration card({
    Color? borderColor,
    double borderRadius = AppRadius.lg,
  }) {
    return BoxDecoration(
      color: AppColors.cardDarkTranslucent,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? AppColors.borderSubtle,
        width: 1.0,
      ),
    );
  }

  /// Highlighted card with accent glow (used for selected states).
  static BoxDecoration cardSelected({
    double borderRadius = AppRadius.lg,
  }) {
    return BoxDecoration(
      color: AppColors.cardDarkTranslucent,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: AppColors.accent,
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.accentGlow,
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    );
  }
}

/// The dark-first Material [ThemeData] for the entire application.
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    ).copyWith(
      // Outfit for display/heading text
      displayLarge: GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleLarge: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      // Inter for body & label text
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.canvasDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.success,
        surface: AppColors.cardDark,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvasDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardDark,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
      ),
    );
  }
}
