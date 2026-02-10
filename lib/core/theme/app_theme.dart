import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
//  SEED COLORS
// ─────────────────────────────────────────────
class AppSeeds {
  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFF00D9FF);
}

// ─────────────────────────────────────────────
//  BACKWARD-COMPAT  (referenced from UI files)
// ─────────────────────────────────────────────
class AppColors {
  static const Color primary = AppSeeds.primary;
  static const Color primaryLight = Color(0xFF8B85FF);
  static const Color primaryDark = Color(0xFF4D45B5);
  static const Color secondary = AppSeeds.secondary;
  static const Color secondaryLight = Color(0xFF5CEBFF);

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

  static Color get background => _isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F6FA);
  static Color get surface => _isDark ? const Color(0xFF1A1A2E) : Colors.white;
  static Color get surfaceLight => _isDark ? const Color(0xFF25253D) : const Color(0xFFEDEEF3);
  static Color get surfaceLighter => _isDark ? const Color(0xFF2F2F4A) : const Color(0xFFE3E4EC);
  static Color get textPrimary => _isDark ? const Color(0xFFF2F2F7) : const Color(0xFF1C1C1E);
  static Color get textSecondary => _isDark ? const Color(0xFFA5A5BF) : const Color(0xFF6E6E80);
  static Color get textTertiary => _isDark ? const Color(0xFF63637A) : const Color(0xFF9D9DAF);
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFFBF40);
  static const Color error = Color(0xFFFF453A);

  /// Testo per sfondo colorato - bianco sempre per gradient e sfondi accesi
  static const Color textOnAccent = Colors.white;

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [AppSeeds.primary, AppSeeds.secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─────────────────────────────────────────────
//  SPACING / RADIUS TOKENS
// ─────────────────────────────────────────────
class Dimens {
  static const double radiusS = 10;
  static const double radiusM = 14;
  static const double radiusL = 20;
  static const double radiusXL = 28;
  static const double paddingS = 8;
  static const double paddingM = 16;
  static const double paddingL = 20;
  static const double paddingXL = 24;
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

    final bg       = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F6FA);
    final surface  = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final surfLt   = isDark ? const Color(0xFF25253D) : const Color(0xFFEDEEF3);
    final surfLtr  = isDark ? const Color(0xFF2F2F4A) : const Color(0xFFE3E4EC);
    final text1    = isDark ? const Color(0xFFF2F2F7) : const Color(0xFF1C1C1E);
    final text2    = isDark ? const Color(0xFFA5A5BF) : const Color(0xFF6E6E80);
    final text3    = isDark ? const Color(0xFF63637A) : const Color(0xFF9D9DAF);
    const primary  = AppSeeds.primary;
    const secondary = AppSeeds.secondary;
    const error    = Color(0xFFFF453A);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: Colors.black,
      error: error,
      onError: Colors.white,
      surface: surface,
      onSurface: text1,
      surfaceContainerHighest: surfLtr,
    );

    final textTheme = GoogleFonts.interTextTheme(
      TextTheme(
        displayLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: text1, letterSpacing: -0.5, decoration: TextDecoration.none),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: text1, letterSpacing: -0.5, decoration: TextDecoration.none),
        displaySmall:  TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: text1, decoration: TextDecoration.none),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: text1, decoration: TextDecoration.none),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: text1, decoration: TextDecoration.none),
        titleLarge:    TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: text1, decoration: TextDecoration.none),
        titleMedium:   TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: text1, decoration: TextDecoration.none),
        bodyLarge:     TextStyle(fontSize: 16, color: text1, decoration: TextDecoration.none),
        bodyMedium:    TextStyle(fontSize: 14, color: text2, decoration: TextDecoration.none),
        bodySmall:     TextStyle(fontSize: 12, color: text3, decoration: TextDecoration.none),
        labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text1, decoration: TextDecoration.none),
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
        titleTextStyle: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: text1),
        iconTheme: IconThemeData(color: text1),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimens.radiusL)),
        margin: const EdgeInsets.symmetric(horizontal: Dimens.paddingM, vertical: Dimens.paddingS),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimens.radiusM)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimens.radiusM)),
          side: BorderSide(color: primary.withAlpha(100)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimens.radiusM)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfLt,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(Dimens.radiusM), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Dimens.radiusM), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Dimens.radiusM), borderSide: const BorderSide(color: primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Dimens.radiusM), borderSide: const BorderSide(color: error, width: 1)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.inter(color: text3, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: text2, fontSize: 14),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: text3,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimens.radiusXL)),
        titleTextStyle: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: text1),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? surfLtr : const Color(0xFF2D2D3A),
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimens.radiusM)),
        behavior: SnackBarBehavior.floating,
      ),

      dividerTheme: DividerThemeData(color: surfLt, thickness: 1, space: 1),

      chipTheme: ChipThemeData(
        backgroundColor: surfLt,
        selectedColor: primary.withAlpha(50),
        labelStyle: GoogleFonts.inter(fontSize: 14, color: text1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimens.radiusS)),
        side: BorderSide.none,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return text3;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary.withAlpha(80);
          return surfLt;
        }),
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: Dimens.paddingL, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimens.radiusM)),
        iconColor: text2,
        textColor: text1,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CONTEXT EXTENSIONS
// ─────────────────────────────────────────────
extension SpendlyColors on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bg          => Theme.of(this).scaffoldBackgroundColor;
  Color get surface     => colors.surface;
  Color get surfaceAlt  => isDark ? const Color(0xFF25253D) : const Color(0xFFEDEEF3);
  Color get primary     => colors.primary;
  Color get secondary   => colors.secondary;
  Color get textPrimary => colors.onSurface;
  Color get textSecondary => isDark ? const Color(0xFFA5A5BF) : const Color(0xFF6E6E80);
  Color get textTertiary => isDark ? const Color(0xFF63637A) : const Color(0xFF9D9DAF);
  Color get success     => const Color(0xFF34C759);
  Color get warning     => const Color(0xFFFFBF40);
  Color get error       => colors.error;

  LinearGradient get primaryGradient => const LinearGradient(
    colors: [AppSeeds.primary, AppSeeds.secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
