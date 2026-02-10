import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/theme/app_theme.dart';

class ThemeTransitionOverlay extends StatefulWidget {
  final bool isChanging;
  final bool isDarkTheme;

  const ThemeTransitionOverlay({
    super.key,
    required this.isChanging,
    required this.isDarkTheme,
  });

  @override
  State<ThemeTransitionOverlay> createState() => _ThemeTransitionOverlayState();
}

class _ThemeTransitionOverlayState extends State<ThemeTransitionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  final List<String> icons = [
    'wallet',
    'shopping',
    'food',
    'transport',
    'home',
    'entertainment',
    'health',
    'education',
    'travel',
    'coffee',
    'gym',
    'gift',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 80,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
    ]).animate(_controller);

    if (widget.isChanging) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ThemeTransitionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isChanging && !oldWidget.isChanging) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isChanging) return const SizedBox.shrink();

    final bgColor = widget.isDarkTheme 
        ? const Color(0xFF0F0F0F) 
        : const Color(0xFFF5F6FA);

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              color: bgColor,
              child: Stack(
                children: [
                  // Icone animate sparse sullo schermo
                  ...List.generate(12, (index) {
                    return _buildFloatingIcon(index);
                  }),
                  
                  // Logo centrale con pulse
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(26),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/icons/wallet.svg',
                          width: 60,
                          height: 60,
                          colorFilter: ColorFilter.mode(
                            AppColors.primary,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    )
                        .animate(
                          onPlay: (controller) => controller.repeat(),
                        )
                        .scale(
                          begin: const Offset(0.9, 0.9),
                          end: const Offset(1.1, 1.1),
                          duration: 1000.ms,
                          curve: Curves.easeInOut,
                        )
                        .then()
                        .scale(
                          begin: const Offset(1.1, 1.1),
                          end: const Offset(0.9, 0.9),
                          duration: 1000.ms,
                          curve: Curves.easeInOut,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingIcon(int index) {
    final screenSize = MediaQuery.of(context).size;
    final iconName = icons[index % icons.length];
    
    final random = Random(index);
    
    // Posizioni random ma distribuite
    final left = (screenSize.width * (index % 4) / 4) + random.nextDouble() * (screenSize.width / 4 - 60);
    final top = (screenSize.height * (index ~/ 4) / 3) + random.nextDouble() * (screenSize.height / 3 - 60);
    
    final delay = index * 50;
    
    return Positioned(
      left: left,
      top: top,
      child: SvgPicture.asset(
        'assets/icons/$iconName.svg',
        width: 40,
        height: 40,
        colorFilter: ColorFilter.mode(
          AppColors.primary.withAlpha(77),
          BlendMode.srcIn,
        ),
      )
          .animate()
          .scale(
            delay: Duration(milliseconds: delay),
            begin: const Offset(0.3, 0.3),
            end: const Offset(1.0, 1.0),
            duration: 500.ms,
            curve: Curves.elasticOut,
          ),
    );
  }
}

