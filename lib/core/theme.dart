import 'package:flutter/material.dart';

class Palette {
  final bool isLight;
  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceHigh;
  final Color border;
  final Color borderSoft;
  final Color accent;
  final Color accentDeep;
  final Color accentSoft;
  final Color accentDim;
  final Color textPrimary;
  final Color textSecondary;
  final Color textFaint;
  final Color success;
  final Color warning;
  final Color danger;
  final List<Color> aiGrad;

  const Palette({
    required this.isLight,
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceHigh,
    required this.border,
    required this.borderSoft,
    required this.accent,
    required this.accentDeep,
    required this.accentSoft,
    required this.accentDim,
    required this.textPrimary,
    required this.textSecondary,
    required this.textFaint,
    required this.success,
    required this.warning,
    required this.danger,
    required this.aiGrad,
  });
}

const Map<String, Palette> palettes = {
  'light': Palette(
    isLight: true,
    bg: Color(0xFFF6F7FB),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF1F3FA),
    surfaceHigh: Color(0xFFE7EAF5),
    border: Color(0xFFDFE3EF),
    borderSoft: Color(0xFFE9ECF4),
    accent: Color(0xFF7C5CFC),
    accentDeep: Color(0xFF5B34E8),
    accentSoft: Color(0xFF6D4DF2),
    accentDim: Color(0x1A7C5CFC),
    textPrimary: Color(0xFF171B26),
    textSecondary: Color(0xFF5A6478),
    textFaint: Color(0xFF9AA3B8),
    success: Color(0xFF16A34A),
    warning: Color(0xFFD97706),
    danger: Color(0xFFDC2626),
    aiGrad: [Color(0xFF8B5CF6), Color(0xFF6236E8)],
  ),
  'dark': Palette(
    isLight: false,
    bg: Color(0xFF050505),
    surface: Color(0xFF111111),
    surfaceAlt: Color(0xFF1A1A1A),
    surfaceHigh: Color(0xFF242424),
    border: Color(0xFF2E2E2E),
    borderSoft: Color(0xFF1E1E1E),
    accent: Color(0xFF7C5CFC),
    accentDeep: Color(0xFF5B34E8),
    accentSoft: Color(0xFF9F7BFF),
    accentDim: Color(0x337C5CFC),
    textPrimary: Color(0xFFF5F5F5),
    textSecondary: Color(0xFFA0A0A8),
    textFaint: Color(0xFF5F5F66),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    aiGrad: [Color(0xFF6D3BF5), Color(0xFF4C2BC4)],
  ),
  'midnight': Palette(
    isLight: false,
    bg: Color(0xFF04060C),
    surface: Color(0xFF0B0F1A),
    surfaceAlt: Color(0xFF121724),
    surfaceHigh: Color(0xFF19202F),
    border: Color(0xFF1C2434),
    borderSoft: Color(0xFF141A28),
    accent: Color(0xFF8B5CF6),
    accentDeep: Color(0xFF6D3BF5),
    accentSoft: Color(0xFFA78BFA),
    accentDim: Color(0x2E8B5CF6),
    textPrimary: Color(0xFFE9EBF2),
    textSecondary: Color(0xFF8A93A8),
    textFaint: Color(0xFF4C5568),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    aiGrad: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
  ),
  'neon': Palette(
    isLight: false,
    bg: Color(0xFF0D0716),
    surface: Color(0xFF180F2B),
    surfaceAlt: Color(0xFF221543),
    surfaceHigh: Color(0xFF2E1C5C),
    border: Color(0xFF43286F),
    borderSoft: Color(0xFF271845),
    accent: Color(0xFFD946EF),
    accentDeep: Color(0xFFA21CAF),
    accentSoft: Color(0xFFE879F9),
    accentDim: Color(0x38D946EF),
    textPrimary: Color(0xFFF9F2FF),
    textSecondary: Color(0xFFC0A6E0),
    textFaint: Color(0xFF6E5596),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFDE047),
    danger: Color(0xFFFB7185),
    aiGrad: [Color(0xFFD946EF), Color(0xFF7C3AED)],
  ),
  'emerald': Palette(
    isLight: false,
    bg: Color(0xFF06110C),
    surface: Color(0xFF0C1D14),
    surfaceAlt: Color(0xFF12291D),
    surfaceHigh: Color(0xFF1A3A2A),
    border: Color(0xFF1F4A34),
    borderSoft: Color(0xFF14301F),
    accent: Color(0xFF10B981),
    accentDeep: Color(0xFF047857),
    accentSoft: Color(0xFF34D399),
    accentDim: Color(0x3310B981),
    textPrimary: Color(0xFFE9F7EF),
    textSecondary: Color(0xFF93BBAA),
    textFaint: Color(0xFF4E7A64),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    aiGrad: [Color(0xFF10B981), Color(0xFF065F46)],
  ),
  'electric': Palette(
    isLight: false,
    bg: Color(0xFF050A16),
    surface: Color(0xFF0C1526),
    surfaceAlt: Color(0xFF12213A),
    surfaceHigh: Color(0xFF1A2E50),
    border: Color(0xFF22395F),
    borderSoft: Color(0xFF152540),
    accent: Color(0xFF3B82F6),
    accentDeep: Color(0xFF1D4ED8),
    accentSoft: Color(0xFF60A5FA),
    accentDim: Color(0x333B82F6),
    textPrimary: Color(0xFFEDF3FF),
    textSecondary: Color(0xFF93A6C8),
    textFaint: Color(0xFF54688C),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    aiGrad: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
  ),
};

