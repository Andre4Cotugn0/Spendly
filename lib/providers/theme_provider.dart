import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';

/// Gestisce il tema dell'app: Chiaro, Scuro, o Sistema.
class ThemeProvider extends ChangeNotifier {
  static const String _key = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  bool _isChangingTheme = false;
  bool get isChangingTheme => _isChangingTheme;

  ThemeProvider() {
    AppColors.setThemeMode(_themeMode);
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ThemeMode.system,
      );
      AppColors.setThemeMode(_themeMode);
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    // Mostra overlay di transizione
    _isChangingTheme = true;
    notifyListeners();

    // Aspetta che l'overlay sia completamente visibile
    await Future.delayed(const Duration(milliseconds: 500));

    // Ora cambia il tema
    _themeMode = mode;
    AppColors.setThemeMode(_themeMode);
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);

    // Mantieni l'overlay visibile per il resto dell'animazione
    await Future.delayed(const Duration(milliseconds: 1500));
    
    _isChangingTheme = false;
    notifyListeners();
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
