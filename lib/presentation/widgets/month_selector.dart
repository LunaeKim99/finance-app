import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_radius.dart';

class MonthSelector extends StatelessWidget {
  final DateTime selectedMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool compact;

  const MonthSelector({
    super.key,
    required this.selectedMonth,
    required this.onPrevious,
    required this.onNext,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('MMMM yyyy', 'id_ID').format(selectedMonth);

    if (compact) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: AppRadius.fullRadius,
            border: Border.all(color: AppColors.surfaceContainerHighest),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left_rounded, color: AppColors.onSurfaceVariant),
                visualDensity: VisualDensity.compact,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(monthName,
                    style: AppTypography.bodyMd.copyWith(
                        fontWeight: FontWeight.w700, color: AppColors.onSurface)),
              ),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceVariant),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: AppRadius.xlRadius,
          border: Border.all(color: AppColors.surfaceContainer),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left_rounded, color: AppColors.onSurfaceVariant),
              visualDensity: VisualDensity.compact,
            ),
            Text(monthName,
                style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
            IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceVariant),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
