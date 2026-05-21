import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/transaction.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/constants/icon_registry.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final bool showEditIcon;
  final bool showIndicator;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.showEditIcon = false,
    this.showIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    final isIncome = transaction.type == TransactionType.income;
    final amountColor = isIncome ? cs.primary : cs.secondary;
    final amountPrefix = isIncome ? '+ ' : '- ';
    final iconData = CategoryIconRegistry.resolve(transaction.category, transaction.category);

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: AppRadius.xlRadius,
        border: Border.all(color: cs.surfaceContainer.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 12, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.xlRadius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                if (showIndicator)
                  Container(
                    width: 4,
                    height: 44,
                    decoration: BoxDecoration(
                      color: amountColor,
                      borderRadius: AppRadius.fullRadius,
                    ),
                  ),
                if (showIndicator) const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isIncome
                        ? cs.primary.withValues(alpha: 0.1)
                        : cs.secondary.withValues(alpha: 0.1),
                    borderRadius: AppRadius.mdRadius,
                  ),
                  child: Icon(iconData, color: amountColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.category,
                        style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${dateFormat.format(transaction.date)}${transaction.note != null && transaction.note!.isNotEmpty ? ' • ${transaction.note}' : ''}',
                        style: AppTypography.bodySm.copyWith(color: cs.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!transaction.isSynced)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Tooltip(
                              message: 'Menunggu sinkronisasi',
                              child: Icon(Icons.cloud_off_rounded, size: 14, color: cs.tertiary),
                            ),
                          ),
                        Text(
                          '$amountPrefix${currencyFormat.format(transaction.amount)}',
                          style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w700, color: amountColor),
                        ),
                      ],
                    ),
                    if (showEditIcon) ...[
                      const SizedBox(height: 4),
                      Icon(Icons.edit_outlined, size: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
