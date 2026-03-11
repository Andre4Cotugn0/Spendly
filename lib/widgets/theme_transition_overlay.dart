import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ThemeTransitionOverlay extends StatefulWidget {
  final bool isChanging;
  final bool isDarkTarget;
  final VoidCallback onComplete;

  const ThemeTransitionOverlay({
    super.key,
    required this.isChanging,
    required this.isDarkTarget,
    required this.onComplete,
  });

  @override
  State<ThemeTransitionOverlay> createState() => _ThemeTransitionOverlayState();
}

class _ThemeTransitionOverlayState extends State<ThemeTransitionOverlay>
    with TickerProviderStateMixin {
  // Unico controller con TweenSequence a 3 fasi:
  // 18% fade-in (~250ms) | 64% hold (~900ms) | 18% fade-out (~250ms) — totale ~1400ms
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _dotsController;

  // Garantisce che onComplete venga chiamato al massimo una volta
  bool _completedOnce = false;

  void _safeComplete() {
    if (!_completedOnce) {
      _completedOnce = true;
      widget.onComplete();
    }
  }

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 64,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 18,
      ),
    ]).animate(_fadeController);

    // Percorso normale: animazione completata
    _fadeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _safeComplete();
      }
    });

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    if (widget.isChanging) {
      // addPostFrameCallback: garantisce che il widget sia nel tree
      // e il ticker sia attivo prima di avviare l'animazione
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fadeController.forward(from: 0);
      });
    }
  }

  @override
  void didUpdateWidget(ThemeTransitionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isChanging && !oldWidget.isChanging) {
      _completedOnce = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fadeController.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    // Fallback: se il widget viene rimosso prima che l'animazione finisca,
    // completa comunque il Completer per sbloccare setThemeMode()
    _safeComplete();
    _fadeController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isChanging) return const SizedBox.shrink();

    final bgColor = widget.isDarkTarget
        ? const Color(0xFF0F172A)
        : Colors.white;
    final titleColor = widget.isDarkTarget
        ? Colors.white
        : const Color(0xFF0F172A);
    final subtitleColor = widget.isDarkTarget
        ? Colors.grey.shade600
        : Colors.grey.shade400;
    final footerColor = widget.isDarkTarget
        ? Colors.grey.shade700
        : Colors.grey.shade400;

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, _) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Material(
              color: bgColor,
              child: SafeArea(
                child: Column(
                  children: [
                    // ── Body centrale ──────────────────────────
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo + label MONEYRA
                            Column(
                              children: [
                                Image.asset(
                                  'assets/icon/icon-no-bg.png',
                                  width: 72,
                                  height: 72,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'MONEYRA',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 3,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            )
                                .animate()
                                .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                                .slideY(begin: -0.08, end: 0, duration: 300.ms),

                            const SizedBox(height: 40),

                            // Titolo
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
                                .fadeIn(delay: 80.ms, duration: 300.ms)
                                .slideY(begin: 0.06, end: 0, delay: 80.ms, duration: 300.ms),

                            const SizedBox(height: 8),

                            // Sottotitolo
                            Text(
                              widget.isDarkTarget
                                  ? 'TEMA SCURO'
                                  : 'TEMA CHIARO',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 4.5,
                                color: subtitleColor,
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 160.ms, duration: 300.ms),
                          ],
                        ),
                      ),
                    ),

                    // ── Footer ───────────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(bottom: 36),
                      child: Column(
                        children: [
                          _AnimatedDots(controller: _dotsController)
                              .animate()
                              .fadeIn(delay: 250.ms, duration: 300.ms),
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
                              .fadeIn(delay: 320.ms, duration: 300.ms),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Tre dot con animazione sequenziale (bounce)
// ─────────────────────────────────────────────
class _AnimatedDots extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedDots({required this.controller});

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