const Map<String, String> themeNames = {
  'light': 'Light',
  'dark': 'Dark',
  'midnight': 'Midnight',
  'neon': 'Neon Purple',
  'emerald': 'Emerald',
  'electric': 'Electric Blue',
};

class AppColors {
  static String _key = 'light';
  static Palette _p = palettes['light']!;

  static String get key => _key;
  static bool get isLight => _p.isLight;

  static void apply(String newKey) {
    _key = palettes.containsKey(newKey) ? newKey : 'light';
    _p = palettes[_key]!;
  }

  static Color get bg => _p.bg;
  static Color get surface => _p.surface;
  static Color get surfaceAlt => _p.surfaceAlt;
  static Color get surfaceHigh => _p.surfaceHigh;
  static Color get border => _p.border;
  static Color get borderSoft => _p.borderSoft;

  static Color get accent => _p.accent;
  static Color get accentDeep => _p.accentDeep;
  static Color get accentSoft => _p.accentSoft;
  static Color get accentDim => _p.accentDim;

  static Color get textPrimary => _p.textPrimary;
  static Color get textSecondary => _p.textSecondary;
  static Color get textFaint => _p.textFaint;

  static Color get success => _p.success;
  static Color get warning => _p.warning;
  static Color get danger => _p.danger;

  static Color get aiGradStart => _p.aiGrad.first;
  static Color get aiGradEnd => _p.aiGrad.last;

  static LinearGradient get aiGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _p.aiGrad,
      );

  static LinearGradient get fabGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_p.accent, _p.accentDeep],
      );
}

class AppRadius {
  static const card = 20.0;
  static const field = 16.0;
  static const button = 16.0;
  static const chip = 12.0;
}

class AppPadding {
  static const screen = EdgeInsets.symmetric(horizontal: 20);
  static const card = EdgeInsets.all(16);
}

abstract class AppText {
  static const family = 'GGSans';

  static TextStyle get pageTitle => TextStyle(
      fontFamily: family,
      fontSize: 26,
      height: 1.2,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary);

  static TextStyle get sectionHeading => TextStyle(
      fontFamily: family,
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary);

  static TextStyle get cardTitle => TextStyle(
      fontFamily: family,
      fontSize: 15.5,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary);

  static TextStyle get body => TextStyle(
      fontFamily: family,
      fontSize: 14,
      height: 1.45,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary);

  static TextStyle get bodyStrong => TextStyle(
      fontFamily: family,
      fontSize: 14,
      height: 1.45,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary);

  static TextStyle get caption => TextStyle(
      fontFamily: family,
      fontSize: 12.5,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary);

  static TextStyle get label => TextStyle(
      fontFamily: family,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
      letterSpacing: 0.2);

  static TextStyle get button => TextStyle(
      fontFamily: family,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: Colors.white);

  static TextStyle withColor(TextStyle s, Color c) => s.copyWith(color: c);
}

class AppTheme {
  static ThemeData get current {
    final base = ThemeData(
      useMaterial3: true,
      brightness: AppColors.isLight ? Brightness.light : Brightness.dark,
      fontFamily: AppText.family,
      colorScheme: ColorScheme(
        brightness: AppColors.isLight ? Brightness.light : Brightness.dark,
        primary: AppColors.accent,
        onPrimary: Colors.white,
        secondary: AppColors.accentSoft,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.danger,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.bg,
    );
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        bodyLarge: AppText.body,
        bodyMedium: AppText.body,
        labelLarge: AppText.button,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: AppText.body.copyWith(color: AppColors.textFaint),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: AppColors.borderSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: AppColors.borderSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: AppColors.accent, width: 1.4),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.borderSoft,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: AppText.bodyStrong,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surface,
        headerForegroundColor: AppColors.textPrimary,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.surface,
      ),
    );
  }
}
