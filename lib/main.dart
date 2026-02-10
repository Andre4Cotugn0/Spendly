import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'providers/expense_provider.dart';
import 'providers/theme_provider.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'widgets/theme_transition_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await initializeDateFormatting('it_IT', null);
  
  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );
  
  runApp(MyApp(showOnboarding: !onboardingCompleted));
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;
  const MyApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Spendly',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: _AppWithOverlay(
              showOnboarding: showOnboarding,
            ),
          );
        },
      ),
    );
  }
}

class _AppWithOverlay extends StatelessWidget {
  final bool showOnboarding;

  const _AppWithOverlay({
    required this.showOnboarding,
  });

  @override
  Widget build(BuildContext context) {
    // Ascolta i cambiamenti del ThemeProvider
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Determina se il tema corrente è scuro
        final brightness = Theme.of(context).brightness;
        final isDark = brightness == Brightness.dark;

        return Stack(
          fit: StackFit.expand,
          children: [
            showOnboarding ? const OnboardingScreen() : const HomeScreen(),
            if (themeProvider.isChangingTheme)
              ThemeTransitionOverlay(
                isChanging: themeProvider.isChangingTheme,
                isDarkTheme: isDark,
              ),
          ],
        );
      },
    );
  }
}
