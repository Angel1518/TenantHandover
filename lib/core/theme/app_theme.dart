import 'package:flutter/material.dart';

/// Motion helper that respects system reduced-motion preferences.
class AppMotion {
  static Duration duration(BuildContext context, Duration normal) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return disableAnimations ? Duration.zero : normal;
  }

  static Curve curve(BuildContext context, [Curve normal = Curves.easeOutCubic]) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return disableAnimations ? Curves.linear : normal;
  }
}

/// Shared minimalist Material 3 theme builder.
class AppTheme {
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFEEF1F6);
  static const Color lightTextPrimary = Color(0xFF182637);
  static const Color lightTextSecondary = Color(0xFF4B5B6E);
  static const Color lightOutline = Color(0xFFD5DCE6);

  static const Color darkBackground = Color(0xFF0F141A);
  static const Color darkSurface = Color(0xFF171F28);
  static const Color darkSurfaceVariant = Color(0xFF202B38);
  static const Color darkTextPrimary = Color(0xFFEBF1F8);
  static const Color darkTextSecondary = Color(0xFFA7B6C8);
  static const Color darkOutline = Color(0xFF2E3C4E);

  static ThemeData light({required Color accent}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.light,
      primary: accent,
      surface: lightSurface,
      onSurface: lightTextPrimary,
      surfaceContainerHighest: lightSurfaceVariant,
      outline: lightOutline,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBg: lightBackground,
      textPrimary: lightTextPrimary,
      textSecondary: lightTextSecondary,
      cardBorder: lightOutline,
    );
  }

  static ThemeData dark({required Color accent}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
      primary: _lighten(accent, 0.22),
      surface: darkSurface,
      onSurface: darkTextPrimary,
      surfaceContainerHighest: darkSurfaceVariant,
      outline: darkOutline,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBg: darkBackground,
      textPrimary: darkTextPrimary,
      textSecondary: darkTextSecondary,
      cardBorder: darkOutline,
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardBorder,
  }) {
    final baseText = Typography.material2021().black.apply(
          bodyColor: textPrimary,
          displayColor: textPrimary,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      visualDensity: VisualDensity.standard,
      textTheme: baseText.copyWith(
        headlineMedium: baseText.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        titleLarge: baseText.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.25,
          height: 1.25,
        ),
        titleMedium: baseText.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        bodyLarge: baseText.bodyLarge?.copyWith(height: 1.45),
        bodyMedium: baseText.bodyMedium?.copyWith(
          color: textSecondary,
          height: 1.45,
        ),
        labelLarge: baseText.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: baseText.titleLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: cardBorder.withValues(alpha: 0.7)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.14),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }

  static Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 0.92))
        .toColor();
  }
}
