import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/theme/app_theme.dart';

/// Widget per icone SVG delle categorie
class CategoryIcon extends StatelessWidget {
  final String iconName;
  final Color? color;
  final double size;

  const CategoryIcon({
    super.key,
    required this.iconName,
    this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Theme.of(context).colorScheme.onSurface;
    
    return SvgPicture.asset(
      'assets/icons/$iconName.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
    );
  }
}

/// Container circolare con icona categoria
class CategoryIconContainer extends StatelessWidget {
  final String iconName;
  final Color backgroundColor;
  final Color? iconColor;
  final double size;
  final double iconSize;

  const CategoryIconContainer({
    super.key,
    required this.iconName,
    required this.backgroundColor,
    this.iconColor,
    this.size = 48,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    // Se bg è chiaro (es. primaryContainer), usa primary; altrimenti Colors.white
    final Color effectiveIconColor = iconColor ??
        (backgroundColor.computeLuminance() > 0.4
            ? AppColors.primary
            : Colors.white);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Center(
        child: CategoryIcon(
          iconName: iconName,
          color: effectiveIconColor,
          size: iconSize,
        ),
      ),
    );
  }
}
