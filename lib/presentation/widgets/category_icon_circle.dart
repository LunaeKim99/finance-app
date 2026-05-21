import 'package:flutter/material.dart';
import '../../core/constants/icon_registry.dart';

class CategoryIconCircle extends StatelessWidget {
  final String categoryId;
  final String categoryName;
  final double size;
  final Color? color;

  const CategoryIconCircle({
    super.key,
    required this.categoryId,
    this.categoryName = '',
    this.size = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconData = CategoryIconRegistry.resolve(categoryId, categoryName.isNotEmpty ? categoryName : categoryId);
    final resolvedColor = color ?? cs.primary.withValues(alpha: 0.1);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: resolvedColor,
        borderRadius: BorderRadius.all(Radius.circular(size / 4)),
      ),
      child: Icon(iconData, color: color ?? cs.primary, size: size * 0.5),
    );
  }
}
