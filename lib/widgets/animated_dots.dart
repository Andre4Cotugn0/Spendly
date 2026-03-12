import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  Widget condiviso: tre dot con animazione
//  sequenziale a bounce. Usato in SplashScreen
//  e ThemeTransitionOverlay.
// ─────────────────────────────────────────────
class AnimatedDots extends StatelessWidget {
  final AnimationController controller;

  const AnimatedDots({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _BounceDot(controller: controller, phaseOffset: i * 0.28),
        );
      }),
    );
  }
}

class _BounceDot extends StatelessWidget {
  final AnimationController controller;
  final double phaseOffset;

  const _BounceDot({required this.controller, required this.phaseOffset});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = (controller.value + phaseOffset) % 1.0;
        final active = t < 0.5;
        final norm = active ? t / 0.5 : 0.0;
        final bell = norm <= 0.5 ? (2 * norm) : (2 * (1 - norm));
        final scale = 1.0 + (active ? 0.45 * bell : 0.0);
        final opacity = active ? (0.35 + 0.65 * bell) : 0.35;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1F6BFF).withValues(alpha: opacity),
            ),
          ),
        );
      },
    );
  }
}
