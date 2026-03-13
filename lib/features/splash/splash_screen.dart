import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/animated_dots.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dotsController;

  @override
  void initState() {
    super.initState();

    // Dot pulsing loop
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    // Chiama il callback dopo 2.8s
    Timer(const Duration(milliseconds: 2800), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF0F172A) : Colors.white;
    final titleColor =
        isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDark ? Colors.grey.shade600 : Colors.grey.shade400;
    final footerColor =
        isDark ? Colors.grey.shade700 : Colors.grey.shade400;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Body centrale ──────────────────────────────
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo + MONEYRA label
                    Column(
                      children: [
                        Image.asset(
                          'assets/icon/notext-nobg.png',
                          width: 88,
                          height: 88,
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                        .slideY(begin: -0.1, end: 0, duration: 600.ms),

                    const SizedBox(height: 20),

                    // Titolo principale
                    Text(
                      'Moneyra',
                      style: TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                        color: titleColor,
                        height: 1,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 600.ms)
                        .slideY(begin: 0.08, end: 0, delay: 200.ms, duration: 600.ms),

                    const SizedBox(height: 8),

                    // Sottotitolo "PERSONAL FINANCE"
                    Text(
                      'PERSONAL FINANCE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 4.5,
                        color: subtitleColor,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 600.ms),
                  ],
                ),
              ),
            ),

            // ── Footer ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 36),
              child: Column(
                children: [
                  // Tre dot animati
                  AnimatedDots(controller: _dotsController)
                      .animate()
                      .fadeIn(delay: 700.ms, duration: 500.ms),

                  const SizedBox(height: 16),

                  Text(
                    'SECURE BANKING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3,
                      color: footerColor,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 900.ms, duration: 500.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
