import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF1F78FF),
      onPrimary: Colors.white,
      secondary: const Color(0xFF3FA2FF),
      onSecondary: const Color(0xFF041B3E),
      tertiary: const Color(0xFF78C6FF),
      onTertiary: const Color(0xFF0A1F3A),
      surface: const Color(0xFF050F2A),
      onSurface: const Color(0xFFEAF2FF),
      onSurfaceVariant: const Color(0xFFA5BDE9),
      outline: const Color(0xFF3563B0),
      outlineVariant: const Color(0xFF224888),
      error: const Color(0xFFFF5B6F),
      onError: Colors.white,
    );

    return _buildThemeData(colorScheme, AppColors.darkTokens);
  }

  static ThemeData _buildThemeData(
    ColorScheme colorScheme,
    AppColorTokens tokens,
  ) {
    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      extensions: <ThemeExtension<dynamic>>[tokens],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0D2250),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
        border: _inputBorder(color: colorScheme.outlineVariant),
        enabledBorder: _inputBorder(color: colorScheme.outlineVariant),
        focusedBorder: _inputBorder(color: colorScheme.primary, width: 1.2),
        errorBorder: _inputBorder(color: colorScheme.error),
        focusedErrorBorder: _inputBorder(color: colorScheme.error, width: 1.2),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0F2454),
        contentTextStyle: TextStyle(color: colorScheme.onSurface),
      ),
    );
  }

  static OutlineInputBorder _inputBorder({required Color color, double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
