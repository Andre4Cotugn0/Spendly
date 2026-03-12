import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
//  SEED COLORS
// ─────────────────────────────────────────────
class AppSeeds {
  static const Color primary = Color(0xFF1F6BFF);
  static const Color primaryLight = Color(0xFF4A8CFF);
}

// ─────────────────────────────────────────────
//  GRADIENTS
// ─────────────────────────────────────────────
class AppGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [Color(0xFF1F6BFF), Color(0xFF4A8CFF)],
    begin: Alignment(-0.71, -0.71), // 135°
    end: Alignment(0.71, 0.71),
  );
}

// ─────────────────────────────────────────────
//  MAIN COLORS  (referenced from UI files)
// ─────────────────────────────────────────────
class AppColors {
  // Light mode palette
  static const Color primaryLight_  = Color(0xFF1F6BFF);
  static const Color primaryLightV2 = Color(0xFF4A8CFF);

  static ThemeMode _themeMode = ThemeMode.system;

  static void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
  }

  static bool get _isDark {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  // ── Dynamic getters ──
  static Color get background       => _isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  static Color get surface          => _isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
  static Color get surfaceVariant   => _isDark ? const Color(0xFF162040) : const Color(0xFFEFF4FF);
  static Color get surfaceLight     => _isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  static Color get primary          => _isDark ? const Color(0xFF4A8CFF) : const Color(0xFF1F6BFF);
  static Color get primaryLight     => _isDark ? const Color(0xFF60A5FA) : const Color(0xFF4A8CFF);
  static Color get primaryContainer => _isDark ? const Color(0xFF1E3A6E) : const Color(0xFFDBEAFE);
  static Color get textPrimary      => _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  static Color get textSecondary    => _isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155);
  static Color get textTertiary     => _isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  static Color get border           => _isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  static Color get success          => _isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
  static Color get warning          => _isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B);
  static Color get error            => _isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);

  static const Color textOnAccent = Colors.white;
}

// ─────────────────────────────────────────────
//  SPACING / RADIUS TOKENS
// ─────────────────────────────────────────────
class Dimens {
  // Spacing
  static const double spaceXS  = 4;
  static const double spaceS   = 8;
  static const double spaceM   = 16;
  static const double spaceL   = 24;
  static const double spaceXL  = 32;
  static const double spaceXXL = 48;

  // Radius
  static const double radiusXS   = 6;
  static const double radiusS    = 12;
  static const double radiusM    = 16;
  static const double radiusL    = 24;
  static const double radiusXL   = 32;
  static const double radiusFull = 999;

  // Legacy aliases (backward compat)
  static const double paddingS  = spaceS;
  static const double paddingM  = spaceM;
  static const double paddingL  = spaceL;
  static const double paddingXL = spaceXL;
}

// ─────────────────────────────────────────────
//  THEME FACTORY
// ─────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme => _build(Brightness.dark);
  static ThemeData get lightTheme => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    final bg             = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final surface        = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final surfLt         = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final primColor      = isDark ? const Color(0xFF4A8CFF) : const Color(0xFF1F6BFF);
    final primContainer  = isDark ? const Color(0xFF1E3A6E) : const Color(0xFFDBEAFE);
    final borderColor    = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final text1          = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final text2          = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155);
    final text3          = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final errorColor     = isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primColor,
      onPrimary: Colors.white,
      secondary: isDark ? const Color(0xFF60A5FA) : const Color(0xFF4A8CFF),
      onSecondary: Colors.white,
      error: errorColor,
      onError: Colors.white,
      surface: surface,
      onSurface: text1,
      surfaceContainerHighest: surfLt,
    );

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      TextTheme(
        displayLarge:   TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: text1, letterSpacing: -0.5, decoration: TextDecoration.none),
        displayMedium:  TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: text1, letterSpacing: -0.5, decoration: TextDecoration.none),
        displaySmall:   TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: text1, decoration: TextDecoration.none),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: text1, decoration: TextDecoration.none),
        headlineSmall:  TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: text1, decoration: TextDecoration.none),
        titleLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: text1, decoration: TextDecoration.none),
        titleMedium:    TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: text1, decoration: TextDecoration.none),
        bodyLarge:      TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: text1, decoration: TextDecoration.none),
        bodyMedium:     TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: text2, decoration: TextDecoration.none),
        bodySmall:      TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: text3, decoration: TextDecoration.none),
        labelLarge:     TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: text1, decoration: TextDecoration.none),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: colorScheme,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w600, color: text1),
        iconTheme: IconThemeData(color: text1),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.radiusL),
          side: BorderSide(color: borderColor, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: Dimens.paddingM, vertical: Dimens.paddingS),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimens.radiusFull)),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimens.radiusFull)),
          side: BorderSide(color: primColor.withAlpha(100)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primColor,
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primColor,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimens.radiusXL)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfLt,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(Dimens.radiusM), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Dimens.radiusM), borderSide: BorderSide(color: borderColor, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Dimens.radiusM), borderSide: BorderSide(color: primColor, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Dimens.radiusM), borderSide: BorderSide(color: errorColor, width: 1)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.plusJakartaSans(color: text3, fontSize: 14),
        labelStyle: GoogleFonts.plusJakartaSans(color: text2, fontSize: 14),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primColor,
        unselectedItemColor: text3,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimens.radiusL)),
        titleTextStyle: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w600, color: text1),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? surfLt : const Color(0xFF0F172A),
        contentTextStyle: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimens.radiusM)),
        behavior: SnackBarBehavior.floating,
      ),

      dividerTheme: DividerThemeData(color: borderColor, thickness: 1, space: 1),

      chipTheme: ChipThemeData(
        backgroundColor: surfLt,
        selectedColor: primContainer,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: text1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimens.radiusFull)),
        side: BorderSide.none,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primColor;
          return text3;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primColor.withAlpha(80);
          return surfLt;
        }),
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: Dimens.paddingL, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimens.radiusM)),
        iconColor: text2,
        textColor: text1,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primColor,
        linearTrackColor: primContainer,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CONTEXT EXTENSIONS
// ─────────────────────────────────────────────
extension MoneyraColors on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bg               => Theme.of(this).scaffoldBackgroundColor;
  Color get surface          => colors.surface;
  Color get surfaceVariant   => isDark ? const Color(0xFF162040) : const Color(0xFFEFF4FF);
  Color get surfaceAlt       => isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  Color get surfaceLight     => isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  Color get primary          => colors.primary;
  Color get primaryLight     => isDark ? const Color(0xFF60A5FA) : const Color(0xFF4A8CFF);
  Color get primaryContainer => isDark ? const Color(0xFF1E3A6E) : const Color(0xFFDBEAFE);
  Color get border           => isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  Color get textPrimary      => colors.onSurface;
  Color get textSecondary    => isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155);
  Color get textTertiary     => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get success          => isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
  Color get warning          => isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B);
  Color get error            => colors.error;

  LinearGradient get primaryGradient => AppGradients.primary;
}
