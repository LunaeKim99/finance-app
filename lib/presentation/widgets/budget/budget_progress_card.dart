import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/icon_registry.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';

class BudgetProgressCard extends StatelessWidget {
  final String category;
  final double budgetAmount;
  final double spentAmount;
  final VoidCallback? onTap;

  const BudgetProgressCard({
    super.key,
    required this.category,
    required this.budgetAmount,
    required this.spentAmount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final percent = budgetAmount > 0 ? (spentAmount / budgetAmount) : 0.0;
    final isOver = percent >= 1.0;
    final isWarning = percent >= 0.8 && percent < 1.0;
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final remaining = budgetAmount - spentAmount;

    Color progressColor;
    Color iconColor;
    Color bgColor;
    if (isOver) {
      progressColor = AppColors.error;
      iconColor = AppColors.error;
      bgColor = AppColors.errorContainer.withValues(alpha: 0.15);
    } else if (isWarning) {
      progressColor = AppColors.tertiary;
      iconColor = AppColors.tertiary;
      bgColor = AppColors.tertiaryFixed.withValues(alpha: 0.15);
    } else {
      progressColor = AppColors.primary;
      iconColor = AppColors.primary;
      bgColor = AppColors.primary.withValues(alpha: 0.08);
    }

    final iconData = CategoryIconRegistry.resolve(category, category);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isOver ? bgColor : AppColors.surfaceContainerLowest,
        borderRadius: AppRadius.xlRadius,
        border: Border.all(
          color: isOver ? AppColors.errorContainer : AppColors.surfaceContainer,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: AppRadius.fullRadius,
                ),
                child: Icon(iconData, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category, style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                    const SizedBox(height: 2),
                    Text(
                      isOver ? 'Melebihi budget!' : 'Sisa ${currencyFormat.format(remaining)}',
                      style: AppTypography.bodySm.copyWith(
                        color: isOver ? AppColors.error : AppColors.onSurfaceVariant,
                        fontWeight: isOver ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(currencyFormat.format(spentAmount), style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                  Text('dari ${currencyFormat.format(budgetAmount)}', style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: AppRadius.fullRadius,
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceContainer,
              valueColor: AlwaysStoppedAnimation(progressColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(percent * 100).toStringAsFixed(0)}% Terpakai',
              style: AppTypography.labelMono.copyWith(
                fontSize: 10,
                color: isOver ? AppColors.error : AppColors.onSurfaceVariant,
                fontWeight: isOver ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
