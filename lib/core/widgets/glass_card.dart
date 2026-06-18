import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry padding;
  final Border? border;
  final Gradient? gradient;
  final List<BoxShadow>? shadow;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.blur = 12.0,
    this.padding = const EdgeInsets.all(20.0),
    this.border,
    this.gradient,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultGradient = isDark
        ? AppTheme.darkGlassGradient
        : AppTheme.lightGlassGradient;

    final defaultBorder = Border.all(
      color: isDark
          ? Colors.white.withOpacity(0.08)
          : Colors.black.withOpacity(0.06),
      width: 1.0,
    );

    final defaultShadow = [
      BoxShadow(
        color: isDark
            ? Colors.black.withOpacity(0.3)
            : Colors.black.withOpacity(0.04),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: gradient ?? defaultGradient,
            border: border ?? defaultBorder,
            boxShadow: shadow ?? defaultShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}
