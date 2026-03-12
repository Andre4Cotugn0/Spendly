import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';

/// Gestisce il tema dell'app: Chiaro, Scuro, o Sistema.
class ThemeProvider extends ChangeNotifier {
  static const String _key = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  ThemeMode? _targetThemeMode;
  ThemeMode? get targetThemeMode => _targetThemeMode;

  bool _isChangingTheme = false;
  bool get isChangingTheme => _isChangingTheme;

  Completer<void>? _overlayCompleter;

  ThemeProvider({ThemeMode initialThemeMode = ThemeMode.system})
      : _themeMode = initialThemeMode {
    AppColors.setThemeMode(_themeMode);
  }

  static Future<ThemeMode> loadSavedThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value == null) return ThemeMode.system;
    return ThemeMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_isChangingTheme) return;

    _targetThemeMode = mode;
    _isChangingTheme = true;
    _overlayCompleter = Completer<void>();
    notifyListeners();

    // Attende che l'overlay copra lo schermo.
    // addPostFrameCallback ~16ms + fade-in ~250ms = ~266ms → 400ms ampio margine
    await Future.delayed(const Duration(milliseconds: 400));

    _themeMode = mode;
    AppColors.setThemeMode(_themeMode);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);

    // Aspetta che l'overlay completi la sua animazione.
    // Timeout di sicurezza: se qualcosa va storto l'app non rimane bloccata.
    await _overlayCompleter!.future.timeout(
      const Duration(seconds: 2),
      onTimeout: () {},
    );

    _isChangingTheme = false;
    _targetThemeMode = null;
    _overlayCompleter = null;
    notifyListeners();
  }

  /// Chiamato dall'overlay quando la sua animazione è completata.
  void notifyOverlayComplete() {
    if (_overlayCompleter != null && !_overlayCompleter!.isCompleted) {
      _overlayCompleter!.complete();
    }
  }

  /// Label leggibile per l'UI
  String get label {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Chiaro';
      case ThemeMode.dark:
        return 'Scuro';
      case ThemeMode.system:
        return 'Sistema';
    }
  }
}
