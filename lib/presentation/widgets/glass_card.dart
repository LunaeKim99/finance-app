import 'package:flutter/material.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? backgroundColor;
  final List<BoxShadow>? shadows;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.shadows,
    this.margin,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final card = Container(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surface,
        borderRadius: BorderRadius.all(Radius.circular(borderRadius ?? AppRadius.xl)),
        boxShadow: shadows ?? AppShadows.level1,
        border: border ?? Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.all(Radius.circular(borderRadius ?? AppRadius.xl)),
          child: card,
        ),
      );
    }

    return card;
  }
}
