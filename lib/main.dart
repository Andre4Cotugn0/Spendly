import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'providers/expense_provider.dart';
import 'providers/theme_provider.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/splash/splash_screen.dart';
import 'widgets/theme_transition_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await initializeDateFormatting('it_IT', null);

  // Consenti il fetch runtime dei font finche' Inter non e' bundled.
  GoogleFonts.config.allowRuntimeFetching = true;

  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  final initialThemeMode = await ThemeProvider.loadSavedThemeMode();

  // Solo orientamento verticale (portrait), app pensata per telefoni
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Edge-to-edge: barra di stato e navigazione trasparenti
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(MyApp(showOnboarding: !onboardingCompleted, initialThemeMode: initialThemeMode));
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;
  final ThemeMode initialThemeMode;
  const MyApp({super.key, required this.showOnboarding, required this.initialThemeMode});

  static bool _resolveIsDarkTarget(ThemeProvider themeProvider) {
    final target = themeProvider.targetThemeMode ?? themeProvider.themeMode;
    if (target == ThemeMode.system) {
      return WidgetsBinding
              .instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return target == ThemeMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(initialThemeMode: initialThemeMode)),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Moneyra',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            // builder esegue SOPRA il Navigator: l'overlay copre sempre
            // tutte le route, incluse quelle di impostazioni
            builder: (ctx, navigatorChild) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  navigatorChild!,
                  if (themeProvider.isChangingTheme)
                    ThemeTransitionOverlay(
                      isChanging: true,
                      isDarkTarget: _resolveIsDarkTarget(themeProvider),
                      onComplete: themeProvider.notifyOverlayComplete,
                    ),
                ],
              );
            },
            home: _AppWithOverlay(
              showOnboarding: showOnboarding,
            ),
          );
        },
      ),
    );
  }
}

class _AppWithOverlay extends StatefulWidget {
  final bool showOnboarding;

  const _AppWithOverlay({
    required this.showOnboarding,
  });

  @override
  State<_AppWithOverlay> createState() => _AppWithOverlayState();
}

class _AppWithOverlayState extends State<_AppWithOverlay> {
  bool _splashDone = false;

  void _onSplashComplete() {
    setState(() => _splashDone = true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Widget screen = _splashDone
        ? (widget.showOnboarding
            ? const OnboardingScreen()
            : const HomeScreen())
        : SplashScreen(onComplete: _onSplashComplete);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeIn,
        child: KeyedSubtree(
          key: ValueKey(_splashDone),
          child: screen,
        ),
      ),
    );
  }
}
